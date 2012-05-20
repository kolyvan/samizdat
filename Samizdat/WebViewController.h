//
//  WebViewController.h
//  samlib
//
//  Created by Kolyvan on 14.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxViewController.h"
#import <WebKit/WebKit.h>
#import "KxHUD.h"
#import "SamLib.h"

// abstract class

@interface WebViewController : KxViewController {
    
    IBOutlet WebView * _webView;     
    BOOL _needReloadWebView;
}

- (void) loadWebViewFromPath: (NSString *) path;

- (void) loadWebViewFromHTML: (NSString *) html 
                    withPath: (NSString *) path;
 
- (void) webViewSetString: (NSString *) value 
                    forID: (NSString *) idName 
                    inDom: (DOMDocument *) dom;

// abstract methods, must provide implemetation
- (void) prepareHTML: (NSURL *)url;
- (void) reloadWebView;
- (BOOL) navigateUrl: (NSURL *) url;

@end
