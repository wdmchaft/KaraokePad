//
//  KPRootViewController.m
//  KaraokePad
//
//  Created by Michael Potter on 12/5/11.
//  Copyright (c) 2011 LucasTizma. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "KPRootViewController.h"

#pragma mark Class Extension -

@interface KPRootViewController () <AVAudioPlayerDelegate>

@property (readwrite, nonatomic, strong) IBOutlet UIButton *playPauseButton;
@property (readwrite, nonatomic, strong) IBOutlet UISlider *playbackSpeedSlider;
@property (readwrite, nonatomic, strong) IBOutlet UISlider *vocalsVolumeSlider;
@property (readwrite, nonatomic, strong) IBOutlet UIProgressView *playbackProgressView;
@property (readwrite, nonatomic, strong) IBOutlet UILabel *timeElapsedLabel;
@property (readwrite, nonatomic, strong) IBOutlet UILabel *timeRemainingLabel;

@property (readwrite, nonatomic, strong) AVAudioPlayer *normalAudioPlayer;
@property (readwrite, nonatomic, strong) AVAudioPlayer *instrumentalAudioPlayer;
@property (readwrite, nonatomic, strong) NSTimer *audioPlayerPollTimer;
@property (readwrite, nonatomic) NSTimeInterval timeElapsed;
@property (readwrite, nonatomic) NSTimeInterval timeRemaining;

- (IBAction)didTapPlayPauseButton;
- (IBAction)playbackSpeedSliderValueChanged;
- (IBAction)vocalsVolumeSliderValueChanged;

- (void)audioStartedPlaying;
- (void)audioStoppedPlaying;
- (void)audioPlayerPollTimerDidFire;
- (void)updateUIForPlaybackState;
- (void)handlePlaybackSpeedSliderTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
- (NSString *)formattedTimeStringFromTimeInterval:(NSTimeInterval)timeInterval;

@end

@implementation KPRootViewController

@synthesize playPauseButton;
@synthesize playbackSpeedSlider;
@synthesize vocalsVolumeSlider;
@synthesize playbackProgressView;
@synthesize timeElapsedLabel;
@synthesize timeRemainingLabel;

@synthesize normalAudioPlayer;
@synthesize instrumentalAudioPlayer;
@synthesize audioPlayerPollTimer;
@synthesize timeElapsed;
@synthesize timeRemaining;

#pragma mark - Property Setters

- (void)setTimeElapsed:(NSTimeInterval)newTimeElapsed
{
	timeElapsed = newTimeElapsed;

	self.timeElapsedLabel.text = [self formattedTimeStringFromTimeInterval:timeElapsed];
}

- (void)setTimeRemaining:(NSTimeInterval)newTimeRemaining
{
	timeRemaining = newTimeRemaining;

	self.timeRemainingLabel.text = [@"-" stringByAppendingString:[self formattedTimeStringFromTimeInterval:timeRemaining]];
}

#pragma mark - KPRootViewController Methods (Private)

- (IBAction)didTapPlayPauseButton
{
	if (self.normalAudioPlayer.playing)
	{
		[self.normalAudioPlayer pause];
		[self.instrumentalAudioPlayer pause];
		[self audioStoppedPlaying];
	}
	else
	{
		[self.normalAudioPlayer play];
		[self.instrumentalAudioPlayer play];
		[self audioStartedPlaying];
	}
}

- (IBAction)playbackSpeedSliderValueChanged
{
	self.normalAudioPlayer.rate = self.instrumentalAudioPlayer.rate = self.playbackSpeedSlider.value;
}

- (IBAction)vocalsVolumeSliderValueChanged
{
	self.normalAudioPlayer.volume = self.vocalsVolumeSlider.value;
	self.instrumentalAudioPlayer.volume = (1.0f - self.vocalsVolumeSlider.value);
}

- (void)audioStartedPlaying
{
	self.audioPlayerPollTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(audioPlayerPollTimerDidFire) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:self.audioPlayerPollTimer forMode:NSDefaultRunLoopMode];

	[self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (void)audioStoppedPlaying
{
	[self.audioPlayerPollTimer invalidate];
	self.audioPlayerPollTimer = nil;

	[self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
}

- (void)audioPlayerPollTimerDidFire
{
	[self updateUIForPlaybackState];
}

- (void)updateUIForPlaybackState
{
	self.playbackProgressView.progress = (float)(self.normalAudioPlayer.currentTime / self.normalAudioPlayer.duration);
	self.timeElapsed = self.normalAudioPlayer.currentTime;
	self.timeRemaining = (self.normalAudioPlayer.duration - self.timeElapsed);
}

- (void)handlePlaybackSpeedSliderTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
	if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded)
	{
		self.normalAudioPlayer.rate = self.instrumentalAudioPlayer.rate = self.playbackSpeedSlider.value = 1.0f;
	}
}

- (NSString *)formattedTimeStringFromTimeInterval:(NSTimeInterval)timeInterval
{
	NSDate *currentDate = [NSDate date];
	NSDate *currentDatePlusTimeInterval = [NSDate dateWithTimeInterval:timeInterval sinceDate:currentDate];

	NSUInteger unitFlags = (NSMinuteCalendarUnit | NSSecondCalendarUnit);
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:currentDate toDate:currentDatePlusTimeInterval options:0];

	return [NSString stringWithFormat:@"%02ld:%02ld", [dateComponents minute], [dateComponents second]];
}

#pragma mark - UIViewController Methods

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	NSURL *normalAudioResourceURL = [[NSBundle mainBundle] URLForResource:@"Masterpiece" withExtension:@"m4a"];
	NSURL *instrumentalAudioResourceURL = [[NSBundle mainBundle] URLForResource:@"Masterpiece (Instrumental)" withExtension:@"m4a"];

	self.normalAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:normalAudioResourceURL error:nil];
	self.normalAudioPlayer.delegate = self;
	self.normalAudioPlayer.enableRate = YES;
	[self.normalAudioPlayer prepareToPlay];

	self.instrumentalAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:instrumentalAudioResourceURL error:nil];
	self.instrumentalAudioPlayer.delegate = self;
	self.instrumentalAudioPlayer.enableRate = YES;
	self.instrumentalAudioPlayer.volume = 0.0f;
	[self.instrumentalAudioPlayer prepareToPlay];

	self.timeElapsed = 0.0;
	self.timeRemaining = self.normalAudioPlayer.duration;

	UITapGestureRecognizer *playbackSpeedSliderTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
		action:@selector(handlePlaybackSpeedSliderTapGesture:)];
	[self.playbackSpeedSlider addGestureRecognizer:playbackSpeedSliderTapGestureRecognizer];
}

- (void)viewDidUnload
{
	[super viewDidUnload];

	self.playPauseButton = nil;
	self.playbackSpeedSlider = nil;
	self.vocalsVolumeSlider = nil;
	self.playbackProgressView = nil;
	self.timeElapsedLabel = nil;
	self.timeRemainingLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Protocol Methods

#pragma mark - AVAudioPlayerDelegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)didFinishPlayingSuccessfully
{
	[self audioStoppedPlaying];
	[self updateUIForPlaybackState];
}

@end