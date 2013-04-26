//
//  MyRedditsViewController.h
//  redditapp
//
//  Created by tang on 3/25/13.
//  Copyright (c) 2013 tangbroski. All rights reserved.
//

#import <UIKit/UIKit.h>

// Adding a delegate
@class MyRedditsViewController;
@protocol MyRedditsViewControllerDelegate <NSObject>

@optional
- (void)selectedReddit:(NSString *)name;

@end

@interface MyRedditsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    __weak id <MyRedditsViewControllerDelegate> delegate;
}

@property (nonatomic, weak) id <MyRedditsViewControllerDelegate> delegate;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
