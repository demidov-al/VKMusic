//
//  DownloadingViewController.m
//  VKMusic
//
//  Created by Демидов Александр on 03.08.12.
//
//

#import "DownloadingViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DownloadingViewController ()

@end

@implementation DownloadingViewController

@synthesize activityIndicator = _activityIndicator;
@synthesize progressBar = _progressBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.view.layer setCornerRadius:6.0];
}

- (void)viewDidUnload
{
    [self setActivityIndicator:nil];
    [self setProgressBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setVisibility:(BOOL)visibility
{
	if (visibility) {
		[self.view setHidden:NO];
		[self.activityIndicator startAnimating];
	}
	else {
		[self.view setHidden:YES];
		[self.activityIndicator stopAnimating];
	}
}

@end
