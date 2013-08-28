//
//  MyRedditsViewController.m
//  redditapp
//
//  Created by tang on 3/25/13.
//  Copyright (c) 2013 foobar. All rights reserved.
//

#import "MyRedditsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Reddits.h"
#import "TBMessage.h"

#define kFontSize 17.0f
#define kDeleteFontSize 15.0f
#define kMargin 15.0f
#define kTextFieldFont 18.0f

#define kNameLabelTag 1
#define kDeleteLabelTag 2

@interface MyRedditsViewController ()
@property (nonatomic, strong) NSMutableArray *redditsArray;
@property (nonatomic, copy) NSArray *fetchedObjects;
@property (nonatomic, strong) NSMutableArray *badWords;
@end

@implementation MyRedditsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.badWords = [NSMutableArray arrayWithObjects:@"nsfw", @"ass", @"milf", @"bdsm", @"sex", @"porn", @"boobies", @"curvy", @"amateur", @"cumsluts", @"ginger", @"penis", @"blowjobs", @"gore", @"lesbians", @"bikinis", @"asshole", @"fuck", @"dick", @"incest", @"cleavage", @"hentai", @"boobs", @"tits", @"bitches", @"bitch", @"sexy", @"butt", nil];
        
        self.redditsArray = [NSMutableArray array];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self fetchRedditsFromDb];
    [self setupView];
}

// Move this into loadView
- (void)setupView
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav"] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationItem.title = @"Reddits";
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    
    [closeButton setBackgroundImage:[[UIImage imageNamed:@"nav_button_30"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)]
                           forState:UIControlStateNormal
                         barMetrics:UIBarMetricsDefault];
    
    [closeButton setBackgroundImage:[[UIImage imageNamed:@"nav_button_24"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)]
                           forState:UIControlStateNormal
                         barMetrics:UIBarMetricsLandscapePhone];

    self.navigationItem.rightBarButtonItem = closeButton;
    
    // Calculates the height needed for the UITextField with a dummy string
    CGFloat textHeight = [@"foo" sizeWithFont:[UIFont systemFontOfSize:kTextFieldFont]].height;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, textHeight + 30, self.view.frame.size.width, self.view.frame.size.height - textHeight - 30) style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(1.0, 0.0, 0.0, 0.0);
    
    UIView *addView = [[UIView alloc] initWithFrame:CGRectMake(-1, -1, self.view.frame.size.width + 2, textHeight + 30 + 1)];
    addView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    addView.backgroundColor = [UIColor colorWithRed:229.0f/255.0f green:229.0f/255.0f blue:229.0f/255.0f alpha:1];
    addView.layer.borderWidth = 1.0f;
    addView.layer.borderColor = [UIColor colorWithRed:166.0f/255.0f green:159.0f/255.0f blue:162.0f/255.0f alpha:1].CGColor;
    
    // Creating UITextField
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(5, 5, self.view.frame.size.width - 10 + 2, textHeight + 20 + 1)];
    textField.placeholder = @"Add a reddit";
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.delegate = self;
    textField.font = [UIFont systemFontOfSize:kTextFieldFont];
    textField.textAlignment = NSTextAlignmentCenter;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.backgroundColor = [UIColor whiteColor];
    textField.layer.borderColor = [UIColor colorWithRed:166.0f/255.0f green:159.0f/255.0f blue:162.0f/255.0f alpha:1].CGColor;
    textField.layer.borderWidth = 1.0f;
    textField.layer.cornerRadius = 4.0f;
    [addView addSubview:textField];
    [self.view addSubview:addView];
    
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didTapDeleteLabel:(id)sender
{
    UITapGestureRecognizer *tapGesture = (UITapGestureRecognizer *)sender;
    if (tapGesture.view.tag == 2) {
        CGPoint touchLocation = [tapGesture locationOfTouch:0 inView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchLocation];
        
        // Remove the item from the db first before removing it from the array
        [self removeItemFromDb:[self.redditsArray objectAtIndex:indexPath.row]];

        [self.redditsArray removeObjectAtIndex:indexPath.row];
        
        [self.tableView reloadData];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

#pragma mark - CoreData - Get/Save/Delete Methods

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
        
        if (error != nil) {
            NSLog(@"setDefaultReddits Error %@", [error localizedDescription]);
        }

        orderingValue += 1;
    }
}

- (void)updateOrderAndSave:(NSString *)newReddit
{
    // Updates the ordering number on each NSManagedObject
    for (NSManagedObject *item in self.fetchedObjects) {
        NSNumber *currentOrdering = [item valueForKey:@"orderingValue"];
        int newOrdering = [currentOrdering intValue] + 1;
        [item setValue:[NSNumber numberWithInt:newOrdering] forKey:@"orderingValue"];
        NSError *error = nil;
        [self.managedObjectContext save:&error];
    }
    
    NSManagedObject *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Reddits"
                                                              inManagedObjectContext:self.managedObjectContext];
    [newItem setValue:newReddit forKey:@"name"];
    [newItem setValue:[NSNumber numberWithBool:1] forKey:@"orderingValue"];
    
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    
    if (error != nil) {
        NSLog(@"updateOrderAndSave Save Error %@", [error localizedDescription]);
    }
}

- (void)removeItemFromDb:(NSString *)name
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Reddits"
                                                         inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = entityDescription;
    request.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"name == '%@'", name]];
    
    NSError *error = nil;
    NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"removeItemFromDb Fetch Error %@", [error localizedDescription]);
    }
    
    for (NSManagedObject *item in fetchedItems) {
        [self.managedObjectContext deleteObject:item];
    }
    
    [self.managedObjectContext save:&error];

    if (error) {
        NSLog(@"removeItemFromDb Save Error %@", [error localizedDescription]);
    }
    
}

- (void)fetchRedditsFromDb
{
    [self.redditsArray removeAllObjects];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"orderingValue"
                                                         ascending:YES];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reddits"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    NSError *error = nil;
    self.fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error != nil) {
        NSLog(@"fetchRedditsFromDb 1 Error %@", [error localizedDescription]);
    }
    
    if (self.fetchedObjects.count == 0) {
        [self setDefaultReddits];
        self.fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error != nil) {
            NSLog(@"fetchRedditsFromDb 2 Error %@", [error localizedDescription]);
        }
        
    }
    
    for (NSManagedObject *info in self.fetchedObjects) {
        [self.redditsArray addObject:[info valueForKey:@"name"]];
    }
}

#pragma mark -

- (NSString *)makeAllRedditsString
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reddits"
                                              inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                error:&error];
    
    if (error != nil) {
        NSLog(@"makeAllRedditsString Error %@", [error localizedDescription]);
    }
    
    NSMutableArray *namesArray = [NSMutableArray array];
    for (NSManagedObject *item in results) {
        if ([[item valueForKey:@"name"] compare:@"Front Page"
                                        options:NSCaseInsensitiveSearch] != NSOrderedSame) {
            [namesArray addObject:[item valueForKey:@"name"]];
        }
    }
    
    return [namesArray componentsJoinedByString:@"+"];
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSString *string = textField.text;
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSCharacterSet *alphabet = [NSCharacterSet letterCharacterSet];
    BOOL isValid = [[trimmedString stringByTrimmingCharactersInSet:alphabet] isEqualToString:@""];
    
    // Screen out some bad words
    // Remove [c] for case sensitivity
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF LIKE[c] %@", trimmedString];
    NSArray *badWordsResults = [self.badWords filteredArrayUsingPredicate:predicate];
    
    if (badWordsResults.count > 0) {
        // Censored word, clear UITextfield and return YES
        [[TBMessage sharedInstance] showMessage:@"You can't add this Reddit." withMessageType:MessageTypeError inViewController:self];

        return YES;
    }
    
    if (((trimmedString.length > 0) && isValid) || ([trimmedString compare:@"Front Page"
                                                                     options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
        [self fetchRedditsFromDb];
        
        // Check for duplicate
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF LIKE[c] %@", trimmedString];
        NSArray *duplicateResults = [self.redditsArray filteredArrayUsingPredicate:predicate];
        
        if (duplicateResults.count > 0) {
            [[TBMessage sharedInstance] showMessage:[NSString stringWithFormat:@"%@ already exists.", trimmedString] withMessageType:MessageTypeError inViewController:self];

            return YES;
        }
        
        
        [self updateOrderAndSave:trimmedString];
        
        [self.redditsArray insertObject:trimmedString atIndex:0];
        [self.tableView reloadData];
    }
    
    textField.text = @"";
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - UITableViewDelegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.redditsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    UILabel *nameLabel = nil;
    UILabel *deleteLabel = nil;
    
    static NSString *CellIdentifier = @"Cell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellAccessoryNone;
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        nameLabel.font = [UIFont systemFontOfSize:kFontSize];
        nameLabel.tag = kNameLabelTag;
        [cell.contentView addSubview:nameLabel];
        
        deleteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        deleteLabel.font = [UIFont fontWithName:@"FontAwesome" size:kDeleteFontSize];
        deleteLabel.textAlignment = NSTextAlignmentCenter;
        deleteLabel.tag = kDeleteLabelTag;
        deleteLabel.userInteractionEnabled = YES;
        [cell.contentView addSubview:deleteLabel];
    }
    
    if (!nameLabel)
        nameLabel = (UILabel *)[cell.contentView viewWithTag:kNameLabelTag];
    
    // Custom setup
    nameLabel.text = [self.redditsArray objectAtIndex:indexPath.row];
    
    CGFloat nameWidth = [nameLabel.text sizeWithFont:[UIFont systemFontOfSize:kFontSize]].width;
    CGFloat nameHeight = [nameLabel.text sizeWithFont:[UIFont systemFontOfSize:kFontSize]].height;
    
    nameLabel.frame = CGRectMake(kMargin, kMargin, nameWidth, nameHeight);
    
    if (!deleteLabel)
        deleteLabel = (UILabel *)[cell.contentView viewWithTag:kDeleteLabelTag];
    
    CGSize deleteSize = [@"\uf068" sizeWithFont:[UIFont fontWithName:@"FontAwesome" size:kDeleteFontSize]];
    
    deleteLabel.frame = CGRectMake(self.view.bounds.size.width - deleteSize.width - 40, 0, deleteSize.width + 40, nameHeight + (kMargin * 2));
    deleteLabel.text = @"\uf068";
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapDeleteLabel:)];
    [deleteLabel addGestureRecognizer:tapGesture];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = [self.redditsArray objectAtIndex:indexPath.row];
    CGFloat height = [name sizeWithFont:[UIFont systemFontOfSize:kFontSize]].height;
    
    return height + (kMargin * 2);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = [self.redditsArray objectAtIndex:indexPath.row];
    
    if ([name compare:@"Front Page"
              options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        name = [self makeAllRedditsString];
        
        [self.delegate selectedReddit:name];
    } else {
        
        [self.delegate selectedReddit:name];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
