//
//  KxViewControllerViewController.m
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "KxViewController.h"
#import "SamLibAgent.h"

@interface KxViewController ()

@end

@implementation KxViewController

- (id)initWithNibName:(NSString *)nibName
{
    NSAssert(nibName != nil, @"nil nibname");
    
    self = [super initWithNibName:nibName 
                           bundle:[NSBundle bundleForClass:[self class]]];
    if (self) {
    }    
    return self;
}

- (void) reset: (id) obj
{
}

- (void) activate
{
    [[self.view window] makeFirstResponder:self];     
}

- (void) deactivate
{
}

- (void) reload: (id) sender
{
}

- (void) cancel: (id) sender
{
    SamLibAgent.cancelAll();
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL r = [super becomeFirstResponder];
    if (r && _firstResponder) {
        [[self.view window] makeFirstResponder:_firstResponder];
    }
    return r;
}


@end
