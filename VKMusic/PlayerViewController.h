//
//  PlayerViewController.h
//  VKMusic
//
//  Created by Demidov Alexander on 13.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol MusicPlayerDelegateProtocol;

@interface PlayerViewController : UIViewController <AVAudioPlayerDelegate> {
    NSURL *_playingSongURL;
    AVAudioPlayer *player;
	NSTimer *progressSliderTimer;
}

@property (strong, nonatomic) NSURL *playingSongURL;

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainsLabel;

@property (weak, nonatomic) id <MusicPlayerDelegateProtocol> delegate;
@property (assign) BOOL isPlaying;
@property (assign) int currentPlayingSongRow;

- (IBAction)play;
- (IBAction)pause;
- (IBAction)stop;
- (IBAction)playNextSong;
- (IBAction)playPreviousSong;
- (IBAction)sliderDidChanged:(UISlider *)sender;
- (IBAction)togglePlayPause;

@end


@protocol MusicPlayerDelegateProtocol <NSObject>

- (void)setMeNextSong:(PlayerViewController *)playerViewController;
- (void)setMePreviousSong:(PlayerViewController *)playerViewController;
- (BOOL)isThereNextSongForMe:(PlayerViewController *)playerViewController;
- (BOOL)isTherePreviousSongForMe:(PlayerViewController *)playerViewController;

@end