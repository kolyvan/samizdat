//
//  FavoritesViewController.h
//  samlib
//
//  Created by Kolyvan on 16.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableViewController.h"

// abstract class

@interface TextsViewController : TableViewController

- (IBAction) showComments:(id)sender;
- (IBAction) toggleFavorite:(id)sender;

@end
