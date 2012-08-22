//
//  MyMusicViewController.m
//  VKMusic
//
//  Created by Demidov Alexander on 11.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyMusicViewController.h"
#import "DownloadedViewController.h"
#import "AppDelegate.h"
#import "ASIHTTPRequest.h"

#define SavedMusicFile @"SavedMusic.plist"

@interface MyMusicViewController ()

- (void)loadMusicList;
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;
- (void)failedLoadingTableViewData;
- (void)toggleTableView;
- (void)downloadSongFromURL:(NSURL *)songURL withArtist:(NSString *)artistName title:(NSString *)title fileName:(NSString *)fileName andRow:(NSInteger)row;

@end

@implementation MyMusicViewController

@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize activityIndicator = _activityIndicator;
@synthesize progressBar = _progressBar;
@synthesize musicForTable = _musicForTable;
@synthesize downloadedMusicViewController = _downloadedMusicViewController;
@synthesize exitButton = _exitButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isAuth = NO;
        isReloading = NO;
        self.title = @"Моя музыка";
        self.tabBarItem.image = [UIImage imageNamed:@"MyMusic"];
        self.musicForTable = [NSMutableArray new];
        parsingElement = nomusic;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (refreshHeaderView == nil) {
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		[view setDelegate:self];
		[self.tableView addSubview:view];
		refreshHeaderView = view;
	}
    
    [self.activityIndicatorView.layer setCornerRadius:6.0];
    [self.activityIndicatorView setCenter:self.tableView.center];
    [self.tableView addSubview:self.activityIndicatorView];
    
    UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Выход", nil]];
    button.momentary = YES;
    button.segmentedControlStyle = UISegmentedControlStyleBar;
    button.tintColor = [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
    [button addTarget:self action:@selector(logout) forControlEvents:UIControlEventValueChanged];
    
    self.exitButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessToken"]) [self.navigationItem setLeftBarButtonItem:self.exitButton animated:NO];
    else [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    
	[refreshHeaderView refreshLastUpdatedDate];
}

- (void)viewDidUnload
{
    refreshHeaderView = nil;
	curArtist = curTitle = curURL = nil;
	downloadingcontroller = nil;
    
    [self setDownloadedMusicViewController:nil];
    [self setMusicForTable:nil];
    [self setActivityIndicatorView:nil];
    [self setActivityIndicator:nil];
    [self setProgressBar:nil];
    [self setExitButton:nil];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (appDelegate.playerViewController != nil) {
        UIBarButtonItem *playerButton = [[UIBarButtonItem alloc] initWithTitle:@"Плеер"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:appDelegate
                                                                        action:@selector(showPlayer)];
        self.navigationItem.rightBarButtonItem = playerButton;
    }
	
	
	[super viewWillAppear:animated];
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource
{
	isReloading = YES;
    [self loadMusicList];
}

- (void)doneLoadingTableViewData
{
	isReloading = NO;
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
}

- (void)failedLoadingTableViewData
{
    isReloading = NO;
    [refreshHeaderView egoRefreshScrollViewDataSourceDidFailedLoading:self.tableView];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.activityIndicatorView setCenter:CGPointMake(self.tableView.center.x, self.tableView.center.y + self.tableView.bounds.origin.y)];
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	[self reloadTableViewDataSource];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return isReloading;
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [NSDate date];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.musicForTable count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SimpleTableIdentifier];
    }
    NSUInteger row = [indexPath row];
    cell.textLabel.text = [[self.musicForTable objectAtIndex:row] objectForKey:@"title"];
    cell.detailTextLabel.text = [[self.musicForTable objectAtIndex:row] objectForKey:@"artist"];
    return cell;
}

#pragma mark -
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isAuth) {
        NSUInteger row = [indexPath row];
        [self downloadSongFromURL:[NSURL URLWithString:[[self.musicForTable objectAtIndex:row] objectForKey:@"url"]]
                       withArtist:[[self.musicForTable objectAtIndex:row] objectForKey:@"artist"]
                            title:[[self.musicForTable objectAtIndex:row] objectForKey:@"title"]
                         fileName:[[[self.musicForTable objectAtIndex:row] objectForKey:@"url"] lastPathComponent]
                           andRow:row];
    }
    else {
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Parser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"artist"]) {
        parsingElement = artist;
        curArtist = [NSMutableString new];
    }
    else if ([elementName isEqualToString:@"title"]) {
        parsingElement = title;
        curTitle = [NSMutableString new];
    }
    else if ([elementName isEqualToString:@"url"]) {
        parsingElement = url;
        curURL = [NSMutableString new];
    }
//    else if ([elementName isEqualToString:@"response"]) NSLog(@"ololo!");
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSDictionary *myMusicInformation;
    parsingElement = nomusic;
    
    if ([elementName isEqualToString:@"audio"]) {
        myMusicInformation = [NSDictionary dictionaryWithObjectsAndKeys:curArtist, @"artist", curTitle, @"title", curURL, @"url", nil];
        [self.musicForTable addObject:myMusicInformation];
        curArtist = curTitle = curURL = nil;
    }
    myMusicInformation = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    switch (parsingElement) {
        case artist:
            [curArtist appendString:string];
            break;
        case title:
            [curTitle appendString:string];
            break;
        case url:
            [curURL appendString:string];
            break;
        default:
            break;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:0];
}

#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    LoginWebViewController *VKLogin = [LoginWebViewController new];
    VKLogin.delegate = self;
    switch (buttonIndex) {
        case 1:
            [self presentModalViewController:VKLogin animated:YES];
            break;
        default:
            VKLogin = nil;
            break;
    }
}

#pragma mark -
#pragma mark Private Methods

- (void)loadMusicList
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessToken"] == nil) {
        [self performSelector:@selector(failedLoadingTableViewData) withObject:nil afterDelay:0];
//        [self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:0];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                        message:@"Вам необходимо авторизоваться, чтобы загрузить список песен"
                                                       delegate:self
                                              cancelButtonTitle:@"Закрыть"
                                              otherButtonTitles:@"ОК", nil];
        [alert show];
        return;
    }
    isAuth = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSString *requestURL = [NSString stringWithFormat:@"https://api.vk.com/method/audio.get.xml?uid=%@&access_token=%@",
                            [[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessUserID"],
                            [[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessToken"]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *musicList, NSError *err) {
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//                               [musicList description];
                               if (err) {
                                   NSLog(@"%@", [err localizedDescription]);
                                   [self failedLoadingTableViewData];
                               }
                               else {
                                   NSXMLParser *parser = [[NSXMLParser alloc] initWithData:musicList];
                                   [parser setDelegate:self];
                                   [parser parse];
                               }
                           }];
}

- (void)toggleTableView
{
    if (self.activityIndicatorView.hidden) {
        [self.tableView setScrollEnabled:NO];
        [self.tableView setAllowsSelection:NO];
        [self.tabBarController.tabBar setUserInteractionEnabled:NO];
        [self.activityIndicatorView setHidden:NO];
        [self.activityIndicator startAnimating];
    }
    else {
        [self.tableView setScrollEnabled:YES];
        [self.tableView setAllowsSelection:YES];
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];
        [self.activityIndicator stopAnimating];
        [self.activityIndicatorView setHidden:YES];
    }
}

- (void)logout
{
    NSString *logout = @"http://api.vk.com/oauth/logout";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:logout] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *urlData, NSError *err) {
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                               if (urlData) {
                                   [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKAccessUserID"];
                                   [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKAccessToken"];
                                   [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKAccessTokenDate"];
                                   [[NSUserDefaults standardUserDefaults] synchronize];
                                   
                                   NSHTTPCookie *cookie;
                                   
                                   NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                                   
                                   for (cookie in [storage cookies]) {
                                       NSString* domainName = [cookie domain];
                                       NSRange domainRange = [domainName rangeOfString:@"vk.com"];
                                       if (domainRange.length > 0) {
                                           [storage deleteCookie:cookie];
                                       }
                                       domainRange = [domainName rangeOfString:@"vkontakte.ru"];
                                       if (domainRange.length > 0) {
                                           [storage deleteCookie:cookie];
                                       }
                                   }
                                   NSLog(@"here");
                                   [self.navigationItem setLeftBarButtonItem:nil animated:YES];
                               }
                           }];
}

- (void)downloadSongFromURL:(NSURL *)songURL withArtist:(NSString *)artistName title:(NSString *)title fileName:(NSString *)fileName andRow:(NSInteger)row
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:songURL];
    [request setDownloadProgressDelegate:self.progressBar];
    
    void (^completionBlock)(void) = ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSError *err = [request error];
        NSData *dataFile = [request responseData];
        if (err) {
            NSLog(@"ERROR! %@", [err localizedDescription]);
        }
        else if (dataFile) {
            NSString *pathToFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
            NSString *pathToList = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:SavedMusicFile];
            [[NSFileManager defaultManager] createFileAtPath:pathToFile contents:dataFile attributes:nil];
            
            NSMutableArray *downloadedMusic = [[NSMutableArray alloc] initWithContentsOfFile:pathToList];
            if (downloadedMusic == nil) downloadedMusic = [NSMutableArray new];
            
            [downloadedMusic addObject:[NSDictionary dictionaryWithObjectsAndKeys:artistName, @"artist", title, @"title", pathToFile, @"pathToFile", nil]];
            [downloadedMusic writeToFile:pathToList atomically:YES];
            [self.downloadedMusicViewController reloadMusicFile];
        }
        
        [self toggleTableView];
    };
    [request setCompletionBlock:completionBlock];
    [request setFailedBlock:completionBlock];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self toggleTableView];
    [request startAsynchronous];
}

#pragma mark VKLogin Delegate Methods

- (void)authComplete
{
    [self dismissModalViewControllerAnimated:YES];
    [self.navigationItem setLeftBarButtonItem:self.exitButton animated:YES];
    NSLog(@"Auth complete!");
}

- (void)authError:(NSString *)errorURL
{
    [self dismissModalViewControllerAnimated:YES];
    NSLog(@"Error: %@", errorURL);
}

@end
