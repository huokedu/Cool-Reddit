//
//  Share.h
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 tangbroski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Share : NSObject

@property (nonatomic, retain) NSString *permalink;
@property (nonatomic, retain) NSString *redditName;
@property (nonatomic, retain) NSString *selftext;
@property (nonatomic, retain) NSURL *link;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;

+ (id)sharedInstance;
@end
