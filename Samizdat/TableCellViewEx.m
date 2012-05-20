//
//  AuthorsCellView.m
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

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
