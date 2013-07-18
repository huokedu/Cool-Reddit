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
#import <Reachability.h>
#import "Indicator.h"
#import "GTMNSString+HTML.h"

#define kFontSize 14.0f
#define kSmallFontSize 11.0f
#define kLoadMoreFontSize 16.0f
#define kHorizontalSpacer 10.0f
#define kVerticalSpacer 3.0f
#define kMargin 10.0f

#define kTitleLabelTag 1
#define kCountLabelTag 2
#define kAuthorLabelTag 3
#define kTapLabelTag 4
#define kCommentIconTag 5
#define kLoadMoreLabelTag 6

@interface RedditViewController ()
{
    NSMutableArray *_posts;
    UIRefreshControl *_refreshControl;
    UITableViewController *_tvc;
}
@property (nonatomic, strong) Indicator *indicator;
@end

@implementation RedditViewController

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
    
    NSDate *createdDate = [NSDate dateWithTimeIntervalSince1970:1368902001];

    [self elapsedTime:createdDate];
    
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
    
    [myRedditsButton setBackgroundImage:[[UIImage imageNamed:@"nav_button_30"]
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)]
                               forState:UIControlStateNormal
                             barMetrics:UIBarMetricsDefault];
    
    [myRedditsButton setBackgroundImage:[[UIImage imageNamed:@"nav_button_24"]
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)]
                               forState:UIControlStateNormal
                             barMetrics:UIBarMetricsLandscapePhone];
    
    self.navigationItem.rightBarButtonItem = myRedditsButton;
    
    [[Share sharedInstance] setRedditName:allRedditsString];
    
    RedditWrapper *wrapper = [[RedditWrapper alloc] init];
    [wrapper redditJSONUsingName:allRedditsString];
    wrapper.delegate = self;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.indicator showWithMessage:@"Loading"];
    
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
    if (_posts.count == 0) {
        return 0;
    } else {
        // The extra row is for the "Load more" cell
        return _posts.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *LoadCellIdentifier = @"LoadMore";
    static NSString *NormalCellIdentifier = @"Normal";

    CGFloat cellWidth = self.view.bounds.size.width;
    
    UITableViewCell *cell = nil;
    UILabel *titleLabel = nil;
    UILabel *countLabel = nil;
    NIAttributedLabel *infoLabel = nil;
    UILabel *tapLabel = nil;
    UILabel *commentIcon = nil;
    UILabel *loadMoreLabel = nil;
    
    if (indexPath.row == _posts.count) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:LoadCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadCellIdentifier];
            
            loadMoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            loadMoreLabel.font = [UIFont systemFontOfSize:kLoadMoreFontSize];
            loadMoreLabel.textAlignment = NSTextAlignmentCenter;
            loadMoreLabel.tag = kLoadMoreLabelTag;
            [cell.contentView addSubview:loadMoreLabel];
        } else {
            loadMoreLabel = (UILabel *)[cell viewWithTag:kLoadMoreLabelTag];
        }
        
        NSString *loadMoreText = @"Load more";
        CGSize loadMoreSize = [loadMoreText sizeWithFont:[UIFont systemFontOfSize:kLoadMoreFontSize]];
        
        loadMoreLabel.text = loadMoreText;
        loadMoreLabel.frame = CGRectMake(cellWidth / 2 - loadMoreSize.width/2, 50/2 - loadMoreSize.height/2, loadMoreSize.width, loadMoreSize.height);
        
        return cell;
    } else {
        
        cell = [tableView dequeueReusableCellWithIdentifier:NormalCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NormalCellIdentifier];
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
            
            infoLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
            infoLabel.font = [UIFont systemFontOfSize:kSmallFontSize];
            infoLabel.numberOfLines = 0;
            infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
            infoLabel.tag = kAuthorLabelTag;
            [cell.contentView addSubview:infoLabel];
            
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
            
        } else {
            commentIcon = (UILabel *)[cell viewWithTag:kCommentIconTag];
            titleLabel = (UILabel *)[cell viewWithTag:kTitleLabelTag];
            tapLabel = (UILabel *)[cell viewWithTag:kTapLabelTag];
            countLabel = (UILabel *)[cell viewWithTag:kCountLabelTag];
            infoLabel = (NIAttributedLabel *)[cell viewWithTag:kAuthorLabelTag];
        }
        
        // Get Data
        NSDictionary *dict = [[_posts objectAtIndex:[indexPath row]] objectForKey:@"data"];
        NSString *count = [[dict objectForKey:@"num_comments"] description];
        NSString *ups = [[dict objectForKey:@"ups"] description];
        NSString *domain = [[dict objectForKey:@"domain"] description];
        NSInteger createdUTC = [[dict objectForKey:@"created_utc"] integerValue];
        NSString *time = [self elapsedTime:[NSDate dateWithTimeIntervalSince1970:createdUTC]];
        
        NSString *temp = [NSString stringWithFormat:@"%@ %@ %@", ups, domain, time];
        
        NSString *title = [[dict objectForKey:@"title"] gtm_stringByUnescapingFromHTML];
        
        // Size Calculations
        CGSize authorSize = [temp sizeWithFont:[UIFont systemFontOfSize:kSmallFontSize]];
        CGSize countSize = [count sizeWithFont:[UIFont systemFontOfSize:kFontSize]];
        CGSize commentIconSize = [@"\uf0e5" sizeWithFont:[UIFont fontWithName:@"FontAwesome" size:12]];    
        CGFloat titleWidth = cellWidth - (kMargin * 2) - kHorizontalSpacer - countSize.width;
        CGSize titleConstraint = CGSizeMake(titleWidth, MAXFLOAT);
        
        CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                             constrainedToSize:titleConstraint
                                 lineBreakMode:NSLineBreakByWordWrapping];

        // Label Configs        
        [commentIcon setText:@"\uf0e5"];
        [commentIcon setFrame:CGRectMake(cellWidth - 10 - commentIconSize.width, kMargin, commentIconSize.width, commentIconSize.height)];
                
        title = [title gtm_stringByUnescapingFromHTML];
        [titleLabel setText:title];
        [titleLabel setFrame:CGRectMake(kMargin, kMargin, titleWidth, titleSize.height)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleLabel:)];
        [titleLabel addGestureRecognizer:tapGesture];
        
        [tapLabel setFrame:CGRectMake(kMargin, 0, titleWidth, 10)];
        UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleLabel:)];
        [tapLabel addGestureRecognizer:tapGesture2];
        
        [countLabel setText:count];
        [countLabel setFrame:CGRectMake(kMargin + titleWidth + kHorizontalSpacer, kMargin + commentIconSize.height, countSize.width, countSize.height)];
                
        [infoLabel setText:[NSString stringWithFormat:@"%@ %@ %@", ups, domain, time]];
        UIColor *upsColor = [UIColor colorWithRed:77.0f/255.0f green:139.0f/255.0f blue:77.0f/255.0f alpha:1];
        
        [infoLabel setTextColor:upsColor range:[infoLabel.text rangeOfString:[NSString stringWithFormat:@"%@", ups]]];
        
        [infoLabel setFrame:CGRectMake(kMargin, kMargin + titleSize.height + kVerticalSpacer, authorSize.width, authorSize.height)];
    }
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _posts.count) {
        NSString *postName = [[[_posts lastObject] objectForKey:@"data"] objectForKey:@"name"];
        RedditWrapper *model = [[RedditWrapper alloc] init];
        [model redditJSON:[[Share sharedInstance] redditName] withPostName:postName withLimit:25];
        [model setDelegate:self];
    } else {
        NSDictionary *dict = [_posts objectAtIndex:indexPath.row];
        dict = [dict objectForKey:@"data"];
        
        // Set Share Singleton properties to be used in the CommentViewController
        [[Share sharedInstance] setSelfText:[[dict objectForKey:@"selftext"] gtm_stringByUnescapingFromHTML]];
        [[Share sharedInstance] setPermalink:[dict objectForKey:@"permalink"]];
        [[Share sharedInstance] setTitle:[[dict objectForKey:@"title"] gtm_stringByUnescapingFromHTML]];
        [[Share sharedInstance] setAuthor:[dict objectForKey:@"author"]];
        [[Share sharedInstance] setTime:[dict objectForKey:@"created_utc"]];
        
        CommentViewController *postController = [[CommentViewController alloc] init];
        [self.navigationController pushViewController:postController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellWidth = self.view.bounds.size.width;
    
    if (indexPath.row == _posts.count) {
        // Height for the "Load more" cell
        return 50;
    } else {
        // Get Data
        NSDictionary *dict = [[_posts objectAtIndex:[indexPath row]] objectForKey:@"data"];
        NSString *title = [[dict objectForKey:@"title"] description];
        title = [title gtm_stringByUnescapingFromHTML];
        
        NSString *count = [[dict objectForKey:@"num_comments"] description];
        NSString *ups = [[dict objectForKey:@"ups"] description];
        NSString *domain = [[dict objectForKey:@"domain"] description];
        NSInteger createdUTC = [[dict objectForKey:@"created_utc"] integerValue];
        NSString *elapsedTime = [self elapsedTime:[NSDate dateWithTimeIntervalSince1970:createdUTC]];
        
        NSString *temp = [NSString stringWithFormat:@"%@ %@ %@", ups, domain, elapsedTime];
        
        // Height Calculations
        CGSize infoSize = [temp sizeWithFont:[UIFont systemFontOfSize:kSmallFontSize]];
        
        // Gets the width of count string
        CGSize countSize = [count sizeWithFont:[UIFont systemFontOfSize:kFontSize]];
        
        CGFloat titleWidth = cellWidth - countSize.width - (kMargin * 2) - kHorizontalSpacer;
        CGSize titleConstraint = CGSizeMake(titleWidth, MAXFLOAT);
        
        CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:kFontSize]
                             constrainedToSize:titleConstraint
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        return titleSize.height + infoSize.height + (kMargin * 2) + kVerticalSpacer;
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
    
    [_tvc.refreshControl endRefreshing];
    
    if (JSON) {
        if (_posts.count > 0) {
//            NSLog(@"Load more tapped");
            [_posts addObjectsFromArray:[[JSON objectForKey:@"data"] objectForKey:@"children"]];
        }
        if (_posts.count == 0) {
            _posts = [[JSON objectForKey:@"data"] objectForKey:@"children"];
        }
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
    _posts = nil;
        
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
    NSDictionary *post = [[_posts objectAtIndex:row] objectForKey:@"data"];
    
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
    NSMutableArray *reddits = [NSMutableArray arrayWithObjects:@"Front Page", @"AdviceAnimals", @"announcements", @"AskReddit", @"atheism", @"aww", @"bestof", @"blog", @"funny", @"gaming", @"IAmA", @"movies", @"Music", @"pics", @"politics", @"science", @"technology", @"todayilearned", @"videos", @"worldnews", nil];
    
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

#pragma mark -
- (void)refreshTableView
{    
    _posts = nil;

    [_tvc.refreshControl beginRefreshing];
    RedditWrapper *wrapper = [[RedditWrapper alloc] init];
    [wrapper redditJSONUsingName:[[Share sharedInstance] redditName]];
    wrapper.delegate = self;
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

@end
