//
//  CommentViewController.m
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 tangbroski. All rights reserved.
//

#import "CommentViewController.h"
#import "Share.h"
#import "RedditWrapper.h"
#import <NimbusAttributedLabel.h>
#import "WebViewController.h"
#import "ActivityDisplay.h"
#import <QuartzCore/QuartzCore.h>
#import "NSString+HTML.h"
#import <Reachability.h>

#define kFontSize 13.0f
#define kTitleFontSize 14.0f
#define kMainAuthorFont 11.0f
#define kAuthorFontSize 11.0f
#define kMargin 10.0f
#define kIndent 10.0f

@interface CommentViewController ()
{
    NSMutableArray *holder;
}
@end

@implementation CommentViewController
@synthesize tableView = _tableView;

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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.view addSubview:self.tableView];
    
    [self showComments];
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
        
        [[ActivityDisplay sharedInstance] hideActivityIndicator];
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
    // Show the Activity Indicator
    // Hide it in returnedJSON:
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[ActivityDisplay sharedInstance] showActivityIndicator];
    
    RedditWrapper *wrapper = [[RedditWrapper alloc] init];
    wrapper.delegate = self;
    [wrapper commentsJSONUsingPermalink:[[Share sharedInstance] permalink]];
}

#pragma mark - JSON Methods
// TODO
// Move extra value returns into RedditWrapper

- (void)returnedJSON:(id)JSON
{
    NSDictionary *commentTree = [JSON objectAtIndex:1];
    
    NSArray *comments = [[commentTree objectForKey:@"data"] objectForKey:@"children"];
    
    holder = [NSMutableArray array];
    for (NSDictionary *testDict in comments) {
        [self build:testDict indent:0];
    }
    
    [self.tableView reloadData];
    
    // Hides the Activity Display from showComments
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[ActivityDisplay sharedInstance] hideActivityIndicator];
}

// TODO
// Move this parsing method into RedditWrapper

// Iterates through the JSON and returns an array
// Each element of the array has a dictionary with each comment
- (void)build:(id)jsonDict
       indent:(int)indent
{
    if ([jsonDict objectForKey:@"data"]) {
        NSDictionary *commentJSON = [jsonDict objectForKey:@"data"];
        // There's always a body
        if ([commentJSON objectForKey:@"body"]) {
            [holder addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:indent], @"indent", [[commentJSON objectForKey:@"body"] description], @"comment", [[commentJSON objectForKey:@"author"] description], @"author", nil]];
            indent = indent + 1;
            
            // Check if replies exist, if so, use some recursion
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
    
    CGPoint screenCenter;
    if (UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)) {
        screenCenter = CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2);
    } else {
        screenCenter = CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2);
    }
    
    [[ActivityDisplay sharedInstance] repositionView:screenCenter];
    
}

- (void)testInternetConnection
{
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

#pragma mark - UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return holder.count + 1;
}

// TODO
// Pull out the configuration part of the cell and put it in configureCell:forIndexPath:
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIAttributedLabel *commentLabel = nil;
    NIAttributedLabel *authorLabel = nil;
    NIAttributedLabel *selftextLabel = nil;
    NIAttributedLabel *titleLabel = nil;
    
    CGFloat cellWidth = self.view.bounds.size.width;
    
    NSString *cellIdentifier = @"CommentCell";
    if (indexPath.row == 0) {
        cellIdentifier = @"FirstCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        if ([cellIdentifier isEqualToString:@"CommentCell"]) {
            commentLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            commentLabel.font = [UIFont systemFontOfSize:kFontSize];
            commentLabel.numberOfLines = 0;
            commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
            commentLabel.tag = 1;
            commentLabel.autoDetectLinks = YES;
            commentLabel.deferLinkDetection = YES;
            commentLabel.delegate = self;
            [cell.contentView addSubview:commentLabel];
            
            authorLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            authorLabel.font = [UIFont systemFontOfSize:kAuthorFontSize];
            authorLabel.numberOfLines = 0;
            authorLabel.lineBreakMode = NSLineBreakByWordWrapping;
            authorLabel.tag = 3;
            [cell.contentView addSubview:authorLabel];
        } else {
            selftextLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            selftextLabel.font = [UIFont systemFontOfSize:kFontSize];
            selftextLabel.numberOfLines = 0;
            selftextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            selftextLabel.tag = 4;
            selftextLabel.autoDetectLinks = YES;
            selftextLabel.delegate = self;
            [cell.contentView addSubview:selftextLabel];
            
            titleLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            titleLabel.font = [UIFont boldSystemFontOfSize:kTitleFontSize];
            titleLabel.numberOfLines = 0;
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            titleLabel.tag = 5;
            titleLabel.autoDetectLinks = YES;
            titleLabel.delegate = self;
            [cell.contentView addSubview:titleLabel];
            
            authorLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            authorLabel.font = [UIFont systemFontOfSize:kMainAuthorFont];
            authorLabel.numberOfLines = 0;
            authorLabel.lineBreakMode = NSLineBreakByWordWrapping;
            authorLabel.tag = 6;
            [cell.contentView addSubview:authorLabel];
            
        }

    }
    
    if ([cellIdentifier isEqualToString:@"FirstCell"]) {
        
        /* Get Data */
        NSString *title = [[Share sharedInstance] title];
        NSString *selftext = [[Share sharedInstance] selftext];
        selftext = [selftext stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *author = [NSString stringWithFormat:@"- %@", [[Share sharedInstance] author]];
        
        
        /* Size Calculations */
        CGSize cellConstraint = CGSizeMake(cellWidth - (kMargin * 2), MAXFLOAT);
        CGSize titleSize = [title sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize]
                             constrainedToSize:cellConstraint
                                 lineBreakMode:NSLineBreakByWordWrapping];
        CGSize selftextSize = [selftext sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                                   constrainedToSize:cellConstraint
                                       lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize authorSize = [author sizeWithFont:[UIFont systemFontOfSize:kMainAuthorFont]
                               constrainedToSize:cellConstraint
                                   lineBreakMode:NSLineBreakByWordWrapping];
        
        /* Additional Label Configs */
        if (!titleLabel)
            titleLabel = (NIAttributedLabel *)[cell viewWithTag:5];
        [titleLabel setText:title];
        [titleLabel setFont:[UIFont boldSystemFontOfSize:kTitleFontSize]];
        [titleLabel setFrame:CGRectMake(kMargin, kMargin, titleSize.width, titleSize.height)];
        
        if (!authorLabel)
            authorLabel = (NIAttributedLabel *)[cell viewWithTag:6];
        [authorLabel setText:author];
        UIColor *authorColor = [UIColor colorWithRed:255.0f/255.0f green:123.0f/255.0f blue:41.0f/255.0f alpha:1];

        [authorLabel setTextColor:authorColor range:[authorLabel.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
        [authorLabel setFont:[UIFont systemFontOfSize:kMainAuthorFont]];
        [authorLabel setFrame:CGRectMake(kMargin, kMargin + titleSize.height, authorSize.width, authorSize.height)];
        
        if (!selftextLabel)
            selftextLabel = (NIAttributedLabel *)[cell viewWithTag:4];
        [selftextLabel setText:selftext];
        [selftextLabel setFrame:CGRectMake(kMargin, kMargin + authorSize.height + titleSize.height +2, selftextSize.width, selftextSize.height)];
        
        return cell;
    }

    NSInteger indexLessOne = indexPath.row - 1;
    
    /* Get Data */
    NSDictionary *dict = [holder objectAtIndex:indexLessOne];
    NSString *comment = [[dict objectForKey:@"comment"] description];
    comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    comment = [comment decodeHTMLEntities];
    
    NSInteger indentLevel = [[dict objectForKey:@"indent"] integerValue];
    NSString *author = [[dict objectForKey:@"author"] description];
    
    /* Size Calculations */
    CGFloat indentCellWidth = [self widthWithIndent:indentLevel width:cellWidth];
    
    CGSize authorContraint = CGSizeMake(indentCellWidth - (kMargin * 2), MAXFLOAT);
    CGSize authorSize = [author sizeWithFont:[UIFont systemFontOfSize:kAuthorFontSize]
                           constrainedToSize:authorContraint
                               lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize commentConstraint = CGSizeMake(indentCellWidth - (kMargin * 2), MAXFLOAT);
    CGSize commentSize = [comment sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                             constrainedToSize:commentConstraint
                                 lineBreakMode:NSLineBreakByWordWrapping];
    
    /* Additional Label Configs */
    if (!authorLabel)
        authorLabel = (NIAttributedLabel *)[cell viewWithTag:3];
    
    [authorLabel setText:author];
    [authorLabel setFrame:CGRectMake(kMargin + (kIndent * indentLevel), kMargin, authorSize.width, authorSize.height)];

    if ([author isEqualToString:[[Share sharedInstance] author]]) {
        UIColor *authorColor = [UIColor colorWithRed:254.0f/255.0f green:131.0f/255.0f blue:51.0f/255.0f alpha:1];

        [authorLabel setTextColor:authorColor range:[authorLabel.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
    } else {
        UIColor *authorColor = [UIColor colorWithRed:76.0f/255.0f green:112.0f/255.0f blue:163.0f/255.0f alpha:1];
        [authorLabel setTextColor:authorColor range:[authorLabel.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
    }
    
    if (!commentLabel)
        commentLabel = (NIAttributedLabel *)[cell viewWithTag:1];
    

    [commentLabel setText:comment];
    [commentLabel setFrame:CGRectMake(kMargin + (kIndent * indentLevel), kMargin + authorSize.height, commentSize.width, commentSize.height)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellWidth = self.view.bounds.size.width;
    
    if ([indexPath row] == 0) {
        
        /* Get Data */
        NSString *title = [[Share sharedInstance] title];
        NSString *selftext = [[Share sharedInstance] selftext];
        selftext = [selftext stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *author = [NSString stringWithFormat:@"%@", [[Share sharedInstance] author]];
        
        /* Height Calculations */
        CGSize cellConstraint = CGSizeMake(cellWidth - (kMargin * 2), MAXFLOAT);
        CGFloat titleHeight = [title sizeWithFont:[UIFont boldSystemFontOfSize:kTitleFontSize]
                                constrainedToSize:cellConstraint
                                    lineBreakMode:NSLineBreakByWordWrapping].height;

        CGFloat authorHeight = [author sizeWithFont:[UIFont systemFontOfSize:kMainAuthorFont]
                                  constrainedToSize:cellConstraint
                                      lineBreakMode:NSLineBreakByWordWrapping].height;
        
        CGFloat selftextHeight = [selftext sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                                      constrainedToSize:cellConstraint
                                          lineBreakMode:NSLineBreakByWordWrapping].height;
        
        return selftextHeight + authorHeight + titleHeight + (kMargin * 2) + 2;
    }
    
    NSInteger indexLessOne = indexPath.row - 1;

    /* Get Data */
    NSDictionary *dict = [holder objectAtIndex:indexLessOne];
    NSString *comment = [[dict objectForKey:@"comment"] description];
    comment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    comment = [comment decodeHTMLEntities];
    
    NSString *author = [[dict objectForKey:@"author"] description];
    NSInteger indentLevel = [[dict objectForKey:@"indent"] integerValue];
        
    /* Height Calculations */
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

#pragma mark - UITableView Helper Method

- (CGFloat)widthWithIndent:(NSInteger)indentLevel
                     width:(CGFloat)width
{
    return width - (indentLevel * kIndent);
}

#pragma mark - NIAttributedLabel Delegate Method

- (void)attributedLabel:(NIAttributedLabel *)attributedLabel
didSelectTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point
{
    WebViewController *webController = [[WebViewController alloc] init];
    [[Share sharedInstance] setLink:result.URL];
    
    [[self navigationController] pushViewController:webController animated:YES];
}

@end
