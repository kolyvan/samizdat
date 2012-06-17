//
//  SamLibCacheNames.h
//  samlib
//
//  Created by Kolyvan on 17.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SamLibCacheNames : NSObject

@property (readonly, nonatomic) BOOL status;           

- (void) close;

- (BOOL) hadName: (NSString *) name;
- (BOOL) hadPath: (NSString *) path;

- (NSArray *) selectByPath: (NSString *) path; 
- (NSArray *) selectByName: (NSString *) name; 

- (void) addPath: (NSString *) path 
        withName: (NSString *) name
        withInfo: (NSString *) info;

- (void) addBatch: (NSArray *) batch;

- (void) each: (void (^)(NSString *path, NSString *name, NSString *info)) block;

@end
