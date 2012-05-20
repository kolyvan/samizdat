//
//  AuthorsCellView.h
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TableCellViewEx : NSTableCellView
@property (readonly, nonatomic) NSButton *goButton;
@property (readonly, nonatomic) NSTextField *sizeField;
@end
