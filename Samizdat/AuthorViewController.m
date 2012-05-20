//
//  AuthorViewController.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "AuthorViewController.h"
#import "KxHUD.h"
#import "AppDelegate.h"
#import "TableCellViewEx.h"
#import "TextCellView.h"

#import "KxUtils.h"
#define NSNUMBER_SHORTHAND
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "KxTuple2.h"

#import "SamLibModel.h"
#import "SamLibAgent.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibParser.h"

#import "DDLog.h"

extern int ddLogLevel;

////

// sorty by group,type,genre,title

static NSArray * sortTexts(NSArray * array) {
    
    static NSDictionary * typeToIdx;
        
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        KxTuple2 * tuple = [[SamLibParser.listOfGroups() zipWithIndex] unzip];            
        typeToIdx = [[NSDictionary alloc] initWithObjects: tuple.second forKeys:tuple.first];
    });
    
    return [array sortWith:^(id left, id right) {
        
        SamLibText * l = left;
        SamLibText * r = right;        
        
        NSComparisonResult res = NSOrderedSame;
        
        if (l.group.nonEmpty &&
            r.group.nonEmpty)
            
            res = [l.group compare: r.group];
        
        else if (l.group.nonEmpty)
            
            res =  NSOrderedAscending;
        
        else if (r.group.nonEmpty)
            
            res =  NSOrderedDescending;
        
        
        if (res == NSOrderedSame) {
            
            NSNumber * lidx = [typeToIdx get:l.type orElse:$integer(-1)];
            NSNumber * ridx = [typeToIdx get:r.type orElse:$integer(-1)];
            
            res = [lidx compare: ridx];            
             if (res == NSOrderedSame) {            
                 res = [l.genre compare: r.genre];            
                 if (res == NSOrderedSame) {
                     res = [l.title compare:r.title];
                 }            
             }
        }
        
        return res;
        
    }];
}

////

@interface AuthorViewController () {
    SamLibAuthor *_author;
}
@end

////

@implementation AuthorViewController

@dynamic author;
- (SamLibAuthor *) author
{
    return _author;
}

- (void) reset:(id) obj
{
    NSAssert([obj isKindOfClass: [SamLibAuthor class]], @"invalid class");
    KX_RELEASE(_author);
    _author = KX_RETAIN(obj);    
}

- (void) dealloc 
{
    KX_RELEASE(_author);
    KX_SUPER_DEALLOC();
}

- (NSArray *) loadContent
{
    NSArray * sorted = sortTexts(_author.texts);    
    NSMutableArray * ma = [NSMutableArray array];
    
    [ma push: _author];
    
    NSString * currentGroup = nil;
    
    for (SamLibText *text in sorted) {
        
        NSString *group = nil;
        
        if (text.group.nonEmpty)
            group = text.group;        
        else if (text.type.nonEmpty)
            group = text.type;            
        
        if (group.nonEmpty &&
            ![currentGroup isEqualTo:group]) {
            [ma push:group];
            KX_RELEASE(currentGroup);
            currentGroup = KX_RETAIN(group);            
        }        
        
        if (text.group.first != '@')        
            [ma push:text];
    }
    
    KX_RELEASE(currentGroup);
    return ma;
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row 
{
    id obj = [_content objectAtIndex:row];
    
    if ([obj isKindOfClass:[SamLibAuthor class]])
        return 36;
    
    return [super tableView: tableView heightOfRow: row];    
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    id obj = [_content objectAtIndex:row];
    
    if ([obj isKindOfClass:[SamLibAuthor class]]) {
        
        TableCellViewEx *cellView = [tableView makeViewWithIdentifier:@"AuthorCell" owner:self];
        SamLibAuthor * author = obj;
        cellView.textField.stringValue = author.name.nonEmpty ? author.name : author.path;
        cellView.goButton.action = @selector(showInfo:);
        cellView.goButton.target = self;
        return cellView;
    }
    
    if ([obj isKindOfClass:[NSString class]]) {
        
        NSString * s = obj;
    
        if (s.first == '@') {
            
            TableCellViewEx *cellView = [tableView makeViewWithIdentifier:@"GroupCell" owner:self];        
            cellView.textField.stringValue = s.tail;
            cellView.goButton.action = @selector(showGroup:);
            cellView.goButton.target = self;
            cellView.goButton.tag = row;
            
            return cellView;
        }
    }
    
    return [super tableView: tableView
         viewForTableColumn: tableColumn
                        row: row];
}

- (void) reload: (id) sender
{   
    AppDelegate *app = [NSApp delegate];    
    
    if ([app startReload:self 
             withMessage:_author.name]) {
        
        [_author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {
            
            [app finishReload:status 
                  withMessage:status == SamLibStatusFailure ? error : _author.name];    
            
            if (status == SamLibStatusSuccess)
                [self reloadTableView];
            
        }];    
    }
}

- (void) doShowGroup: (NSString *) groupName
{
    NSArray * group = [_author.texts filter:^BOOL(id elem) {
        SamLibText * p = elem;
        return [p.group isEqualToString:groupName];
    }];
    
    [[NSApp delegate] showTextsGroup:group]; 
}

- (void) showGroup: (id) sender
{
    id obj = [_content objectAtIndex:[sender tag]];
    [self doShowGroup: obj];    
}

- (void) showInfo:(id)sender
{
    [[NSApp delegate] showAuthorInfoView:_author];    
}

- (void) handleSelect:(id)obj
{
    if ([obj isKindOfClass:[SamLibAuthor class]]) {
        [self showInfo:nil];
        return;
    }
    
     if ([obj isKindOfClass:[NSString class]]) {
         NSString * group = obj;
         if (group.first == '@') {
             [self doShowGroup: group];    
             return;
         }
     }
    
    [super handleSelect:obj];
}

/*
- (void) handleSelect:(id)obj
{
    if ([obj isKindOfClass:[NSString class]]) {
                                
        NSString * group = obj;
        
        NSRange range = {NSNotFound,0};
        NSInteger n = 0;
        
        for (id p in _content) {
            
            if ([p isKindOfClass:[SamLibText class]]) {
                SamLibText *text = p;
                
                if ([text.group isEqualToString: group]) {
                    
                    if (range.location == NSNotFound) {
                        range.location = n;
                    } 
                    
                    range.length++;                                       
                }
            }
            
            ++n;
        }
        
        if (range.location != NSNotFound) {
            
            DDLogInfo(@"remove %@ - %ld %ld", obj, range.location, range.length);
            
            NSMutableArray * ma = [_content mutableCopy];
            [ma  removeObjectsInRange:range];
            KX_RELEASE(_content);
            _content = ma;
            
            [_tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range] 
                              withAnimation:YES];            
        } else {
        
            //[_tableView insertRowsAtIndexes:(NSIndexSet *)
            //                  withAnimation:
        }
        
        return;
    }
    
    [super handleSelect:obj];
}
*/

@end
