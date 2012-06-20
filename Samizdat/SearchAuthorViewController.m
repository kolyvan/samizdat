//
//  SearchAuthorViewController.m
//  samlib
//
//  Created by Kolyvan on 19.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SearchAuthorViewController.h"

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
#import "TableCellViewEx.h"
#import "SamLibSearch.h"


@interface SearchAuthorViewController () {
    
    IBOutlet NSSearchField * _searchField;
    IBOutlet NSTableView * _tableView;
    IBOutlet NSScrollView *_scrollView;
    NSArray * _result;
    SamLibSearch *_search;
    BOOL _byName;
}
@end

@implementation SearchAuthorViewController

- (id) init
{
    self = [super initWithNibName:@"SearchAuthorView"];
    if (self) {            
        _byName = YES;        
    }
    return self;
}

- (void)dealloc
{   
    KX_RELEASE(_search);
    _search = nil;
    KX_RELEASE(_result);    
    _result = nil;
    
    KX_SUPER_DEALLOC();
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];    
    
    [self mkSearchMenu];
}

- (void) activate
{   
    [super activate];
    
    [_scrollView setHidden:YES];
    [_searchField.cell setTitle:@""];
}

- (void) deactivate
{
    [super deactivate];
    //[self cancelSearch];
}

- (IBAction) cancel: (id) sender
{    
    [_search cancel];
    KX_RELEASE(_search);
    _search = nil;   
}

- (void) addSearchResult: (NSArray *) found
{
    // union and sort
    NSArray *t = [SamLibSearch unionArray:found withArray:_result];    
    
    KX_RELEASE(_result);
    _result = KX_RETAIN([SamLibSearch sortByDistance:t]);
    
    [_tableView reloadData];
}

#pragma mark - search field

- (void) setSearchCategoryFrom: (NSMenuItem *)menuItem
{
    NSString *s;    
    
    if (menuItem.tag == 1) {
    
        s = @"enter name: ";
        _byName = YES;
              
    } else {

        s = @"enter address: ";        
        _byName = NO;
    }
    
    [_searchField.cell setPlaceholderString:locString(s)];        
}

- (IBAction)updateFilter:sender
{
    NSString *pattern = _searchField.stringValue;
    
     AppDelegate *app = [NSApp delegate];   
    
    if (_search) {    
        
        [app finishReload:-1 
              withMessage:locString(@"canceled")];
        [self cancel: nil];
    }
    
    KX_RELEASE(_result); 
    _result = nil;
        
    if (pattern.nonEmpty) {
               
        [_tableView reloadData];        
        [_scrollView setHidden:NO];
        
        NSString *message = KxUtils.format(locString(@"searhing %@ by %@"), pattern, _byName ? @"name" : @"path");
     
        if ([app startReload:self 
                 withMessage:message]) {
            
            void(^block)(NSArray *) = ^(NSArray *result) {
                
                if (!result.nonEmpty) {
                    
                    [app finishReload:SamLibStatusSuccess 
                          withMessage:KxUtils.format(locString(@"found %d"), _result.count)]; 
                }
                
                if (self.view.isHidden)
                    return;
                
                if (result.nonEmpty)                                                         
                    [self addSearchResult:result];                                                     
            };
            
            _search = [SamLibSearch searchAuthor:pattern 
                                          byName:_byName
                                            flag:FuzzySearchFlagAll
                                           block:block];
        }        
        
    } else {
    
        [_scrollView setHidden:YES];
    }
}

- (void) mkSearchMenu
{
    NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
    
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:locString(@"Search by name")
                                                   action:@selector(setSearchCategoryFrom:)
                                            keyEquivalent:@""];
    [item1 setTarget:self];
    [item1 setTag:1];
    [cellMenu insertItem:item1 atIndex:0];
    
    NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:locString(@"Search by address")
                                                   action:@selector(setSearchCategoryFrom:)
                                            keyEquivalent:@""];
    [item2 setTarget:self];
    [item2 setTag:2];
    [cellMenu insertItem:item2 atIndex:1];
    
    [_searchField.cell setSearchMenuTemplate:cellMenu];
    
    KX_RELEASE(cellMenu);
    KX_RELEASE(item1);    
    KX_RELEASE(item2);        
}

#pragma mark - textview delegate

- (void) select: (id) sender
{
    NSInteger i = [sender tag];
    NSDictionary *dict = [_result objectAtIndex:i];
    
    SamLibModel *model = [SamLibModel shared];
    
    NSString *from = [dict get:@"from"];
    NSString *path = [dict get:@"path"]; 
    
    SamLibAuthor *author; 
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    if ([from isEqualToString:@"local"]) {
    
        author = [model findAuthor:path];
        if (author)
            [appDelegate showAuthorView: author];         
        else
            [appDelegate showAuthorsView: nil];         
    
    } else {
        
        author = [SamLibAuthor fromDictionary:dict withPath:path];                        
        [model addAuthor:author];                          
        [appDelegate showAuthorView: author];                 
        [appDelegate reload: nil];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return _result.count;
}

- (NSView *) tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row 
{

    NSDictionary *dict = [_result objectAtIndex:row];

    TableCellViewEx *cellView = [tableView makeViewWithIdentifier:[tableColumn identifier] 
                                                            owner:self];
    
    NSAssert(cellView != nil, @"nil cell");

    NSString *path = [dict get:@"path"];
    NSString *name = [dict get:@"name" orElse:@"-"];
    NSString *info = [dict get:@"info" orElse:@"-"];
    float distance = [[dict get:@"distance"] floatValue];    
    
    cellView.textField.stringValue = KxUtils.format(@"%@ (%@)", name, path);
    cellView.sizeField.stringValue = KxUtils.format(@"%@ (%.2f)", info, distance);
    cellView.goButton.target = self;
    cellView.goButton.action = @selector(select:);
    cellView.goButton.tag = row;
    
    NSString *from = [dict get: @"from"];
    if ([from isEqualToString:@"google"])
        cellView.imageView.image = [NSImage imageNamed:@"google.png"];
    else if ([from isEqualToString:@"samlib"])
        cellView.imageView.image  = [NSImage imageNamed:@"samlib.png"];
    else if ([from isEqualToString:@"local"])
        cellView.imageView.image  = [NSImage imageNamed:@"asterisk.png"];
    else if ([from isEqualToString:@"direct"])
        cellView.imageView.image  = [NSImage imageNamed:@"ok-green.png"];
    else
        cellView.imageView.image  = nil;
    
    return cellView;    
}


@end