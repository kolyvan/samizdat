//
//  WebViewController.m
//  samlib
//
//  Created by Kolyvan on 14.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "WebViewController.h"
#import "AppDelegate.h"
#import "DDLog.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "NSDictionary+Kolyvan.h"


extern int ddLogLevel;

static NSScrollView* findScrollBars(NSView * view)
{
    if ([view  isKindOfClass:[NSScrollView class]]) {
        NSString * className = [view className];
        if ([className isEqualToString:@"WebDynamicScrollBarsView"]) {
            return (NSScrollView *)view;
        } 
    }
    
    for (NSView *sv in [view subviews]) {
        id found = findScrollBars(sv);
        if (found)
            return found;
    }
    
    return nil;
}


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

- (CGFloat) scrollOffset
{    
    NSScrollView *scrollView = findScrollBars(_webView);
    if (scrollView) {
        NSRect rect = scrollView.documentVisibleRect;    
        // DDLogInfo(@"rect %f %f %f %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);       
        CGFloat y = rect.origin.y;
        if (y > 10) {
            NSClipView * clipView = scrollView.documentView;
            rect = clipView.frame;
            // DDLogInfo(@"frame %f %f %f %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);   
            return y / rect.size.height;
        }
    }
    return 0;
}

- (void) setScrollOffset: (CGFloat) offset
{
    NSScrollView *scrollView = findScrollBars(_webView);
    if (scrollView) {
        NSClipView * clipView = scrollView.documentView;
        NSRect rect = clipView.frame;
        CGFloat y = rect.size.height * offset;    
        [clipView scrollPoint: NSMakePoint(0, y)];    
    }
}



@end
