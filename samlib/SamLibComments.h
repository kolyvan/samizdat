//
//  SamLibComments.h
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SamLib.h"

@class SamLibComments;

typedef void (^UpdateCommentsBlock)(SamLibComments *author, 
                                    SamLibStatus status,                                    
                                    NSString *error);

@interface SamLibComment : NSObject

@property (readonly, nonatomic) NSInteger number;
@property (readonly, nonatomic) NSString * deleteMsg;
@property (readonly, nonatomic) NSString * name;
@property (readonly, nonatomic) NSString * link;
@property (readonly, nonatomic) NSString * color;
@property (readonly, nonatomic) NSString * msgid;
@property (readonly, nonatomic) NSString * replyto;
@property (readonly, nonatomic) NSString * message;
@property (readonly, nonatomic) NSDate * timestamp;
@property (readonly, nonatomic) BOOL isSamizdat;

+ (id) fromDictionary: (NSDictionary *) dict;

- (NSDictionary *) toDictionary;

- (NSComparisonResult) compare: (SamLibComment *) other;

@end

////

@interface SamLibComments : SamLibBase {

    KX_WEAK SamLibText * _text;    
    NSArray * _all;
    //BOOL _subscribed;
    NSString *_lastModified;
    BOOL _isDirty;
    NSInteger _numberOfNew;
}

@property (readonly, nonatomic, KX_PROP_WEAK) SamLibText * text;
@property (readonly, nonatomic) NSArray * all;
@property (readonly, nonatomic) BOOL changed;
//@property (readwrite, nonatomic) BOOL subscribed;
@property (readonly, nonatomic) NSString * lastModified;
@property (readonly, nonatomic) BOOL isDirty;
@property (readonly, nonatomic) NSInteger numberOfNew; 

+ (id) fromFile: (NSString *) filepath withText: (SamLibText *) text;
+ (id) fromDictionary: (NSDictionary *)dict withText: (SamLibText *) text;

- (id) initFromDictionary: (NSDictionary *)dict withText: (SamLibText *) text;

- (NSDictionary *) toDictionary;

- (void) update: (UpdateCommentsBlock) block;

- (void) save: (NSString *)folder;

- (void) post: (NSString *) message 
        block: (UpdateCommentsBlock) block;


@end
