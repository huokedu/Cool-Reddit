//
//  TBMessage.h
//  Test
//
//  Created by tang on 4/22/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum MessageType {
    MessageTypeError,
    MessageTypeSuccess,
    MessageTypeNormal
} MessageType;

@interface TBMessage : UIView


+ (id)sharedInstance;

- (void)showMessage:(NSString *)message
    withMessageType:(MessageType)messageType
   inViewController:(UIViewController *)viewController;
@end
