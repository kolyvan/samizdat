//
//  SamLibModel.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "KxMacros.h"
#import "KxUtils.h"
#import "KxTuple2.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAgent.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibComments.h"
#import "SamLibStorage.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface SamLibModel() {
        
    NSArray * _authors;
    NSInteger _version;
}

@property (readwrite, nonatomic, KX_PROP_STRONG) NSArray * authors;
@property (readwrite, nonatomic) NSInteger version;

@end

@implementation SamLibModel

@synthesize authors = _authors;
@synthesize version = _version;

+ (SamLibModel *) shared
{
    static SamLibModel * gModel = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        gModel = [[SamLibModel alloc] init];
        [gModel reload];
        
    });
    
    return gModel;
}

- (id) init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_authors);
    _authors = nil;
    KX_SUPER_DEALLOC();
}

- (void) reload
{
    self.authors = [self->isa loadAuthors];    
    self.version += 1;
    
    DDLogInfo(@"loaded authors: %ld", _authors.count);    
}

- (void) save
{
    for (SamLibAuthor * author in _authors) {
        if (author.isDirty) {
            [author save: SamLibStorage.authorsPath()];
            DDLogInfo(@"save author: %@", author.path);
        }
        for (SamLibText *text in author.texts)
            [text saveComments];
    }
}

- (void) addAuthor: (SamLibAuthor *) author
{    
    [author save:SamLibStorage.authorsPath()];

    NSMutableArray *a = [_authors mutableCopy];
    [a push: author];    
    self.authors = a;
    KX_RELEASE(a);    
    self.version += 1;    
}

- (void) deleteAuthor: (SamLibAuthor *) author
{
    // remove cached texts and comments
    for (SamLibText *text in author.texts)
        [text removeTextFiles:YES andComments:YES];

    // remove file
    NSError * error;    
    NSString * fullpath = [SamLibStorage.authorsPath() stringByAppendingPathComponent:author.path];
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (![fm removeItemAtPath:fullpath error:&error]) {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));                   
    }    
    KX_RELEASE(fm);
    
    // remove from authors
    NSMutableArray *ma = [_authors mutableCopy];
    [ma removeObject:author];    
    self.authors = ma;
    KX_RELEASE(ma);    
    self.version += 1;  
}

- (SamLibAuthor *) findAuthor: (NSString *) byPath
{
    return [_authors find:^BOOL(id elem) {
        SamLibAuthor * author = elem;
        return [author.path isEqualToString:byPath];
    }];
}

- (SamLibText *) findTextByKey: (NSString *)key
{
    KxTuple2 *t = [SamLibText splitKey:key];
    if (t) {
        
        SamLibAuthor *author = [self findAuthor: t.first];        
        if (author) {
            //return [author findText:t.second];            
            return [author.texts find: ^(id elem) { 
                SamLibText *text = elem;        
                return [text.key isEqualToString:key];
            }]; 
        }
    }      
    
    return nil;
}

+ (NSArray*) loadAuthors
{    
    NSMutableArray * authors = [NSMutableArray array];
        
    SamLibStorage.enumerateFolder(SamLibStorage.authorsPath(), 
                                  ^(NSFileManager *fm, NSString *fullpath, NSDictionary *attr){
                                      
                                      SamLibAuthor *author = [SamLibAuthor fromFile: fullpath];
                                      
                                      if (author) {
                                          DDLogVerbose(@"loaded author: %@", author.path);
                                          [authors push: author];
                                      }
                                      else {
                                          DDLogWarn(@"unable load author: %@", [fullpath lastPathComponent]);                        
                                      }   
    });
    
    return authors;
}

@end
