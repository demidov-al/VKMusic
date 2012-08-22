//
//  SearchMusicViewController.m
//  VKMusic
//
//  Created by Demidov Alexander on 12.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchMusicViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "DownloadedViewController.h"
#import "AppDelegate.h"
#import "ASIHTTPRequest.h"

#define SavedMusicFile @"SavedMusic.plist"

@interface SearchMusicViewController ()

- (void)toggleTableView;
- (void)downloadSongFromURL:(NSURL *)songURL withArtist:(NSString *)artistName title:(NSString *)title fileName:(NSString *)fileName andRow:(NSInteger)row;

@end

@implementation SearchMusicViewController

@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize activityIndicator = _activityIndicator;
@synthesize progressBar = _progressBar;
@synthesize searchBar = _searchBar;
@synthesize downloadedMusicViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Поиск";
        self.tabBarItem.image = [UIImage imageNamed:@"searchMusic"];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.activityIndicatorView.layer setCornerRadius:6.0];
    [self.activityIndicatorView setCenter:self.tableView.center];
    [self.tableView addSubview:self.activityIndicatorView];
}

- (void)viewDidUnload
{
    searchResult = nil;
    searchConnection = nil;
    dataFile = nil;
    
    [self setDownloadedMusicViewController:nil];
    [self setSearchBar:nil];
    [self setActivityIndicatorView:nil];
    [self setActivityIndicator:nil];
    [self setProgressBar:nil];
    
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

#pragma mark - NSURL Connection Delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [dataFile appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    id results = [NSJSONSerialization JSONObjectWithData:dataFile options:NSJSONReadingMutableContainers error:nil];
//    NSLog(@"%@", [results description]);
    dataFile = nil;
    
    int resultCount = [[[results objectForKey:@"response"] objectAtIndex:0] intValue];
    if (resultCount <= 0) {
        NSLog(@"Nothing was found!");
        return;
    }
    else NSLog(@"founded %d tracks", resultCount);
    
    searchResult = [NSMutableArray new];
    NSArray *callbackArray = [results objectForKey:@"response"];
    for (int i = 1; i < [callbackArray count]; i++) {
        [searchResult addObject:[callbackArray objectAtIndex:i]];
    }
//    NSLog(@"%@", [searchResult description]);
    [self.tableView reloadData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

#pragma mark - Search Bar Delegate Methods

//- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText
//{
//    
//}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessToken"]) {
        NSLog(@"You must authorize!");
        return;
    }
    if (searchBar.text.length == 0) return;
    
    NSString *URLString = [NSString stringWithFormat:@"https://api.vk.com/method/audio.search?q=%@&sort=2&count=20&access_token=%@",
                           [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessToken"]];
    
    NSURLRequest *searchRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    if (searchConnection) {
        [searchConnection cancel];
        searchConnection = nil;
        dataFile = nil;
    }
    dataFile = [NSMutableData new];
    searchConnection = [[NSURLConnection alloc] initWithRequest:searchRequest delegate:self startImmediately:YES];
    if (searchConnection == nil) {
        dataFile = nil;
        NSLog(@"Error! Search Connection");
    }
    else [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.searchBar resignFirstResponder];
}


#pragma mark - Scaroll View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.activityIndicatorView setCenter:CGPointMake(self.tableView.center.x, self.tableView.center.y + self.tableView.bounds.origin.y)];
    [self.searchBar resignFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [searchResult count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SimpleTableIdentifier];
    }
    NSUInteger row = [indexPath row];
    cell.textLabel.text = [[searchResult objectAtIndex:row] objectForKey:@"title"];
    cell.detailTextLabel.text = [[searchResult objectAtIndex:row] objectForKey:@"artist"];
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    [self downloadSongFromURL:[NSURL URLWithString:[[searchResult objectAtIndex:row] objectForKey:@"url"]]
                   withArtist:[[searchResult objectAtIndex:row] objectForKey:@"artist"]
                        title:[[searchResult objectAtIndex:row] objectForKey:@"title"]
                     fileName:[[[searchResult objectAtIndex:row] objectForKey:@"url"] lastPathComponent]
                       andRow:row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private Methods

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

- (void)downloadSongFromURL:(NSURL *)songURL withArtist:(NSString *)artistName title:(NSString *)title fileName:(NSString *)fileName andRow:(NSInteger)row
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:songURL];
    [request setDownloadProgressDelegate:self.progressBar];
    
    void (^completionBlock)(void) = ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSError *err = [request error];
        NSData *data = [request responseData];
        if (err) {
            NSLog(@"ERROR! %@", [err localizedDescription]);
        }
        else if (data) {
            NSString *pathToFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
            NSString *pathToList = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:SavedMusicFile];
            [[NSFileManager defaultManager] createFileAtPath:pathToFile contents:data attributes:nil];
            
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

@end
