//
//  ActivityDisplay.m
//  redditapp
//
//  Created by tang on 4/7/13.
//  Copyright (c) 2013 tangbroski. All rights reserved.
//

// TODO
// Add the ability to add messages (UILabel's) to the activity indicator view

#import "ActivityDisplay.h"
#import <QuartzCore/QuartzCore.h>

@implementation ActivityDisplay
@synthesize activityIndicator = _activityIndicator;

+ (id)sharedInstance
{
    static ActivityDisplay *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
        
    return shared;
}

- (void)showActivityIndicator
{
    if (self.activityIndicator == nil) {
        self.activityIndicator = [self createActivityIndicator];
    }
    
    [self.activityIndicator startAnimating];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.activityIndicator];
    
}

- (void)hideActivityIndicator
{
    [self.activityIndicator removeFromSuperview];
}

- (UIActivityIndicatorView *)createActivityIndicator
{
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
    activity.frame = CGRectMake(0, 0, 60.0, 60.0);
    activity.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.8];
    activity.layer.cornerRadius = 5;

    activity.center = CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2);
    
    return activity;
}

- (void)repositionView:(CGPoint)newCenter
{
    self.activityIndicator.center = newCenter;
}
@end
