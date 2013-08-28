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

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *headers = @{@"accept": @"application/json"};
    
    [request setAllHTTPHeaderFields:headers];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               NSError *errorJSON = nil;
                               NSMutableArray *JSON = [data mutableObjectFromJSONDataWithParseOptions:JKParseOptionNone error:&errorJSON];
                               
                               if (errorJSON != nil) {
                                   NSLog(@"JSON Request Error %@", [errorJSON localizedDescription]);
                                   NSLog(@"Handled behind the scenes for now");
                                   [self.delegate returnedJSON:nil];
                               } else {
                                   //Do something with returned array
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       
                                       [self.delegate returnedJSON:JSON];
                                   });
                               }
                               
                           }];
    
}

@end