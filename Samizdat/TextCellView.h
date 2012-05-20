//
//  TextCellView.h
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SamLibText;


@interface TextCellView : NSTableCellView

@property (readonly, nonatomic) NSButton *goButton;
@property (readonly, nonatomic) NSButton *tagButton;
@property (readonly, nonatomic) NSButton *commentsButton;
@property (readonly, nonatomic) NSTextField *commentsField;
@property (readonly, nonatomic) NSTextField *sizeField;
@property (readonly, nonatomic) NSTextField *ratingField;
@property (readonly, nonatomic) NSTextField *subinfoField;

- (void) loadFromText: (SamLibText *) text 
              withTag: (NSInteger) tag
            forTarget: (id) target;


@end
