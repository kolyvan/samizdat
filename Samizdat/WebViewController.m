//
//  WebViewController.m
//  samlib
//
//  Created by Kolyvan on 14.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"
#import "DDLog.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "NSDictionary+Kolyvan.h"


extern int ddLogLevel;


@implementation WebViewController

- (void) awakeFromNib
{
    [_webView setPolicyDelegate: self];    
    [_webView setResourceLoadDelegate: self];        
}

- (void) activate
{   
    if (_needReloadWebView) {        
        _needReloadWebView = NO;
        [self reloadWebView];  
    }
    [super activate];
}

- (void) loadWebViewFromPath: (NSString *) path
{
    NSURL *url = [NSURL URLWithString: [@"file://" stringByAppendingString: path]];
    NSURLRequest * request = [NSURLRequest requestWithURL: url];    
    [[_webView mainFrame] loadRequest:request];
}

- (void) loadWebViewFromHTML: (NSString *) html 
                    withPath: (NSString *) path
{
    [[_webView mainFrame] loadHTMLString:html 
                                 baseURL:[NSURL URLWithString: path]];
}

- (void) webViewSetString: (NSString *) value 
                    forID: (NSString *) idName 
                    inDom: (DOMDocument *) dom
{
    DOMElement *elem = [dom getElementById: idName];
    if (elem != nil &&
        [elem isKindOfClass:[DOMHTMLElement class]]) {
        
        DOMHTMLElement * htmlElem = (DOMHTMLElement * )elem;    
        htmlElem.innerText = value;           
    } else {
        
        // DDLogWarn(@"invalid DOM element id=%@", idName);            
    }
}

////

- (void) reloadWebView
{
    NSAssert(NO, @"abstract method");    
}

- (BOOL) navigateUrl: (NSURL *) url
{
    NSAssert(NO, @"abstract method");    
    return NO;
}

- (void) prepareHTML: (NSURL *)url
{
    NSAssert(NO, @"abstract method");    
}


//// web view delegate

- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    DDLogInfo(@"policy for %@ %@", request, actionInformation);    
    [listener ignore];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{    
    if (WebNavigationTypeReload == 
        [[actionInformation get:@"WebActionNavigationTypeKey"] integerValue])
    {
        [listener ignore];        
        [self reload: nil];
        
    } else {
        
        NSURL *url = [actionInformation get:@"WebActionOriginalURLKey"];        
        if ([self navigateUrl: url]) {
            //DDLogInfo(@"allow %@", url);            
            [listener use];
        }
        else {
            //DDLogInfo(@"ignore %@", url);
            [listener ignore];
        }
    }   
}

-(void)webView:(WebView *)sender
      resource:(id)identifier
didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
    NSURL * url = dataSource.request.URL;       
    // todo: called twice per page ???    
    //DDLogInfo(@"didFinishLoading %@", url);            
    [self prepareHTML: url];
}

@end
