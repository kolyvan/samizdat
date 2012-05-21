//
//  AuthorsViewController.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "AuthorsViewController.h"
#import "TableCellViewEx.h"
#import "AppDelegate.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "DDLog.h"


extern int ddLogLevel;

///// 

@implementation AuthorsViewController

- (id)init
{
    self = [super initWithNibName:@"AuthorsView"];
    if (self) {
    }    
    return self;
}

- (NSArray *) loadContent
{   
    NSArray *authors = [[SamLibModel shared].authors sortWith:^NSComparisonResult(id obj1, id obj2){
        
        SamLibAuthor *l = obj1;
        SamLibAuthor *r = obj2;        
        
        BOOL li = l.ignored;
        BOOL ri = r.ignored;        
        
        if (li == ri)
            return [l.name compare:r.name];
        else if (li) 
            return NSOrderedDescending;
        else
            return NSOrderedAscending;        
        
    }];
    
    NSMutableArray * ma = [NSMutableArray array];            
    for (SamLibAuthor *author in authors) {            
        [ma push:author];    
        for (SamLibText *text in author.texts)
            if (text.changedSize)
                [ma push:text];
    }
    return ma;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row 
{    
    id obj = [_content objectAtIndex:row];
    return [obj isKindOfClass:[SamLibAuthor class]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row 
{
    id obj = [_content objectAtIndex:row];
    
    if ([obj isKindOfClass:[SamLibAuthor class]])
        return [tableView rowHeight];
    else 
        return 24;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    id obj = [_content objectAtIndex:row];
    
    if ([obj isKindOfClass:[SamLibText class]]) {
        
        id x = [tableView makeViewWithIdentifier:@"TextCell" owner:self];
        NSAssert(x != nil, @"nil cell");
       
        SamLibText * text = obj;        
        TableCellViewEx * cellView = x;
        cellView.textField.stringValue = text.title;
        cellView.sizeField.stringValue = KxUtils.format(@"%+ldk", text.deltaSize);
        cellView.goButton.target = self;
        cellView.goButton.action = @selector(select:);
        cellView.goButton.tag = row;
        return cellView;
    }
    
    if ([obj isKindOfClass:[SamLibAuthor class]]) {
    
        id x = [tableView makeViewWithIdentifier:@"AuthorCell" owner:self];
        NSAssert(x != nil, @"nil cell");
        
        SamLibAuthor * author = obj;
        TableCellViewEx * cellView = x;                
        cellView.textField.stringValue =  author.name.nonEmpty ? author.name : author.path;
        cellView.goButton.target = self;
        cellView.goButton.action = @selector(select:);
        cellView.goButton.tag = row;   
        cellView.textField.textColor = author.ignored ? [NSColor grayColor] : [NSColor textColor];
        
        return cellView;        
    }
    
    NSAssert(NO, @"bugcheck, invalid object");
    return nil;
    
}

- (void) handleSelect:(id)obj
{   
    if ([obj isKindOfClass:[SamLibText class]]) {
        [[NSApp delegate] showTextView: obj];
    }
    
    if ([obj isKindOfClass:[SamLibAuthor class]]) {
        [[NSApp delegate] showAuthorView: obj];
    }
}

- (void) reload: (id) sender;
{   
    [super reloadAuthors:[SamLibModel shared].authors 
             withMessage:locString(@"authors")];
}

@end
