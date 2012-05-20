//
//  TestViewController.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "TestViewController.h"

#import "KxUtils.h"

@implementation TestView

- (void)drawRect:(NSRect)dirtyRect 
{       
    [[NSColor redColor] set];    
    NSRect  bounds = [self bounds];
    NSRectFill(bounds);      
}

@end

@interface TestViewController () {
    IBOutlet NSTableView *_tableView;
    
    NSArray * _content;
}

@end

@implementation TestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"TestView"];
    if (self) {
        _content = KxUtils.array(@"111111111111", 
                                 @"222222222222",
                                 @"333333333333",
                                 @"444444444444",nil); 
    }    
    return self;
}

- (void) awakeFromNib
{
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _content.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    id x = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    NSLog(@"%@", x);
    
    NSTableCellView * cellView = x;
    NSTextField *result = cellView.textField;
    
    result.stringValue = [_content objectAtIndex:row];
    return result;
    
}



@end

