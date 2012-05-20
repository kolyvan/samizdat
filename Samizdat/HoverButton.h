//
//  HoverButton.h
//  samlib
//
//  Created by Kolyvan on 17.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxArc.h"

@interface HoverButton : NSButton

@property (readwrite, nonatomic, KX_PROP_STRONG) NSImage * hoveredImage;

@end
