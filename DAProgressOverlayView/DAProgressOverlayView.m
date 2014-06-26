//
//  DAProgressOverlayView.m
//  DAProgressOverlayView
//
//  Created by Daria Kopaliani on 8/1/13.
//  Copyright (c) 2013 Daria Kopaliani. All rights reserved.
//

#import "DAProgressOverlayView.h"
#import <tgmath.h>

#ifndef LIMIT
#define LIMIT(X, A, B) MAX(A, MIN(X, B))
#endif

typedef enum {
    DAProgressOverlayViewStateWaiting = 0,
    DAProgressOverlayViewStateOperationInProgress = 1,
    DAProgressOverlayViewStateOperationFinished = 2
} DAProgressOverlayViewState;

@interface DAProgressOverlayView ()

@property (assign, nonatomic) DAProgressOverlayViewState state;
@property (assign, nonatomic) CGFloat animationProgress;
@property (assign, nonatomic) CGFloat progressAnimationStart;
@property (strong, nonatomic) NSTimer *timer;

@end


CGFloat const DAUpdateUIFrequency = 1. / 25.;


@implementation DAProgressOverlayView

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    self.backgroundColor = [UIColor clearColor];
    self.progress = 0.;
    self.outerRadiusRatio = 0.7;
    self.innerRadiusRatio = 0.6;
    self.overlayColor = [UIColor colorWithRed:0. green:0. blue:0. alpha:0.5];
    self.animationProgress = 0.;
    self.stateChangeAnimationDuration = 0.25;
    self.triggersDownloadDidFinishAnimationAutomatically = YES;
    self.iconDrawingBlock = ^(CGContextRef ctx, CGRect rect, CGColorRef fillColor) {
        CGRect barRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(0.8, 0.2));
        UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:(CGFloat) (rect.size.width * 0.05)];
        CGContextRotateCTM(ctx, M_PI_4);
        CGContextAddPath(ctx, path.CGPath);
        CGContextRotateCTM(ctx, M_PI_2);
        CGContextAddPath(ctx, path.CGPath);
        CGContextClip(ctx);
        CGContextClearRect(ctx, rect);
    };
}

#pragma mark - Public

- (void)displayOperationWillTriggerAnimation
{
    self.state = DAProgressOverlayViewStateWaiting;
    [self startUpdateTimer];
}

- (void)displayOperationDidFinishAnimation
{
    self.state = DAProgressOverlayViewStateOperationFinished;
    [self startUpdateTimer];
}

- (void)setDrawIcon:(BOOL)drawIcon {
    [self willChangeValueForKey:@"drawIcon"];
    _drawIcon = drawIcon;
    [self didChangeValueForKey:@"drawIcon"];

    [self update];
}

#pragma mark * Overwritten methods

- (void)drawRect:(CGRect)rect
{
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat outerRadius = [self outerRadius];
    CGFloat innerRadius = [self innerRadius];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, width / 2., height / 2.);
    CGColorRef fillColor = [self fillColor];
    CGContextSetFillColorWithColor(context, fillColor);

    CGMutablePathRef path0 = CGPathCreateMutable();
    CGPathMoveToPoint(path0, NULL, width / 2., 0.);
    CGPathAddLineToPoint(path0, NULL, width / 2., height / 2.);
    CGPathAddLineToPoint(path0, NULL, -width / 2., height / 2.);
    CGPathAddLineToPoint(path0, NULL, -width / 2., 0.);
    CGPathAddLineToPoint(path0, NULL, (cosf(M_PI) * outerRadius), 0.);
    CGPathAddArc(path0, NULL, 0., 0., outerRadius, M_PI, 0., 1.);
    CGPathAddLineToPoint(path0, NULL, width / 2., 0.);
    CGPathCloseSubpath(path0);
    
    CGMutablePathRef path1 = CGPathCreateMutable();
    CGAffineTransform rotation = CGAffineTransformMakeScale(1., -1.);
    CGPathAddPath(path1, &rotation, path0);
    
    CGContextAddPath(context, path0);
    CGContextFillPath(context);
    CGPathRelease(path0);
    
    CGContextAddPath(context, path1);
    CGContextFillPath(context);
    CGPathRelease(path1);
    

    CGFloat iconRadius = [self iconRadius];

    CGFloat visibleProgress = _progressAnimationStart + self.animationProgress * (_progress - _progressAnimationStart);
    if (0.0f == visibleProgress) {
        CGContextFillEllipseInRect(context, CGRectMake(-innerRadius, -innerRadius, innerRadius * 2.0f, innerRadius * 2.0f));
    }
    else if (visibleProgress >= 1.0f) {
        CGContextFillEllipseInRect(context, CGRectMake(-iconRadius, -iconRadius, iconRadius * 2.0f, iconRadius * 2.0f));
    } else {
        CGFloat angle = (360. * visibleProgress);
        CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
        CGMutablePathRef path2 = CGPathCreateMutable();
        CGPathMoveToPoint(path2, &transform, innerRadius, 0.);
        CGPathAddArc(path2, &transform, 0., 0., innerRadius, 0., angle / 180. * M_PI, YES);
        CGPathAddLineToPoint(path2, &transform, iconRadius * cos(angle * M_PI / 180.0), iconRadius * sin(angle * M_PI / 180.0));
        CGPathAddArc(path2, &transform, 0., 0., iconRadius, angle / 180. * M_PI, 0, YES);
        CGPathAddLineToPoint(path2, &transform, innerRadius, 0.);
        CGContextAddPath(context, path2);
        CGContextFillPath(context);
        CGPathRelease(path2);
    }

    if (self.iconDrawingBlock) {
        CGContextSaveGState(context);
        self.iconDrawingBlock(context, CGRectMake(-iconRadius / 2.0, -iconRadius / 2.0, iconRadius, iconRadius), fillColor);
        CGContextRestoreGState(context);
    }
}

- (CGColorRef)fillColor {
    CGFloat alpha = CGColorGetAlpha(self.overlayColor.CGColor);

    switch (self.state) {
        case DAProgressOverlayViewStateWaiting:
            return [self.overlayColor colorWithAlphaComponent:self.animationProgress * alpha].CGColor;
        default:
        case DAProgressOverlayViewStateOperationInProgress:
            return self.overlayColor.CGColor;
        case DAProgressOverlayViewStateOperationFinished:
            return [self.overlayColor colorWithAlphaComponent:alpha - self.animationProgress * alpha].CGColor;
    }
}

- (void)setInnerRadiusRatio:(CGFloat)innerRadiusRatio
{
    _innerRadiusRatio = LIMIT(innerRadiusRatio, 0.0f, 1.0f);
}

- (void)setOuterRadiusRatio:(CGFloat)outerRadiusRatio
{
    _outerRadiusRatio = LIMIT(outerRadiusRatio, 0.0f, 1.0f);
}

- (void)setProgress:(CGFloat)progress
{
    if (_progress != progress) {
        self.progressAnimationStart = _progress;
        _progress = LIMIT(progress, 0.0f, 1.0f);
        if (progress == 1. && self.triggersDownloadDidFinishAnimationAutomatically) {
            [self displayOperationDidFinishAnimation];
        } else {
            self.state = DAProgressOverlayViewStateOperationInProgress;
            [self startUpdateTimer];
        }
    }
}

#pragma mark - Private

- (CGFloat)innerRadius
{
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat radius = MIN(width, height) / 2. * self.innerRadiusRatio;
    switch (self.state) {
        case DAProgressOverlayViewStateWaiting:
            return radius * self.animationProgress;
        case DAProgressOverlayViewStateOperationFinished:
            return radius + (MAX(width, height) / sqrtf(2.) - radius) * self.animationProgress;
        default:
            return radius;
    }
}

- (CGFloat)iconRadius
{
    if (self.drawIcon) {
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds);
        CGFloat ratio = self.innerRadiusRatio - (self.outerRadiusRatio - self.innerRadiusRatio);
        CGFloat radius = MIN(width, height) / 2. * ratio;

        switch (self.state) {
            default:
                return radius;
            case DAProgressOverlayViewStateWaiting:
                return radius * self.animationProgress;
            case DAProgressOverlayViewStateOperationFinished:
                return radius * (1.0f - self.animationProgress);
        }
    } else {
        return 0.0f;
    }
}

- (CGFloat)outerRadius
{
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat radius = MIN(width, height) / 2. * self.outerRadiusRatio;
    switch (self.state) {
        case DAProgressOverlayViewStateWaiting:
            return radius * self.animationProgress;
        case DAProgressOverlayViewStateOperationFinished:
            return radius + (MAX(width, height) / sqrtf(2.) - radius) * self.animationProgress;
        default:
            return radius;
    }
}

- (void)startUpdateTimer
{
    self.animationProgress = 0.0f;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:DAUpdateUIFrequency target:self selector:@selector(update) userInfo:nil repeats:YES];
    [self update];
}

- (void)update
{
    CGFloat animationProgress = self.animationProgress + DAUpdateUIFrequency / self.stateChangeAnimationDuration;
    if (animationProgress >= 1.) {
        self.animationProgress = 1.;
        [self.timer invalidate];
    } else {
        self.animationProgress = animationProgress;
    }
    [self setNeedsDisplay];
}



@end