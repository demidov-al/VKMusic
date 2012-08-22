//
//  PlayerViewController.m
//  VKMusic
//
//  Created by Demidov Alexander on 13.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerViewController ()

- (void)checkProgressTimer;
- (void)updateSliderAndLabels;

@end

@implementation PlayerViewController

@synthesize progressSlider = _progressSlider;
@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize playButton = _playButton;
@synthesize artistLabel = _artistLabel;
@synthesize songTitleLabel = _songTitleLabel;
@synthesize currentTimeLabel = _currentTimeLabel;
@synthesize timeRemainsLabel = _timeRemainsLabel;
@synthesize delegate = _delegate;
@synthesize playingSongURL = _playingSongURL;
@synthesize isPlaying = _isPlaying;
@synthesize currentPlayingSongRow = _currentPlayingSongRow;

#pragma mark - Lifecycle Methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = @"Плеер";
		self.isPlaying = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.progressSlider setBackgroundColor:[UIColor clearColor]];
    UIImage *stetchLeftTrack = [[UIImage imageNamed:@"sliderBlue"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 9.0, 0.0, 0.0)];
    UIImage *stetchRightTrack = [[UIImage imageNamed:@"sliderWhite"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 9.0, 0.0, 0.0)];
    [self.progressSlider setThumbImage: [UIImage imageNamed:@"thumbImage"] forState:UIControlStateNormal];
    [self.progressSlider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
    [self.progressSlider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
}

- (void)viewDidUnload
{
	[progressSliderTimer invalidate];
	progressSliderTimer = nil;
	player = nil;
	
	[self setPlayingSongURL:nil];
	[self setDelegate:nil];
    [self setProgressSlider:nil];
    [self setBackButton:nil];
    [self setForwardButton:nil];
    [self setPlayButton:nil];
    [self setArtistLabel:nil];
    [self setSongTitleLabel:nil];
    [self setCurrentTimeLabel:nil];
    [self setTimeRemainsLabel:nil];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidAppear:(BOOL)animated
{
	self.navigationController.navigationBar.backItem.title = @"Назад";
	[super viewDidAppear:animated];
}

#pragma mark - Setters and Getters

- (NSURL *)playingSongURL
{
    return _playingSongURL;
}

- (void)setPlayingSongURL:(NSURL *)playingSongURL
{
    _playingSongURL = playingSongURL;
	
	if (!playingSongURL) return;
	
	NSError *err;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:playingSongURL error:&err];
	if (err) NSLog(@"%@", [err localizedDescription]);
    [player setDelegate:self];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [player prepareToPlay];
    
    [self checkProgressTimer];
}

#pragma mark - Public Methods

- (IBAction)play
{
	[player play];
	
	UIImage *pauseImage = [UIImage imageNamed:@"pauseButton@2x.png"];
	[self.playButton setImage:pauseImage forState:UIControlStateNormal];
	self.isPlaying = YES;
	[self checkProgressTimer];
}

- (IBAction)stop
{
	[player stop];
	
	UIImage *playImage = [UIImage imageNamed:@"playButton@2x.png"];
	[self.playButton setImage:playImage forState:UIControlStateNormal];
	self.isPlaying = NO;
	
	[progressSliderTimer invalidate];
	progressSliderTimer = nil;
}

- (IBAction)pause
{
	[player pause];
    
	UIImage *playImage = [UIImage imageNamed:@"playButton@2x.png"];
    [self.playButton setImage:playImage forState:UIControlStateNormal];
	self.isPlaying = NO;
}

- (IBAction)sliderDidChanged:(UISlider *)sender
{
	NSTimeInterval currentTime = self.progressSlider.value;
    NSTimeInterval duration = player.duration;
    
    NSDateFormatter *timeFormatter = [NSDateFormatter new];
    [timeFormatter setDateFormat:@"mm:ss"];
    
    NSDate *date1 = [NSDate dateWithTimeIntervalSince1970:currentTime];
    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:duration-currentTime];
    
    NSString *currentTimeString = [timeFormatter stringFromDate:date1];
    NSString *leftTimeString = [@"-" stringByAppendingString:[timeFormatter stringFromDate:date2]];
    
    [player stop];
	[player setCurrentTime:currentTime];
    
    [self.currentTimeLabel setText:currentTimeString];
    [self.timeRemainsLabel setText:leftTimeString];
    
	[player prepareToPlay];
	[player play];
}

- (IBAction)togglePlayPause
{
	if (self.isPlaying) [self pause];
	else [self play];
}

- (IBAction)playNextSong
{
	if (!self.delegate) {
		NSLog(@"No delegate with play list");
		return;
	}
	if (![self.delegate isThereNextSongForMe:self]) return;
	[self stop];
	player = nil;
	[self.delegate setMeNextSong:self];
	[self play];
}

- (IBAction)playPreviousSong
{
	if (!self.delegate) {
		NSLog(@"No delegate with play list");
		return;
	}
	if (player.currentTime > player.duration * 0.01) {
		NSLog(@"Back!");
		[self stop];
		[player setCurrentTime:0.0];
		[player prepareToPlay];
		[self play];
		return;
	}
	if (![self.delegate isTherePreviousSongForMe:self]) return;
	[self stop];
	player = nil;
	[self.delegate setMePreviousSong:self];
	[self play];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[progressSliderTimer invalidate];
	progressSliderTimer = nil;
	NSAssert(flag, @"player has not finished successfully");
    [progressSliderTimer invalidate];
    if ([self.delegate isThereNextSongForMe:self]) {
		[self.delegate setMeNextSong:self];
		[self checkProgressTimer];
		[self play];
	}
}

#pragma mark - Private Methods

- (void)checkProgressTimer
{
	if (!progressSliderTimer) {
		[progressSliderTimer invalidate];
		progressSliderTimer = nil;
	}
	self.progressSlider.maximumValue = player.duration;
    progressSliderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSliderAndLabels) userInfo:nil repeats:YES];
}

- (void)updateSliderAndLabels
{
	NSTimeInterval currentTime = player.currentTime;
    NSTimeInterval duration = player.duration;
    
    NSDateFormatter *timeFormatter = [NSDateFormatter new];
    [timeFormatter setDateFormat:@"mm:ss"];
    
    NSDate *date1 = [NSDate dateWithTimeIntervalSince1970:currentTime];
    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:duration-currentTime];
    
    NSString *currentTimeString = [timeFormatter stringFromDate:date1];
    NSString *leftTimeString = [@"-" stringByAppendingString:[timeFormatter stringFromDate:date2]];
    
    [self.currentTimeLabel setText:currentTimeString];
    [self.timeRemainsLabel setText:leftTimeString];
    
    self.progressSlider.value = currentTime;
}

@end
