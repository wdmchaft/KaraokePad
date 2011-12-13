//
//	KPMultitrackAudioPlayer.h
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
#import <CoreMedia/CoreMedia.h>

@protocol KPMultitrackAudioPlayerDelegate;

@interface KPMultitrackAudioPlayer : NSObject

@property (readwrite, nonatomic, weak) id<KPMultitrackAudioPlayerDelegate> delegate;
@property (readwrite, nonatomic, assign) CGFloat rate;
@property (readwrite, nonatomic, assign) NSTimeInterval currentTime;
@property (readwrite, nonatomic, assign) NSTimeInterval currentTimeUpdateInterval;
@property (readonly, nonatomic, assign) NSTimeInterval duration;
@property (readonly, nonatomic, assign, getter = isPlaying) BOOL playing;

- (AVAssetTrack *)addAudioTrackFromURL:(NSURL *)audioTrackURL;
- (AVAssetTrack *)addAudioTrackFromURL:(NSURL *)audioTrackURL withTimingOffset:(NSTimeInterval)timingOffset;
- (CGFloat)volumeForAudioTrack:(AVAssetTrack *)audioTrack;
- (void)setVolume:(CGFloat)volume forAudioTrack:(AVAssetTrack *)audioTrack;
- (void)prepareForPlayback;
- (void)play;
- (void)pause;
- (void)stop;

@end

@protocol KPMultitrackAudioPlayerDelegate <NSObject>

@optional

- (void)multitrackAudioPlayerDidFinishPreparingForPlayback:(KPMultitrackAudioPlayer *)multitrackAudioPlayer;
- (void)multitrackAudioPlayerDidStartPlaying:(KPMultitrackAudioPlayer *)multitrackAudioPlayer;
- (void)multitrackAudioPlayerDidPause:(KPMultitrackAudioPlayer *)multitrackAudioPlayer;
- (void)multitrackAudioPlayerDidStopPlaying:(KPMultitrackAudioPlayer *)multitrackAudioPlayer;
- (void)multitrackAudioPlayerDidChangeCurrentTime:(KPMultitrackAudioPlayer *)multitrackAudioPlayer;

@end