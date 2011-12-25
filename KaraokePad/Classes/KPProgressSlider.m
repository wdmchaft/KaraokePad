//
//	KPProgressSlider.m
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

#import "KPProgressSlider.h"

#pragma mark Internal Definitions

static CGFloat const KPProgressViewMinimumWidthThreshold = 11.0f;

#pragma mark - Class Extension -

@interface KPProgressSlider ()

@property (readwrite, nonatomic, assign) NSInteger trackingRateLevel;
@property (readwrite, nonatomic, strong) UIView *thumbViewContainerView;
@property (readwrite, nonatomic, assign) CGFloat progressAtPreviousTrackingRateLevel;
@property (readwrite, nonatomic, assign) CGFloat thumbViewTouchPointMaxXOffset;
@property (readwrite, nonatomic, assign, getter = isUsingDefaultThumbView) BOOL usingDefaultThumbView;

- (void)adjustThumbViewFrameForCurrentProgress;
- (void)handleThumbViewPanGesture:(UIPanGestureRecognizer *)panGestureRecognizer;

@end

@implementation KPProgressSlider

@synthesize delegate;
@synthesize thumbView;
@synthesize thumbViewBoundsInsets;
@synthesize shouldUseTrackingRateLevels;
@synthesize numberOfTrackingRateLevels;
@synthesize trackingRateLevelHeight;
@synthesize trackingRateLevelMultiplier;
@synthesize trackingRateLevel;
@synthesize trackingRate;
@synthesize thumbViewContainerView;
@synthesize progressAtPreviousTrackingRateLevel;
@synthesize thumbViewTouchPointMaxXOffset;
@synthesize usingDefaultThumbView;

#pragma mark - Property Accessors

- (void)setThumbView:(UIView *)newThumbView
{
	if (!self.usingDefaultThumbView)
	{
		self.thumbViewBoundsInsets = UIEdgeInsetsZero;
	}

	thumbView = newThumbView;

	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleThumbViewPanGesture:)];

	[thumbView addGestureRecognizer:panGestureRecognizer];
	thumbView.userInteractionEnabled = YES;

	self.usingDefaultThumbView = NO;

	[self.thumbViewContainerView removeFromSuperview];
	self.thumbViewContainerView = [[UIView alloc] initWithFrame:thumbView.bounds];		// Use UIView+LTKAdditions category
	self.thumbViewContainerView.backgroundColor = [UIColor clearColor];
	[self.thumbViewContainerView addSubview:thumbView];

	[self addSubview:self.thumbViewContainerView];
}

- (void)setThumbViewBoundsInsets:(UIEdgeInsets)newThumbViewBoundsInsets
{
	thumbViewBoundsInsets = newThumbViewBoundsInsets;

	self.thumbViewContainerView.contentMode = UIViewContentModeCenter;
	self.thumbViewContainerView.frameMidY = self.boundsMidY;
	self.thumbViewContainerView.bounds = UIEdgeInsetsInsetRect(self.thumbView.bounds, thumbViewBoundsInsets);
}

- (void)setTrackingRateLevel:(NSInteger)newTrackingRateLevel
{
	if (trackingRateLevel != newTrackingRateLevel)
	{
		self.progressAtPreviousTrackingRateLevel = self.progress;

		if ([self.delegate respondsToSelector:@selector(progressSlider:didChangeTrackingRateLevel:)])
		{
			[self.delegate progressSlider:self didChangeTrackingRateLevel:newTrackingRateLevel];
		}
	}

	trackingRateLevel = newTrackingRateLevel;
}

- (CGFloat)trackingRate
{
	return (1.0f * powf(self.trackingRateLevelMultiplier, fabsf(self.trackingRateLevel)));;
}

#pragma mark - KPProgressSlider Methods (Public)

+ (id)progressSliderWithThumbView:(UIView *)thumbView
{
	return [[self alloc] initWithThumbView:thumbView];
}

- (id)initWithThumbView:(UIView *)newThumbView
{
	self = [super initWithProgressViewStyle:UIProgressViewStyleDefault];

	if (self != nil)
	{
		thumbView = newThumbView;
		thumbViewBoundsInsets = UIEdgeInsetsZero;
	}

	return self;
}

#pragma mark - KPProgressSlider Methods (Private)

- (void)adjustThumbViewFrameForCurrentProgress
{
	// In order to align the thumb view properly at all points along the progress view, its bounds width is used to offset the normal frame calculation.
	// Effectively, the thumb view's bounds need to be flush against both the left edge of the progress view (at 0.0 progress) and the right edge of the
	// progress view (at 1.0 progress).

	CGFloat effectiveWidth = (self.boundsWidth - self.thumbViewContainerView.boundsWidth);

	self.thumbViewContainerView.frameMaxX = (self.thumbViewContainerView.boundsWidth + (effectiveWidth * self.progress));
}

- (void)handleThumbViewPanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
	CGPoint localizedTouchPoint = [panGestureRecognizer locationInView:self];

	if (panGestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		// If the delegate indicates that tracking should not begin, then the gesture recognizer is disabled.

		BOOL panGestureRecognizerEnabled = YES;

		if ([self.delegate respondsToSelector:@selector(progressSliderShouldBeginTracking:)])
		{
			panGestureRecognizerEnabled = [self.delegate progressSliderShouldBeginTracking:self];
		}

		// Setting a gesture recognizer's enabled property to NO doesn't immediately change the property's value, apparently. It merely changes the state to
		// UIGestureRecognizerStateCancelled. A separate variable must maintain the return value of -progressSliderShouldBeginTracking: so that
		// -progressSliderDidBeginTracking: is not called on the delegate in the event that -progressSliderShouldBeginTracking: returns NO.

		panGestureRecognizer.enabled = panGestureRecognizerEnabled;

		// Capture the offset between the right edge of thumbView and the x coordinate of localizedTouchPoint. This offset prevents thumbView from suddenly
		// jumping to a new position when panning. Instead, the thumb view pans relative to the original touch point.

		self.thumbViewTouchPointMaxXOffset = (self.thumbViewContainerView.frameMidX - localizedTouchPoint.x);

		if (panGestureRecognizerEnabled && [self.delegate respondsToSelector:@selector(progressSliderDidBeginTracking:)])
		{
			[self.delegate progressSliderDidBeginTracking:self];
		}
	}
	else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged)
	{
		// If tracking rates are to be applied, they are calculated according to height levels: for each multiple of trackingRateLevelHeight that the touch
		// position travels from the origin point (the vertical center of self, the progress view), the tracking rate level is increased (touches above the
		// progress slider) or decreased (touches below the progress slider) by one. The normal tracking rate, 1.0, is multiplied by trackingRateLevelMultiplier
		// for each level.

		if (self.shouldUseTrackingRateLevels)
		{
			CGFloat integralValue = 0.0f;
			modff(-((localizedTouchPoint.y - self.boundsMidY) / self.trackingRateLevelHeight), &integralValue);

			if (abs((NSInteger)integralValue) < self.numberOfTrackingRateLevels)
			{
				self.trackingRateLevel = (NSInteger)integralValue;
			}
		}

		// This calculation is effectively the inverse of the one performed in -adjustThumbViewFrameForCurrentProgress, taking into account the x offset
		// captured in the UIGestureRecognizerStateBegan state. The tracking rate is applied here.

		CGFloat effectiveXPosition = (localizedTouchPoint.x + self.thumbViewTouchPointMaxXOffset);
		CGFloat effectiveWidth = self.boundsWidth;

		self.progress = (effectiveXPosition / effectiveWidth);

		if ([self.delegate respondsToSelector:@selector(progressSlider:didChangeProgress:)])
		{
			[self.delegate progressSlider:self didChangeProgress:self.progress];
		}
	}
	else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded)
	{
		self.trackingRateLevel = 0;

		if ([self.delegate respondsToSelector:@selector(progressSliderDidEndTracking:)])
		{
			[self.delegate progressSliderDidEndTracking:self];
		}
	}
	else if (panGestureRecognizer.state == UIGestureRecognizerStateCancelled)
	{
		panGestureRecognizer.enabled = YES;
	}
}

#pragma mark - UIProgressView Methods

- (void)setProgress:(float)newProgress animated:(BOOL)animated
{
	CGRect previousThumbViewFrame = self.thumbViewContainerView.frame;
	CGFloat animationDuration = fabsf(self.progress - newProgress);

	[super setProgress:newProgress animated:animated];

	// UIProgressView sets its animation duration to the magnitude of the difference between the current progress and the new progress. thumbView is animated
	// using this same logic.

	if (animated)
	{
		self.thumbViewContainerView.frame = previousThumbViewFrame;

		// To prevent potentially awkward interactions, user interaction on thumbView is disabled duration the animation. It is re-enabled when the animation
		// completes.

		[UIView animateWithDuration:animationDuration
			animations:
			^{
				self.thumbViewContainerView.userInteractionEnabled = NO;
				[self adjustThumbViewFrameForCurrentProgress];
			}
			completion:
			^(BOOL finished)
			{
				self.thumbViewContainerView.userInteractionEnabled = YES;
			}
		];
	}
}

#pragma mark - UIView Methods

- (void)layoutSubviews
{
	[super layoutSubviews];

	// Adding thumbView as a subview is deferred to this point so as to centralize the remaining setup logic. Because there is no single override point for
	// views (i.e., they can be initialized manually or through Interface Builder), this is the first point where thumbView is guaranteed to exist, regardless
	// of whether or not a custom thumbView is provided.

	if (self.thumbView == nil)
	{
		self.usingDefaultThumbView = YES;
		self.thumbView = [UIImageView imageViewWithImageNamed:@"KPProgressSliderThumb"];
		self.thumbViewBoundsInsets = UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f);
	}

	[self adjustThumbViewFrameForCurrentProgress];
}

@end