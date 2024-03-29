//
//  RedditWrapper.h
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <Foundation/Foundation.h>

// Adding a delegate
@class RedditWrapper;
@protocol RedditWrapperDelegate <NSObject>

@required
- (void)returnedJSON:(id)JSON;

@end

@interface RedditWrapper : NSObject

@property (nonatomic, weak) id <RedditWrapperDelegate> delegate;

- (void)commentsJSONUsingPermalink:(NSString *)link;
- (void)redditJSONUsingName:(NSString *)name;
- (void)redditJSON:(NSString *)redditName withPostName:(NSString *)postName withLimit:(NSInteger)limit;

//- (void)commentsFromPermalink:(NSString *)link completion:(void (^)(BOOL hasComments, NSDictionary *commentsDict, NSError *error)) block;
@end