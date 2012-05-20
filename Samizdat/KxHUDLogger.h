//
//  KxHUDLogger.h
//  samlib
//
//  Created by Kolyvan on 11.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DDLog.h"

@class KxHUDView;

@interface KxHUDLogger : DDAbstractLogger <DDLogger>

- (id) init: (KxHUDView *) hudView;

@end

