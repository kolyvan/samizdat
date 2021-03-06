//
//  KxHUDLogger.h
//  samlib
//
//  Created by Kolyvan on 11.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import <Foundation/Foundation.h>

#import "DDLog.h"

@class KxHUDView;

@interface KxHUDLogger : DDAbstractLogger <DDLogger>

- (id) init: (KxHUDView *) hudView;

@end

