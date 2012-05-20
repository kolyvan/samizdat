//
//  TestViewController.h
//  samlib
//
//  Created by Kolyvan on 12.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KxViewController.h"

@interface TestView : NSView

@end

@interface TestViewController : KxViewController<NSTableViewDataSource,NSTableViewDelegate> {

}

@end
