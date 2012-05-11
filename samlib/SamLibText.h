//
//  SamLibText.h
//  samlib
//
//  Created by Kolyvan on 09.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KxArc.h"
#import "SamLib.h"

typedef void (^UpdateTextBlock)(SamLibText *text, SamLibStatus status, NSString *error);

typedef enum {
    
    SamLibTextChangedNone        = 0,        
    SamLibTextChangedSize        = 1 << 0,    
    SamLibTextChangedNote        = 1 << 1,    
    SamLibTextChangedComments    = 1 << 2,
    SamLibTextChangedRating      = 1 << 3,        
    SamLibTextChangedCopyright   = 1 << 4,        
    SamLibTextChangedTitle       = 1 << 5,       
    SamLibTextChangedGenre       = 1 << 6,          
    SamLibTextChangedGroup       = 1 << 7,
    SamLibTextChangedType        = 1 << 8,    
    SamLibTextChangedRemoved     = 1 << 9,    
    
} SamLibTextChanged;

// 
@class SamLibComments;

@interface SamLibText : SamLibBase {
@protected    

    NSString * _copyright;
    NSString * _title;
    NSString * _size;
    NSString * _comments;        
    NSString * _note;
    NSString * _genre;
    NSString * _group;
    NSString * _type;
    NSString * _rating;        
    NSString * _flagNew;
    NSString * _lastModified;
    NSString * _diffResult;
    NSDate * _filetime;    

    SamLibTextChanged _changedFlag;        
    //BOOL _favorited;    
    
    KX_WEAK SamLibAuthor * _author;
}

@property (readonly, nonatomic) NSString * copyright;
@property (readonly, nonatomic) NSString * title;
@property (readonly, nonatomic) NSString * size;
@property (readonly, nonatomic) NSString * comments;
@property (readonly, nonatomic) NSString * note;
@property (readonly, nonatomic) NSString * genre;
@property (readonly, nonatomic) NSString * group;
@property (readonly, nonatomic) NSString * type;
@property (readonly, nonatomic) NSString * rating;
@property (readonly, nonatomic) NSString * flagNew;
//@property (readonly, nonatomic) BOOL favorited;

@property (readonly, nonatomic) SamLibTextChanged changedFlag;
@property (readonly) BOOL changedSize;
@property (readonly) BOOL changedNote;
@property (readonly) BOOL changedComments;
@property (readonly) BOOL changedRating;
@property (readonly) BOOL changedCopyright;
@property (readonly) BOOL changedTitle;
@property (readonly) BOOL changedGenre;
@property (readonly) BOOL changedGroup;
@property (readonly) BOOL changedType;
@property (readonly) BOOL isRemoved;

@property (readonly) NSString * key;
@property (readonly, KX_PROP_WEAK) SamLibAuthor * author;

@property (readonly, nonatomic) NSDate * filetime;
@property (readonly, nonatomic) NSString * lastModified;
@property (readonly, nonatomic) NSString * diffResult;
@property (readonly, nonatomic) NSString * htmlFile;
@property (readonly, nonatomic) NSString * diffFile;
@property (readonly, nonatomic) BOOL canUpdate;
@property (readonly, nonatomic) BOOL canMakeDiff;


// comments

+ (id) fromDictionary: (NSDictionary *) dict 
           withAuthor: (SamLibAuthor *) author;

- (id) initFromDictionary: (NSDictionary *) dict
                 withPath: (NSString *)path
                andAuthor: (SamLibAuthor *) author;

- (void) updateFromDictionary: (NSDictionary *) dict;

- (NSDictionary *) toDictionary;

- (void) flagAsRemoved;

- (void) update: (UpdateTextBlock) block
      formatter: (NSString *(^)(NSString *)) formatter;

- (void) makeDiff: (NSString *(^)(NSString *)) formatter;


@end
