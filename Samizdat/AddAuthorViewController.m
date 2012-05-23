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
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModel.h"

typedef enum {
    
    AddAuthorStateInit,
    AddAuthorStateFetching,  
    AddAuthorStateFetchedSuccess,   
    AddAuthorStateFetchedFailure,       
    AddAuthorStateSearching,             
    AddAuthorStateSearchedSuccess,              
    AddAuthorStateSearchedFailure,                  
    
} AddAuthorState;

@interface AddAuthorViewController() {

    IBOutlet NSTextField * _url;
    IBOutlet NSTextField * _search;
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
    IBOutlet NSButton * _btnFetch;
    IBOutlet NSButton * _btnSearch;
    IBOutlet NSTableView * _tableView;
    IBOutlet NSScrollView *_scrollView;
    
    SamLibAuthor * _author;    
    NSArray * _searchResult;
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
    KX_RELEASE(_searchResult);
    KX_SUPER_DEALLOC();
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _url.delegate = self;
    //_search.delegate = self;    
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];    
}

- (void) activate
{   
    [self setState: AddAuthorStateInit withInfo: @""];       
        
    [super activate];
}

- (void) setState: (AddAuthorState) state  
         withInfo: (NSString *) info
{
    switch (state) {
        case AddAuthorStateInit:
            
            [_url setEnabled:YES];
            [_search setEnabled:YES];
            [_fetchedInfo setHidden:YES];            
            [_infoBox setHidden:YES];            
            [_scrollView setHidden:YES]; 
            [_btnAdd setEnabled:NO];    
            [_btnSearch setEnabled:NO];
            [_btnFetch setEnabled:NO]; 
            
            _url.stringValue = @"";
            _search.stringValue = @"";            
            break;
            
        case AddAuthorStateFetching: 
            
            [_url setEnabled:NO];
            [_search setEnabled:NO];
            [_fetchedInfo setHidden:NO];            
            [_infoBox setHidden:YES];
            [_scrollView setHidden:YES];            
            [_btnAdd setEnabled:NO];
            [_btnSearch setEnabled:NO];            
            [_btnFetch setEnabled:NO];                        
                        
            _fetchedInfo.stringValue = KxUtils.format(locString(@"fetching %@"), info);
            _fetchedInfo.textColor = [NSColor textColor];
            break;
          
        case AddAuthorStateFetchedSuccess:
            
            [_url setEnabled:YES];
            [_search setEnabled:YES];
            [_fetchedInfo setHidden:NO];            
            [_infoBox setHidden:NO];
            [_scrollView setHidden:YES];            
            [_btnAdd setEnabled:YES];
            [_btnSearch setEnabled:YES];            
            [_btnFetch setEnabled:YES];  
             
            _fetchedInfo.stringValue = locString(@"author's information");
            _fetchedInfo.textColor = [NSColor blueColor];               
            break;
            
        case AddAuthorStateFetchedFailure:
        case AddAuthorStateSearchedFailure:    
            
            [_url setEnabled:YES];
            [_search setEnabled:YES];
            [_fetchedInfo setHidden:NO];            
            [_infoBox setHidden:YES];
            [_scrollView setHidden:YES];            
            [_btnAdd setEnabled:NO];
            [_btnSearch setEnabled:YES];            
            [_btnFetch setEnabled:YES];  
            
            _fetchedInfo.stringValue = info;
            _fetchedInfo.textColor = [NSColor redColor];                        
            break;
            
            
        case AddAuthorStateSearching:
                       
            [_url setEnabled:NO];
            [_search setEnabled:NO];
            [_fetchedInfo setHidden:NO];            
            [_infoBox setHidden:YES];
            [_scrollView setHidden:YES];            
            [_btnAdd setEnabled:NO];
            [_btnSearch setEnabled:NO];            
            [_btnFetch setEnabled:NO];                        
            
            _fetchedInfo.stringValue = KxUtils.format(locString(@"searching %@"), info);
            _fetchedInfo.textColor = [NSColor textColor];            
            break;
          
        case AddAuthorStateSearchedSuccess:
            
            [_url setEnabled:YES];
            [_search setEnabled:YES];
            [_fetchedInfo setHidden:NO];            
            [_infoBox setHidden:YES];
            [_scrollView setHidden:NO];            
            [_btnAdd setEnabled:NO];
            [_btnSearch setEnabled:YES];            
            [_btnFetch setEnabled:YES];  
            
            _fetchedInfo.stringValue = KxUtils.format(locString(@"found: %@"), info);
            _fetchedInfo.textColor = [NSColor blueColor];               
            break;            
            
        default:
            break;
    }
}

- (IBAction)controlTextDidChange:(NSNotification *)aNotification
{
    NSTextField *textField = aNotification.object;
    [_btnFetch setEnabled:textField.stringValue.nonEmpty];
}

- (IBAction) fetchPressed:(id)sender
{
    if (_url.stringValue.nonEmpty)
        [self urlChanged:_url];
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
    
    if (!url.nonEmpty || 
        [url contains: @"."] ||
        [url contains: @"/"]) {
            
        [_fetchedInfo setStringValue: KxUtils.format(locString(@"invalid URL: %@"), url)];        
        [_fetchedInfo setTextColor:[NSColor redColor]];        
        return;
    }
    
    SamLibAuthor *author = [[SamLibModel shared] findAuthor: url];
    if (author) {
        
        [_fetchedInfo setStringValue: KxUtils.format(locString(@"already exists: %@"), author.name)];        
        [_fetchedInfo setTextColor:[NSColor redColor]];   
        return;
    }
        
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
        
        [self setState: AddAuthorStateFetching withInfo: url];       
        
        KX_RELEASE(_author);
        _author = KX_RETAIN([[SamLibAuthor alloc] initWithPath:url]);
        
        [_author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
            
            [app finishReload:status 
                  withMessage:nil];    
            
            if (self.view.isHidden)
                return;
            
            if (status == SamLibStatusFailure) {
                                
                [self setState: AddAuthorStateFetchedFailure 
                      withInfo: error];                       
                               
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
                
                [self setState: AddAuthorStateFetchedSuccess 
                      withInfo: @""];                       
            }
            
        }];     
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

- (IBAction) searchPressed:(id)sender
{
    if (_search.stringValue.nonEmpty)
        [self searchChanged:_search];
}

- (IBAction) searchChanged: (id) sender
{
    NSString * name = [sender stringValue];
    
    if (!name.nonEmpty)
        return;    
    
    AppDelegate *app = [NSApp delegate];    
    if ([app startReload:self 
             withMessage:KxUtils.format(locString(@"searching %@"), name)]) {
    
        [self setState: AddAuthorStateSearching 
              withInfo: name]; 
        
        [SamLibAuthor fuzzySearchAuthorByName:name 
                                 minDistance1:0.2
                                 minDistance2:0.4 
                                        block:^(NSArray *result) {
                                            
                                            [app finishReload:result.nonEmpty ? SamLibStatusSuccess : SamLibStatusFailure  
                                                  withMessage:nil];    
                                            
                                            if (self.view.isHidden)
                                                return;
                                            
                                            if (result.nonEmpty) {
                                                
                                                KX_RELEASE(_searchResult);
                                                _searchResult = KX_RETAIN(result);
                                                
                                                [_tableView reloadData];                                                                                                    
                                                
                                                [self setState: AddAuthorStateSearchedSuccess
                                                      withInfo: KxUtils.format(@"%ld", result.count)]; 
                                                
                                            } else {
                                                
                                                [self setState: AddAuthorStateSearchedFailure
                                                      withInfo: @"not found"];
                                                
                                            }
                                            
                                        }];
    }

}

- (IBAction) searchSelect: (id) sender
{
    NSDictionary *dict = [_searchResult objectAtIndex:_tableView.selectedRow];
    _url.stringValue = [dict get:@"path"];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return _searchResult.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    NSDictionary *dict = [_searchResult objectAtIndex:row];
    
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:[tableColumn identifier] 
                                       owner:self];

    cellView.textField.stringValue = KxUtils.format(@"%@ %@", 
                                                    [dict get:@"name"],
                                                    [dict get:@"info"]);
    
    return cellView;    
}

@end
