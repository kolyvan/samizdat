//
//  AddAuthorViewController.h
//  samizdat
//
//  Created by Konstantin Boukreev on 23.04.12.
//  Copyright 2012 github.com/kolyvan. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import <Cocoa/Cocoa.h>
#import "KxViewController.h"

@class SamLibAuthor;

@interface AddAuthorViewController : KxViewController<NSTextFieldDelegate>

- (IBAction) fetchPressed:(id)sender;
- (IBAction) urlChanged: (id) sender;
- (IBAction) addAuthor: (id) sender;
- (IBAction) cancel: (id) sender;

@end
