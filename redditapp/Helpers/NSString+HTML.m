//
//  NSString+HTML.m
//  redditapp
//
//  Created by tang on 4/15/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

/*
 TODO
 - Update decodeHTMLEntities to not create a new NSString for every string replacement
*/
 
#import "NSString+HTML.h"

@implementation NSString (HTML)

- (NSString *)decodeHTMLEntities
{    
    NSString *newString = [NSString stringWithString:self];
    
    newString = [newString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&cent;" withString:@"¢"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&pound;" withString:@"£"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&yen;" withString:@"¥"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&euro;" withString:@"€"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&sect;" withString:@"§"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&copy;" withString:@"©"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&reg;" withString:@"®"];
    newString = [newString stringByReplacingOccurrencesOfString:@"&trade;" withString:@"™"];
    
    return newString;
}
@end
