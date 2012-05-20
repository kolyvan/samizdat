//
//  AddAuthorViewController.m
//  samizdat
//
//  Created by Konstantin Boukreev on 23.04.12.
//  Copyright 2012 github.com/kolyvan. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "AddAuthorViewController.h"
#import "AppDelegate.h"
#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSObject+Kolyvan.h"
#import "NSString+Kolyvan.h"

@interface AddAuthorViewController() {

    IBOutlet NSTextField * _url;
    IBOutlet NSTextField * _fetchedInfo;    
    IBOutlet NSBox * _infoBox;
    IBOutlet NSTextField * _name;
    IBOutlet NSTextField * _subtitle;
    IBOutlet NSTextField * _www;
    IBOutlet NSTextField * _email;
    IBOutlet NSTextField * _updated;    
    IBOutlet NSTextField * _size;        
    IBOutlet NSTextField * _rating;            
    IBOutlet NSTextField * _visitors;
    IBOutlet NSButton * _btnAdd;
    
    SamLibAuthor * _author;    
}
@end


@implementation AddAuthorViewController


- (id) init
{
    self = [super initWithNibName:@"AddAuthorView"];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    KX_RELEASE(_author);
    KX_SUPER_DEALLOC();
}

- (void) activate
{    
    _url.stringValue = @"";
    _fetchedInfo.stringValue = @"";
    
    [_url setEnabled:YES];
    [_infoBox setHidden:YES];
    [_btnAdd setEnabled:NO];
    
    [super activate];
}

- (IBAction) urlChanged: (id) sender
{
    NSString * url = [sender stringValue];
    
    if (!url.nonEmpty)
        return;
    
    // valid examles :
    // http://samlib.ru/d/dmitriew_p/
    // samlib.ru/d/dmitriew_p/    
    // dmitriew_p        
    
    // todo: allow ip 81.176.66.169 81.176.66.171
    
    if ([url hasPrefix:@"http://"]) {
        url = [url drop:@"http://".length];
    }
    
    if ([url hasPrefix:@"samlib.ru"]) {
        url = [url drop:@"samlib.ru".length];
    } 
    
    if ([url hasPrefix:@"zhurnal.lib.ru"]) {
        url = [url drop:@"zhurnal.lib.ru".length];        
    }
    
    if ([url hasPrefix:@"/"]) {
        url = [url drop:@"/".length];
    }

    if (url.length > 2 && 
        [url characterAtIndex:1] == '/' &&
        url.first == [url characterAtIndex:2]) {
        
        url = [url drop:2];
    }
    
    if (url.nonEmpty && 
        url.last == '/') {
        
        url = [url butlast];        
    }
    
    [_fetchedInfo setHidden:NO];
    
    if (url.nonEmpty && 
        ![url contains: @"."] &&
        ![url contains: @"/"]) {
        
        _name.stringValue = @"";
        _subtitle.stringValue = @"";
        _www.stringValue = @"";
        _email.stringValue = @"";
        _updated.stringValue = @"";
        _size.stringValue = @"";
        _rating.stringValue = @"";
        _visitors.stringValue = @"";            

        NSString *message = KxUtils.format(locString(@"fetching %@"), url);
        
        AppDelegate *app = [NSApp delegate];    
        if ([app startReload:self 
                 withMessage:message]) {
        
            _fetchedInfo.stringValue = message;
            _fetchedInfo.textColor = [NSColor textColor];
            
            [_url setEnabled:NO];
            [_infoBox setHidden:YES];
            [_btnAdd setEnabled:NO];
            
            KX_RELEASE(_author);
            _author = KX_RETAIN([[SamLibAuthor alloc] initWithPath:url]);
            
            [_author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
                
                [app finishReload:status 
                      withMessage:nil];    
                
                if (self.view.isHidden)
                    return;
                
                [_url setEnabled:YES];
                
                if (status == SamLibStatusFailure) {
                    
                    _fetchedInfo.stringValue = error;
                    _fetchedInfo.textColor = [NSColor redColor];
                }
                else {
                    
                    _url.stringValue = author.url;                
                    
                    if (author.name.nonEmpty)
                        _name.stringValue = author.name;
                    if (author.title.nonEmpty)
                        _subtitle.stringValue = author.title ;
                    if (author.www.nonEmpty)
                        _www.stringValue = author.www;
                    if (author.email.nonEmpty)
                        _email.stringValue = author.email;
                    if (author.updated.nonEmpty)
                        _updated.stringValue = author.updated;
                    if (author.size.nonEmpty)
                        _size.stringValue = author.size;
                    if (author.rating.nonEmpty)                
                        _rating.stringValue = author.rating;
                    if (author.visitors.nonEmpty)            
                        _visitors.stringValue = author.visitors;            
                    
                    _fetchedInfo.stringValue = locString(@"author's information");
                    _fetchedInfo.textColor = [NSColor blueColor];   
                    
                    [_infoBox setHidden:NO];                
                    [_btnAdd setEnabled:YES]; 
                }
                
            }];     
        }
            
    } else {
      
        [_fetchedInfo setStringValue: KxUtils.format(locString(@"invalid URL: %@"), url)];        
        [_fetchedInfo setTextColor:[NSColor redColor]];        
    }
}

- (IBAction) addAuthor: (id) sender
{
    [[SamLibModel shared] addAuthor:_author];    
    KX_RELEASE(_author);
    _author = nil;        
    [[NSApp delegate] showAuthorsView: nil];
}

- (IBAction) cancel: (id) sender
{
    [super cancel:sender];        
    KX_RELEASE(_author);
    _author = nil;    
    [[NSApp delegate] showAuthorsView: nil];
}


@end
