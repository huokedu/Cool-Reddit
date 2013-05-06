//
//  RedditWrapper.m
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import "RedditWrapper.h"
#import "JSONKit.h"

@implementation RedditWrapper
@synthesize delegate = _delegate;

- (void)commentsJSONUsingPermalink:(NSString *)link
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com%@.json", link]];
    [self requestJSON:url];
}

- (void)redditJSONUsingName:(NSString *)name
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com/r/%@/.json", name]];
    [self requestJSON:url];
}

- (void)redditJSON:(NSString *)redditName withPostName:(NSString *)postName withLimit:(NSInteger)limit
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com/r/%@/.json?count=%d&after=%@", redditName, limit, postName]];
    
    [self requestJSON:url];
}

- (void)requestJSON:(NSURL *)url
{

    NSMutableURLRequest *_request = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *_headers = [NSDictionary dictionaryWithObjectsAndKeys:@"application/json", @"accept", nil];
    [_request setAllHTTPHeaderFields:_headers];

    [NSURLConnection sendAsynchronousRequest:_request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
                               
                               NSError *_errorJson = nil;
                               NSMutableArray *_JSON = [data mutableObjectFromJSONDataWithParseOptions:JKParseOptionNone error:&_errorJson];
                               
                               if (_errorJson != nil) {
                                   NSLog(@"JSON Request Error %@", [_errorJson localizedDescription]);
                                   NSLog(@"Handled behind the scenes for now");
                                   [self.delegate returnedJSON:nil];
                               } else {
                                   //Do something with returned array
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       
                                       [self.delegate returnedJSON:_JSON];
                                   });
                               }
                               
                           }];
    
}

@end