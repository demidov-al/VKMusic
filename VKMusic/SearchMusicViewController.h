//
//  SearchMusicViewController.h
//  VKMusic
//
//  Created by Demidov Alexander on 12.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownloadedViewController;

@interface SearchMusicViewController : UITableViewController <UISearchBarDelegate, NSURLConnectionDelegate> {
    NSURLConnection *searchConnection;
    NSMutableArray *searchResult;
    NSMutableData *dataFile;
}

@property (strong, nonatomic) IBOutlet UIView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (weak, nonatomic) DownloadedViewController *downloadedMusicViewController;

@end
