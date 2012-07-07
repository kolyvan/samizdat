//
//  BansViewController.h
//  samlib
//
//  Created by Kolyvan on 07.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxArc.h"
#import "KxViewController.h"


@interface BansViewController : KxViewController<NSTableViewDataSource, NSTableViewDelegate>

- (IBAction) insertRow:(id)sender;
- (IBAction) deleteRow:(id)sender;
- (IBAction) editRow:(id)sender;


@end
