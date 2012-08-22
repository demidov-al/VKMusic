//
//  AppDelegate.m
//  VKMusic
//
//  Created by Demidov Alexander on 11.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "MyMusicViewController.h"
#import "SearchMusicViewController.h"
#import "DownloadedViewController.h"
#import "PlayerViewController.h"


@implementation AppDelegate

@synthesize window = _window;
@synthesize rootNavController = _rootNavController;
@synthesize playerViewController = _playerViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MyMusicViewController *myMusic = [[MyMusicViewController alloc] initWithNibName:@"MyMusicViewController" bundle:nil];
    SearchMusicViewController *searchMusic = [[SearchMusicViewController alloc] initWithNibName:@"SearchMusicViewController" bundle:nil];
    downloadedMusicViewController = [[DownloadedViewController alloc] initWithNibName:@"DownloadedViewController" bundle:nil];
    myMusic.downloadedMusicViewController = searchMusic.downloadedMusicViewController = downloadedMusicViewController;
    
    UINavigationController *myMusicNavController = [[UINavigationController alloc] initWithRootViewController:myMusic];
    UINavigationController *searchMusicNavController = [[UINavigationController alloc] initWithRootViewController:searchMusic];
    UINavigationController *downloadedMusicNavController = [[UINavigationController alloc] initWithRootViewController:downloadedMusicViewController];
    
    UITabBarController *tabBar = [UITabBarController new];
    [tabBar setViewControllers:[NSArray arrayWithObjects:myMusicNavController, searchMusicNavController, downloadedMusicNavController, nil]];
    
    self.rootNavController = [[UINavigationController alloc] initWithRootViewController:tabBar];
    [self.rootNavController setNavigationBarHidden:YES];
    
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = self.rootNavController;
	[self.rootNavController setDelegate:self];
    [self.window makeKeyAndVisible];
	
	[self becomeFirstResponder];
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//	[self resignFirstResponder];
//	[[UIApplication sharedApplication] endBackgroundTask:ID];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Public Methods

- (void)playSongWithPath:(NSString *)pathToFile artist:(NSString *)artistName title:(NSString *)title andRow:(int)row
{
	if (!self.playerViewController) {
		self.playerViewController = [[PlayerViewController alloc] initWithNibName:@"PlayerViewController" bundle:nil];
		[self.playerViewController setDelegate:downloadedMusicViewController];
	}
	NSURL *urlToSong = [[NSURL alloc] initFileURLWithPath:pathToFile];
	NSLog(@"%@", [urlToSong absoluteURL]);
	[self.playerViewController setPlayingSongURL:urlToSong];
	[self.playerViewController setCurrentPlayingSongRow:row];
	[self.rootNavController pushViewController:self.playerViewController animated:YES];
	[self.playerViewController.artistLabel setText:artistName];
	[self.playerViewController.songTitleLabel setText:title];
	[self.playerViewController play];
}

- (void)showPlayer
{
	[self.rootNavController pushViewController:self.playerViewController animated:YES];
}

#pragma mark - Navigation Bar Delegate Methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isEqual:self.playerViewController]) [self.rootNavController setNavigationBarHidden:NO animated:YES];
	else [self.rootNavController setNavigationBarHidden:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    NSLog(@"Event has been received!");
    if (event.type == UIEventTypeRemoteControl) {
		switch (event.subtype) {
			case UIEventSubtypeRemoteControlPlay:
			case UIEventSubtypeRemoteControlTogglePlayPause:
			case UIEventSubtypeRemoteControlPause:
				[self.playerViewController togglePlayPause];
				break;
			case UIEventSubtypeRemoteControlNextTrack:
				[self.playerViewController playNextSong];
				break;
			case UIEventSubtypeRemoteControlPreviousTrack:
				[self.playerViewController playPreviousSong];
				break;
			default:
				break;
		}
    }
}

@end
