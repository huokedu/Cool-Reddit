//
//  MyRedditsViewController.h
//  redditapp
//
//  Created by tang on 3/25/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <UIKit/UIKit.h>

// Adding a delegate
@class MyRedditsViewController;
@protocol MyRedditsViewControllerDelegate <NSObject>

@required
- (void)selectedReddit:(NSString *)name;

@end

@interface MyRedditsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) id <MyRedditsViewControllerDelegate> delegate;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
