//
//  TBMessage.m
//  Test
//
//  Created by tang on 4/22/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import "TBMessage.h"
#import <QuartzCore/QuartzCore.h>

@interface TBMessage ()

@property (nonatomic, weak) UIViewController *currentViewController;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation TBMessage
@synthesize currentViewController = _currentViewController;
@synthesize messageLabel = _messageLabel;

#define kPadding 40.0f

+ (id)sharedInstance
{
    static TBMessage *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    
    return share;
}

- (void)updateWithMessage:(NSString *)message
          withMessageType:(MessageType)messageType
         inViewController:(UIViewController *)viewController
{
    UIColor *bgColor;
    
    switch (messageType) {
        case MessageTypeError:
            bgColor = [UIColor colorWithRed:191.0f/255.0f green:75.0f/255.0f blue:49.0f/255.0f alpha:.95];
            break;
            
        case MessageTypeSuccess:
            bgColor = [UIColor colorWithRed:77.0f/255.0f green:139.0f/255.0f blue:77.0f/255.0f alpha:.95];
            break;
            
        case MessageTypeNormal:
            bgColor = [UIColor colorWithRed:133.0f/255.0f green:133.0f/255.0f blue:133.0f/255.0f alpha:.95];
            break;
            
        default:
            break;
    }
        
    // view and messageLabel setup
    self.frame = CGRectMake(0, 0, viewController.view.bounds.size.width, 40);
    self.backgroundColor = bgColor;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.messageLabel.text = message;
    self.messageLabel.font = [UIFont systemFontOfSize:14];
    self.messageLabel.textColor = [UIColor whiteColor];
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize messageSize = [message sizeWithFont:[UIFont systemFontOfSize:14]];
    self.messageLabel.frame = CGRectMake(0, 0, 200, messageSize.height);
    [self.messageLabel sizeToFit];
    
    // Getting the correct height including padding
    CGFloat updatedHeight = [self updateHeight];
    // The messageView will appear off the screen and will be animated to its display position
    self.frame = CGRectMake(0, -updatedHeight, viewController.view.bounds.size.width, updatedHeight);
    // Position the center of messageLabel at the current center of messageView
    self.messageLabel.center = CGPointMake(self.center.x, self.center.y);
    
    self.messageLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [self addSubview:self.messageLabel];
    
}

- (CGFloat)updateHeight
{
    CGFloat height;
    return height = self.messageLabel.frame.size.height + kPadding;
}

- (void)showMessage:(NSString *)message
    withMessageType:(MessageType)messageType
   inViewController:(UIViewController *)viewController
{
    
    if (self.messageLabel == nil) {
        self.messageLabel = [[UILabel alloc] init];
    }
    
    // Updates messageView and messageLabel according to the MessageType and Text
    [self updateWithMessage:message
            withMessageType:(MessageType)messageType
           inViewController:viewController];
    
    [viewController.view addSubview:self];
    
    /*
        Animate both messageView and messageLabel to the correct position
        Wait for a predetermined time
        Then animate both back to it's original origin
     */
    
    if (self.hidden)
        self.hidden = NO;
    
    CGFloat originalHeight = self.frame.origin.y;
    [UIView animateWithDuration:.5
                     animations:^{
                         self.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
                         self.messageLabel.center = self.center;
                     }
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration:.5
                                               delay:.5
                                             options:0
                                          animations:^{
                                              self.frame = CGRectMake(0, originalHeight, self.frame.size.width, self.frame.size.height);
                                              self.messageLabel.center = self.center;
                                          } completion:^(BOOL finished) {
                                              [self hide];
                                          }];
                     }];
    
}

- (void)hide
{
    if (!self.hidden)
        self.hidden = YES;
}

@end
