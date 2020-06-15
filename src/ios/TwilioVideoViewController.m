#import "TwilioVideoViewController.h"

// CALL EVENTS
NSString *const OPENED = @"OPENED";
NSString *const CONNECTED = @"CONNECTED";
NSString *const CONNECT_FAILURE = @"CONNECT_FAILURE";
NSString *const DISCONNECTED = @"DISCONNECTED";
NSString *const DISCONNECTED_WITH_ERROR = @"DISCONNECTED_WITH_ERROR";
NSString *const PARTICIPANT_CONNECTED = @"PARTICIPANT_CONNECTED";
NSString *const PARTICIPANT_DISCONNECTED = @"PARTICIPANT_DISCONNECTED";
NSString *const AUDIO_TRACK_ADDED = @"AUDIO_TRACK_ADDED";
NSString *const AUDIO_TRACK_REMOVED = @"AUDIO_TRACK_REMOVED";
NSString *const VIDEO_TRACK_ADDED = @"VIDEO_TRACK_ADDED";
NSString *const VIDEO_TRACK_REMOVED = @"VIDEO_TRACK_REMOVED";
NSString *const PERMISSIONS_REQUIRED = @"PERMISSIONS_REQUIRED";
NSString *const HANG_UP = @"HANG_UP";
NSString *const CLOSED = @"CLOSED";

@implementation TwilioVideoViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[TwilioVideoManager getInstance] setActionDelegate:self];

    [[TwilioVideoManager getInstance] publishEvent: OPENED];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self logMessage:[NSString stringWithFormat:@"TwilioVideo v%ld", (long)[TwilioVideoSDK version]]];
    
    // Configure access token for testing. Create one manually in the console
    // at https://www.twilio.com/console/video/runtime/testing-tools
    self.accessToken = @"TWILIO_ACCESS_TOKEN";
    
    // Preview our local camera track in the local video preview view.
    [self startPreview];
    
    // Disconnect and mic button will be displayed when client is connected to a room.
    self.micButton.hidden = YES;
    [self.micButton setImage:[UIImage imageNamed:@"mic"] forState: UIControlStateNormal];
    [self.micButton setImage:[UIImage imageNamed:@"no_mic"] forState: UIControlStateSelected];
    [self.videoButton setImage:[UIImage imageNamed:@"video"] forState: UIControlStateNormal];
    [self.videoButton setImage:[UIImage imageNamed:@"no_video"] forState: UIControlStateSelected];
    
    // Customize button colors
    NSString *primaryColor = [self.config primaryColorHex];
    if (primaryColor != NULL) {
        self.disconnectButton.backgroundColor = [TwilioVideoConfig colorFromHexString:primaryColor];
    }
    
    NSString *secondaryColor = [self.config secondaryColorHex];
    if (secondaryColor != NULL) {
        self.micButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.videoButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.cameraSwitchButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
    }
    
    self.callTitleLabel.text = [self.config i18nCallTitle];
    self.callDurationLabel.text = [self.config i18nCallDuration];
    
    [self setShadowForView:self.callTimeLabel];
    [self setShadowForView:self.callDurationLabel];
    [self setShadowForView:self.callTitleLabel];
    [self setShadowForView:self.bannerView];
    self.bannerView.layer.cornerRadius = 8.0f;

    [self setGradientForView:self.topGradientView colors:[NSArray arrayWithObjects: (id) [[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor, (id)[[UIColor whiteColor] colorWithAlphaComponent:0.0].CGColor, nil]];
    [self setGradientForView:self.bottomGradientView colors:[NSArray arrayWithObjects:(id)[[UIColor whiteColor] colorWithAlphaComponent:0.0].CGColor, (id) [[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor, nil]];
    self.topGradientView.alpha = 0.8f;
    self.bottomGradientView.alpha = 0.8f;
    
    [self startDurationTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.callDurationTimer invalidate];
}

#pragma mark - Public

- (void)connectToRoom:(NSString*)room token:(NSString *)token {
    self.roomName = room;
    self.accessToken = token;
    [self showRoomUI:YES];

    [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
         if (grantedPermissions) {
             [self doConnect];
         } else {
             [[TwilioVideoManager getInstance] publishEvent: PERMISSIONS_REQUIRED];
             [self handleConnectionError: [self.config i18nConnectionError]];
         }
    }];
}

- (IBAction)disconnectButtonPressed:(id)sender {
    if ([self.config hangUpInApp]) {
        [[TwilioVideoManager getInstance] publishEvent: HANG_UP];
    } else {
        [self onDisconnect];
    }
}

- (IBAction)micButtonPressed:(id)sender {
    // We will toggle the mic to mute/unmute and change the title according to the user action.
    
    if (self.localAudioTrack) {
        self.localAudioTrack.enabled = !self.localAudioTrack.isEnabled;
        // If audio not enabled, mic is muted and button crossed out
        [self.micButton setSelected: !self.localAudioTrack.isEnabled];
    }
}

- (IBAction)cameraSwitchButtonPressed:(id)sender {
    [self flipCamera];
}

- (IBAction)videoButtonPressed:(id)sender {
    [self toggleVideoTrackOn:!self.localVideoTrack.isEnabled];
}

- (IBAction) toggleControlsVisibility:(id)sender {
    CGFloat alpha = 1.0f;
    CGFloat gradientAlpha = 0.8f;
    if (self.callTitleLabel.alpha == 1.0f) {
        alpha = 0.0f;
        gradientAlpha = 0.0f;
    }
    
    [UIView animateWithDuration:0.450 animations:^{
        self.callTitleLabel.alpha = alpha;
        self.callDurationLabel.alpha = alpha;
        self.callTimeLabel.alpha = alpha;
        self.disconnectButton.alpha = alpha;
        self.micButton.alpha = alpha;
        self.videoButton.alpha = alpha;
    
        self.topGradientView.alpha = gradientAlpha;
        self.bottomGradientView.alpha = gradientAlpha;
    }];
}

- (IBAction)bannerButton1Pressed:(id)sender {
    [self toggleBanner:NO];
    [self toggleVideoTrackOn:NO];
}

- (IBAction)swipeUpOnBanner:(id)sender {
    [self toggleBanner:NO];
}

#pragma mark - Private

- (void) setShadowForView:(UIView*)view {
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.5f;
    view.layer.shadowRadius = 4.0f;
    view.layer.shadowOffset = CGSizeMake(0, 2);
}

- (void) setGradientForView:(UIView*)view colors:(NSArray*)colors {
    CAGradientLayer* gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = view.bounds;
    gradientLayer.colors = colors;
    [view.layer addSublayer: gradientLayer];
}

- (void) startDurationTimer {
    self.currentCallDuration = self.config.startCallTimeInSeconds;
    self.callDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        int minutes = self.currentCallDuration / 60;
        int seconds = self.currentCallDuration - minutes * 60.0;
        NSString *durationText = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
        self.callTimeLabel.text = durationText;
        
        self.currentCallDuration++;
    }];
}

- (void) toggleBanner:(BOOL)show {
    if (show) {
        if (self.lastBannerInteractionDate != nil) {
            NSTimeInterval timeSinceLastInteraction = -[self.lastBannerInteractionDate timeIntervalSinceNow];
            if (timeSinceLastInteraction < self.config.ignoreNQBannerInSeconds) {
                return; // skip this show
            }
        }
    } else {
        // Hiding the banner, so mark the time so we can ignore next banner show
        self.lastBannerInteractionDate = [NSDate date];
    }
    
    if (show) {
        self.bannerBottomConstraint.constant = -80;
        self.previewTopConstraint.constant = 94;
        self.callTitleTopConstraint.constant = 94;
    } else {
        self.bannerBottomConstraint.constant = 80;
        self.previewTopConstraint.constant = 20;
        self.callTitleTopConstraint.constant = 20;
    }
    [UIView animateWithDuration:0.35 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void) toggleVideoTrackOn:(BOOL)on {
    if(self.localVideoTrack){
        self.localVideoTrack.enabled = on;
        [self.videoButton setSelected: !on];
    }
}

- (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return NO;
}

- (void)startPreview {
    // TVICameraCapturer is not supported with the Simulator.
    if ([self isSimulator]) {
        [self logMessage:@"Preview view does not work in Simulator"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.previewView removeFromSuperview];
        });
        return;
    }
    
    self.cameraSource = [[TVICameraSource alloc] initWithDelegate:nil];
    self.frontCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    self.backCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    
    self.localVideoTrack = [TVILocalVideoTrack trackWithSource:self.cameraSource enabled:YES name:@"Camera"];
    if (!self.localVideoTrack) {
        [self logMessage:@"Failed to add video track"];
    } else {
        // Add renderer to video track for local preview
        [self.localVideoTrack addRenderer:self.previewView];
        
        [self logMessage:@"Video track created"];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(flipCamera)];
        
        self.videoButton.hidden = NO;
        self.cameraSwitchButton.hidden = NO;
        [self.previewView addGestureRecognizer:tap];
    }
    
    [self.cameraSource startCaptureWithDevice:self.frontCamera completion:^(AVCaptureDevice * _Nonnull device, TVIVideoFormat * _Nonnull format, NSError * _Nullable error) {
        [self cameraCaptureDidStartWithDevice:device];
    }];
}

- (void)flipCamera {
    if (self.cameraSource.device == self.frontCamera) {
        [self.cameraSource selectCaptureDevice:self.backCamera completion:^(AVCaptureDevice * _Nonnull device, TVIVideoFormat * _Nonnull format, NSError * _Nullable error) {
            [self cameraCaptureDidStartWithDevice:device];
        }];
    } else {
        [self.cameraSource selectCaptureDevice:self.frontCamera completion:^(AVCaptureDevice * _Nonnull device, TVIVideoFormat * _Nonnull format, NSError * _Nullable error) {
            [self cameraCaptureDidStartWithDevice:device];
        }];
    }
}

- (void)prepareLocalMedia {
    
    // We will share local audio and video when we connect to room.
    
    // Create an audio track.
    if (!self.localAudioTrack) {
        self.localAudioTrack = [TVILocalAudioTrack trackWithOptions:nil
                                                            enabled:YES
                                                               name:@"Microphone"];
        
        if (!self.localAudioTrack) {
            [self logMessage:@"Failed to add audio track"];
        }
    }
    
    // Create a video track which captures from the camera.
    if (!self.localVideoTrack) {
        [self startPreview];
    }
}

- (void)doConnect {
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"]) {
        [self logMessage:@"Please provide a valid token to connect to a room"];
        return;
    }
    
    // Prepare local media which we will share with Room Participants.
    [self prepareLocalMedia];
    
    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken
                                                                      block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
        builder.roomName = self.roomName;
        // Use the local media that we prepared earlier.
        builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
        builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
        [builder setNetworkQualityEnabled:YES];
    }];
    
    // Connect to the Room using the options we provided.
    self.room = [TwilioVideoSDK connectWithOptions:connectOptions delegate:self];
    
    [self logMessage:@"Attempting to connect to room"];
}

- (void)setupRemoteView {
    // Creating `TVIVideoView` programmatically
    TVIVideoView *remoteView = [[TVIVideoView alloc] init];
        
    // `TVIVideoView` supports UIViewContentModeScaleToFill, UIViewContentModeScaleAspectFill and UIViewContentModeScaleAspectFit
    // UIViewContentModeScaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
    remoteView.contentMode = UIViewContentModeScaleAspectFill;

    [self.view insertSubview:remoteView atIndex:0];
    self.remoteView = remoteView;
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerX];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerY];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0];
    [self.view addConstraint:width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:0];
    [self.view addConstraint:height];
}

// Reset the client ui status
- (void)showRoomUI:(BOOL)inRoom {
    self.micButton.hidden = !inRoom;
    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
}

- (void)cleanupRemoteParticipant {
    if (self.remoteParticipant) {
        if ([self.remoteParticipant.videoTracks count] > 0) {
            TVIRemoteVideoTrack *videoTrack = self.remoteParticipant.remoteVideoTracks[0].remoteTrack;
            [videoTrack removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
        self.remoteParticipant = nil;
    }
}

- (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

- (void)handleConnectionError: (NSString*)message {
    if ([self.config handleErrorInApp]) {
        [self logMessage: @"Error handling disabled for the plugin. This error should be handled in the hybrid app"];
        [self dismiss];
        return;
    }
    [self logMessage: @"Connection error handled by the plugin"];
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NULL
                                 message: message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:[self.config i18nAccept]
                                style:UIAlertActionStyleDefault
                                handler: ^(UIAlertAction * action) {
                                    [self dismiss];
                                }];
    
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) dismiss {
    [self.cameraSource stopCapture];
    [[TwilioVideoManager getInstance] publishEvent: CLOSED];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) updatePreviewViewHeightTo:(CGFloat) height {
    // LR: Since TVIVideoView gets replaces with another view, we need
    // to search for the constraints, instead of having a IBOutlet to the
    // constraint we want in the .storyboard
    for (NSLayoutConstraint *constraint in self.previewView.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            constraint.constant = roundf(height);
            [self.previewView layoutIfNeeded];
            return;
        }
    }
}

#pragma mark - TVIRoomDelegate

- (void) onDisconnect {
    if (self.room != NULL) {
        [self.room disconnect];
    }
}

#pragma mark - TVIRoomDelegate

- (void)didConnectToRoom:(TVIRoom *)room {
    room.localParticipant.delegate = self;
    // At the moment, this example only supports rendering one Participant at a time.
    [self logMessage:[NSString stringWithFormat:@"Connected to room %@ as %@", room.name, room.localParticipant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: CONNECTED];
    
    if (room.remoteParticipants.count > 0) {
        self.remoteParticipant = room.remoteParticipants[0];
        self.remoteParticipant.delegate = self;
    }
}

- (void)room:(TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Disconnected from room %@, error = %@", room.name, error]];
    
    [self cleanupRemoteParticipant];
    self.room = nil;
    
    [self showRoomUI:NO];
    if (error != NULL) {
        [[TwilioVideoManager getInstance] publishEvent:DISCONNECTED_WITH_ERROR with:@{ @"code": [NSString stringWithFormat:@"%ld",[error code]] }];
        [self handleConnectionError: [self.config i18nDisconnectedWithError]];
    } else {
        [[TwilioVideoManager getInstance] publishEvent: DISCONNECTED];
        [self dismiss];
    }
}

- (void)room:(TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error{
    [self logMessage:[NSString stringWithFormat:@"Failed to connect to room, error = %@", error]];
    [[TwilioVideoManager getInstance] publishEvent: CONNECT_FAILURE];
    
    self.room = nil;
    
    [self showRoomUI:NO];
    [self handleConnectionError: [self.config i18nConnectionError]];
}

- (void)room:(TVIRoom *)room participantDidConnect:(TVIRemoteParticipant *)participant {
    if (!self.remoteParticipant) {
        self.remoteParticipant = participant;
        self.remoteParticipant.delegate = self;
    }
    [self logMessage:[NSString stringWithFormat:@"Participant %@ connected with %lu audio and %lu video tracks",
                      participant.identity,
                      (unsigned long)[participant.audioTracks count],
                      (unsigned long)[participant.videoTracks count]]];
    [[TwilioVideoManager getInstance] publishEvent: PARTICIPANT_CONNECTED];
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIRemoteParticipant *)participant {
    if (self.remoteParticipant == participant) {
        [self cleanupRemoteParticipant];
    }
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: PARTICIPANT_DISCONNECTED];
}

#pragma mark - TVIRemoteParticipantDelegate

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      publishedVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has offered to share the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ video track .",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
    unpublishedVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      publishedAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has offered to share the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
    unpublishedAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)subscribedToVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                   publication:(TVIRemoteVideoTrackPublication *)publication
                forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's video frames now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: VIDEO_TRACK_ADDED];

    if (self.remoteParticipant == participant) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)unsubscribedFromVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                       publication:(TVIRemoteVideoTrackPublication *)publication
                    forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
    // remote Participant's video.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: VIDEO_TRACK_REMOVED];
    
    if (self.remoteParticipant == participant) {
        [videoTrack removeRenderer:self.remoteView];
        [self.remoteView removeFromSuperview];
    }
}

- (void)subscribedToAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                   publication:(TVIRemoteAudioTrackPublication *)publication
                forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's audio now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: AUDIO_TRACK_ADDED];
}

- (void)unsubscribedFromAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                       publication:(TVIRemoteAudioTrackPublication *)publication
                    forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
    // remote Participant's audio.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: AUDIO_TRACK_REMOVED];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
        enabledVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
       disabledVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
        enabledAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
       disabledAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)failedToSubscribeToAudioTrack:(TVIRemoteAudioTrackPublication *)publication
                                error:(NSError *)error
                       forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)failedToSubscribeToVideoTrack:(TVIRemoteVideoTrackPublication *)publication
                                error:(NSError *)error
                       forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ video track.",
                      participant.identity, publication.trackName]];
}

#pragma mark - TVIVideoViewDelegate

- (void)videoView:(TVIVideoView *)view videoDimensionsDidChange:(CMVideoDimensions)dimensions {
    NSLog(@"Dimensions changed to: %d x %d", dimensions.width, dimensions.height);
    [self.view setNeedsLayout];
}

- (void) cameraCaptureDidStartWithDevice:(AVCaptureDevice*)device {
    self.previewView.mirror = (device == self.frontCamera);
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription);
    CGFloat previewHeight = self.previewView.frame.size.width * dimensions.width / dimensions.height;
    [self updatePreviewViewHeightTo: previewHeight];
}

#pragma mark - TVILocalParticipantDelegate

- (void)localParticipant:(nonnull TVILocalParticipant *)participant networkQualityLevelDidChange:(TVINetworkQualityLevel)networkQualityLevel {
    // networkQuality will always be 0 while reconnecting, so skip
    if (self.room.state == TVIRoomStateReconnecting) return;
    [self logMessage:[NSString stringWithFormat:@"Network quality: %ld", (long)networkQualityLevel]];
    if (!self.config.disableNQBanner && networkQualityLevel <= self.config.videoNetworkQualityThreshold) {
        [self toggleBanner:YES];
    }
}

@end
