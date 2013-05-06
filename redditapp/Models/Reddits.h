//
//  Reddits.h
//  redditapp
//
//  Created by tang on 4/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Reddits : NSManagedObject

@property (nonatomic) BOOL enabled;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) double orderingValue;

@end
