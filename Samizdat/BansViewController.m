//
//  BansViewController.m
//  samlib
//
//  Created by Kolyvan on 07.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "BansViewController.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModerator.h"
#import "SamLibComments.h"
#import "AppDelegate.h"

@interface BansViewController () {
    IBOutlet NSTableView * _tableView;
}
@end

@implementation BansViewController

- (id) init
{
    self = [super initWithNibName:@"BansView"];
    if (self) {
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];   
}

- (void) activate
{
    [super activate];    
    [_tableView reloadData];
}

- (SamLibBan *) getBanForRow: (NSInteger) row
{
    SamLibModerator *moder = [SamLibModerator shared];
    NSAssert(moder.allBans.nonEmpty, @"empty array");
    return [moder.allBans objectAtIndex:row - 1];
}

- (IBAction) insertRow:(id)sender
{
    SamLibBanRule *rule = [[SamLibBanRule alloc] initFromPattern:@"*" 
                                                        category:SamLibBanCategoryName];        

    SamLibBan *ban = [[SamLibBan alloc] initWithName:@"noname"
                                               rules:KxUtils.array(rule, nil) 
                                           tolerance:1
                                                path:@""];
    ban.enabled = NO;
    
    SamLibModerator *moder = [SamLibModerator shared];
    [moder addBan:ban];

    NSInteger index = moder.allBans.count - 1;
     
    [_tableView beginUpdates];
    [_tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] 
                      withAnimation:NSTableViewAnimationEffectFade];
    [_tableView scrollRowToVisible:index];
    [_tableView endUpdates];    
}

- (IBAction) deleteRow:(id)sender
{    
    NSInteger row = _tableView.selectedRow;
    
    if (row > 0) {
        
        [_tableView beginUpdates];        
        [_tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                          withAnimation:NSTableViewAnimationEffectFade];
        [_tableView endUpdates];                
        
        SamLibModerator *moder = [SamLibModerator shared];
        [moder removeBanAtIndex:row - 1];
    }
}

- (IBAction) editRow:(id)sender
{
    NSInteger row = _tableView.selectedRow;
    
    if (row > 0) {                
        AppDelegate *appDelegate = [NSApp delegate];
        [appDelegate showBanView:[self getBanForRow: row]];
    }
}

#pragma mark - textview delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    SamLibModerator *moder = [SamLibModerator shared];
    return moder.allBans.count + 1;
}

- (NSCell *)tableView:(NSTableView *)tableView 
dataCellForTableColumn:(NSTableColumn *)tableColumn 
                  row:(NSInteger)row
{
    if (tableColumn)
        return [tableColumn dataCellForRow:row];    
    
    if (row == 0) {
        static NSTextFieldCell *cell = nil;
        if (!cell) {
            cell = [[NSTextFieldCell alloc] initTextCell:@""];
            cell.textColor = [NSColor blueColor];
            cell.alignment = NSCenterTextAlignment;            
        }
        return cell;
    }
    
    return nil;
}

- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
            row:(NSInteger)row
{
    if (!tableColumn && row == 0) {
        return @" - click here for add new ban - ";
    }
    
    if (row > 0) {
            
        SamLibBan *ban = [self getBanForRow: row];
        
        if ([tableColumn.identifier isEqualToString:@"enabled"]) {
            
            return [NSNumber numberWithInteger:ban.enabled ? NSOnState : NSOffState];
            
        } else if ([tableColumn.identifier isEqualToString:@"name"]) {
            
            return ban.name;
            
        } else if ([tableColumn.identifier isEqualToString:@"path"]) {
            
            return ban.path;
            
        }  else if ([tableColumn.identifier isEqualToString:@"test"]) {
            
            switch (ban.option) {
                    
                case SamLibBanTestOptionAll:     return @"All";
                case SamLibBanTestOptionGuests:  return @"Guests";
                case SamLibBanTestOptionSamizdat:return @"Samlib";
            }               
        }
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)value 
   forTableColumn:(NSTableColumn *)tableColumn 
              row:(NSInteger)row
{
    if (row > 0) {
    
        if ([tableColumn.identifier isEqualToString:@"delete"] ||
            [tableColumn.identifier isEqualToString:@"edit"])
            return;
        
        SamLibBan *ban = [self getBanForRow: row];
        
        if ([tableColumn.identifier isEqualToString:@"enabled"]) {
            
            ban.enabled = [value integerValue] == NSOnState;
            
        } else if ([tableColumn.identifier isEqualToString:@"name"]) {
            
            ban.name = value;
            
        } else if ([tableColumn.identifier isEqualToString:@"path"]) {
            
            ban.path = value;
            
        } else if ([tableColumn.identifier isEqualToString:@"test"]) {
            
            if ([value isEqualToString:@"All"])
                ban.option = SamLibBanTestOptionAll;
            else if ([value isEqualToString:@"Guests"])
                ban.option = SamLibBanTestOptionGuests;
            else if ([value isEqualToString:@"Samlib"])
                ban.option = SamLibBanTestOptionSamizdat;     
            else {
                NSAssert(false, @"unknown SamLibBanTestOption");
            }   
        }
            
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger row = _tableView.selectedRow;
    
    if (row == 0) {
        [self insertRow:nil];
        [_tableView deselectRow:0];
    }
}

@end
