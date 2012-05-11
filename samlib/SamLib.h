//
//  SamLib.h
//  samlib
//
//  Created by Kolyvan on 08.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KxArc.h"

typedef enum {
    
    SamLibStatusSuccess,
    SamLibStatusFailure,
    SamLibStatusNotModifed,    
    
} SamLibStatus;

////

@class SamLibAuthor;
@class SamLibText;

////

extern NSString * getStringFromDict(NSDictionary *dict, NSString *name, NSString *path);
extern NSDate * getDateFromDict(NSDictionary * dict, NSString *name, NSString *path);
extern NSHTTPCookie * searchSamLibCookie(NSString *name);
extern NSHTTPCookie * deleteSamLibCookie(NSString *name);
extern NSDictionary * loadDictionary(NSString *filepath);
extern BOOL saveDictionary(NSDictionary *dict, NSString * filepath);
////

@interface SamLibBase : NSObject {

@protected    
    NSString * _path;
    NSDate * _timestamp;
}

@property (readonly, nonatomic) NSString *path; 
@property (readwrite, nonatomic, KX_PROP_STRONG) NSDate *timestamp;
@property (readonly, nonatomic) BOOL changed;

@property (readonly) NSString * url;
@property (readonly) NSString * relativeUrl;

- (id) initWithPath: (NSString *)path;

@end