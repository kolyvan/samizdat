//
//  AddBanViewController.h
//  samlib
//
//  Created by Kolyvan on 06.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxArc.h"
#import "KxViewController.h"

@class SamLibBan;

@interface BanViewController : KxViewController<NSTableViewDataSource, NSTableViewDelegate>

- (IBAction) cancel :(id)sender;

- (IBAction) insertRow:(id)sender;
- (IBAction) deleteRow:(id)sender;

- (IBAction) toleranceChanged: (id)sender;
- (IBAction) nameFieldChanged: (id)sender;
- (IBAction) pathFieldChanged: (id)sender;
- (IBAction) enableButtonChanged: (id)sender;

@end
