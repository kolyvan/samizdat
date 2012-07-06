//
//  SamLibModerator.m
//  samlib
//
//  Created by Kolyvan on 06.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibModerator.h"
#import "KxUtils.h"
#define NSNUMBER_SHORTHAND
#import "KxMacros.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "SamLibComments.h"
#import "SamLib.h"
#import "SamLibStorage.h"

@implementation SamLibBanSymptom
@synthesize pattern = _pattern, category = _category, threshold = _threshold;

+ (id) fromDictionary: (NSDictionary *) dict
{
    SamLibBanSymptom *p;
    p = [[SamLibBanSymptom alloc] initFromPattern:[dict get:@"pattern"]  
                                         category:[[dict get:@"category"] intValue] 
                                        threshold:[[dict get:@"threshold"] floatValue]];
    return p;
}

- (NSDictionary *) toDictionary
{
    return KxUtils.dictionary(_pattern, @"pattern",
                              $int(_category), @"category",
                              $float(_threshold), @"threshold",
                              nil);
}

- (id) initFromPattern: (NSString *) pattern 
              category: (SamLibBanCategory) category 
             threshold: (CGFloat) threshold
{
    NSAssert(pattern.nonEmpty, @"empty pattern");
    NSAssert(threshold > 0, @"threshold out of range");        
    
    self = [super init];
    if (self) {
        self.pattern = pattern.lowercaseString;
        _category = category;
        _threshold = threshold;
    }
    return self;
}

- (CGFloat) testPatternAgainst: (NSString *) s
{
    s = s.lowercaseString;
    
    if (_category == SamLibBanCategoryWord)
    {
        BOOL sentence= [_pattern contains:@" "];
        
        if (sentence) {
            
            return [self testSentence: s];
                        
        } else {
            for (NSString * w in [s split]) {
                CGFloat r = [self testWord: w];
                if (r > 0)
                    return r;             
            }
        }
        
    } else {
                
        return [self testWord: s];
    }
    
    return 0;
}

- (CGFloat) test: (NSString *) s
{
    float distance = levenshteinDistanceNS2(_pattern, s);
    distance = 1.0 - (distance / MAX(_pattern.length, s.length));
    return _threshold < distance ? distance : 0;
}

- (CGFloat) testWord: (NSString *) s
{
    if (_threshold > 0.999)        
        return [s isEqualToString:_pattern] ? 1 : 0;    
    return [self test: s];
}

- (CGFloat) testSentence: (NSString *) s
{
    if (_threshold > 0.999)        
        return [s rangeOfString:_pattern].location != NSNotFound ? 1 : 0;
    
    if (_pattern.length >= s.length)        
        return [self test: s];

    NSInteger n = s.length - _pattern.length;
    for (int i = 0; i < n; ++i) {
        
        NSString *subs = [s substringWithRange:NSMakeRange(i, _pattern.length)];
        CGFloat r = [self test: subs];
        if (r > 0)
            return r;        
    }
    
    return 0;
}

@end

////

@implementation SamLibBan {
    NSMutableArray *_symptoms;
}

@synthesize name = _name; 
@synthesize symptoms = _symptoms; 
@synthesize tolerance = _tolerance; 
@synthesize path = _path;
@synthesize enabled = _enabled;

+ (id) fromDictionary: (NSDictionary *) dict
{
    NSArray *symptoms = [dict get:@"symptoms"];
    
    symptoms = [symptoms map:^(id elem) {
        return [SamLibBanSymptom fromDictionary: elem];
    }];
    
    SamLibBan *p;
    p = [[SamLibBan alloc] initWithName: [dict get:@"name"]
                               symptoms: symptoms
                              tolerance: [[dict get:@"tolerance"] floatValue]
                                   path: [dict get:@"path"]];

    p.enabled = [[dict get:@"enabled"] boolValue];
    return p;
}

- (NSDictionary *) toDictionary
{
    NSArray *symptoms = [_symptoms map:^(id elem) {
        return [elem toDictionary];
    }];
    
    return KxUtils.dictionary(_name.nonEmpty ? _name : @"", @"name",
                              _path.nonEmpty ? _path : @"", @"path",
                              symptoms, @"symptoms",
                              $float(_tolerance), @"tolerance",
                              $bool(_enabled), @"enabled",
                              nil);
}

- (id) initWithName: (NSString *) name 
           symptoms: (NSArray *) symptoms 
          tolerance: (CGFloat) tolerance
               path: (NSString *) path
{
    NSAssert(symptoms.nonEmpty, @"empty symptoms");
    NSAssert(tolerance > 0, @"tolerance out of range");    
    
    self = [super init];
    if (self) {
        
        _symptoms = [symptoms mutableCopy];        
        self.name = name;
        self.path = path;
        _tolerance = tolerance;
        _enabled = YES;
    }
    return self;
}

- (void) addSymptom:(SamLibBanSymptom *)symptom
{
    [_symptoms push:symptom];
}

- (void) removeSymptom:(SamLibBanSymptom *)symptom
{
    [_symptoms removeObject:symptom];
}

- (void) removeSymptomAtIndex:(NSUInteger)index
{
    [_symptoms removeObjectAtIndex:index];
}

- (BOOL) checkPath: (NSString *) path
{
    if (!_path.nonEmpty)
        return YES; // empty path, always true 
    
    return [path hasPrefix:_path];
}

- (BOOL) testForBan: (SamLibComment *) comment 
           withPath:(NSString *)path
{
    if (![self checkPath: path])
        return NO;
    
    CGFloat total = 0;
        
    for (SamLibBanSymptom *sym in _symptoms) {
    
        NSString *s = nil;
        
        switch (sym.category) {
            case SamLibBanCategoryName:     s = comment.name;   break;
            case SamLibBanCategoryEmail:    s = comment.email;  break;
            case SamLibBanCategoryURL:      s = comment.link;   break;
            case SamLibBanCategoryWord:     s = comment.message; break;
        }
        
        if (s.nonEmpty)
            total += [sym testPatternAgainst: s];
            
        if (total >= _tolerance)
            return YES;        
    }
    
    return NO;
}

@end

@implementation SamLibModerator {
    
    NSMutableArray *_allBans;
    NSString * _hash;

}

@synthesize allBans = _allBans;

+ (SamLibModerator *) shared
{
    static SamLibModerator * gModer = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        gModer = [[SamLibModerator alloc] init];
        
    });
    
    return gModer;
}

- (id) init
{
    self = [super init];
    if (self) {
        
        NSArray *array = nil;
        
        if (KxUtils.fileExists(SamLibStorage.bansPath())) {
            array = SamLibStorage.loadObject(SamLibStorage.bansPath(), YES);
        }
        
        _allBans = [NSMutableArray arrayWithCapacity:array.count];
        for (NSDictionary *d in array)
            [_allBans push:[SamLibBan fromDictionary:d]];                
        
        _hash = _allBans.description.md5;
    }
    return self;
}

- (SamLibBan *) testForBan: (SamLibComment *) comment 
                  withPath:(NSString *)path
{
    for (SamLibBan *ban in _allBans) {
        if ([ban testForBan:comment withPath:path])
            return ban;    
    }
    return nil;
}

- (void) addBan: (SamLibBan *) ban
{
    [_allBans push:ban];
}

- (void) removeBan: (SamLibBan *) ban
{
    [_allBans removeObject:ban];
}

- (void) save
{
    NSString *newHash = _allBans.description.md5;
    
    if (![_hash isEqualToString:newHash]) {

        _hash = newHash;
        
        NSArray *a = [_allBans map:^id(id elem) {
            return [elem toDictionary];
        }];
        
        SamLibStorage.saveObject(a, SamLibStorage.bansPath());
    }
}

@end
