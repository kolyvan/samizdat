//
//  AuthorsCellView.m
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "TableCellViewEx.h"

@interface TableCellViewEx()  {
    IBOutlet NSButton *_goButton;
    IBOutlet NSTextField *_sizeField;
}
@end

@implementation TableCellViewEx
@synthesize goButton = _goButton;
@synthesize sizeField = _sizeField;
@end
