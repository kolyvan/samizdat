//
//  KxHistoryNav.h
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import <Foundation/Foundation.h>

@class KxProxy;

@interface KxHistoryNav : NSObject {
@private
    NSMutableArray * _prev;
    NSMutableArray * _next;
    KxProxy * _now;
    NSInteger _flag;
}

@property (readonly, nonatomic) BOOL canGoBack;
@property (readonly, nonatomic) BOOL canGoForward;
@property (readonly, nonatomic) BOOL isGoBack;
@property (readonly, nonatomic) BOOL isGoForward;

- (id) prepare: (id) target;
- (id) prepare: (id) target name: (NSString *) name;

- (void) goBack;
- (void) goForward;

- (void) clear;

@end
