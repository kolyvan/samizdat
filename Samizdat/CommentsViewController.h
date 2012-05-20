//
//  CommentsViewController.h
//  samlib
//
//  Created by Kolyvan on 14.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebViewController.h"

@interface CommentsViewController : WebViewController

- (IBAction)nameEdited:(id)sender;
- (IBAction)postComment:(id)sender;
- (IBAction)cancelPost:(id)sender;

@end
