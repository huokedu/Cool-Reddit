//
//  WebViewController.m
//  redditapp
//
//  Created by tang on 3/27/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

// TODO
// - Add the ability to share via email and text message

#import "WebViewController.h"
#import "Share.h"
#import "Indicator.h"

@interface WebViewController ()
@property (nonatomic, strong) Indicator *indicator;
@end

@implementation WebViewController
@synthesize webView = _webView;
@synthesize indicator = _indicator;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.indicator = [[Indicator alloc] init];
    [self.view addSubview:self.indicator];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapBackButton)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [flexibleSpace setWidth:15];
    
    UIBarButtonItem *forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forwardIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapForwardButton)];
        
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didTapRefreshButton)];

    NSArray *buttonArray = [NSArray arrayWithObjects:flexibleSpace, backButton, flexibleSpace, forwardButton, flexibleSpace, refreshButton, flexibleSpace, nil];
    
    [self setToolbarItems:buttonArray];

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
    
    // Create a UIWebView and set it to the webView property
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.scalesPageToFit = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[Share sharedInstance] link]]];
    [self.view addSubview:self.webView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.toolbarHidden = YES;

}

- (void)voidDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.webView = nil;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] init];  
    self.view = view;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didTapBackButton
{
    [self.webView goBack];
}

- (void)didTapForwardButton
{
    [self.webView goForward];
}

- (void)didTapRefreshButton
{
    [self.webView reload];
}

#pragma mark - UIWebView Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    NSLog(@"webViewDidStartLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.indicator showWithMessage:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    NSLog(@"webViewDidFinishLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.indicator hide];
}

@end
