//
//	KPProgressSlider.h
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

@protocol KPProgressSliderDelegate;

@interface KPProgressSlider : UIProgressView

@property (readwrite, nonatomic, weak) IBOutlet id<KPProgressSliderDelegate> delegate;
@property (readwrite, nonatomic, strong) UIView *thumbView;
@property (readwrite, nonatomic, assign) UIEdgeInsets thumbViewBoundsInsets;
@property (readwrite, nonatomic, assign) BOOL shouldUseTrackingRateLevels;
@property (readwrite, nonatomic, assign) NSInteger numberOfTrackingRateLevels;
@property (readwrite, nonatomic, assign) CGFloat trackingRateLevelHeight;
@property (readwrite, nonatomic, assign) CGFloat trackingRateLevelMultiplier;
@property (readonly, nonatomic, assign) NSInteger trackingRateLevel;
@property (readonly, nonatomic, assign) CGFloat trackingRate;

+ (id)progressSliderWithThumbView:(UIView *)thumbView;
- (id)initWithThumbView:(UIView *)thumbView;

@end

@protocol KPProgressSliderDelegate <NSObject>

@optional

- (BOOL)progressSliderShouldBeginTracking:(KPProgressSlider *)progressSlider;
- (void)progressSliderDidBeginTracking:(KPProgressSlider *)progressSlider;
- (void)progressSliderDidEndTracking:(KPProgressSlider *)progressSlider;
- (void)progressSlider:(KPProgressSlider *)progressSlider didChangeProgress:(CGFloat)progress;
- (void)progressSlider:(KPProgressSlider *)progressSlider didChangeTrackingRateLevel:(NSInteger)trackingRateLevel;

@end