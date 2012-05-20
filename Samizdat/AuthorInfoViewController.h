//
//  AuthorInfoViewController.h
//  samlib
//
//  Created by Kolyvan on 18.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxViewController.h"

@class SamLibAuthor;

@interface AuthorInfoViewController : KxViewController

@property (readonly, nonatomic) SamLibAuthor *author;

- (IBAction)deleteAuthor:(id)sender;
- (IBAction)ignoreAuthor:(id)sender;
- (IBAction)goBack:(id)sender;

@end
