//
//  SearchAuthorViewController.h
//  samlib
//
//  Created by Kolyvan on 19.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Cocoa/Cocoa.h>

#import "KxViewController.h"

@interface SearchAuthorViewController : KxViewController<NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

- (IBAction) cancel: (id) sender;

@end
