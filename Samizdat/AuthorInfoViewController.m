//
//  AuthorInfoViewController.m
//  samlib
//
//  Created by Kolyvan on 18.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "AuthorInfoViewController.h"
#import "AppDelegate.h"
#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "KxLinkLabel.h"


@interface AuthorInfoViewController () {
    IBOutlet KxLinkLabel * _nameField;
    IBOutlet NSTextField * _subtitleField;
    IBOutlet NSTextField * _wwwField;
    IBOutlet NSTextField * _emailField;
    IBOutlet NSTextField * _updatedField;    
    IBOutlet NSTextField * _sizeField;        
    IBOutlet NSTextField * _visitorsField;
    IBOutlet NSTextField * _aboutField;
    IBOutlet NSLevelIndicator *_ratingIndicator;
    IBOutlet NSButton * _ignoreButton;    
    
    SamLibAuthor * _author;  
}
@end

@implementation AuthorInfoViewController

@dynamic author;
- (SamLibAuthor *) author
{
    return _author;
}

- (id) init
{
    self = [super initWithNibName:@"AuthorInfoView"];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    KX_RELEASE(_author);
    KX_SUPER_DEALLOC();
}

- (void) reset:(id) obj
{
    NSAssert([obj isKindOfClass: [SamLibAuthor class]], @"invalid class");
    KX_RELEASE(_author);
    _author = KX_RETAIN(obj);    
}

- (void) activate
{    
    _nameField.stringValue = _author.name.nonEmpty ? _author.name : @"-";    
    _nameField.url = _author.url;    
    _nameField.toolTip = _author.url;        
    _subtitleField.stringValue = _author.title.nonEmpty ? _author.title : @"-";
    _wwwField.stringValue = _author.www.nonEmpty ? _author.www : @"-";
    _emailField.stringValue = _author.email.nonEmpty ? _author.email : @"-";
    _updatedField.stringValue = _author.updated.nonEmpty ? _author.updated : @"-";
    _sizeField.stringValue = _author.size.nonEmpty ? _author.size : @"-";
    _visitorsField.stringValue = _author.visitors.nonEmpty ? _author.visitors : @"-";   
    _aboutField.stringValue = _author.about.nonEmpty ? _author.about : @"";   ;
    _ratingIndicator.floatValue = _author.ratingFloat;
    
    [super activate];
}

- (IBAction)deleteAuthor:(id)sender
{
    [[NSApp delegate] deleteAuthor:nil];    
}

- (IBAction)ignoreAuthor:(id)sender
{
}

- (IBAction)goBack:(id)sender
{
    [[NSApp delegate] showAuthorView:_author];
}


@end
