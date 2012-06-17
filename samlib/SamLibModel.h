//
//  SamLibModel.h
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Foundation/Foundation.h>

@class SamLibAuthor;
@class SamLibText;
@class SamLibComments;

@interface SamLibModel : NSObject 

@property (readonly, nonatomic) NSArray * authors;
@property (readonly, nonatomic) NSInteger version;

+ (SamLibModel *) shared;

- (void) reload;
- (void) save;

- (void) addAuthor: (SamLibAuthor *) author;
- (void) deleteAuthor: (SamLibAuthor *) author;

- (SamLibAuthor *) findAuthor: (NSString *) byPath;
- (SamLibText *) findTextByKey: (NSString *)key;

//+ (void) fuzzySearchAuthorByName: (NSString *) name 
//                           block: (void(^)(NSArray *result)) block;
//+ (void) fuzzySearchAuthorByPath: (NSString *) name 
//                           block: (void(^)(NSArray *result)) block;

@end
