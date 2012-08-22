//
//  DownloadedViewController.h
//  VKMusic
//
//  Created by Demidov Alexander on 12.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerViewController.h"

@interface DownloadedViewController : UITableViewController <MusicPlayerDelegateProtocol>

@property (strong, nonatomic) NSMutableArray *musicList;

- (void)reloadMusicFile;
- (IBAction)toggleMove;

@end
