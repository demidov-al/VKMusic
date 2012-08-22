//
//  LoginWebViewController.h
//  VKMusic
//
//  Created by Demidov Alexander on 11.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol LoginWebViewControllerProtocol <NSObject>

-(void)authComplete;
-(void)authError:(NSString *)errorURL;

@end



@interface LoginWebViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) id <LoginWebViewControllerProtocol> delegate;
@property (strong, nonatomic) UIWebView *authWebView;

@end
