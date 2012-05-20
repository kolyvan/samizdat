//
//  KxHyperLinkField.h
//  AppKitLab
//
//  Created by Konstantin Boukreev on 19.04.12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KxLinkLabel : NSTextField {
@private
    NSString * _url;
    NSTrackingRectTag trackingRect;
    NSColor * _normalColor;
    NSColor * _hoveredColor;
}

@property (readwrite, copy, nonatomic) NSString * url;
@property (readwrite, retain, nonatomic) NSColor * hoveredColor;

@end
