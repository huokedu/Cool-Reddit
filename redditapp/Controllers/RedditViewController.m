//
//  RedditViewController.m
//  redditapp
//
//  Created by tang on 3/13/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

// TODO
// - Add the ability to share posts via email and text message

#import "RedditViewController.h"
#import "RedditWrapper.h"
#import "Share.h"
#import "CommentViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MyRedditsViewController.h"
#import "WebViewController.h"
#import <NimbusAttributedLabel.h>
#import "NSString+HTML.h"
#import <Reachability.h>
#import "Indicator.h"

#define kFontSize 13.0f
#define kSmallFontSize 11.0f
#define kLoadMoreFontSize 14.0f
#define kHorizontalSpacer 10.0f
#define kVerticalSpacer 3.0f
#define kMargin 10.0f

#define kTitleLabelTag 1
#define kCountLabelTag 2
#define kAuthorLabelTag 3
#define kTapLabelTag 4
#define kCommentIconTag 5
#define kLoadLabelTag 6


@interface RedditViewController ()
{
    NSMutableArray *posts;
}
@property (nonatomic, strong) Indicator *indicator;
@end

@implementation RedditViewController
@synthesize tableView = _tableView;
@synthesize managedObjectContext = _managedObjectContext;
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
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    // UISwipeGesture setup
    UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft:)];
    gestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSString *allRedditsString = [self makeAllRedditsString];
    if ([allRedditsString isEqualToString:@""]) {
        [self setDefaultReddits];
        allRedditsString = [self makeAllRedditsString];
    }
    
    UIBarButtonItem *myRedditsButton = [[UIBarButtonItem alloc] initWithTitle:@"Reddits" style:UIBarButtonItemStylePlain target:self action:@selector(showMyReddits)];
    
    self.navigationItem.rightBarButtonItem = myRedditsButton;
    
    [[Share sharedInstance] setRedditName:allRedditsString];
    
    RedditWrapper *wrapper = [[RedditWrapper alloc] init];
    [wrapper redditJSONUsingName:allRedditsString];
    wrapper.delegate = self;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.indicator showWithMessage:@"Loading"];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self testInternetConnection];

    NSString *navTitle = [[Share sharedInstance] redditName];
    if ([navTitle rangeOfString:@"+"].location != NSNotFound) {
        navTitle = @"Front Page";
    }
    self.navigationItem.title = navTitle;
       
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.indicator hide];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableViewDelegate Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    if (posts.count == 0) {
        return 0;
    } else {
        // The extra row is for the "Load more" cell
        return posts.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    static NSString *CustomCellIdentifier = @"CustomCell";
    
    CGFloat cellWidth = self.view.bounds.size.width;
    
    UITableViewCell *cell = nil;
    UILabel *titleLabel = nil;
    UILabel *countLabel = nil;
    NIAttributedLabel *authorLabel = nil;
    UILabel *tapLabel = nil;
    UILabel *commentIcon = nil;
    NIAttributedLabel *loadLabel = nil;
    
    // TODO
    // Fix this ugly code
    if (indexPath.row == posts.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
            
            loadLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            loadLabel.font = [UIFont fontWithName:@"FontAwesome" size:kLoadMoreFontSize];
            loadLabel.textAlignment = NSTextAlignmentCenter;
            loadLabel.tag = kLoadLabelTag;
            [cell.contentView addSubview:loadLabel];
        }
        
        if (!loadLabel)
            loadLabel = (NIAttributedLabel *)[cell viewWithTag:kLoadLabelTag];
        
        loadLabel.frame = CGRectMake(0, 10, cellWidth, 50);
        loadLabel.text = @"Load more \uf08a";
        [loadLabel setFont:[UIFont fontWithName:@"FontAwesome" size:kLoadMoreFontSize] range:[loadLabel.text rangeOfString:@"\uf08a"]];
        
        return cell;
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:CustomCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CustomCellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.font = [UIFont systemFontOfSize:kFontSize];
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.tag = kTitleLabelTag;
        titleLabel.userInteractionEnabled = YES;
        [cell.contentView addSubview:titleLabel];
        
        countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        countLabel.font = [UIFont systemFontOfSize:kFontSize];
        countLabel.numberOfLines = 0;
        countLabel.lineBreakMode = NSLineBreakByWordWrapping;
        countLabel.tag = kCountLabelTag;
        [cell.contentView addSubview:countLabel];
        
        authorLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
        authorLabel.font = [UIFont systemFontOfSize:kSmallFontSize];
        authorLabel.numberOfLines = 0;
        authorLabel.lineBreakMode = NSLineBreakByWordWrapping;
        authorLabel.tag = kAuthorLabelTag;
        [cell.contentView addSubview:authorLabel];
        
        tapLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        tapLabel.font = [UIFont systemFontOfSize:kFontSize];
        tapLabel.numberOfLines = 0;
        tapLabel.lineBreakMode = NSLineBreakByWordWrapping;
        tapLabel.tag = kTapLabelTag;
        tapLabel.userInteractionEnabled = YES;
        [cell.contentView addSubview:tapLabel];
        
        UILabel *commentIcon = [[UILabel alloc] initWithFrame:CGRectZero];
        commentIcon.font = [UIFont fontWithName:@"FontAwesome" size:12];
        commentIcon.numberOfLines = 0;
        commentIcon.lineBreakMode = NSLineBreakByWordWrapping;
        commentIcon.tag = kCommentIconTag;
        [cell.contentView addSubview:commentIcon];
        
    }
    
    /* Gets Data */
    NSDictionary *dict = [[posts objectAtIndex:[indexPath row]] objectForKey:@"data"];
    NSString *count = [[dict objectForKey:@"num_comments"] description];
    NSString *author = [[dict objectForKey:@"author"] description];
    NSString *ups = [[dict objectForKey:@"ups"] description];
    NSString *domain = [[dict objectForKey:@"domain"] description];
    NSString *temp = [NSString stringWithFormat:@"%@ %@ %@", author, ups, domain];
    
    // Replaces the HTML representation of ampersand with the symbol
    NSString *title = [[dict objectForKey:@"title"] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    
    /* Size Calculations */
    CGSize authorSize = [temp sizeWithFont:[UIFont systemFontOfSize:kSmallFontSize]];
    CGSize countSize = [count sizeWithFont:[UIFont systemFontOfSize:kFontSize]];
    CGSize commentIconSize = [@"\uf0e5" sizeWithFont:[UIFont fontWithName:@"FontAwesome" size:12]];    
    CGFloat titleWidth = cellWidth - (kMargin * 2) - kHorizontalSpacer - countSize.width;
    CGSize titleConstraint = CGSizeMake(titleWidth, MAXFLOAT);
    
    CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                         constrainedToSize:titleConstraint
                             lineBreakMode:NSLineBreakByWordWrapping];

    /* Label Configs */
    if (!commentIcon)
        commentIcon = (UILabel *)[cell viewWithTag:kCommentIconTag];
    
    [commentIcon setText:@"\uf0e5"];
    [commentIcon setFrame:CGRectMake(cellWidth - 10 - commentIconSize.width, kMargin, commentIconSize.width, commentIconSize.height)];
    
    if (!titleLabel)
        titleLabel = (UILabel *)[cell viewWithTag:kTitleLabelTag];
    
    title = [title decodeHTMLEntities];
    [titleLabel setText:title];
    [titleLabel setFrame:CGRectMake(kMargin, kMargin, titleWidth, titleSize.height)];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleLabel:)];
    [titleLabel addGestureRecognizer:tapGesture];
    
    if (!tapLabel)
        tapLabel = (UILabel *)[cell viewWithTag:kTapLabelTag];
    [tapLabel setFrame:CGRectMake(kMargin, 0, titleWidth, 10)];
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleLabel:)];
    [tapLabel addGestureRecognizer:tapGesture2];
    
    if (!countLabel)
        countLabel = (UILabel *)[cell viewWithTag:kCountLabelTag];

    [countLabel setText:count];
    [countLabel setFrame:CGRectMake(kMargin + titleWidth + kHorizontalSpacer, kMargin + commentIconSize.height, countSize.width, countSize.height)];
    
    if (!authorLabel)
        authorLabel = (NIAttributedLabel *)[cell viewWithTag:kAuthorLabelTag];
    
    [authorLabel setText:[NSString stringWithFormat:@"%@ %@ %@", author, ups, domain]];
    UIColor *upsColor = [UIColor colorWithRed:77.0f/255.0f green:139.0f/255.0f blue:77.0f/255.0f alpha:1];
//    UIColor *redColorILiked = [UIColor colorWithRed:191.0f/255.0f green:75.0f/255.0f blue:49.0f/255.0f alpha:1];
    UIColor *authorColor = [UIColor colorWithRed:76.0f/255.0f green:112.0f/255.0f blue:163.0f/255.0f alpha:1];

    [authorLabel setTextColor:upsColor range:[authorLabel.text rangeOfString:[NSString stringWithFormat:@"%@", ups]]];
    [authorLabel setTextColor:authorColor range:[authorLabel.text rangeOfString:[NSString stringWithFormat:@"%@", author]]];
    [authorLabel setFrame:CGRectMake(kMargin, kMargin + titleSize.height + kVerticalSpacer, authorSize.width, authorSize.height)];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == posts.count) {
        NSString *postName = [[[posts lastObject] objectForKey:@"data"] objectForKey:@"name"];
        RedditWrapper *model = [[RedditWrapper alloc] init];
        [model redditJSON:[[Share sharedInstance] redditName] withPostName:postName withLimit:25];
        [model setDelegate:self];
    } else {
        NSDictionary *dict = [posts objectAtIndex:indexPath.row];
        dict = [dict objectForKey:@"data"];
        
        // Set Share Singleton properties to be used in the CommentViewController
        [[Share sharedInstance] setSelftext:[[dict objectForKey:@"selftext"] decodeHTMLEntities]];
        [[Share sharedInstance] setPermalink:[dict objectForKey:@"permalink"]];
        [[Share sharedInstance] setTitle:[dict objectForKey:@"title"]];
        [[Share sharedInstance] setAuthor:[dict objectForKey:@"author"]];
        
        CommentViewController *postController = [[CommentViewController alloc] init];
        [self.navigationController pushViewController:postController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellWidth = self.view.bounds.size.width;
    
    if (indexPath.row == posts.count) {
        // Height for the "Load more" cell
        return 50;
    } else {
        /* Gets Data */
        NSDictionary *dict = [[posts objectAtIndex:[indexPath row]] objectForKey:@"data"];
        NSString *title = [[dict objectForKey:@"title"] description];
        title = [title decodeHTMLEntities];
        
        NSString *count = [[dict objectForKey:@"num_comments"] description];
        NSString *author = [[dict objectForKey:@"author"] description];
        NSString *ups = [[dict objectForKey:@"ups"] description];
        NSString *domain = [[dict objectForKey:@"domain"] description];
        NSString *temp = [NSString stringWithFormat:@"%@ %@ %@", author, ups, domain];
        
        /* Height Calculations */
        CGSize authorSize = [temp sizeWithFont:[UIFont systemFontOfSize:kSmallFontSize]];
        
        // Gets the width of count string
        CGSize countSize = [count sizeWithFont:[UIFont systemFontOfSize:kFontSize]];
        
        CGFloat titleWidth = cellWidth - countSize.width - (kMargin * 2) - kHorizontalSpacer;
        CGSize titleConstraint = CGSizeMake(titleWidth, MAXFLOAT);
        
        CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                             constrainedToSize:titleConstraint
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        return titleSize.height + authorSize.height + (kMargin * 2) + kVerticalSpacer;
    }
}

#pragma mark -

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}


#pragma mark - JSON Methods
- (void)returnedJSON:(id)JSON
{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.indicator hide];
    
    if (posts.count > 0) {
//        NSLog(@"Load more tapped");
        [posts addObjectsFromArray:[[JSON objectForKey:@"data"] objectForKey:@"children"]];
    }
    if (posts.count == 0) {
        posts = [[JSON objectForKey:@"data"] objectForKey:@"children"];
    }
            
    [self.tableView reloadData];
}

#pragma mark -

- (void)showMyReddits
{
    MyRedditsViewController *myRedditsController = [[MyRedditsViewController alloc] init];
    myRedditsController.managedObjectContext = self.managedObjectContext;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:myRedditsController];
    myRedditsController.delegate = self;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)selectedReddit:(NSString *)name
{    
    // Clear out the posts array
    posts = nil;
        
    RedditWrapper *model = [[RedditWrapper alloc] init];
    [model redditJSONUsingName:name];
    [model setDelegate:self];
    
    // Show Indicator
    [self.indicator showWithMessage:@"Loading"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[Share sharedInstance] setRedditName:name];
    
    [self.tableView reloadData];
}

- (void)didTapTitleLabel:(id)sender
{
    UITapGestureRecognizer *tapGesture = (UITapGestureRecognizer *)sender;
    if ((tapGesture.view.tag == kTitleLabelTag) | (tapGesture.view.tag == kTapLabelTag)) {
        
        CGPoint touchLocation = [tapGesture locationOfTouch:0 inView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchLocation];
        
        [self showLinkWithRow:indexPath.row];
    }
}

- (void)showLinkWithRow:(NSInteger)row
{
    NSDictionary *post = [[posts objectAtIndex:row] objectForKey:@"data"];
    
    NSString *url = [post objectForKey:@"url"];
    
    WebViewController *webController = [[WebViewController alloc] init];
    [[Share sharedInstance] setLink:[NSURL URLWithString:url]];
    
    [self.navigationController pushViewController:webController animated:YES];
}

- (NSString *)makeAllRedditsString
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reddits" inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                error:&error];
    
    NSMutableArray *namesArray = [NSMutableArray array];
    for (NSManagedObject *item in results) {
        if ([[item valueForKey:@"name"] compare:@"Front Page"
                                        options:NSCaseInsensitiveSearch] != NSOrderedSame) {
            [namesArray addObject:[item valueForKey:@"name"]];
        }
    }
    
    NSString *concat = [namesArray componentsJoinedByString:@"+"];

    return concat;
}

- (void)setDefaultReddits
{
    int orderingValue = 1;
    NSMutableArray *reddits = [NSMutableArray arrayWithObjects:@"Front Page", @"AdviceAnimals", @"announcements", @"AskReddit", @"atheism", @"aww", @"bestof", @"blog", @"funny", @"gaming", @"IAmA", @"movies", @"Music", @"pics", @"politics", @"science", @"technology", @"todayilearned", @"videos", @"worldnews", @"WTF", nil];
    
    for (NSString *name in reddits) {
        NSManagedObject *redditsItem = [NSEntityDescription insertNewObjectForEntityForName:@"Reddits"
                                                                     inManagedObjectContext:self.managedObjectContext];
        
        [redditsItem setValue:name forKey:@"name"];
        [redditsItem setValue:[NSNumber numberWithInt:orderingValue] forKey:@"orderingValue"];
        
        NSError *error = nil;
        [self.managedObjectContext save:&error];
        
        orderingValue += 1;
    }
}

#pragma mark - Test Connection Method

// TODO
// Create a singleton or move this method to its own class
- (void)testInternetConnection
{
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

- (void)didSwipeLeft:(UIGestureRecognizer *)gestureRecognizer
{
//    NSLog(@"Swiped left");
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint swipeLocation = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *swipeIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
        
        [self tableView:self.tableView didSelectRowAtIndexPath:swipeIndexPath];
    }
}

@end
