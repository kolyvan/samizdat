//
//  TextCellView.m
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "TextCellView.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibText.h"
#import "SamLibAgent.h"

//#import "HoverButton.h"

@interface TextCellView()  {
    IBOutlet NSButton *_goButton;
    IBOutlet NSButton *_tagButton;
    IBOutlet NSButton *_commentsButton;    
    IBOutlet NSTextField *_commentsField;
    IBOutlet NSTextField *_sizeField;
    IBOutlet NSTextField *_ratingField;
    IBOutlet NSTextField *_subinfoField;    
}

@end

////

@implementation TextCellView

@synthesize goButton = _goButton;
@synthesize tagButton = _tagButton;
@synthesize commentsButton = _commentsButton;
@synthesize commentsField = _commentsField;
@synthesize sizeField = _sizeField;
@synthesize ratingField = _ratingField;
@synthesize subinfoField = _subinfoField;

- (void) loadFromText: (SamLibText *) text 
              withTag: (NSInteger) tag
            forTarget: (id) target
{    
    self.textField.stringValue = text.title;
    self.goButton.target = target;
    self.goButton.action = @selector(select:);
    self.goButton.tag = tag;
    
    NSImage *image = nil;
    NSImage *altImage = nil;
    
    if (text.favorited) {
        image = [NSImage imageNamed: @"bookmark-on.png"];  
        altImage = [NSImage imageNamed: @"bookmark-off.png"];        
    }
    else {
        if (text.flagNew.nonEmpty) {
            
            if ([text.flagNew isEqualToString:@"red"])
                image = [NSImage imageNamed:@"new-red.png"];        
            else if ([text.flagNew isEqualToString:@"brown"])
                image = [NSImage imageNamed:@"new-brown.png"];        
            else if ([text.flagNew isEqualToString:@"gray"])
                image = [NSImage imageNamed:@"new-gray.png"];  
        
            altImage = [NSImage imageNamed: @"bookmark-on.png"];  
            
        } else {                
            //image = [NSImage imageNamed: @"bookmark-off.png"];                  
            altImage = [NSImage imageNamed: @"bookmark-on.png"];
        }
    }
    
    self.tagButton.image = image;  
    self.tagButton.alternateImage = altImage;      
    self.tagButton.action = @selector(toggleFavorite:);
    self.tagButton.target = target;
    self.tagButton.tag = tag;
    
    self.sizeField.stringValue = [text sizeWithDelta: @"\n"];
    self.sizeField.textColor = text.changedSize ? [NSColor blueColor] : [NSColor textColor];
    
    self.commentsField.stringValue = [text commentsWithDelta: @"\n"];    
    self.commentsField.textColor = text.changedComments ? [NSColor blueColor] : [NSColor textColor];
    self.commentsButton.action = @selector(showComments:);
    self.commentsButton.target = target;
    self.commentsButton.tag = tag;
    
    if (text.rating.nonEmpty) {
        self.ratingField.stringValue = [text ratingWithDelta:@"\n"];
        self.ratingField.textColor = text.changedRating ? [NSColor blueColor] : [NSColor textColor];
    } else {
        [self.ratingField setHidden: YES];
        [self.imageView setHidden: YES];        
    }
    
    if (text.note.nonEmpty) {
        self.subinfoField.textColor = text.changedNote ? [NSColor blueColor] : [NSColor textColor];
        self.subinfoField.stringValue = text.note;    
    } else {
        NSString *s = text.group;
        if (!s.nonEmpty) s = text.type;
        if (!s.nonEmpty) s = text.genre;
        if (!s.nonEmpty) s = @"";
        self.subinfoField.stringValue = s;               
        self.subinfoField.textColor = [NSColor textColor];
    }
    
}

@end