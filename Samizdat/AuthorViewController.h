
//
//  AuthorViewController.h
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TextsViewController.h"

@class SamLibAuthor;

@interface AuthorViewController : TextsViewController

@property (readonly, nonatomic) SamLibAuthor *author;

@end
