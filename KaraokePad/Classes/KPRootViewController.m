//
//	KPRootViewController.m
//	KaraokePad
//
//	Copyright (c) 2011 Michael Potter
//	http://lucas.tiz.ma
//	lucas@tiz.ma
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <AVFoundation/AVFoundation.h>

#import "KPRootViewController.h"
#import "KPMultitrackAudioPlayer.h"

#pragma mark Class Extension -

@interface KPRootViewController () <AVAudioPlayerDelegate, KPMultitrackAudioPlayerDelegate>

@property (readwrite, nonatomic, strong) IBOutlet UIButton *playPauseButton;
@property (readwrite, nonatomic, strong) IBOutlet UISlider *playbackSpeedSlider;
@property (readwrite, nonatomic, strong) IBOutlet UISlider *vocalsVolumeSlider;
@property (readwrite, nonatomic, strong) IBOutlet UIProgressView *playbackProgressView;
@property (readwrite, nonatomic, strong) IBOutlet UILabel *timeElapsedLabel;
@property (readwrite, nonatomic, strong) IBOutlet UILabel *timeRemainingLabel;

@property (readwrite, nonatomic, strong) KPMultitrackAudioPlayer *karaokeAudioPlayer;
@property (readwrite, nonatomic, strong) AVAssetTrack *backingAudioTrack;
@property (readwrite, nonatomic, strong) AVAssetTrack *vocalsAudioTrack;
@property (readwrite, nonatomic) NSTimeInterval timeElapsed;
@property (readwrite, nonatomic) NSTimeInterval timeRemaining;

- (IBAction)didTapPlayPauseButton;
- (IBAction)playbackSpeedSliderValueChanged;
- (IBAction)vocalsVolumeSliderValueChanged;

- (void)audioStartedPlaying;
- (void)audioStoppedPlaying;
- (void)updateUIForCurrentTime;
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

@synthesize karaokeAudioPlayer;
@synthesize backingAudioTrack;
@synthesize vocalsAudioTrack;
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
	if (self.karaokeAudioPlayer.playing)
	{
		[self.karaokeAudioPlayer pause];
		[self audioStoppedPlaying];
	}
	else
	{
		[self.karaokeAudioPlayer play];
		[self audioStartedPlaying];
	}
}

- (IBAction)playbackSpeedSliderValueChanged
{
	self.karaokeAudioPlayer.rate = self.playbackSpeedSlider.value;
}

- (IBAction)vocalsVolumeSliderValueChanged
{
	[self.karaokeAudioPlayer setVolume:self.vocalsVolumeSlider.value forAudioTrack:self.vocalsAudioTrack];
}

- (void)audioStartedPlaying
{
	[self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (void)audioStoppedPlaying
{
	[self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
}

- (void)updateUIForCurrentTime
{
	self.playbackProgressView.progress = (float)(self.karaokeAudioPlayer.currentTime / self.karaokeAudioPlayer.duration);
	self.timeElapsed = self.karaokeAudioPlayer.currentTime;
	self.timeRemaining = (self.karaokeAudioPlayer.duration - self.timeElapsed);
}

- (void)handlePlaybackSpeedSliderTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
	if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded)
	{
		self.karaokeAudioPlayer.rate = self.playbackSpeedSlider.value = 1.0f;
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

	NSURL *backingAudioResourceURL = [[NSBundle mainBundle] URLForResource:@"Masterpiece (Backing)" withExtension:@"m4a"];
	NSURL *vocalsAudioResourceURL = [[NSBundle mainBundle] URLForResource:@"Masterpiece (Vocals)" withExtension:@"m4a"];

	self.karaokeAudioPlayer = [KPMultitrackAudioPlayer new];
	self.karaokeAudioPlayer.delegate = self;
	self.backingAudioTrack = [self.karaokeAudioPlayer addAudioTrackFromURL:backingAudioResourceURL];
	self.vocalsAudioTrack = [self.karaokeAudioPlayer addAudioTrackFromURL:vocalsAudioResourceURL];

	[self.karaokeAudioPlayer prepareForPlayback];
	[self.karaokeAudioPlayer setVolume:self.vocalsVolumeSlider.value forAudioTrack:self.vocalsAudioTrack];

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
	[self updateUIForCurrentTime];
}

#pragma mark - KPMultitrackAudioPlayerDelegate Methods

- (void)multitrackAudioPlayerDidFinishPreparingForPlayback:(KPMultitrackAudioPlayer *)multitrackAudioPlayer
{
	NSLog(@"Finished preparing for audio playback.");

	self.timeElapsed = 0.0;
	self.timeRemaining = multitrackAudioPlayer.duration;
	self.playPauseButton.enabled = YES;
}

- (void)multitrackAudioPlayerDidStartPlaying:(KPMultitrackAudioPlayer *)multitrackAudioPlayer
{
	NSLog(@"Started playing.");
}

- (void)multitrackAudioPlayerDidPause:(KPMultitrackAudioPlayer *)multitrackAudioPlayer
{
	NSLog(@"Audio playback paused.");
}

- (void)multitrackAudioPlayerDidStopPlaying:(KPMultitrackAudioPlayer *)multitrackAudioPlayer
{
	NSLog(@"Finished playing.");
}

- (void)multitrackAudioPlayerDidChangeCurrentTime:(KPMultitrackAudioPlayer *)multitrackAudioPlayer
{
	[self updateUIForCurrentTime];
}

@end