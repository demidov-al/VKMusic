//
//  DownloadedViewController.m
//  VKMusic
//
//  Created by Demidov Alexander on 12.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DownloadedViewController.h"
#import "AppDelegate.h"

#define SavedMusicFile @"SavedMusic.plist"

@interface DownloadedViewController ()


@end

@implementation DownloadedViewController

@synthesize musicList = _musicList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Скачано";
        self.tabBarItem.image = [UIImage imageNamed:@"DownloadedMusic"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *moveButton = [[UIBarButtonItem alloc] initWithTitle:@"Правка"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(toggleMove)];
    self.navigationItem.leftBarButtonItem = moveButton;
    
    [self reloadMusicFile];
}

- (void)viewDidUnload
{
    [self setMusicList:nil];
    
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

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.musicList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SimpleTableIdentifier];
    }
    NSUInteger row = [indexPath row];
    cell.textLabel.text = [[self.musicList objectAtIndex:row] objectForKey:@"title"];
    cell.detailTextLabel.text = [[self.musicList objectAtIndex:row] objectForKey:@"artist"];
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    NSString *filePath = [[self.musicList objectAtIndex:row] objectForKey:@"pathToFile"];
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&err];
    NSAssert(err == nil, [err localizedDescription]);
    
    [self.musicList removeObjectAtIndex:row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    NSString *pathToList = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:SavedMusicFile];
    [self.musicList writeToFile:pathToList atomically:YES];
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSUInteger fromRow = [fromIndexPath row];
    NSUInteger toRow = [toIndexPath row];
	
    id object = [self.musicList objectAtIndex:fromRow];
    [self.musicList removeObjectAtIndex:fromRow];
    [self.musicList insertObject:object atIndex:toRow];
    NSString *pathToList = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:SavedMusicFile];
    [self.musicList writeToFile:pathToList atomically:YES];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate playSongWithPath:[[self.musicList objectAtIndex:indexPath.row] objectForKey:@"pathToFile"]
						   artist:[[self.musicList objectAtIndex:indexPath.row] objectForKey:@"artist"]
							title:[[self.musicList objectAtIndex:indexPath.row] objectForKey:@"title"]
						   andRow:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Public Methods

- (void)reloadMusicFile
{
    self.musicList = [[NSMutableArray alloc] initWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:SavedMusicFile]];
    if (self.musicList) [self.tableView reloadData];
}

#pragma mark - Private Methods

- (IBAction)toggleMove
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
	UIBarButtonItem *moveButton;
    
    if (self.tableView.editing) moveButton = [[UIBarButtonItem alloc] initWithTitle:@"Готово"
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(toggleMove)];
	
    else moveButton = [[UIBarButtonItem alloc] initWithTitle:@"Правка"
													   style:UIBarButtonItemStyleBordered
													  target:self
													  action:@selector(toggleMove)];
	
	[self.navigationItem setLeftBarButtonItem:moveButton animated:YES];
}

#pragma mark - Music Data Source

- (void)setMeNextSong:(PlayerViewController *)playerViewController
{
	int row = playerViewController.currentPlayingSongRow;
	row++;
	NSURL *url = [[NSURL alloc] initFileURLWithPath:[[self.musicList objectAtIndex:row] objectForKey:@"pathToFile"]];
	[playerViewController setPlayingSongURL:url];
	[playerViewController.artistLabel setText:[[self.musicList objectAtIndex:row] objectForKey:@"artist"]];
	[playerViewController.songTitleLabel setText:[[self.musicList objectAtIndex:row] objectForKey:@"title"]];
	
	playerViewController.currentPlayingSongRow = row;
}

- (void)setMePreviousSong:(PlayerViewController *)playerViewController
{
	int row = playerViewController.currentPlayingSongRow;
	row--;
	NSURL *url = [[NSURL alloc] initFileURLWithPath:[[self.musicList objectAtIndex:row] objectForKey:@"pathToFile"]];
	[playerViewController setPlayingSongURL:url];
	[playerViewController.artistLabel setText:[[self.musicList objectAtIndex:row] objectForKey:@"artist"]];
	[playerViewController.songTitleLabel setText:[[self.musicList objectAtIndex:row] objectForKey:@"title"]];
	
	playerViewController.currentPlayingSongRow = row;
}

- (BOOL)isThereNextSongForMe:(PlayerViewController *)playerViewController
{
	int row = playerViewController.currentPlayingSongRow;
	if (row == (self.musicList.count - 1)) return NO;
	else return YES;
}

- (BOOL)isTherePreviousSongForMe:(PlayerViewController *)playerViewController
{
	int row = playerViewController.currentPlayingSongRow;
	if (row == 0) return NO;
	else return YES;
}

@end
