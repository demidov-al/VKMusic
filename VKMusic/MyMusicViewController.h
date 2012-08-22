//
//  MyMusicViewController.h
//  VKMusic
//
//  Created by Demidov Alexander on 11.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#include "LoginWebViewController.h"

@class DownloadedViewController;
@class DownloadingViewController;

typedef enum _MusicParsingElement {
    artist, title, url, nomusic
} MusicParsingElement;

@interface MyMusicViewController : UITableViewController <EGORefreshTableHeaderDelegate, NSXMLParserDelegate, LoginWebViewControllerProtocol> {
    BOOL isReloading;
    BOOL isAuth;
	BOOL failed;
    
    MusicParsingElement parsingElement;
    NSMutableString *curArtist, *curTitle, *curURL;
    
    EGORefreshTableHeaderView *refreshHeaderView;
	DownloadingViewController *downloadingcontroller;
}

@property (strong, nonatomic) IBOutlet UIView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@property (strong, nonatomic) UIBarButtonItem *exitButton;
@property (strong, nonatomic) NSMutableArray *musicForTable;
@property (weak, nonatomic) DownloadedViewController *downloadedMusicViewController;

- (void)logout;

@end
