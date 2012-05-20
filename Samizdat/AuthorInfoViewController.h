//
//  AuthorInfoViewController.h
//  samlib
//
//  Created by Kolyvan on 18.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Cocoa/Cocoa.h>
#import "KxViewController.h"

@class SamLibAuthor;

@interface AuthorInfoViewController : KxViewController

@property (readonly, nonatomic) SamLibAuthor *author;

- (IBAction)deleteAuthor:(id)sender;
- (IBAction)ignoreAuthor:(id)sender;
- (IBAction)goBack:(id)sender;

@end
