//
//  TextViewController.m
//  samlib
//
//  Created by Kolyvan on 14.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "TextViewController.h"
#import "AppDelegate.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "DDLog.h"

extern int ddLogLevel;

////

static NSString * mkHTML(NSString * html)
{
    NSString *path = KxUtils.pathForResource(@"text.html");
    NSError *error;
    NSString *template = [NSString stringWithContentsOfFile:path 
                                                   encoding:NSUTF8StringEncoding 
                                                      error:&error];            
    if (!template.nonEmpty) {
        DDLogCWarn(@"file error %@", 
                   KxUtils.completeErrorMessage(error));
        return html;                
    }
    
    // replase css link from relative to absolute         
    template = [template stringByReplacingOccurrencesOfString:@"text.css" 
                                                   withString:KxUtils.pathForResource(@"text.css")];
    
    return [template stringByReplacingOccurrencesOfString:@"<!-- DOWNLOADED_TEXT -->" 
                                               withString:html];
}


////

@interface TextViewController () {    
    SamLibText * _text;
    id _version;
    
    void (^_progressBlock)(CGFloat);
}

@property (readwrite, nonatomic, copy) id  version;

@end

@implementation TextViewController
 
@synthesize version = _version;

- (id)init
{
    self = [super initWithNibName:@"TextView"];
    if (self) {
    }    
    return self;
}

- (void) dealloc 
{
    KX_RELEASE(_progressBlock);
    KX_RELEASE(_text);
    KX_RELEASE(_version);
    KX_SUPER_DEALLOC();
}

- (void) reset: (id) obj
{
    NSAssert([obj isKindOfClass: [SamLibText class]], @"invalid class");
    SamLibText * text = obj;
    
    if (_text == text &&
        [_version isEqualTo:text.version]) {

        return;  
    }
    
    self.version = text.version;    
    _needReloadWebView = YES;        
    KX_RELEASE(_text);
    _text = KX_RETAIN(text);        
    
    DDLogInfo(@"reload text view %@", _text.path);
    
}

- (void) prepareHTML: (NSURL *) url
{
    BOOL isDiff = [[url lastPathComponent] hasSuffix: @"diff.html"];
    
    WebFrame *mainFrame = [_webView mainFrame];
    DOMDocument * dom = [mainFrame DOMDocument];
    
    [self webViewSetString:_text.author.name forID:@"authorName" inDom:dom];
    [self webViewSetString:_text.title forID:@"textName" inDom:dom];    
    
    if (_text.group.nonEmpty)
        [self webViewSetString:_text.group forID:@"textGroup" inDom:dom];        
    
    if (_text.type.nonEmpty)
        [self webViewSetString:_text.type forID:@"textType" inDom:dom];            
    
    if (_text.genre.nonEmpty)    
        [self webViewSetString:_text.genre forID:@"textGenre" inDom:dom];
    
    if (_text.dateModified.nonEmpty)        
        [self webViewSetString:_text.dateModified forID:@"textDate" inDom:dom];                    
    
    if (_text.note.nonEmpty)
        [self webViewSetString: _text.note forID:@"textNote"  inDom:dom];  
    
    [self webViewSetString:[_text sizeWithDelta:@" "]
                     forID:@"textSize" 
                     inDom:dom];
        
    [self webViewSetString:[_text ratingWithDelta:@" "]
                     forID:@"textRating" 
                     inDom:dom];                        

    [self webViewSetString: [_text commentsWithDelta:@" "]
                     forID:@"commentsCount" 
                     inDom:dom];  
    
    if (_text.canUpdate)
        [self webViewSetString:locString(@"a new version is available") 
                         forID:@"textReload" 
                         inDom:dom];
        
    if (isDiff) {

        [self webViewSetString:locString(@"show original") 
                         forID:@"textOriginal" 
                         inDom:dom];
       
    } else {
        
        if (_text.diffFile.nonEmpty ||
            _text.canMakeDiff) {
            
            [self webViewSetString:locString(@"show changes") 
                             forID:@"textDiff" 
                             inDom:dom];
        } 
    }
}

- (void) reloadWebView
{    
    NSString *path = _text.htmlFile;
    if (!path)
        path = KxUtils.pathForResource(@"text.html");            
    [self loadWebViewFromPath: path];
}

- (void) reloadWebViewWithDiff
{    
    NSString *path = _text.diffFile;
    if (path.nonEmpty)        
        [self loadWebViewFromPath: path];
}

- (void) reload:(id)sender
{    
    AppDelegate *app = [NSApp delegate];    

    KX_RELEASE(_progressBlock);
    _progressBlock = nil;
    _progressBlock = [app startReload:self 
                          withMessage:_text.title 
                          andProgress:YES];
    
    if (_progressBlock) {
        
        [_text update:^(SamLibText *text, SamLibStatus status, NSString *error) {
            
            KX_RELEASE(_progressBlock);
            _progressBlock = nil;
            
            [app finishReload:status 
                  withMessage:status == SamLibStatusFailure ? error : _text.title ];    
            
            if (status == SamLibStatusSuccess)
                [self reloadWebView];           
            
        }
             progress:^(NSInteger bytes, long long totalBytes, long long totalBytesExpected) {
                                
                 CGFloat progress = 0;
                 if (totalBytesExpected > 0)
                    progress = (CGFloat)totalBytes / totalBytesExpected;                 
                 else
                    progress = (CGFloat)totalBytes/ (_text.sizeInt * 1024);
                                                   
                 //DDLogCInfo(@"progress %ld, %ld, %f",totalBytes,totalBytesExpected,progress);                 
                 _progressBlock(progress);
             } 
            formatter: ^(NSString * html) { 
                return mkHTML(html); 
            }
         ];
    }
}

- (BOOL) navigateUrl: (NSURL *) url
{
    NSString * scheme = [url scheme];
    
    if ([scheme isEqualToString: @"file"]) {
        
        NSString * last = [url lastPathComponent];
        
        if ([last isEqualToString:@"text.html"]) {
            
            return YES;
            
        } else if ([last isEqualToString:@"comments"]) {
            
            [[NSApp delegate] showCommentsView: [_text commentsObject: YES]];
            return NO;
            
        } else if ([last isEqualToString:@"author"]) {

            [[NSApp delegate] showAuthorView: _text.author];
            return NO;            
            
        } else if ([last isEqualToString:@"diff"]) {
            
            if (!_text.diffFile.nonEmpty) {
                
                [_text makeDiff:^(NSString *html) { 
                    return mkHTML(html); 
                }];
            }
                        
            [self reloadWebViewWithDiff];
            return NO;            
            
        } else if ([last isEqualToString:@"reload"]) {  
            
            [self reload:nil];
            return NO;                        
            
        } else if ([last isEqualToString:@"original"]) {  

            [self reloadWebView];
            return NO;                                    
            
        } else {                                    
            
            NSString *path = [url path];
            if ([_text.htmlFile isEqualToString: path] ||
                [_text.diffFile isEqualToString: path]) {

                return YES;                 
            }    
        }
    }  

    DDLogInfo(@"ignore %@", url);                                           
    return NO;
}

@end
