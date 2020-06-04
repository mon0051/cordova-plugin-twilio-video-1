@import TwilioVideo;
@import UIKit;
#import "TwilioVideoManager.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoPermissions.h"

@interface TwilioVideoViewController: UIViewController <TVIRemoteParticipantDelegate, TVIRoomDelegate, TVIVideoViewDelegate, TwilioVideoActionProducerDelegate, TVILocalParticipantDelegate>

// Configure access token manually for testing in `ViewDidLoad`, if desired! Create one manually in the console.
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) TwilioVideoConfig *config;

#pragma mark Video SDK components

@property (nonatomic, strong) TVICameraSource *cameraSource;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) TVILocalVideoTrack *localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack *localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant *remoteParticipant;
@property (nonatomic, weak) TVIVideoView *remoteView;
@property (nonatomic, strong) TVIRoom *room;

#pragma mark UI Element Outlets and handles

// `TVIVideoView` created from a storyboard
@property (weak, nonatomic) IBOutlet TVIVideoView *previewView;

@property (nonatomic, weak) IBOutlet UIButton *disconnectButton;
@property (nonatomic, weak) IBOutlet UIButton *micButton;
@property (nonatomic, weak) IBOutlet UILabel *roomLabel;
@property (nonatomic, weak) IBOutlet UILabel *roomLine;
@property (nonatomic, weak) IBOutlet UIButton *cameraSwitchButton;
@property (nonatomic, weak) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIView *topGradientView;
@property (weak, nonatomic) IBOutlet UIView *bottomGradientView;
@property (weak, nonatomic) IBOutlet UILabel *callTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *callTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *callDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *bannerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bannerBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *callTitleTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewTopConstraint;

@property (nonatomic, strong) NSTimer *callDurationTimer;
@property (nonatomic) int currentCallDuration;

- (void)connectToRoom:(NSString*)room token: (NSString *)token;

@end
