//
//  LoginWebViewController.m
//  VKMusic
//
//  Created by Demidov Alexander on 11.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginWebViewController.h"

@interface LoginWebViewController ()

- (NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end innerString:(NSString*)str;

@end

@implementation LoginWebViewController

@synthesize delegate = _delegate;
@synthesize authWebView = _authWebView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if(!self.authWebView) {
        self.authWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        self.authWebView.delegate = self;
        self.authWebView.scalesPageToFit = YES;
    }
    [self.view addSubview:self.authWebView];
    NSString *authString = @"http://api.vkontakte.ru/oauth/authorize?client_id=2999764&scope=audio,groups&redirect_uri=http://api.vkontakte.ru/blank.html&display=touch&response_type=token";
    NSURL *url = [NSURL URLWithString:authString];
    [self.authWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)viewDidUnload
{
    [self setDelegate:nil];
    [self setAuthWebView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Delegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([webView.request.URL.absoluteString rangeOfString:@"access_token"].location != NSNotFound) {
        NSString *accessToken = [self stringBetweenString:@"access_token=" andString:@"&" innerString:[[[webView request] URL] absoluteString]];
        
        NSArray *userAr = [webView.request.URL.absoluteString componentsSeparatedByString:@"&user_id="];
        NSString *user_id = [userAr lastObject];
        
        if(user_id) {
            [[NSUserDefaults standardUserDefaults] setObject:user_id forKey:@"VKAccessUserID"];
        }
        
        if(accessToken) {
            [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"VKAccessToken"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"VKAccessTokenDate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [self.delegate authComplete];
    }
    else if ([webView.request.URL.absoluteString rangeOfString:@"error"].location != NSNotFound) {
        [self.delegate authError:webView.request.URL.absoluteString];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self.delegate authError:webView.request.URL.absoluteString];
}

#pragma mark -
#pragma mark Private Methods

- (NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end innerString:(NSString*)str 
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString* result = nil;
        if ([scanner scanUpToString:end intoString:&result]) {
            return result;
        }
    }
    return nil;
}

@end
