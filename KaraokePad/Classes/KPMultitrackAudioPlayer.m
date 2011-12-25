//
//	KPMultitrackAudioPlayer.m
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

#import "KPMultitrackAudioPlayer.h"

#pragma mark Internal Definitions

typedef enum KPMultitrackAudioPlayerState
{
	KPMultitrackAudioPlayerStateStopped = 1,
	KPMultitrackAudioPlayerStatePlaying = 2,
	KPMultitrackAudioPlayerStatePaused = 4
}
KPMultitrackAudioPlayerState;

#pragma mark - Class Extension -

@interface KPMultitrackAudioPlayer ()

@property (readwrite, nonatomic, assign) NSTimeInterval currentTime;
@property (readwrite, nonatomic, assign) NSTimeInterval duration;

@property (readwrite, nonatomic, strong) AVMutableComposition *mutableComposition;
@property (readwrite, nonatomic, strong) AVMutableAudioMix *mutableAudioMix;
@property (readwrite, nonatomic, strong) AVPlayerItem *audioPlayerItem;
@property (readwrite, nonatomic, strong) AVPlayer *audioPlayer;
@property (readwrite, nonatomic, assign) dispatch_queue_t periodicTimeObserverQueue;
@property (readwrite, nonatomic, strong) id opaqueTimeObserver;
@property (readwrite, nonatomic, assign, getter = isPreparedForPlayback) BOOL preparedForPlayback;
@property (readwrite, nonatomic, assign) BOOL wantsToBeginPlaying;
@property (readwrite, nonatomic, assign) KPMultitrackAudioPlayerState state;

- (void)playerItemDidPlayToEndTime;

@end

@implementation KPMultitrackAudioPlayer

@synthesize delegate;
@synthesize rate;
@synthesize currentTime;
@synthesize currentTimeUpdateInterval;
@synthesize duration;
@synthesize playing;

@synthesize mutableComposition;
@synthesize mutableAudioMix;
@synthesize audioPlayerItem;
@synthesize audioPlayer;
@synthesize periodicTimeObserverQueue;
@synthesize opaqueTimeObserver;
@synthesize preparedForPlayback;
@synthesize wantsToBeginPlaying;
@synthesize state;

#pragma mark - Property Accessors

- (void)setRate:(CGFloat)newRate
{
	rate = newRate;

	if (self.playing)
	{
		self.audioPlayer.rate = rate;
	}
}

- (void)setCurrentTime:(NSTimeInterval)newCurrentTime
{
	currentTime = newCurrentTime;

	dispatch_async(dispatch_get_main_queue(),
		^{
			if ([self.delegate respondsToSelector:@selector(multitrackAudioPlayerDidChangeCurrentTime:)])
			{
				[self.delegate multitrackAudioPlayerDidChangeCurrentTime:self];
			}
		}
	);
}

- (void)setPreparedForPlayback:(BOOL)newPreparedForPlayback
{
	preparedForPlayback = newPreparedForPlayback;

	if (! preparedForPlayback)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.audioPlayerItem];

		[self.audioPlayer removeObserver:self forKeyPath:@"status"];

		if (self.opaqueTimeObserver != nil)
		{
			dispatch_sync(self.periodicTimeObserverQueue,
				^{
					[self.audioPlayer removeTimeObserver:self.opaqueTimeObserver];
					self.opaqueTimeObserver = nil;
				}
			);
		}
	}
}

- (BOOL)isPlaying
{
	return (self.state == KPMultitrackAudioPlayerStatePlaying);
}

#pragma mark - KPMultitrackAudioPlayer Methods (Public)

- (AVAssetTrack *)addAudioTrackFromURL:(NSURL *)audioTrackURL
{
	return [self addAudioTrackFromURL:audioTrackURL withTimingOffset:0.0];
}

- (AVAssetTrack *)addAudioTrackFromURL:(NSURL *)audioTrackURL withTimingOffset:(NSTimeInterval)timingOffset
{
	if (self.state != KPMultitrackAudioPlayerStateStopped)
	{
		[NSException raise:NSInternalInconsistencyException format:[NSString stringWithFormat:@"Adding an audio track while %1$@ is playing is not allowed. "
			"Stop playback by calling -[%1$@ stop] before adding additional audio tracks.", NSStringFromClass([self class])]];
	}

	static NSDictionary *URLAssetOptions = nil;

	if (URLAssetOptions == nil)
	{
		URLAssetOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
	}

	AVMutableCompositionTrack *mutableCompositionTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
		preferredTrackID:kCMPersistentTrackID_Invalid];

    AVURLAsset *audioTrackFileAsset = [AVURLAsset URLAssetWithURL:audioTrackURL options:URLAssetOptions];
    CMTimeRange audioTrackTimeRange = CMTimeRangeMake(kCMTimeZero, [audioTrackFileAsset duration]);
    AVAssetTrack *audioAssetTrack = [[audioTrackFileAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];

    [mutableCompositionTrack insertTimeRange:audioTrackTimeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(timingOffset, 1) error:nil];

	self.preparedForPlayback = NO;

	return [mutableCompositionTrack copy];
}

- (CGFloat)volumeForAudioTrack:(AVAssetTrack *)audioTrack
{
	return 0.0f;
}

- (void)setVolume:(CGFloat)volume forAudioTrack:(AVAssetTrack *)audioTrack
{
	AVMutableAudioMixInputParameters *mutableAudioMixInputParamaters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
	[mutableAudioMixInputParamaters setVolume:volume atTime:self.audioPlayer.currentTime];

	self.mutableAudioMix.inputParameters = [NSArray arrayWithObject:mutableAudioMixInputParamaters];
	self.audioPlayerItem.audioMix = self.mutableAudioMix;
}

- (void)seekToTime:(NSTimeInterval)time
{
	[self.audioPlayer seekToTime:CMTimeMakeWithSeconds(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)prepareForPlayback
{
	if (! self.preparedForPlayback)
	{
		self.audioPlayerItem = [AVPlayerItem playerItemWithAsset:self.mutableComposition];
		self.audioPlayerItem.audioMix = self.mutableAudioMix;

		self.audioPlayer = [[AVPlayer alloc] initWithPlayerItem:self.audioPlayerItem];
		self.audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime) name:AVPlayerItemDidPlayToEndTimeNotification
			object:self.audioPlayerItem];

		[self.audioPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];

		CMTime observerTimeInterval = CMTimeMakeWithSeconds(self.currentTimeUpdateInterval, 1);
		__weak KPMultitrackAudioPlayer *weakSelf = self;

		self.opaqueTimeObserver = [self.audioPlayer addPeriodicTimeObserverForInterval:observerTimeInterval queue:self.periodicTimeObserverQueue
			usingBlock:^(CMTime time)
			{
				weakSelf.currentTime = CMTimeGetSeconds(time);
			}
		];
	}
}

- (void)play
{
	if (! self.preparedForPlayback)
	{
		self.wantsToBeginPlaying = YES;
		[self prepareForPlayback];
	}
	else
	{
		self.state = KPMultitrackAudioPlayerStatePlaying;

		self.audioPlayer.rate = self.rate;		// Assuming a non-zero rate, this will cause the player to start playing

		if ([self.delegate respondsToSelector:@selector(multitrackAudioPlayerDidStartPlaying:)])
		{
			[self.delegate multitrackAudioPlayerDidStartPlaying:self];
		}
	}
}

- (void)pause
{
	self.state = KPMultitrackAudioPlayerStatePaused;

	[self.audioPlayer pause];
	[self.audioPlayer seekToTime:self.audioPlayer.currentTime];

	if ([self.delegate respondsToSelector:@selector(multitrackAudioPlayerDidPause:)])
	{
		[self.delegate multitrackAudioPlayerDidPause:self];
	}
}

- (void)stop
{
	self.state = KPMultitrackAudioPlayerStateStopped;

	[self.audioPlayer pause];
	[self.audioPlayerItem seekToTime:kCMTimeZero];

	if ([self.delegate respondsToSelector:@selector(multitrackAudioPlayerDidStopPlaying:)])
	{
		[self.delegate multitrackAudioPlayerDidStopPlaying:self];
	}
}

#pragma mark - KPMultitrackAudioPlayer Methods (Private)

- (void)playerItemDidPlayToEndTime
{
	[self stop];
}

#pragma mark - NSObject Methods

- (id)init
{
	self = [super init];

	if (self != nil)
	{
		NSString *dispatchQueueLabel = [NSString stringWithFormat:@"ma.tiz.lucas.KaraokePad.%@.periodicTimeObserverQueue", NSStringFromClass([self class])];

		self.rate = 1.0f;
		self.currentTimeUpdateInterval = 1.0f;
		self.mutableComposition = [AVMutableComposition composition];
		self.mutableAudioMix = [AVMutableAudioMix audioMix];
		self.periodicTimeObserverQueue = dispatch_queue_create([dispatchQueueLabel cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
		self.state = KPMultitrackAudioPlayerStateStopped;
	}

	return self;
}

- (void)dealloc
{
	self.preparedForPlayback = NO;
	dispatch_release(self.periodicTimeObserverQueue);
}

#pragma mark - Protocol Implementations

#pragma mark - NSObject (NSKeyValueObserving) Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"status"])
	{
		if (self.audioPlayer.status == AVPlayerStatusReadyToPlay)
		{
			self.preparedForPlayback = YES;
			self.duration = CMTimeGetSeconds(self.audioPlayerItem.duration);

			if ([self.delegate respondsToSelector:@selector(multitrackAudioPlayerDidFinishPreparingForPlayback:)])
			{
				[self.delegate multitrackAudioPlayerDidFinishPreparingForPlayback:self];
			}

			if (self.wantsToBeginPlaying)
			{
				self.wantsToBeginPlaying = NO;
				[self play];
			}
		}
	}
}

@end