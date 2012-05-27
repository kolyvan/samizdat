//
//  AppDelegate.h
//  Samizdat
//
//  Created by Kolyvan on 11.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import <Cocoa/Cocoa.h>

@class KxHUDView;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (readonly, nonatomic) KxHUDView * hudView;

- (IBAction) reload: (id) sender;

- (IBAction) toggleHUD: (id) sender;
- (IBAction) showAuthorsView: (id) sender;
- (IBAction) showAddAuthorView: (id) sender;
- (IBAction) showFavoritesView: (id) sender;

- (void) showAuthorView:(id)author;
- (void) showAuthorInfoView:(id)author;
- (void) showTextView:(id)text;
- (void) showCommentsView:(id)comments;
- (void) showTextsGroup:(id)group;

- (IBAction) goBack: (id) sender;
- (IBAction) goForward: (id) sender;

- (IBAction) loginSamizdat:(id)sender;
- (IBAction) logoutSamizdat:(id)sender;
- (IBAction) clearCookie:(id)sender;

- (IBAction) deleteAuthor:(id)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)item;


- (void) hudInfo: (NSString *) message;
- (void) hudSuccess: (NSString *) message;
- (void) hudWarning: (NSString *) message;

- (BOOL) startReload: (id) object
          withMessage: (NSString *) message;

- (void(^)(CGFloat progress)) startReload: (id) object
                              withMessage: (NSString *) message
                              andProgress: (BOOL) unused;

- (void) finishReload: (NSInteger) status 
          withMessage: (NSString *) message;


@end
