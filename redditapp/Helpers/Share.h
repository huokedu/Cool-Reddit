//
//  Share.h
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Share : NSObject

@property (nonatomic, strong) NSString *permalink;
@property (nonatomic, strong) NSString *redditName;
@property (nonatomic, strong) NSString *selftext;
@property (nonatomic, strong) NSURL *link;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;

+ (id)sharedInstance;
@end
