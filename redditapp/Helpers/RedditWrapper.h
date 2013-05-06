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
{
    __weak id <RedditWrapperDelegate> delegate;
}

@property (nonatomic, weak) id <RedditWrapperDelegate> delegate;

- (void)commentsJSONUsingPermalink:(NSString *)link;
- (void)redditJSONUsingName:(NSString *)name;
- (void)redditJSON:(NSString *)redditName withPostName:(NSString *)postName withLimit:(NSInteger)limit;

@end
