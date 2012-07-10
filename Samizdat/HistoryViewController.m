//
//  HistoryViewController.m
//  samlib
//
//  Created by Kolyvan on 10.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "HistoryViewController.h"
#import "AppDelegate.h"
#import "KxUtils.h"
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibHistory.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface HistoryTableCellView : NSTableCellView
@property (readwrite, nonatomic) IBOutlet NSButton *goButton;
@property (readwrite, nonatomic) IBOutlet NSTextField *nameField;
@property (readwrite, nonatomic) IBOutlet NSTextField *timestampField;
@end

@implementation HistoryTableCellView
@synthesize goButton = _goButton;
@synthesize nameField = _nameField;
@synthesize timestampField = _timestampField;
@end

@interface HistoryViewController ()

@end

@implementation HistoryViewController

- (id)init
{
    self = [super initWithNibName:@"HistoryView"];
    if (self) {
    }    
    return self;
}
- (void) reloadTableView
{
    _content = [[SamLibHistory shared].history reverse];
    [_tableView reloadData];    
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    id obj = [_content objectAtIndex:row];
    
    id x = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    NSAssert(x != nil, @"nil cell");
    
    SamLibHistoryEntry *p = obj;        
    HistoryTableCellView * cell = x;
    
    BOOL found = [[SamLibModel shared] findTextByKey:p.key] != nil;
    
    cell.textField.stringValue = p.title;
    cell.nameField.stringValue = p.name;
    cell.timestampField.stringValue = p.timestamp.shortRelativeFormatted;
    
    if (p.category == SamLibHistoryCategoryText)
        cell.imageView.image = [NSImage imageNamed:@"book.png"];
    else
        cell.imageView.image = [NSImage imageNamed:@"comments3.png"];
    
    if (found) {
        
        cell.goButton.target = self;
        cell.goButton.action = @selector(select:);
        cell.goButton.tag = row;
        [cell.goButton setHidden:NO];        
        cell.textField.textColor = [NSColor textColor];        
        
    } else {
        
        cell.goButton.target = nil;
        cell.goButton.action = nil;
        [cell.goButton setHidden:YES];
        cell.textField.textColor = [NSColor grayColor];
    }
    
    return cell;
}

- (void) handleSelect:(id)obj
{   
    SamLibHistoryEntry *p = obj; 
    SamLibText *text = [[SamLibModel shared] findTextByKey:p.key];
    if (p.category == SamLibHistoryCategoryText)
        [[NSApp delegate] showTextView: text];
    else
        [[NSApp delegate] showCommentsView: [text commentsObject: YES]];
}

- (void) reload: (id) sender;
{       
}

@end
