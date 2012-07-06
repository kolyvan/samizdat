//
//  SamLibModerator.h
//  samlib
//
//  Created by Kolyvan on 06.07.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KxArc.h"

@class SamLibComment;

typedef enum {
    
    SamLibBanCategoryName,
    SamLibBanCategoryEmail, 
    SamLibBanCategoryURL,     
    SamLibBanCategoryWord,    
    
} SamLibBanCategory;

@interface SamLibBanSymptom : NSObject
@property (readwrite, KX_PROP_STRONG) NSString *pattern;
@property (readwrite) SamLibBanCategory category;
@property (readwrite) CGFloat threshold;

- (id) initFromPattern: (NSString *) pattern 
              category: (SamLibBanCategory) category 
             threshold: (CGFloat) threshold;

- (CGFloat) testPatternAgainst: (NSString *) s;

@end

@interface SamLibBan : NSObject
@property (readwrite, KX_PROP_STRONG) NSString *name;
@property (readwrite, KX_PROP_STRONG) NSString *path;
@property (readonly, KX_PROP_STRONG) NSArray *symptoms;
@property (readwrite) CGFloat tolerance;
@property (readwrite) BOOL enabled;

- (id) initWithName: (NSString *) name 
           symptoms: (NSArray *) symptoms 
          tolerance: (CGFloat) tolerance
               path: (NSString *) path;

- (BOOL) checkPath: (NSString *) path;
- (BOOL) testForBan: (SamLibComment *) comment 
           withPath: (NSString *) path;

- (void) addSymptom:(SamLibBanSymptom *)symptom;
- (void) removeSymptom:(SamLibBanSymptom *)symptom;
- (void) removeSymptomAtIndex:(NSUInteger)index;

@end

@interface SamLibModerator : NSObject

@property (readonly, KX_PROP_STRONG) NSArray * allBans;

+ (SamLibModerator *) shared;

- (SamLibBan *) testForBan: (SamLibComment *) comment 
                  withPath: (NSString *) path;

- (void) addBan: (SamLibBan *) ban;
- (void) removeBan: (SamLibBan *) ban;

- (void) save;

@end
