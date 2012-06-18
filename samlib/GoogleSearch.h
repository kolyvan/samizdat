//
//  GoogleSearch.h
//  samlib
//
//  Created by Kolyvan on 17.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {

    GoogleSearchStatusSuccess,
    GoogleSearchStatusHTTPFailure,  
    GoogleSearchStatusJSONFailure,      
    GoogleSearchStatusResponseFailure,       
    
} GoogleSearchStatus;

typedef void (^GoogleSearchResult)(GoogleSearchStatus status, NSString *details, NSArray *results);

@interface GoogleSearch : NSObject

+ (id) search: (NSString *)query 
        block: (GoogleSearchResult) block;

- (void) cancel;

@end