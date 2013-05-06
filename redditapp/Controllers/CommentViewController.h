//
//  CommentViewController.h
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditWrapper.h"
#import <NimbusAttributedLabel.h>

@interface CommentViewController : UIViewController <RedditWrapperDelegate, UITableViewDataSource, UITableViewDelegate, NIAttributedLabelDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end
