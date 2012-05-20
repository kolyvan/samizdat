//
//  AddAuthorViewController.h
//  samizdat
//
//  Created by Konstantin Boukreev on 23.04.12.
//  Copyright 2012 github.com/kolyvan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxViewController.h"

@class SamLibAuthor;

@interface AddAuthorViewController : KxViewController

- (IBAction) urlChanged: (id) sender;
- (IBAction) addAuthor: (id) sender;
- (IBAction) cancel: (id) sender;

@end
