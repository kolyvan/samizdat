//
//  KxViewControllerViewController.h
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxArc.h"

@interface KxViewController : NSViewController {
@protected    
    IBOutlet KX_WEAK NSView * _firstResponder;    
}

- (id)initWithNibName:(NSString *)nibName;

- (void) reset: (id) obj;
- (void) activate;
- (void) deactivate;

- (void) reload: (id) sender;
- (void) cancel: (id) sender;

@end
