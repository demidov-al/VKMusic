//
//  DownloadingViewController.h
//  VKMusic
//
//  Created by Демидов Александр on 03.08.12.
//
//

#import <UIKit/UIKit.h>

@protocol DownloadingViewDelegate;

@interface DownloadingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) id <DownloadingViewDelegate> delegate;

- (void)setVisibility:(BOOL)visibility;

@end

@protocol DownloadingViewDelegate <NSObject>

- (void)downloadingWasCanceled;

@end