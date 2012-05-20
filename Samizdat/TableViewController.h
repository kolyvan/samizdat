//
//  TableViewController.h
//  samlib
//
//  Created by Kolyvan on 17.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "KxViewController.h"

////

@interface SamizdatTableView : NSTableView
@end

// abstract class

@interface TableViewController : KxViewController<NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTableView *_tableView;   
    NSArray * _content;
}

- (void) reloadTableView;
- (void) reloadAuthors: (NSArray *) authors 
           withMessage: (NSString *) message;

- (IBAction)select:(id)sender;

// abstract
- (NSArray *) loadContent;
- (void) handleSelect: (id) obj;

@end
