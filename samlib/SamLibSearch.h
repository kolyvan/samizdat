//
//  SamLibSearch.h
//  samlib
//
//  Created by Kolyvan on 18.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AsyncSearchResult)(NSArray *result);

typedef enum {
    
    FuzzySearchFlagLocal    = 1 << 0,
    FuzzySearchFlagCache    = 1 << 1,
    FuzzySearchFlagGoogle   = 1 << 2,    
    FuzzySearchFlagSamlib   = 1 << 3,  
    FuzzySearchFlagDirect   = 1 << 4,      
    FuzzySearchFlagAll      = FuzzySearchFlagLocal|FuzzySearchFlagCache|FuzzySearchFlagGoogle|FuzzySearchFlagSamlib|FuzzySearchFlagDirect
    
} FuzzySearchFlag;


@interface SamLibSearch : NSObject

+ (id) searchAuthor: (NSString *) name 
             byName: (BOOL) byName
               flag: (FuzzySearchFlag) flag
              block: (AsyncSearchResult) block;

- (void) cancel;

+ (NSArray *) sortByDistance: (NSArray *) result;

+ (NSArray *) unionLeft: (NSArray *) left 
               andRight: (NSArray *) right;

@end
