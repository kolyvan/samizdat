//
//  TableViewController.m
//  samlib
//
//  Created by Kolyvan on 17.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "TableViewController.h"
#import "TextCellView.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibText.h"
#import "AppDelegate.h"
#import "SamLibAgent.h"
#import "SamLibAuthor.h"
#import "DDLog.h"

extern int ddLogLevel;

////

@implementation SamizdatTableView

- (void)keyUp:(NSEvent *)event 
{
    if ([event type] == NSKeyUp) {
        
        /*
        NSString* characters = [event characters];
        if (([characters length] > 0) && 
            (([characters characterAtIndex:0] == NSCarriageReturnCharacter) || 
             ([characters characterAtIndex:0] == NSEnterCharacter))) {
        }
        */

        if ([event keyCode] == 36 && 
            self.doubleAction) { 
            
            [NSApp sendAction:self.doubleAction 
                           to:self.target 
                         from:self];
            return;
        }
    }
    
    [super keyUp:event];
}


@end

////

@implementation TableViewController

- (void) dealloc 
{
    KX_RELEASE(_content);
    KX_SUPER_DEALLOC();
}

- (void) awakeFromNib
{
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];    
    [_tableView setDoubleAction:@selector(tableDoubleClick:)];
    [_tableView setTarget:self];    
}

- (void) activate
{
    [self reloadTableView];
    [super activate];
}

- (NSArray *) loadContent
{
    NSAssert(NO, @"abstract method");
    return nil;
}

- (void) handleSelect: (id) obj
{
    NSAssert(NO, @"abstract method");    
}

- (void) reloadTableView
{
    NSArray * newContent = [self loadContent];
    if (![newContent isEqualTo:_content]) {
        KX_RELEASE(_content);    
        _content = KX_RETAIN(newContent);
        [_tableView reloadData];
        
        DDLogInfo(@"reload table data %@", self.className);
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return _content.count;
}

- (void) reloadAuthors: (NSArray *) authors
           withMessage: (NSString *) message
{    
    AppDelegate *app = [NSApp delegate]; 
    
    if ([app startReload:self 
             withMessage:message]) {
                
        __block NSInteger count = authors.count;
        __block SamLibStatus reloadStatus = SamLibStatusNotModifed;
        __block NSString *lastError = nil;
                        
        for (SamLibAuthor *author in authors) {
            
            [author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
                
                if (status == SamLibStatusSuccess) {
                    reloadStatus = SamLibStatusSuccess;
                    [self reloadTableView];
                }
                
                if (status == SamLibStatusFailure &&
                    ![error isEqualToString: lastError]) {
                    
                    [app hudWarning:KxUtils.format(@"reload failure\n%@", error)];
                    KX_RELEASE(lastError);
                    lastError = KX_RETAIN(error);
                }
                
                if (--count == 0) {
                                        
                    [app finishReload:reloadStatus 
                          withMessage:message]; 
                    
                    KX_RELEASE(lastError);
                    lastError = nil;
                }
            }];    
        }     
    }
}

- (IBAction)tableDoubleClick:(id)sender 
{    
    NSInteger row = [_tableView selectedRow];
    if (row != -1) {
        id obj = [_content objectAtIndex:row];
        [self handleSelect: obj];
    }
}

- (IBAction)select:(id)sender
{ 
    id obj = [_content objectAtIndex:[sender tag]];
    [self handleSelect: obj];
}


@end