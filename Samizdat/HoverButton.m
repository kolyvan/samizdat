//
//  HoverButton.m
//  samlib
//
//  Created by Kolyvan on 17.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "HoverButton.h"
#import "KxArc.h"

@interface HoverButton() {
    NSTrackingRectTag _trackingRect;
    NSImage * _image;
    BOOL _flag;
}

@end

@implementation HoverButton

@synthesize hoveredImage = _hoveredImage;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }    
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_image); 
    KX_SUPER_DEALLOC();
}

- (void) setImage:(NSImage *)image
{
    _flag = NO;   
    [super setImage:image];
}

//- (void)drawRect:(NSRect)dirtyRect

- (void) createTrackingRect
{
    if (_trackingRect) {       
        [self removeTrackingRect:_trackingRect];        
        _trackingRect = 0;
    }
    
    _trackingRect = [self addTrackingRect:[self bounds] 
                                    owner:self 
                                 userData:nil 
                             assumeInside:NO];
}

- (void)viewDidMoveToWindow 
{
    [super viewDidMoveToWindow]; 
    [self createTrackingRect];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow 
{
    [super viewWillMoveToWindow:newWindow];     
    if ([self window] && _trackingRect) {        
        [self removeTrackingRect:_trackingRect];        
        _trackingRect = 0;
    }    
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self createTrackingRect];
}

- (void) mouseEntered:(NSEvent *)event
{
    [super mouseEntered:event];    

    /*
    if (_hoveredImage) {  
        KX_RELEASE(_image);
        _image = KX_RETAIN(self.image);
        self.image = _hoveredImage;
    }
    */
    

    if (self.alternateImage) { 
    
        if (!_flag) {
            _flag = YES;
            KX_RELEASE(_image);
            _image = KX_RETAIN(self.image);
        }
        
        super.image = self.alternateImage;
    }
}

- (void) mouseExited:(NSEvent *)event
{
    [super mouseExited:event];           
    
    /*
    if (_hoveredImage &&
        self.image == _hoveredImage) {        
        self.image = _image;
        KX_RELEASE(_image);
        _image = nil;
    }
    */
    
    if (_flag &&
        self.image == self.alternateImage) {        
        super.image = _image;
    }    
}


@end
