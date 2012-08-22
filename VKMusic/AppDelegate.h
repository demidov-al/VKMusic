//
//  AppDelegate.h
//  VKMusic
//
//  Created by Demidov Alexander on 11.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayerViewController;
@class DownloadedViewController;


@interface AppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate > {
	DownloadedViewController *downloadedMusicViewController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *rootNavController;
@property (strong, nonatomic) PlayerViewController *playerViewController;

- (void)playSongWithPath:(NSString *)pathToFile artist:(NSString *)artistName title:(NSString *)title andRow:(int)row;
- (void)showPlayer;

@end
