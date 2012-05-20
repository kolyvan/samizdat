//
//  KxHUD.h
//  AppKitLab
//
//  Created by Konstantin Boukreev on 29.04.12.
//  Copyright 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import <Foundation/Foundation.h>
#import "KxArc.h"

@class KxHUDView;

@protocol KxHUDRow <NSObject>

@property (readwrite, nonatomic) BOOL isActive;
@property (readwrite, nonatomic) BOOL isPinned;
@property (readwrite, nonatomic, copy) NSString *text;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSColor *textColor;

@property (readonly, nonatomic, KX_PROP_WEAK) KxHUDView *view;

- (void) reset;
- (void) remove;

@end

@protocol KxHUDRowWithProgress<KxHUDRow>
@property (readwrite, nonatomic) CGFloat progress;
@end

@protocol KxHUDRowWithSpin<KxHUDRow>
@property (readwrite, nonatomic) BOOL isComplete;
@end


@interface KxHUDView : NSBox 
{
    
    NSMutableArray * _rows;    
    NSTimer * _timer;

    NSInteger _scrollPos;    
    NSTrackingRectTag _trackingRect;
    BOOL _toggled;    
    BOOL _mouseOver;
    
    NSColor *_defaultTextColor;
    NSTimeInterval _defaultShowTime;    
    NSSize _maxSize;
}

@property (readwrite, nonatomic) BOOL isToggled;
@property (readwrite, nonatomic, KX_PROP_STRONG) NSColor *defaultTextColor;
@property (readwrite, nonatomic) NSTimeInterval defaultShowTime;
@property (readwrite, nonatomic) NSSize maxSize;

- (id<KxHUDRow>) message: (NSString *) text
                   color: (NSColor *) color
                interval: (NSTimeInterval) interval;

- (id<KxHUDRowWithProgress>) progress: (NSString *) text 
                                style: (NSInteger) style;

- (id<KxHUDRowWithSpin>) spin: (NSString *) text 
                        style: (NSInteger) style;

- (id<KxHUDRow>) select: (NSString *) text 
                  links: (NSArray *) links 
                  block: (void(^)(id<KxHUDRow> row, NSInteger link)) block;


- (void) refresh;
- (void) clear;

@end
