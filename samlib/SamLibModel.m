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



#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibModel.h"
#import "SamLibAgent.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibComments.h"
//#import "KxTuple2.h"
#import "SamLibParser.h"
#import "SamLibCacheNames.h"
#import "GoogleSearch.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface SamLibModel() {
        
    NSArray * _authors;
    NSInteger _version;
    SamLibCacheNames * _cacheNames;
}

@property (readwrite, nonatomic, ) NSArray * authors;
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
        _cacheNames = [[SamLibCacheNames alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [_cacheNames close];
    KX_RELEASE(_cacheNames);
    KX_RELEASE(_authors);
    _cacheNames = nil;
    _authors = nil;
    KX_SUPER_DEALLOC();
}

- (void) reload
{
    self.authors = SamLibAgent.loadAuthors();
    self.version += 1;
    
    DDLogInfo(@"loaded authors: %ld", _authors.count);    
}

- (void) save
{
    for (SamLibAuthor * author in _authors) {
        if (author.isDirty) {
            [author save: SamLibAgent.authorsPath()];
            DDLogInfo(@"save author: %@", author.path);
        }
        for (SamLibText *text in author.texts) {
            SamLibComments *comments = [text commentsObject:NO];
            if (comments && comments.isDirty) {
                [comments save: SamLibAgent.commentsPath()];
                DDLogInfo(@"save comments: %@", text.key);
            }
        }
    }
}

- (void) addAuthor: (SamLibAuthor *) author
{    
    [author save:SamLibAgent.authorsPath()];

    NSMutableArray *a = [_authors mutableCopy];
    [a push: author];    
    self.authors = a;
    KX_RELEASE(a);    
    self.version += 1;    
}

- (void) deleteAuthor: (SamLibAuthor *) author
{
    SamLibAgent.removeAuthor(author.path); 
    
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
    NSArray *a = [key split:@"."];
    
    if (a.count == 2) {
        
        NSString *path = [a objectAtIndex:0];        
        SamLibAuthor *author = [self findAuthor: path];        
        if (author) {
            //return [author findText:path];            
            return [author.texts find: ^(id elem) { 
                SamLibText *text = elem;        
                return [text.key isEqualToString:key];
            }]; 
        }
    }      
    
    return nil;
}

#pragma mark - fuzzy search

+ (NSArray *) sortByDistance: (NSArray *) array
{
    return [array sortWith:^(id obj1, id obj2) {
        NSDictionary *l = obj1, *r = obj2;
        return [[r get:@"distance"] compare: [l get:@"distance"]];
    }];
}

+ (NSDictionary *) mapGoogleResult: (NSDictionary *) dict 
                           baseURL: (NSString *) baseURL
{        
    // "titleNoFormatting": "Журнал &quot;Самиздат&quot;.Смирнов Василий Дмитриевич. Смирнов ..."
    // "url": "http://samlib.ru/s/smirnow_w_d/indexdate.shtml",
    
    NSScanner *scanner;
    scanner = [NSScanner scannerWithString:[dict get:@"url"]];  
    if (![scanner scanString:baseURL intoString:nil])
        return nil;
    
    NSString *path = nil;
    if (![scanner scanUpToString:@"/indexdate.shtml" intoString:&path])
        return nil;
    
    if (!path.nonEmpty)
        return nil;
    
    scanner = [NSScanner scannerWithString:[dict get:@"titleNoFormatting"]];  
    
    if (![scanner scanString:@"Журнал &quot;Самиздат&quot;." intoString:nil])
        return nil;
    
    NSString *name = nil;
    if (![scanner scanUpToString:@"." intoString:&name])
        return nil;
    
    if (!name.nonEmpty)
        return nil;
    
    return KxUtils.dictionary(name, @"name", 
                              path, @"path",
                              @"google", @"place",                                                                
                              nil);
}

+ (NSArray *) fuzzySearchAuthorByName: (NSString *) authorName 
                         minDistance1: (float) minDistance1
                         minDistance2: (float) minDistance2
                              inArray: (NSArray *) array
{
    NSInteger authorLengtn = authorName.length;
    unichar authorChars[authorName.length];
    [authorName getCharacters:authorChars 
                        range:NSMakeRange(0, authorLengtn)];
    
    NSMutableArray * ma = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        
        NSString *name = [dict get:@"name"];
        if (name.nonEmpty) {
            
            float distance = levenshteinDistanceNS(name, authorChars, authorLengtn);
            distance = 1.0 - (distance / MAX(name.length, authorLengtn));
            
            if (authorLengtn < name.length &&                
                [name hasPrefix: authorName] &&
                (distance > minDistance1)) {
                
                NSMutableDictionary *md = [dict mutableCopy];
                [md update:@"distance" value:[NSNumber numberWithFloat:1.0 + distance]];                
                [ma push:md];
            }
            else if (distance > minDistance2) {            

                NSMutableDictionary *md = [dict mutableCopy];
                [md update:@"distance" value:[NSNumber numberWithFloat:distance]];                
                [ma push:md];
            }
        }
    }
    
    return ma;    
}

- (NSArray *) localFuzzySearchAuthorByName: (NSString *)name  
{
    NSArray *array;
    array = [_authors map:^(id elem) {
        SamLibAuthor *author = elem;
        return KxUtils.dictionary(author.name, @"name", 
                                  author.path, @"path", 
                                  @"local", @"place",                                  
                                  nil);
    }];

    return [self->isa fuzzySearchAuthorByName:name   
                                 minDistance1:0.2
                                 minDistance2:0.4
                                      inArray:array]; 
}

- (NSArray *) cacheFuzzySearchAuthorByName: (NSString *)name  
                                      path: (NSString *)path
{
    // load from the cache all names with the same first letter 
    NSArray *section = [_cacheNames selectBySection:path.first]; 
    
    DDLogInfo(@"loaded from cache: %d", section.count);
    
    if (!section.nonEmpty)
        return nil;
    
    return [self->isa fuzzySearchAuthorByName: name   
                                 minDistance1: 0.2
                                 minDistance2: 0.4
                                      inArray: section];    
}

- (void) googleSearchByName: (NSString *)name
                       path: (NSString *) path
                      block: (AsyncSearchResult) block

{
    NSMutableString *ms = [NSMutableString string];
    for (NSString *s in [name split])
        [ms appendFormat:@"intitle:%@ ", s];        
        
    unichar section = path.first;
    
    NSString *query = KxUtils.format(@"site:samlib.ru/%c %@ inurl:indexdate.shtml", 
                                     section,
                                     ms);
    googleSearch(query, 
                 ^(GoogleSearchStatus status, NSString *details, NSArray *googleResult) {
                     
                     NSArray *result = nil;
                     
                     if (status == GoogleSearchStatusSuccess) {
                         
                         NSString *baseURL = KxUtils.format(@"http://samlib.ru/%c/", section);
                         
                         DDLogInfo(@"loaded from google: %d", googleResult.count);
                         
                         NSMutableArray *ma = [NSMutableArray array];
                         
                         for (NSDictionary *d in googleResult) {
                             NSDictionary *mapped = [self->isa mapGoogleResult:d
                                                                      baseURL:baseURL];
                             if (mapped)
                                 [ma push:mapped];
                         }
                         
                         if (ma.nonEmpty) {
                             
                             result = [self->isa fuzzySearchAuthorByName:name   
                                                            minDistance1:0.2
                                                            minDistance2:0.4
                                                                 inArray:ma];
                             
                             DDLogInfo(@"found in google: %d", result.count);               
                         }                         
                     } 
                     
                     block(result);                     
                     
                 });
}
                 
- (void) samlibSearchByName: (NSString *) name  
                       path: (NSString *) path                       
                      block: (AsyncSearchResult) block
{
    SamLibAgent.fetchData(path, nil, NO, nil, nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified) {                                  

                              NSArray *result = nil;
                              
                              if (status == SamLibStatusSuccess) {
                                  
                                  NSArray *authors = SamLibParser.scanAuthors(data); 
                                  
                                  DDLogInfo(@"loaded from samlib: %d", authors.count);
                                  
                                  if (authors.nonEmpty) {
                                      
                                      result = [self->isa fuzzySearchAuthorByName:name   
                                                                     minDistance1:0.2
                                                                     minDistance2:0.4
                                                                          inArray:authors];                                      
                                      
                                      DDLogInfo(@"found in samlib: %d", result.count);                                      
                                  }
                              }
                              
                              block(result);                              
                          },
                          nil);

}

- (void) fuzzySearchAuthorByName: (NSString *) name 
                            flag: (FuzzySearchFlag) flag
                           block: (AsyncSearchResult) block
{
   
    name = [name capitalizedString];
    NSString *path = SamLibParser.captitalToPath(name.first);
    
    if (!path.nonEmpty) {
        
        DDLogWarn(locString(@"invalid author name: %@"), name);
        block(nil);
        return;
    }
    
    NSMutableArray *result = [NSMutableArray array];    
    
    if (0 != (flag & FuzzySearchFlagCache)) {
        
        NSArray *found = [self cacheFuzzySearchAuthorByName:name  
                                                       path:path];
        DDLogInfo(@"found in cache: %d", found.count);            
        [result appendAll:found];        
    }
    
    __block int asyncCount = 0;
    
    if (!result.nonEmpty) {
        
        if (0 != (flag & FuzzySearchFlagGoogle))
            asyncCount++ ;
        
        if (0 != (flag & FuzzySearchFlagSamlib))
            asyncCount++ ;        
    }
    
    if (0 != (flag & FuzzySearchFlagLocal)) {
        
        NSArray *found = [self localFuzzySearchAuthorByName: name];    
        DDLogInfo(@"found local: %d", found.count);    
        [result appendAll: found];    
    }
            
    if (asyncCount) {
                        
        void(^asyncBlock)(NSArray *) = ^(NSArray *found) {
            
            if (found.nonEmpty) {        
                
                if (result.nonEmpty) {
                    
                    // remove duplicates
                    
                    found = [found filterNot:^(id elem) {

                        NSString *path = [(NSDictionary *)elem get:@"path"];                        
                        return [result exists:^(id elem) {                          
                            NSDictionary *d = elem;
                            return [path isEqualToString:[d get:@"path"]];                            
                        }];
                    }];
                }

                [_cacheNames addBatch:found];
                [result appendAll:found];
            }
            
            if (--asyncCount == 0) {
                block([self->isa sortByDistance:result]);
            }
        };
        
        if (0 != (flag & FuzzySearchFlagGoogle)) {
            
            [self googleSearchByName:name 
                                path:path
                               block:asyncBlock];
        }
                
        if (0 != (flag & FuzzySearchFlagSamlib)) {
            
            [self samlibSearchByName:name 
                                path:path
                               block:asyncBlock];
        }
        
    } else {
        
        block([self->isa sortByDistance:result]);
    }    
}

@end
