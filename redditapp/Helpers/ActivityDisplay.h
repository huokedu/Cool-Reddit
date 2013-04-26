//
//  ActivityDisplay.h
//  redditapp
//
//  Created by tang on 4/7/13.
//  Copyright (c) 2013 tangbroski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActivityDisplay : UIView
{
    
}

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

+ (id)sharedInstance;

- (void)showActivityIndicator;
- (void)hideActivityIndicator;
- (void)repositionView:(CGPoint)newCenter;
@end
