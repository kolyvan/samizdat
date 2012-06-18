//
//  SamLibSearch.m
//  samlib
//
//  Created by Kolyvan on 18.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibSearch.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "SamLibAgent.h"
#import "SamLibModel.h"
#import "SamLibParser.h"
#import "SamLibAuthor.h"
#import "SamLibCacheNames.h"
#import "GoogleSearch.h"
#import "DDLog.h"

extern int ddLogLevel;

#define MINDISTANCE1 0.2
#define MINDISTANCE2 0.4
#define DISTANCE_THRESHOLD 0.8
#define GOOGLE_REQUERY_TIME 1
#define SAMLIB_REQUERY_TIME 24

///

static NSArray * sortByDistance(NSArray * array)
{
    return [array sortWith:^(id obj1, id obj2) {
        NSDictionary *l = obj1, *r = obj2;
        return [[r get:@"distance"] compare: [l get:@"distance"]];
    }];
}

static NSDictionary * mapGoogleResult(NSDictionary * dict, NSString * baseURL)
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

    NSString *info = nil;
    if (!scanner.isAtEnd)
        info = [[scanner.string substringFromIndex:scanner.scanLocation + 1] trimmed];
    
    return KxUtils.dictionary(name, @"name", 
                              path, @"path",
                              info, @"info",                              
                              @"google", @"from",                                                                
                              nil);
}

static NSArray * searchAuthor(NSString * pattern,
                              NSString * key,
                              NSArray * array)
{
    NSInteger patternLengtn = pattern.length;
    unichar patternChars[patternLengtn];
    [pattern getCharacters:patternChars 
                     range:NSMakeRange(0, patternLengtn)];
    
    NSMutableArray * ma = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        
        NSString *value = [dict get:key];
        if (value.nonEmpty) {
            
            float distance = levenshteinDistanceNS(value, patternChars, patternLengtn);
            distance = 1.0 - (distance / MAX(value.length, patternLengtn));
            
            if (patternLengtn < value.length &&                
                [value hasPrefix: pattern] &&
                (distance > MINDISTANCE1)) {
                
                NSMutableDictionary *md = [dict mutableCopy];
                [md update:@"distance" value:[NSNumber numberWithFloat:1.0 + distance]];                
                [ma push:md];
            }
            else if (distance > MINDISTANCE2) {            
                
                NSMutableDictionary *md = [dict mutableCopy];
                [md update:@"distance" value:[NSNumber numberWithFloat:distance]];                
                [ma push:md];
            }
        }
    }
    
    return ma;    
}

static NSArray * mkUnion (NSArray* l, NSArray *r)
{    
    NSMutableArray *result = [NSMutableArray array];
    
    // filter duplicates    
    for (NSDictionary *m in l) {
        
        NSString *path = [m get:@"path"];
        
        BOOL found = NO;
        
        for (NSDictionary *n in r)            
            if ([path isEqualToString: [n get:@"path"]]) {
                found = YES;
                break;
            }   
        
        if (!found) 
            [result push:m];
    }
    
    // union    
    [result appendAll: r];
    return result;
}

static NSString * mkPathFromName(NSString *name)
{    
    // convert from cirillyc name to path                                
    // Дмитриев Павел -> dmitriew_p
    
    NSMutableString *ms = [NSMutableString string];
    NSArray *a = [name split];
    NSString *first = a.first;
    
    for (NSNumber *n in [first toArray])  {
        
        unichar ch = [n unsignedShortValue];            
        NSString *s = SamLibParser.cyrillicToLatin(ch);
        if (s)
            [ms appendFormat:@"%@", s];                    
        else
            [ms appendFormat:@"%c", ch];                    
    };
    
    for (NSString *p in a.tail) {
        NSString *s = SamLibParser.cyrillicToLatin(p.first);
        if (s)
            [ms appendFormat:@"_%@", s];                    
        else
            [ms appendFormat:@"_%c", p.first];                    
    }
    
    return ms;
}

///

@interface SamLibSearch() {
    SamLibCacheNames * _cacheNames;
    NSMutableDictionary *_history;
    NSString * _historyDigest;
}
@end

@implementation SamLibSearch

+ (NSString *) historyPath
{
    return [KxUtils.cacheDataPath() stringByAppendingPathComponent: @"searchlog.json"];
}

- (id) init
{
    self = [super init];
    if (self) {
        _cacheNames = [[SamLibCacheNames alloc] init];
        
        _history = (NSMutableDictionary *)loadDictionaryEx([self->isa historyPath], NO);
        if (!_history)            
            _history = [NSMutableDictionary dictionary];        
        _historyDigest = [_history.description md5];
    }
    return self;
}

- (void) dealloc
{
    DDLogInfo(@"%@ dealloc", [self class]);

    if (![_historyDigest isEqualToString: [_history.description md5]]) {

        DDLogInfo(@"save search history");
        saveDictionary(_history, [self->isa historyPath]);        
    }

    KX_RELEASE(_history);
    KX_RELEASE(_historyVersion); 
    
    [_cacheNames close];
    KX_RELEASE(_cacheNames);
    _cacheNames = nil;
    KX_SUPER_DEALLOC();
}

- (BOOL) checkTime: (NSInteger ) hours 
          forQuery: (NSString *) query
{    
    NSNumber *timestamp = [_history get:query];
    NSDate *now = [NSDate date];
    
    // check timeout
    if (timestamp) {
        
        NSDate *dt = [NSDate dateWithTimeIntervalSinceReferenceDate:timestamp.doubleValue];        
        if ([now isLess:dt])        
            return NO; // still wait
    }
    
    // save timeout
    NSDate *dt = [now addHours:hours];
    timestamp = [NSNumber numberWithDouble:dt.timeIntervalSinceReferenceDate];
    [_history update: query value: timestamp];
    
    return YES;
}


- (NSArray *) localSearchAuthor: (NSString *)pattern 
                            key: (NSString *)key  
{
    NSArray *authors = [SamLibModel shared].authors;
    
    authors = [authors map:^(id elem) {
        SamLibAuthor *author = elem;
        return KxUtils.dictionary(author.name, @"name", 
                                  author.path, @"path", 
                                  @"local", @"from",                                  
                                  nil);
    }];
    
    return searchAuthor(pattern, key, authors); 
}

- (NSArray *) cacheSearchAuthorByName: (NSString *)name 
                              section: (unichar) sectionChar
{
    NSArray *like = [_cacheNames selectByName:KxUtils.format(@"%%%@%%", name)]; // LIKE %name%     
    NSArray *section = [_cacheNames selectBySection:sectionChar];
    NSArray *result = mkUnion(section, like);         
    DDLogInfo(@"loaded from cache: %d", result.count);    
    if (result.nonEmpty)
        return searchAuthor(name, @"name", result);    
    return nil;
}

- (NSArray *) cacheSearchAuthorByPath: (NSString *)path
{
    NSArray *like = [_cacheNames selectByPath:KxUtils.format(@"%%%@%%", path)];    
    NSArray *section = [_cacheNames selectBySection:path.first];
    NSArray *result = mkUnion(section, like); 
    DDLogInfo(@"loaded from cache: %d", result.count);    
    if (result.nonEmpty)
        return searchAuthor(path, @"path", result);    
    return nil;
}

- (void) googleSearch: (NSString *)pattern
                  key: (NSString *)key
                query: (NSString *)query 
              baseURL: (NSString *)baseURL
                block: (AsyncSearchResult) block
{
    googleSearch(query, 
                 ^(GoogleSearchStatus status, NSString *details, NSArray *googleResult) {
                     
                     NSArray *result = nil;
                     
                     if (status == GoogleSearchStatusSuccess) {
                         
                         DDLogInfo(@"loaded from google: %d", googleResult.count);
                         
                         NSMutableArray *authors = [NSMutableArray array];
                         
                         for (NSDictionary *d in googleResult) {
                             NSDictionary *mapped = mapGoogleResult(d, baseURL);
                             if (mapped)
                                 [authors push:mapped];
                         }
                         
                         if (authors.nonEmpty) {
                             
                             [_cacheNames addBatch:authors];
                             result = searchAuthor(pattern, key, authors);                             
                             DDLogInfo(@"found in google: %d", result.count);               
                         }                         
                     } 
                     
                     block(result);                     
                     
                 });

}

- (void) googleSearchByName: (NSString *)name
                       path: (NSString *) path
                      block: (AsyncSearchResult) block

{   
    NSMutableString *ms = [NSMutableString string];
    for (NSString *s in [name split])
        [ms appendFormat:@"intitle:%@ ", s];        
    
    unichar section = path.first;
        
    [self googleSearch:name 
                   key:@"name" 
                 query:KxUtils.format(@"site:samlib.ru/%c %@ inurl:indexdate.shtml", section, ms) 
               baseURL:KxUtils.format(@"http://samlib.ru/%c/", section) 
                 block:block];
    
}

- (void) googleSearchByPath: (NSString *)path
                      block: (AsyncSearchResult) block

{    
    unichar section = path.first;
    
    [self googleSearch:path 
                   key:@"path" 
                 query:KxUtils.format(@"site:samlib.ru/%c inurl:indexdate.shtml", section) 
               baseURL:KxUtils.format(@"http://samlib.ru/%c/", section) 
                 block:block];
}


- (void) samlibSearch: (NSString *)pattern
                  key: (NSString *)key
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
                                      
                                      [_cacheNames addBatch:authors];
                                      
                                      result = searchAuthor(pattern, key, authors);
                                      DDLogInfo(@"found in samlib: %d", result.count);                                      
                                  }
                              }
                              
                              block(result);                              
                          },
                          nil);
}

- (void) samlibSearchByName: (NSString *) name  
                       path: (NSString *) path                       
                      block: (AsyncSearchResult) block
{ 
    [self samlibSearch:name key:@"name" path:path block:block];    
}

- (void) samlibSearchByPath: (NSString *) path  
                      block: (AsyncSearchResult) block
{ 
    [self samlibSearch:path 
                   key:@"path" 
                  path:KxUtils.format(@"%c/", path.first)
                 block:block];    
}

-(void) directSearchByPath: (NSString *) path  
                     block: (AsyncSearchResult) block
{
    SamLibAuthor *author = [[SamLibAuthor alloc] initWithPath:path];
    
    [author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {        
        
        if (status == SamLibStatusSuccess) {
            
            NSDictionary *d = KxUtils.dictionary(author.path, @"path",
                                                 author.name, @"name",
                                                 author.title, @"info",  
                                                 [NSNumber numberWithFloat:2], @"distance",
                                                 @"direct", @"from",
                                                 nil);
            block([NSArray arrayWithObject:d]);
            
        } else {
            
            block(nil);        
        }
    
    }];
}


- (void) searchAuthor: (NSString *) pattern 
               byName: (BOOL) byName
                 flag: (FuzzySearchFlag) flag
                block: (AsyncSearchResult) block
{      
    NSString *path; 
    
    if (byName) {        
        
        //pattern = [pattern capitalizedString];    
        //NSString *capital = [pattern capitalizedString];    
        path = SamLibParser.captitalToPath(pattern.first);        
        
        if (!path.nonEmpty) {
            
            DDLogWarn(locString(@"invalid author name: %@"), pattern);
            block(nil);
            return;
        }  
    }
    
    if (0 != (flag & FuzzySearchFlagLocal)) {
        
        NSArray *found = [self localSearchAuthor:pattern 
                                             key:byName ? @"name" : @"path"];    
        DDLogInfo(@"found local: %d", found.count);    
        if (found.nonEmpty)
            block(sortByDistance(found));
    }
    
    __block int asyncCount = 0;
    
    if (0 != (flag & FuzzySearchFlagDirect))
        asyncCount++;
    
    BOOL cacheHit = NO;
    
    if (0 != (flag & FuzzySearchFlagCache)) {
        
        NSArray *found;
        if (byName)
            found = [self cacheSearchAuthorByName:pattern section:path.first];
        else
            found = [self cacheSearchAuthorByPath:pattern];
        
        DDLogInfo(@"found in cache: %d", found.count);     
        
        if (found.nonEmpty) {
            
            block(sortByDistance(found));                    
            for (NSDictionary *d in found) {
                float distance = [[d get: @"distance"] floatValue];
                if (distance > DISTANCE_THRESHOLD) {
                    cacheHit = YES;
                    break;
                }
            }  
        }
    }
    
    if (!cacheHit) {
        
        if (0 != (flag & FuzzySearchFlagGoogle)) {
            
            if ([self checkTime:GOOGLE_REQUERY_TIME 
                       forQuery:KxUtils.format(@"google:%@", pattern)])
                asyncCount++;
            else
                flag &= ~FuzzySearchFlagGoogle;
        }
        
        if (0 != (flag & FuzzySearchFlagSamlib)) {
            
            if ([self checkTime:SAMLIB_REQUERY_TIME 
                       forQuery:KxUtils.format(@"samlib:%@", pattern)])
                asyncCount++;         
            else
                flag &= ~FuzzySearchFlagSamlib;
        }
    }
    
    if (asyncCount) {
        
        void(^asyncBlock)(NSArray *) = ^(NSArray *found) {
            
            if (found.nonEmpty)
                block(sortByDistance(found));
            
            if (--asyncCount == 0) {
                
                block(nil); // fire about finish
            }
        };
                
        if (0 != (flag & FuzzySearchFlagDirect)) {
                                    
            if (byName)                            
                pattern = mkPathFromName(pattern);                               
                        
            [self directSearchByPath:pattern block:asyncBlock];
        }
        
        if (0 != (flag & FuzzySearchFlagGoogle)) {
            
            if (byName)
                [self googleSearchByName:pattern path:path block:asyncBlock];
            else
                [self googleSearchByPath:pattern block:asyncBlock];
        }
        
        if (0 != (flag & FuzzySearchFlagSamlib)) {
            
            if (byName)
                [self samlibSearchByName:pattern path:path block:asyncBlock];
            else
                [self samlibSearchByPath:pattern block:asyncBlock];
        }
        
    } else {
        
        block(nil); // fire about finish
    }    
}

+ (id) searchAuthorByName: (NSString *) name 
                     flag: (FuzzySearchFlag) flag
                    block: (void(^)(NSArray *result)) block
{
    NSAssert(name.nonEmpty, @"empty name");
    SamLibSearch *p = [[SamLibSearch alloc] init];    
    [p searchAuthor:name byName:YES flag:flag block:block];    
    return KX_AUTORELEASE(p);
}

+ (id) searchAuthorByPath: (NSString *) path 
                     flag: (FuzzySearchFlag) flag
                    block: (AsyncSearchResult) block
{
    NSAssert(path.nonEmpty, @"empty path");
    SamLibSearch *p = [[SamLibSearch alloc] init];    
    [p searchAuthor:path byName:NO flag:flag block:block];    
    return nil;
}


- (void) cancel
{
    // todo:
    // SamLibAgent.cancelAll
}

@end
