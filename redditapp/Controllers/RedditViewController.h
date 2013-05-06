//
//  RedditViewController.h
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditWrapper.h"
#import "MyRedditsViewController.h"

@interface RedditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RedditWrapperDelegate, MyRedditsViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
