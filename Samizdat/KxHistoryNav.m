//
//  KxHistoryNav.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "KxHistoryNav.h"
#import "KxArc.h"
#import "NSArray+Kolyvan.h" 

@interface KxProxy : NSProxy {    
	id _target;
    NSString * _name;     
    NSInvocation *_invocation;
}

@property (nonatomic, KX_PROP_STRONG) id target;
@property (nonatomic, KX_PROP_STRONG) NSString * name;
@property (nonatomic, KX_PROP_STRONG) NSInvocation *invocation;

@end

@implementation KxProxy

@synthesize target = _target;
@synthesize name = _name;
@synthesize invocation = _invocation;

- (id) init: (id) target 
       name: (NSString *) name 
{
    _target = KX_RETAIN(target); 
    _name = KX_RETAIN(name);
    
    return self;
}

- (void)dealloc 
{
    KX_RELEASE(_name);
	KX_RELEASE(_target);
	KX_RELEASE(_invocation);

    KX_SUPER_DEALLOC();
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)selector 
{
	return [self.target methodSignatureForSelector:selector];
}

- (void) forwardInvocation: (NSInvocation*)invocation
{
	[invocation setTarget:_target];
	self.invocation = invocation;
}

@end


@implementation KxHistoryNav

@dynamic canGoBack;
@dynamic canGoForward;
@dynamic isGoBack;
@dynamic isGoForward;

- (BOOL) canGoBack 
{
    return _prev.nonEmpty;
}

- (BOOL) canGoForward 
{
    return _next.nonEmpty;
}

- (BOOL) isGoBack
{
    return _flag == 1;
}

- (BOOL) isGoForward
{
    return _flag == 2;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        _next = [[NSMutableArray alloc] init];
        _prev = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    KX_RELEASE(_now);
    KX_RELEASE(_next);
    KX_RELEASE(_prev);
    KX_SUPER_DEALLOC();
}

- (void) clear
{
    [_next removeAllObjects];
    [_prev removeAllObjects];
}

- (id) prepare: (id) target
{
    return [self prepare: target name: nil];
}

- (id) prepare: (id) target name: (NSString *) name
{
    if (_now) {
        [_prev push:_now];
        KX_RELEASE(_now);
        _now = nil;
    }
    
    if (!_flag)
        [_next removeAllObjects];
    
    _now = [[KxProxy alloc] init: target name: name];    
    return _now;    
}

- (void) goBack
{
    if (!_prev.nonEmpty)
        return;
    
    KxProxy * p = [_prev pop];
    
    if (_now) {
        [_next push:_now];
        KX_RELEASE(_now);
        _now = nil;
    }
    
    _flag = 1;
    [p.invocation invoke];
    _flag = 0;        
}

- (void) goForward
{
    if (!_next.nonEmpty)
        return;
    
    KxProxy * p = [_next pop];
    
    if (_now) {
        [_prev push:_now];
        KX_RELEASE(_now);
        _now = nil;
    }
    
    _flag = 2;
    [p.invocation invoke];
    _flag = 0; 
}


@end
