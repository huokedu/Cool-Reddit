//
//  Indicator.h
//  Cool Reddit
//
//  Created by tang on 5/4/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Indicator : UIView

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (void)showWithMessage:(NSString *)message;
- (void)hide;
@end
