//
//  WebViewController.h
//  redditapp
//
//  Created by tang on 3/27/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@end
