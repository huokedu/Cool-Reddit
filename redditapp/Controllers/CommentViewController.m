//
//  CommentViewController.m
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import "CommentViewController.h"
#import "Share.h"
#import "RedditWrapper.h"
#import <NimbusAttributedLabel.h>
#import "WebViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <Reachability.h>
#import "Indicator.h"
#import "GTMNSString+HTML.h"

#define kFontSize 13.0f
#define kTitleFontSize 13.0f
#define kMainAuthorFont 11.0f
#define kAuthorFontSize 11.0f
#define kMargin 10.0f
#define kIndent 10.0f

#define kCommentLabelTag 1
#define kAuthorLabelForCommentCellTag 2
#define kSelfTextLabelTag 3
#define kTitleLabelTag 4
#define kAuthorLabelForFirstCellTag 5
#define kTimeLabelTag 6

@interface CommentViewController ()
{
    NSMutableArray *_holder;
    UITableViewController *_tvc;
    
}
@property (nonatomic, strong) Indicator *indicator;
@end

@implementation CommentViewController

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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
    gestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    [self showComments];
    
    _tvc = [[UITableViewController alloc] initWithStyle:self.tableView.style];
    [self addChildViewController:_tvc];
    _tvc.tableView = self.tableView;
    
    _tvc.refreshControl = [[UIRefreshControl alloc] init];
    _tvc.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull To Refresh"];
    [_tvc.refreshControl addTarget:self action:@selector(refreshTableView) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self testInternetConnection];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        // Back button was pressed. We know this is true because self is no longer
        // in the navigation stack.
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.indicator hide];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Gets the permalink from the singleton
// Passes the value to the RedditWrapper
// The JSON will return via returnedJSON: once it has downloaded
- (void)showComments
{
    RedditWrapper *wrapper = [[RedditWrapper alloc] init];
    wrapper.delegate = self;
    [wrapper commentsJSONUsingPermalink:[[Share sharedInstance] permalink]];
    
    // Show the Indicator
    // Hide it in returnedJSON:
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.indicator showWithMessage:@"Loading"];
}

#pragma mark - JSON Methods

- (void)returnedJSON:(id)JSON
{
    NSDictionary *commentTree = [JSON objectAtIndex:1];
    
    NSArray *comments = [[commentTree objectForKey:@"data"] objectForKey:@"children"];
    
    _holder = [NSMutableArray array];
    for (NSDictionary *testDict in comments) {
        [self build:testDict indent:0];
    }
    
    if (_tvc.refreshControl.isRefreshing) {
        [_tvc.refreshControl endRefreshing];
    }
    
    [self.tableView reloadData];
    
    // Hides the Activity Display from showComments
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.indicator hide];
}

// Iterates through the JSON using recursion and returns an array
// Each element of the array has a dictionary with each comment
- (void)build:(id)jsonDict
       indent:(int)indent
{
    if ([jsonDict objectForKey:@"data"]) {
        NSDictionary *commentJSON = [jsonDict objectForKey:@"data"];
        // There's always a body
        if ([commentJSON objectForKey:@"body"]) {
            [_holder addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:indent], @"indent", [[commentJSON objectForKey:@"body"] description], @"comment", [[commentJSON objectForKey:@"author"] description], @"author", [commentJSON objectForKey:@"created_utc"], @"created_utc", nil]];
            indent = indent + 1;
            
            if (![[[commentJSON objectForKey:@"replies"] description] isEqualToString:@""]) {

                NSArray *childrenArray = [[[commentJSON objectForKey:@"replies"] objectForKey:@"data"] objectForKey:@"children"];
                if ([childrenArray count]) {
                    for (NSArray *child in childrenArray) {
                        [self build:child indent:indent];
                    }
                }
            }
        }
    }
    
}

#pragma mark -

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
    
}

- (void)testInternetConnection
{
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _holder.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FirstCellIdentifier = @"FirstCell";
    static NSString *CommentCellIdentifier = @"CommentCell";
    
    UITableViewCell *cell = nil;
    NIAttributedLabel *commentLabel = nil;
    NIAttributedLabel *authorLabelForFirstCell = nil;
    NIAttributedLabel *authorLabelForCommentCell = nil;
    NIAttributedLabel *selfTextLabel = nil;
    NIAttributedLabel *titleLabel = nil;
    UILabel *timeLabel = nil;
    
    CGFloat cellWidth = self.view.bounds.size.width;
    
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:FirstCellIdentifier];

        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FirstCellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            selfTextLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            selfTextLabel.font = [UIFont systemFontOfSize:kFontSize];
            selfTextLabel.numberOfLines = 0;
            selfTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            selfTextLabel.tag = kSelfTextLabelTag;
            selfTextLabel.autoDetectLinks = YES;
            selfTextLabel.delegate = self;
            [cell.contentView addSubview:selfTextLabel];
            
            titleLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            titleLabel.font = [UIFont boldSystemFontOfSize:kTitleFontSize];
            titleLabel.numberOfLines = 0;
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            titleLabel.tag = kTitleLabelTag;
            titleLabel.autoDetectLinks = YES;
            titleLabel.delegate = self;
            [cell.contentView addSubview:titleLabel];
            
            authorLabelForFirstCell = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            authorLabelForFirstCell.font = [UIFont systemFontOfSize:kMainAuthorFont];
            authorLabelForFirstCell.numberOfLines = 0;
            authorLabelForFirstCell.lineBreakMode = NSLineBreakByWordWrapping;
            authorLabelForFirstCell.tag = kAuthorLabelForFirstCellTag;
            [cell.contentView addSubview:authorLabelForFirstCell];
            
            timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            timeLabel.font = [UIFont systemFontOfSize:kAuthorFontSize];
            timeLabel.numberOfLines = 0;
            timeLabel.lineBreakMode = NSLineBreakByWordWrapping;
            timeLabel.tag = kTimeLabelTag;
            [cell.contentView addSubview:timeLabel];
        } else {
            titleLabel = (NIAttributedLabel *)[cell viewWithTag:kTitleLabelTag];
            authorLabelForFirstCell = (NIAttributedLabel *)[cell viewWithTag:kAuthorLabelForFirstCellTag];
            selfTextLabel = (NIAttributedLabel *)[cell viewWithTag:kSelfTextLabelTag];
            timeLabel = (UILabel *)[cell viewWithTag:kTimeLabelTag];

        }
        
        // Get Data
        NSString *title = [[Share sharedInstance] title];
        NSString *selfText = [[Share sharedInstance] selfText];
        selfText = [selfText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *author = [NSString stringWithFormat:@"%@", [[Share sharedInstance] author]];
        
        NSInteger createdUTC = [[[Share sharedInstance] time] integerValue];
        NSString *time = [self elapsedTime:[NSDate dateWithTimeIntervalSince1970:createdUTC]];
        
        // Size Calculations
        CGSize timeSize = [time sizeWithFont:[UIFont systemFontOfSize:kAuthorFontSize]];
        
        CGSize cellConstraint = CGSizeMake(cellWidth - (kMargin * 2), MAXFLOAT);
        CGSize titleSize = [title sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize]
                             constrainedToSize:cellConstraint
                                 lineBreakMode:NSLineBreakByWordWrapping];
        CGSize selftextSize = [selfText sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                                   constrainedToSize:cellConstraint
                                       lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize authorSize = [author sizeWithFont:[UIFont systemFontOfSize:kMainAuthorFont]
                               constrainedToSize:cellConstraint
                                   lineBreakMode:NSLineBreakByWordWrapping];
        
        // Additional Label Configs
        [titleLabel setText:title];
        [titleLabel setFont:[UIFont boldSystemFontOfSize:kTitleFontSize]];
        [titleLabel setFrame:CGRectMake(kMargin, kMargin + authorSize.height + 1, titleSize.width, titleSize.height)];
        
        [authorLabelForFirstCell setText:author];
        UIColor *authorColor = [UIColor colorWithRed:231.0f/255.0f green:76.0f/255.0f blue:60.0f/255.0f alpha:1];
        
        [authorLabelForFirstCell setTextColor:authorColor range:[authorLabelForFirstCell.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
        [authorLabelForFirstCell setFont:[UIFont systemFontOfSize:kMainAuthorFont]];
        [authorLabelForFirstCell setFrame:CGRectMake(kMargin, kMargin, authorSize.width, authorSize.height)];
        
        [selfTextLabel setText:selfText];
        [selfTextLabel setFrame:CGRectMake(kMargin, kMargin + authorSize.height + titleSize.height + 2, selftextSize.width, selftextSize.height)];
        
        [timeLabel setText:time];
        [timeLabel setFrame:CGRectMake(kMargin + authorSize.width + 2, kMargin, timeSize.width, timeSize.height)];
        
        return cell;
        
    } else {
    
        cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CommentCellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            commentLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            commentLabel.font = [UIFont systemFontOfSize:kFontSize];
            commentLabel.numberOfLines = 0;
            commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
            commentLabel.tag = kCommentLabelTag;
            commentLabel.autoDetectLinks = YES;
            commentLabel.deferLinkDetection = YES;
            commentLabel.delegate = self;
            [cell.contentView addSubview:commentLabel];
            
            authorLabelForCommentCell = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            authorLabelForCommentCell.font = [UIFont systemFontOfSize:kAuthorFontSize];
            authorLabelForCommentCell.numberOfLines = 0;
            authorLabelForCommentCell.lineBreakMode = NSLineBreakByWordWrapping;
            authorLabelForCommentCell.tag = kAuthorLabelForCommentCellTag;
            [cell.contentView addSubview:authorLabelForCommentCell];
            
            timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            timeLabel.font = [UIFont systemFontOfSize:kAuthorFontSize];
            timeLabel.numberOfLines = 0;
            timeLabel.lineBreakMode = NSLineBreakByWordWrapping;
            timeLabel.tag = kTimeLabelTag;
            [cell.contentView addSubview:timeLabel];

        } else {
            authorLabelForCommentCell = (NIAttributedLabel *)[cell viewWithTag:kAuthorLabelForCommentCellTag];
            commentLabel = (NIAttributedLabel *)[cell viewWithTag:kCommentLabelTag];
            timeLabel = (UILabel *)[cell viewWithTag:kTimeLabelTag];

        }

        NSInteger indexLessOne = indexPath.row - 1;
        
        // Get Data
        NSDictionary *dict = [_holder objectAtIndex:indexLessOne];
        NSString *comment = [[dict objectForKey:@"comment"] description];
        comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        comment = [comment gtm_stringByUnescapingFromHTML];
        
        NSInteger createdUTC = [[dict objectForKey:@"created_utc"] integerValue];
        NSString *time = [self elapsedTime:[NSDate dateWithTimeIntervalSince1970:createdUTC]];
        
        NSInteger indentLevel = [[dict objectForKey:@"indent"] integerValue];
        NSString *author = [[dict objectForKey:@"author"] description];
        
        // Size Calculations
        CGSize timeSize = [time sizeWithFont:[UIFont systemFontOfSize:kAuthorFontSize]];
        
        CGFloat indentCellWidth = [self widthWithIndent:indentLevel width:cellWidth];
        
        CGSize authorContraint = CGSizeMake(indentCellWidth - (kMargin * 2), MAXFLOAT);
        CGSize authorSize = [author sizeWithFont:[UIFont systemFontOfSize:kAuthorFontSize]
                               constrainedToSize:authorContraint
                                   lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize commentConstraint = CGSizeMake(indentCellWidth - (kMargin * 2), MAXFLOAT);
        CGSize commentSize = [comment sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                                 constrainedToSize:commentConstraint
                                     lineBreakMode:NSLineBreakByWordWrapping];
        
        // Additional Label Configs        
        [authorLabelForCommentCell setText:author];
        [authorLabelForCommentCell setFrame:CGRectMake(kMargin + (kIndent * indentLevel), kMargin, authorSize.width, authorSize.height)];

        if ([author isEqualToString:[[Share sharedInstance] author]]) {
            UIColor *authorColor = [UIColor colorWithRed:231.0f/255.0f green:76.0f/255.0f blue:60.0f/255.0f alpha:1];

            [authorLabelForCommentCell setTextColor:authorColor range:[authorLabelForCommentCell.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
        } else {
            UIColor *authorColor = [UIColor colorWithRed:76.0f/255.0f green:112.0f/255.0f blue:163.0f/255.0f alpha:1];
            [authorLabelForCommentCell setTextColor:authorColor range:[authorLabelForCommentCell.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
        }
                
        [commentLabel setText:comment];
        [commentLabel setFrame:CGRectMake(kMargin + (kIndent * indentLevel), kMargin + authorSize.height, commentSize.width, commentSize.height)];
        
        [timeLabel setText:time];
        [timeLabel setFrame:CGRectMake(kMargin + (kIndent * indentLevel) + authorSize.width + 2, kMargin, timeSize.width, timeSize.height)];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellWidth = self.view.bounds.size.width;
    
    if ([indexPath row] == 0) {
        
        // Get Data
        NSString *title = [[Share sharedInstance] title];
        NSString *selfText = [[Share sharedInstance] selfText];
        selfText = [selfText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *author = [NSString stringWithFormat:@"%@", [[Share sharedInstance] author]];
        
        // Height Calculations
        CGSize cellConstraint = CGSizeMake(cellWidth - (kMargin * 2), MAXFLOAT);
        CGFloat titleHeight = [title sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize]
                                constrainedToSize:cellConstraint
                                    lineBreakMode:NSLineBreakByWordWrapping].height;

        CGFloat authorHeight = [author sizeWithFont:[UIFont systemFontOfSize:kMainAuthorFont]
                                  constrainedToSize:cellConstraint
                                      lineBreakMode:NSLineBreakByWordWrapping].height;
        
        CGFloat selftextHeight = [selfText sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                                      constrainedToSize:cellConstraint
                                          lineBreakMode:NSLineBreakByWordWrapping].height;
        
        return selftextHeight + authorHeight + titleHeight + (kMargin * 2) + 2;
    } else {
        
        NSInteger indexLessOne = indexPath.row - 1;

        // Get Data
        NSDictionary *dict = [_holder objectAtIndex:indexLessOne];
        NSString *comment = [[dict objectForKey:@"comment"] description];
        comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        comment = [comment gtm_stringByUnescapingFromHTML];
        
        NSString *author = [[dict objectForKey:@"author"] description];
        NSInteger indentLevel = [[dict objectForKey:@"indent"] integerValue];
            
        // Height Calculations
        CGFloat indentCellWidth = [self widthWithIndent:indentLevel width:cellWidth];
        
        // The constraint is the cell width minus the indent level minus the left and right margins
        CGSize cellConstaint = CGSizeMake(indentCellWidth - (kMargin * 2), MAXFLOAT);
     
        CGFloat authorHeight = [author sizeWithFont:[UIFont systemFontOfSize:kAuthorFontSize]
                                  constrainedToSize:cellConstaint
                                      lineBreakMode:NSLineBreakByWordWrapping].height;
        
        CGFloat commentHeight = [comment sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                                    constrainedToSize:cellConstaint
                                        lineBreakMode:NSLineBreakByWordWrapping].height;
            
        return commentHeight + authorHeight + (kMargin * 2);
    }
}

#pragma mark - UITableView Helper Method

- (CGFloat)widthWithIndent:(NSInteger)indentLevel
                     width:(CGFloat)width
{
    return width - (indentLevel * kIndent);
}

#pragma mark - NIAttributedLabelDelegate Method

- (void)attributedLabel:(NIAttributedLabel *)attributedLabel
didSelectTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point
{
    WebViewController *webController = [[WebViewController alloc] init];
    [[Share sharedInstance] setLink:result.URL];
        
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Comments" style:UIBarButtonItemStylePlain target:self action:@selector(didTapBackButton)];
    [backButton setBackgroundImage:[[UIImage imageNamed:@"nav_back_30"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(0, 11, 0, 2)]
                          forState:UIControlStateNormal
                        barMetrics:UIBarMetricsDefault];
    
    [backButton setBackgroundImage:[[UIImage imageNamed:@"nav_back_24"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(0, 11, 0, 2)]
                          forState:UIControlStateNormal
                        barMetrics:UIBarMetricsLandscapePhone];
    
    [backButton setTitlePositionAdjustment:UIOffsetMake(3, 0) forBarMetrics:UIBarMetricsDefault];
        
    [webController.navigationItem setLeftBarButtonItem:backButton];
    [self.navigationController pushViewController:webController animated:YES];
}

#pragma mark -

- (void)didSwipeRight:(UIGestureRecognizer *)gestureRecognizer
{
//    NSLog(@"Swiped right");
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void)didTapBackButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)elapsedTime:(NSDate *)created
{
    NSInteger time;
    NSString *timeString;
    
//    NSLog(@"Start %@", created.description);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss z";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    NSString *createdlocal = [formatter stringFromDate:created];
//    NSLog(@"Converted %@", createdlocal);
    
    NSDate *now = [NSDate date];
    NSString *nowLocal = [formatter stringFromDate:now];
//    NSLog(@"Current %@", nowLocal);
    
    NSTimeInterval timeBetweenDates = [now timeIntervalSinceDate:created];
    
//    NSLog(@"Seconds %f", timeBetweenDates);
    double secondsInAnHour = 3600;
    double minutesInAnHour = 60;
    time = timeBetweenDates / secondsInAnHour;
    
//    NSLog(@"Hours elapsed %d", time);
    
    timeString = [NSString stringWithFormat:@"%dh", time];
    if (time == 0) {
        time = timeBetweenDates / minutesInAnHour;
        timeString = [NSString stringWithFormat:@"%dm", time];
        
        if (time == 0) {
            time = timeBetweenDates;
            timeString = [NSString stringWithFormat:@"%ds", time];
            
        }
        
    }
    
    return [NSString stringWithFormat:@"%@ ago", timeString];
}

- (void)refreshTableView
{
    RedditWrapper *wrapper = [[RedditWrapper alloc] init];
    wrapper.delegate = self;
    [wrapper commentsJSONUsingPermalink:[[Share sharedInstance] permalink]];
}

@end
