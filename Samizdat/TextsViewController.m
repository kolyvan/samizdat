//
//  FavoritesViewController.m
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "TextsViewController.h"
#import "TextCellView.h"
//#import "KxArc.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibText.h"
#import "AppDelegate.h"
#import "SamLibAgent.h"

////

@implementation TextsViewController

- (id)init
{
    self = [super initWithNibName:@"TextsView"];
    if (self) {
    }    
    return self;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row 
{    
    id obj = [_content objectAtIndex:row];
    return [obj isKindOfClass:[NSString class]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row 
{
    id obj = [_content objectAtIndex:row];
    
    if ([obj isKindOfClass:[SamLibText class]])
        return 60; //[tableView rowHeight];
    else 
        return 20;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    id obj = [_content objectAtIndex:row];
       
    if ([obj isKindOfClass:[NSString class]]) {
        
        NSTextField *textField = [tableView makeViewWithIdentifier:@"SimpleCell" owner:self];
        textField.stringValue = obj;
        return textField;
    }
    
    if ([obj isKindOfClass:[SamLibText class]]) {
        id x = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
        NSAssert(x != nil, @"nil cell");        
        TextCellView * cellView = x;
        SamLibText * text = obj;
        [cellView loadFromText:text withTag:row forTarget:self];        
        return cellView;
    }
    
    NSAssert(NO, @"bugcheck, invalid object");
    return nil;
}



- (IBAction) showComments:(id)sender
{  
    id obj = [_content objectAtIndex:[sender tag]];
    if ([obj isKindOfClass:[SamLibText class]])    
        [[NSApp delegate] showCommentsView: [obj commentsObject: YES]];
}

- (IBAction)toggleFavorite:(id)sender
{   
    NSInteger row = [sender tag];
    id obj = [_content objectAtIndex:row];
    if ([obj isKindOfClass:[SamLibText class]]) {
        
        SamLibText * text = obj;
        
        NSMutableArray * favorites = [SamLibAgent.settings() get: @"favorites" 
                                                           orSet:^id{
                                                               return [NSMutableArray array];
                                                           }];
        
        BOOL isFav = [favorites containsObject:text.key];
        if (isFav)
            [favorites removeObject:text.key];
        else
            [favorites addObject:text.key];
        
        //[sender setImage: [NSImage imageNamed: isFav ? @"bookmark-on.png" : @"bookmark-off.png"]];  
        [sender setImage: [NSImage imageNamed: isFav ? @"bookmark-on.png" : nil]];  

        
        [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] 
                              columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        
    }    
}

- (void) handleSelect:(id)obj
{
    if ([obj isKindOfClass:[SamLibText class]])
        [[NSApp delegate] showTextView: obj];
}

@end