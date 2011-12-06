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
@property (readwrite, nonatomic, strong) IBOutlet UISlider *playheadSlider;
@property (readwrite, nonatomic, strong) IBOutlet UISlider *playbackSpeedSlider;
@property (readwrite, nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (readwrite, nonatomic, strong) NSTimer *audioPlayerPollTimer;

- (IBAction)didTapPlayPauseButton;
- (IBAction)playheadSliderValueChanged;
- (IBAction)playbackSpeedSliderValueChanged;
- (void)audioStartedPlaying;
- (void)audioStoppedPlaying;
- (void)audioPlayerPollTimerDidFire;

@end

@implementation KPRootViewController

@synthesize playPauseButton;
@synthesize playheadSlider;
@synthesize playbackSpeedSlider;
@synthesize audioPlayer;
@synthesize audioPlayerPollTimer;

#pragma mark - KPRootViewController Methods (Private)

- (IBAction)didTapPlayPauseButton
{
	if (self.audioPlayer.playing)
	{
		[self.audioPlayer pause];
		[self audioStoppedPlaying];
	}
	else
	{
		[self.audioPlayer play];
		[self audioStartedPlaying];
	}
}

- (IBAction)playheadSliderValueChanged
{
	self.audioPlayer.currentTime = (self.playheadSlider.value * self.audioPlayer.duration);
}

- (IBAction)playbackSpeedSliderValueChanged
{
	self.audioPlayer.rate = self.playbackSpeedSlider.value;
}

- (void)audioStartedPlaying
{
	self.audioPlayerPollTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(audioPlayerPollTimerDidFire) userInfo:nil repeats:YES];
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
	self.playheadSlider.value = (float)(self.audioPlayer.currentTime / self.audioPlayer.duration);
}

#pragma mark - UIViewController Methods

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	NSURL *audioResourceURL = [[NSBundle mainBundle] URLForResource:@"マスターピース (TVsize)" withExtension:@"m4a"];

	self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioResourceURL error:nil];
	self.audioPlayer.delegate = self;
	self.audioPlayer.enableRate = YES;
	[self.audioPlayer prepareToPlay];
}

- (void)viewDidUnload
{
	[super viewDidUnload];

	self.playPauseButton = nil;
	self.playheadSlider = nil;
	self.playbackSpeedSlider = nil;
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
}

@end