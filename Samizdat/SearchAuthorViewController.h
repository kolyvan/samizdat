//
//  SearchAuthorViewController.h
//  samlib
//
//  Created by Kolyvan on 19.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "KxViewController.h"

@interface SearchAuthorViewController : KxViewController<NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

- (IBAction) cancel: (id) sender;

@end
