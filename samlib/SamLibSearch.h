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
    
} FuzzySearchFlag;


@interface SamLibSearch : NSObject

+ (id) searchAuthorByName: (NSString *) name 
                     flag: (FuzzySearchFlag) flag
                    block: (AsyncSearchResult) block;

+ (id) searchAuthorByPath: (NSString *) path 
                     flag: (FuzzySearchFlag) flag
                    block: (AsyncSearchResult) block;

- (void) cancel;

@end
