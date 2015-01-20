//
//  DAProgressOverlayView.h
//  DAProgressOverlayView
//
//  Created by Daria Kopaliani on 8/1/13.
//  Copyright (c) 2013 Daria Kopaliani. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DAProgressOverlayView : UIView

@property (strong, nonatomic) UIColor *overlayColor;

/**
 The ratio of the inner circle to the minimum side of DAProgressOverlayView,
 0 ≤ innerRadiusRatio ≤ 1,
 This is #000000 with alpha equal 0.5 by default.
 */
@property (assign, nonatomic) CGFloat innerRadiusRatio;

/**
 The ratio of the outer circle to the minimum side of DAProgressOverlayView,
 0 ≤ outerRadiusRatio ≤ 1,
 This is 0.7 by default.
 */

@property (assign, nonatomic) CGFloat outerRadiusRatio;

/**
 The float value used to for calculate the `filled in` fraction of the inner circle,
  0 ≤ progress ≤ 1.
 */
@property (assign, nonatomic) CGFloat progress;

/**
 The duration for animations displayed after calling `show:animated:` and `displayOperationDidFinishAnimation` methods.
 This is 0.25 by default.
 */
@property (assign, nonatomic) CGFloat stateChangeAnimationDuration;

/**
 This flag indicates wheter or not 'displayDownloadDidFinishAnimation' method is called when 'progress' property is set to 1.,
 This is YES by default.
 */
@property (assign, nonatomic) BOOL triggersDownloadDidFinishAnimationAutomatically;

@property(nonatomic) BOOL isShowing;

/**
 If you only update progress in chunks, use this method instead of the `progress` property to get a smooth animation.
*/
- (void)setProgress:(CGFloat)targetProgress animated:(BOOL)animated;

/**
When showing, changes radiuses of the inner and outer circles from zero to the corresponding values,
calculated from 'innerRadiusRatio' and 'outerRadiusRatio' properties.

When hiding, makes the outer faded out circle radius expand until it circumscribes the DAProgressOverlayView bounds
*/
typedef void (^DAAnimationCompletionBlock)();
- (void)show:(BOOL)show animated:(BOOL)animated;
- (void)show:(BOOL)show animated:(BOOL)animated withCompletionBlock:(DAAnimationCompletionBlock)block;

/**
 Assignable drawing block for showing an icon in the overlay view's center.
*/
typedef void (^DADrawingBlock)(CGContextRef ctx, CGRect rect, CGColorRef fillColor);
@property(nonatomic, copy) DADrawingBlock iconDrawingBlock;
@property(nonatomic) BOOL drawIcon;

@end
