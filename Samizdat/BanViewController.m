//
//  AddBanViewController.m
//  samlib
//
//  Created by Kolyvan on 06.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "BanViewController.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModerator.h"

@interface BanViewController () {
    IBOutlet NSTextField * _banName;
    IBOutlet NSSlider * _banTolerance;
    IBOutlet NSButton * _banEnabled;    
    IBOutlet NSTableView * _tableView;

//    IBOutlet NSTextField * _textSymptomPattern;
//    IBOutlet NSSlider * _sliderSymptomThreshold;
//    IBOutlet NSPopUpButton *_popupCategory;
}

@property (readwrite, KX_PROP_STRONG) SamLibBan* ban;

@end

@implementation BanViewController

@synthesize ban = _ban;

- (id) init
{
    self = [super initWithNibName:@"BanView"];
    if (self) {            
     
        NSArray *bans = [SamLibModerator shared].allBans;
        if (bans.nonEmpty)
            self.ban = bans.first;
    
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    [_tableView setDelegate:self];
    [_tableView setDataSource:self];   
}

- (void) reset: (id) obj
{
    //self.ban = obj;
}

- (void) activate
{
    [super activate];
    
    _banName.stringValue = _ban.name.nonEmpty ? _ban.name : @"";
    _banTolerance.floatValue = _ban.tolerance; 
    _banEnabled.state = _ban.enabled ? NSOnState : NSOffState;
    
    [_tableView reloadData];
}

- (IBAction) doneBan :(id)sender
{
}

- (IBAction) cancel :(id)sender
{
}

- (IBAction) insertRow:(id)sender
{
    SamLibBanSymptom *symptom = [[SamLibBanSymptom alloc] initFromPattern:@"*" 
                                                                 category:SamLibBanCategoryName
                                                                threshold:1];    
    [_ban addSymptom:symptom];
    
    NSInteger index = _ban.symptoms.count - 1;

    [_tableView beginUpdates];
    [_tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] 
                      withAnimation:NSTableViewAnimationEffectFade];
    [_tableView scrollRowToVisible:index];
    [_tableView endUpdates];
}

- (IBAction) deleteRow:(id)sender
{    
    NSInteger row = _tableView.selectedRow;
 
    if (row != -1) {
                    
        [_tableView beginUpdates];        
        [_tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                          withAnimation:NSTableViewAnimationEffectFade];
        [_tableView endUpdates];        
        
        [_ban removeSymptomAtIndex:row];                
    }
}


#pragma mark - textview delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return _ban.symptoms.count;
}

- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
            row:(NSInteger)row
{
    SamLibBanSymptom *symptom = [_ban.symptoms objectAtIndex:row];
    
    if ([tableColumn.identifier isEqualToString:@"category"]) {

        switch (symptom.category) {
            case SamLibBanCategoryName:     return @"Name";
            case SamLibBanCategoryEmail:    return @"Email";
            case SamLibBanCategoryURL:      return @"URL";
            case SamLibBanCategoryWord:     return @"Word";                
        }
        
    } else if ([tableColumn.identifier isEqualToString:@"pattern"]) {

        return symptom.pattern;
        
    } else if ([tableColumn.identifier isEqualToString:@"threshold"]) {
        
        return [NSNumber numberWithInt: symptom.threshold * 100];
    } 
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)value 
   forTableColumn:(NSTableColumn *)tableColumn 
              row:(NSInteger)row
{
    SamLibBanSymptom *symptom = [_ban.symptoms objectAtIndex:row];
    
    if ([tableColumn.identifier isEqualToString:@"category"]) {
        
        if ([value isEqualToString:@"Name"])
            symptom.category = SamLibBanCategoryName;
        else if ([value isEqualToString:@"Email"])
            symptom.category = SamLibBanCategoryEmail;
        else if ([value isEqualToString:@"URL"])
            symptom.category = SamLibBanCategoryURL;
        else if ([value isEqualToString:@"Word"])
            symptom.category = SamLibBanCategoryWord;
        
        
    } else if ([tableColumn.identifier isEqualToString:@"pattern"]) {
        
        symptom.pattern = (NSString *)value;
        
    } else if ([tableColumn.identifier isEqualToString:@"threshold"]) {
        
        symptom.threshold = [value integerValue] / 100.0;
    } 
    
}

@end
