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
#import "NSDictionary+Kolyvan.h"
#import "SamLibModerator.h"
//#import "SamLibComments.h"
#import "AppDelegate.h"

@interface BanViewController () {
    IBOutlet NSTextField * _banName;
    IBOutlet NSTextField * _banPath;
    IBOutlet NSSlider * _banTolerance;
    IBOutlet NSButton * _banEnabled;    
    IBOutlet NSTableView * _tableView;
    IBOutlet NSTextField *_labelTolerance;
    IBOutlet NSButton *_cancelButton;    
    
}

@property (readwrite, KX_PROP_STRONG) SamLibBan* resetBan;
@property (readwrite, KX_PROP_STRONG) SamLibBan* ban;

@end

@implementation BanViewController

@synthesize ban = _ban, resetBan;

- (void) flagDirty
{       
    [_cancelButton setEnabled:YES];
}

- (id) init
{
    self = [super initWithNibName:@"BanView"];
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

- (void) reset: (id) obj
{        
    if ([obj isKindOfClass:[NSDictionary class]]) {
    
        NSDictionary *dict = obj;
        NSString *name = [dict get: @"name" orElse:@""];
        NSString *path = [dict get: @"path" orElse:@""];        
        NSString *email = [dict get: @"email"];
        NSString *link = [dict get: @"link"];
        
        NSMutableArray *rules = [NSMutableArray array];
        SamLibBanRule *rule;
               
        rule = [[SamLibBanRule alloc] initFromPattern:name
                                             category:SamLibBanCategoryName];
        [rules push:rule];
        
        if (email.nonEmpty) {
            
            rule = [[SamLibBanRule alloc] initFromPattern:email
                                                 category:SamLibBanCategoryEmail];        
            [rules push:rule];
        }
        
        if (link.nonEmpty) {
            
            rule = [[SamLibBanRule alloc] initFromPattern:link
                                                 category:SamLibBanCategoryURL];        
            [rules push:rule];
        }
        
        self.resetBan = nil;
        self.ban = [[SamLibBan alloc] initWithName:KxUtils.format(@"from %@", name)
                                          rules:rules
                                         tolerance:rules.count
                                              path:path];
        
        
    } else if ([obj isKindOfClass:[SamLibBan class]]) {
        
        self.resetBan = obj;
        self.ban = [obj copy];
        
    } else {
        
        SamLibBanRule *rule = [[SamLibBanRule alloc] initFromPattern:@"*" 
                                                            category:SamLibBanCategoryName];        
        self.resetBan = nil;
        self.ban = [[SamLibBan alloc] initWithName:@"noname"
                                             rules:KxUtils.array(rule, nil) 
                                         tolerance:1
                                              path:@""];
        self.ban.enabled = NO;
    }

}

- (void) activate
{
    [super activate];
    
    _banName.stringValue = _ban.name.nonEmpty ? _ban.name : @"";
    _banPath.stringValue = _ban.path.nonEmpty ? _ban.path : @"";    
    _banEnabled.state = _ban.enabled ? NSOnState : NSOffState;
           
    [self refreshTolerance];    
    
    [_tableView reloadData];
    
    [_cancelButton setEnabled:self.resetBan == nil];
}

- (void) deactivate
{
    [super deactivate];
    
    if (self.ban) {
        
        SamLibModerator *moder = [SamLibModerator shared];
        
        if (self.resetBan)
            [moder removeBan:self.resetBan];
        [moder addBan:self.ban];
    }    
}

- (IBAction) cancel :(id)sender
{
    self.ban = nil;
    self.resetBan = nil;
    
    AppDelegate *appDelegate = [NSApp delegate];
    [appDelegate goBack:nil];
}

- (IBAction) insertRow:(id)sender
{
    SamLibBanRule *rule = [[SamLibBanRule alloc] initFromPattern:@"*" 
                                                        category:SamLibBanCategoryName];    
    [_ban addRule:rule];
    
    NSInteger index = _ban.rules.count - 1;

    [_tableView beginUpdates];
    [_tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] 
                      withAnimation:NSTableViewAnimationEffectFade];
    [_tableView scrollRowToVisible:index];
    [_tableView endUpdates];
    
    [self refreshTolerance];
    [self flagDirty];
}

- (IBAction) deleteRow:(id)sender
{    
    NSInteger row = _tableView.selectedRow;
 
    if (row > 0) {
                    
        [_tableView beginUpdates];        
        [_tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
                          withAnimation:NSTableViewAnimationEffectFade];
        [_tableView endUpdates];        
        
        [_ban removeRuleAtIndex:row - 1];
        
        [self refreshTolerance];
        [self flagDirty];
    }
}

- (void) refreshTolerance
{
    CGFloat maxValue = _ban.rules.count;
    CGFloat minValue = maxValue;
    
    for (SamLibBanRule *rule in _ban.rules)
        minValue = MIN(minValue, rule.threshold);
    
    if (minValue > _ban.tolerance)        
        _ban.tolerance = minValue;
    
    if (maxValue < _ban.tolerance)        
        _ban.tolerance = maxValue;

    _banTolerance.minValue  = minValue  * 100;
    _banTolerance.maxValue  = maxValue  * 100;    
    _banTolerance.floatValue = _ban.tolerance * 100;    
    
    [self refreshLabelTolerance];    
}

- (void) refreshLabelTolerance
{
    _labelTolerance.stringValue = KxUtils.format(@"%.2f - %.2f - %.2f", 
                                                 _banTolerance.minValue / 100, 
                                                 _banTolerance.floatValue / 100, 
                                                 _banTolerance.maxValue / 100);
}

- (IBAction) toleranceChanged: (id)sender
{   
    _ban.tolerance = _banTolerance.floatValue / 100;    
    [self refreshLabelTolerance];
    [self flagDirty];
}

- (IBAction) nameFieldChanged: (id)sender
{
    NSString *s =  [sender stringValue];
    if (![s isEqualToString:_ban.name]) {
        _ban.name = s;
        [self flagDirty];        
    }
}

- (IBAction) pathFieldChanged: (id)sender
{
    NSString *s =  [sender stringValue];
    if (![s isEqualToString:_ban.path]) {
        _ban.path = s;
        [self flagDirty];        
    }
}

- (IBAction) enableButtonChanged: (id)sender
{
    BOOL enabled = _banEnabled.state == NSOnState;
    if (_ban.enabled != enabled) {
        _ban.enabled = enabled;
        [self flagDirty];        
    }    
}

- (SamLibBanRule *) getRuleForRow: (NSInteger) row
{
    return [_ban.rules objectAtIndex:row - 1];  
}


#pragma mark - textview delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return _ban.rules.count + 1;
}

- (NSCell *)tableView:(NSTableView *)tableView 
dataCellForTableColumn:(NSTableColumn *)tableColumn 
                  row:(NSInteger)row
{ 
    if (tableColumn) {
    
        if ([tableColumn.identifier isEqualToString:@"threshold"]) {
            
            SamLibBanRule *rule = [self getRuleForRow:row];
            
            if (rule.category == SamLibBanCategoryURL || 
                rule.category == SamLibBanCategoryEmail ||
                rule.option == SamLibBanRuleOptionRegex) {
                
                static NSCell *cell = nil; // empty cell (no value)
                if (!cell)
                    cell = [[NSCell alloc] init];            
                return cell;
            }
        } 
        
        return [tableColumn dataCellForRow:row]; 
    }
        
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
    if (!tableColumn && row == 0)
        return @" - click here for add new rule - ";
        
    SamLibBanRule *rule = [self getRuleForRow:row];    
    
    if ([tableColumn.identifier isEqualToString:@"category"]) {

        switch (rule.category) {
            case SamLibBanCategoryName:     return @"Name";
            case SamLibBanCategoryEmail:    return @"Email";
            case SamLibBanCategoryURL:      return @"URL";
            case SamLibBanCategoryText:     return @"Text";                
        }
        
    } else if ([tableColumn.identifier isEqualToString:@"option"]) {
        
        switch (rule.option) {
            case SamLibBanRuleOptionNone:    return @"None";
            case SamLibBanRuleOptionSubs:    return @"Subs";
            case SamLibBanRuleOptionRegex:   return @"Regex";
            case SamLibBanRuleOptionLink:    return @"Link";                
        }            
        
    } else if ([tableColumn.identifier isEqualToString:@"pattern"]) {

        return rule.pattern;
        
    } else if ([tableColumn.identifier isEqualToString:@"threshold"]) {
        
        return [NSNumber numberWithInt: rule.threshold * 100];
    } 
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)value 
   forTableColumn:(NSTableColumn *)tableColumn 
              row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"delete"]) {        
        return;
    }
    
    SamLibBanRule *rule = [self getRuleForRow:row];
    
    if ([tableColumn.identifier isEqualToString:@"category"]) {
        
        if ([value isEqualToString:@"Name"])
            rule.category = SamLibBanCategoryName;
        else if ([value isEqualToString:@"Email"])
            rule.category = SamLibBanCategoryEmail;
        else if ([value isEqualToString:@"URL"])
            rule.category = SamLibBanCategoryURL;
        else if ([value isEqualToString:@"Text"])
            rule.category = SamLibBanCategoryText;    
        else {
            NSAssert(false, @"unknown SamLibBanCategory");
        }
        
    } else if ([tableColumn.identifier isEqualToString:@"option"]) {
        
        if ([value isEqualToString:@"None"])
            rule.option = SamLibBanRuleOptionNone;
        else if ([value isEqualToString:@"Subs"])
            rule.option = SamLibBanRuleOptionSubs;
        else if ([value isEqualToString:@"Regex"])
            rule.option = SamLibBanRuleOptionRegex;
        else {
            NSAssert(false, @"unknown SamLibBanRuleOption");
        }    
        
    } else if ([tableColumn.identifier isEqualToString:@"pattern"]) {
        
        rule.pattern = (NSString *)value;
        
    } else if ([tableColumn.identifier isEqualToString:@"threshold"]) {
        
        rule.threshold = [value integerValue] / 100.0;
        
        [self refreshTolerance];
    } 
    
    [self flagDirty];
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
