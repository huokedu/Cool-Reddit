//
//  Indicator.m
//  Cool Reddit
//
//  Created by tang on 5/4/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import "Indicator.h"
#import <QuartzCore/QuartzCore.h>

#define kFontSize 18.0
#define kSpacing 20.0
#define kMaxMessageLabelWidth 150.0
#define kPadding 10.0

@implementation Indicator
@synthesize messageLabel = _messageLabel;
@synthesize activityIndicator = _activityIndicator;

- (id)init
{
    self = [super init];
    if (self) {
        // Start out hidden
        self.hidden = YES;
        
        self.backgroundColor = [UIColor blackColor];
        self.alpha = .90;
        self.layer.cornerRadius = 3;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        // UILabel Config
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.textColor = [UIColor whiteColor];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.font = [UIFont systemFontOfSize:kFontSize];
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.messageLabel];
        
        // UIActivityIndicatorView Config
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        self.frame = CGRectMake(0, 0, self.activityIndicator.frame.size.width + kSpacing, kSpacing + self.activityIndicator.frame.size.height);
        self.activityIndicator.center = CGPointMake(self.frame.size.width/2, kSpacing);
        [self addSubview:self.activityIndicator];
    }
    
    return self;
    
}

- (void)showWithMessage:(NSString *)message
{
    self.hidden = NO;
    [self.activityIndicator startAnimating];
    
    if (message) {
        CGSize messageSize = [message sizeWithFont:[UIFont systemFontOfSize:kFontSize] forWidth:kMaxMessageLabelWidth lineBreakMode:NSLineBreakByWordWrapping];
        
        // Resize the view frame
        self.frame = CGRectMake(0, 0, messageSize.width + kSpacing, self.activityIndicator.frame.size.height + kSpacing + messageSize.height + kPadding);
        
        self.messageLabel.frame = CGRectMake(0, self.activityIndicator.frame.size.height + kSpacing, messageSize.width, messageSize.height);
        self.messageLabel.text = message;
        self.messageLabel.center = CGPointMake(self.frame.size.width/2, self.messageLabel.center.y);
    }
    
    [self.superview bringSubviewToFront:self];
    self.center = CGPointMake(self.superview.bounds.size.width/2, self.superview.bounds.size.height/2);
}

- (void)hide
{
    if (!self.hidden) {
        self.hidden = YES;
        [self.activityIndicator stopAnimating];
    }
}

@end
