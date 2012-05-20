//
//  TextsGroupViewController.m
//  samlib
//
//  Created by Kolyvan on 18.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "TextsGroupViewController.h"
#import "KxArc.h"
#import "SamLibText.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"

@interface TextsGroupViewController () {
    NSArray * _group;
}

@end

@implementation TextsGroupViewController


- (void) reset:(id) obj
{
    NSAssert([obj isKindOfClass: [NSArray class]], @"invalid class");
    KX_RELEASE(_group);
    _group = KX_RETAIN(obj);    
    
    [super reset:[_group.first author]];
}

- (void) dealloc 
{
    KX_RELEASE(_group);
    KX_SUPER_DEALLOC();
}

- (NSArray *) loadContent
{
    NSMutableArray * ma = [NSMutableArray array];    
    [ma push: [_group.first author]];    
    [ma push: [_group.first groupEx]];
    [ma appendAll:_group];  
    return ma;
}


 
@end