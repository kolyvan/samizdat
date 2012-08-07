//
//  AppDelegate.m
//  Samizdat
//
//  Created by Kolyvan on 11.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "AppDelegate.h"

#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"

#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"

#import "KxHUD.h"
#import "KxHUDLogger.h"
#import "KxHistoryNav.h"
#import "KxViewController.h"

#import "SamLibAgent.h"
#import "SamLibUser.h"
#import "SamLibAuthor.h"

#import "AuthorsViewController.h"
#import "AuthorViewController.h"
#import "AuthorInfoViewController.h"
#import "TextViewController.h"
#import "CommentsViewController.h"
#import "FavoritesViewController.h"
#import "TextsGroupViewController.h"
#import "SearchAuthorViewController.h"
#import "BanViewController.h"
#import "BansViewController.h"
#import "SamLibModel.h"
#import "SamLibModerator.h"
#import "SamLibHistory.h"
#import "HistoryViewController.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#if DEBUG
int ddLogLevel = LOG_LEVEL_INFO;
#else
int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface AppDelegate() {
    
    IBOutlet NSToolbarItem * _reloadToolbarItem;    
    KxHistoryNav * _historyNav;        
    KxHUDView * _hudView;
    id<KxHUDRowWithSpin> _hudSpin;
    id<KxHUDRowWithProgress> _progress;
    id _reloaded;
    KxViewController * _activeController;
    NSMutableDictionary * _controllers;
}

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize hudView = _hudView;

- (void) dealloc 
{
    KX_RELEASE(_progress);
    KX_RELEASE(_hudSpin);
    KX_RELEASE(_hudView);
    KX_RELEASE(_historyNav);
    KX_SAFE_RELEASE(_activeController);
    KX_RELEASE(_controllers);  
    KX_RELEASE(_reloaded);
    KX_SUPER_DEALLOC();
}

- (void) hudInit
{
    NSRect frame = [_window frame];            
    
    _hudView = [[KxHUDView alloc] init];
    [_hudView setFrameOrigin:NSMakePoint(8,8)];
    _hudView.maxSize = NSMakeSize(frame.size.width * 0.8, frame.size.height * 0.8);
    
    NSView *root = _window.contentView;
    [root addSubview:_hudView positioned:NSWindowAbove relativeTo:nil];
}

- (void) initLogger
{
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];    
#endif
    
    KxHUDLogger *hudLogger = [[KxHUDLogger alloc] init: _hudView];
    [DDLog addLogger:hudLogger];
    KX_RELEASE(hudLogger);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{     
    [SamLibUser setKeychainService: KxUtils.appBundleID()];
    
    [_window setDelegate:self];  
    _window.title = locString(@"Samizdat");
    
    [self initLogger];
    [self hudInit];
    restoreSamLibSessionCookies();

    _controllers = [[NSMutableDictionary alloc] init];    
    _historyNav = [[KxHistoryNav alloc] init];
    
    [self showAuthorsView: nil];
        
    //NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];    
    //DDLogInfo(@"%@", [storage cookiesForURL: [NSURL URLWithString: @"http://samlib.ru/"]]);
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{       
    [_window makeFirstResponder:_activeController]; 
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    //NSView *root = window.contentView;    
    //NSAssert(([_controllers allKeys].count + 1) == root.subviews.count, @"bugcheck");
        
    [_historyNav clear];    
    [_hudView clear];
    [_controllers removeAllObjects];
    KX_SAFE_RELEASE(_activeController);
    
    [[SamLibModel shared] save];    
    [[SamLibModerator shared] save];
    [[SamLibHistory shared] save];
    
    SamLibAgent.cleanup();
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSRect frame = [_window frame];
    _hudView.maxSize = NSMakeSize(frame.size.width * 0.8, frame.size.height * 0.8);
}

- (void) selectControllerClass: (Class) klass
                       withArg: (id) arg
{
    KxViewController * p;
    p = [_controllers get:klass orSet:^{
        return [[klass alloc] init];
    }];    
    
    if ([self selectController: p withArg: arg]) {    
        [[_historyNav prepare:self] selectControllerClass: klass withArg: arg];      
    }    
}

- (BOOL) selectController: (KxViewController *) controller
                  withArg: (id) arg
{   
    if (controller == _activeController)
        return NO;
    
    [controller reset: arg];
    [_activeController deactivate];
    
    NSView * view = controller.view;
    
    NSView *root = _window.contentView;
    
    BOOL found = NO;
    for (NSView * p in  root.subviews) {
        
        if (p == _hudView)
            continue;
        
        if (p == view) {
            found = YES;
        }
        else if (!p.isHidden) {
            //[p setAlphaValue:0];            
            [p setHidden:YES];             
        }
    }
        
    if (!found) {        
        //[view setFrameOrigin:NSMakePoint(0,0)];
        //|NSViewMaxXMargin|NSViewMinXMargin
        [view setFrameSize: root.frame.size];
        [view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [root addSubview:view positioned:NSWindowBelow relativeTo:_hudView]; 
    }
    
    if (_historyNav.isGoBack)
        [view setFrameOrigin:NSMakePoint(view.frame.size.width, 0)];
    else            
        [view setFrameOrigin:NSMakePoint(-view.frame.size.width, 0)];

    [view setHidden: NO];
    [[view animator] setFrameOrigin:NSMakePoint(0, 0)];
    [[view animator] setAlphaValue:1];                    

    
    if (view.isHidden) {
        //[view setHidden: NO];        
        //[[view animator] setAlphaValue:1];                    
    }
        
    _activeController = controller;    
    [_activeController activate];
    
    return YES;
    
}

- (void) hudInfo: (NSString *) message
{
    [_hudView message: message color: [NSColor lightGrayColor] interval: 4];    
}

- (void) hudSuccess: (NSString *) message
{
    [_hudView message: message color: [NSColor greenColor] interval: 4];    
}

- (void) hudWarning: (NSString *) message
{
    [_hudView message: message color: [NSColor yellowColor] interval: 8];
}

- (IBAction) showAuthorsView: (id) sender
{
    [self selectControllerClass:[AuthorsViewController class] 
                        withArg:nil];    
}

- (void) showAuthorView: (in) author
{  
    [self selectControllerClass:[AuthorViewController class] 
                        withArg:author];
}

- (void) showAuthorInfoView:(id)author
{    
    [self selectControllerClass:[AuthorInfoViewController class] 
                        withArg:author];    
}

- (void) showTextView:(id)text
{
    [self selectControllerClass:[TextViewController class] 
                        withArg:text];
}

- (void) showCommentsView:(id)comments
{
    [self selectControllerClass:[CommentsViewController class] 
                        withArg:comments];
}

- (void) showTextsGroup:(id)group
{
    [self selectControllerClass:[TextsGroupViewController class] 
                        withArg:group];
}

- (IBAction) showAddAuthorView: (id) sender
{
    [self selectControllerClass:[SearchAuthorViewController class] withArg:nil];    
}

- (IBAction) showFavoritesView: (id) sender
{
    [self selectControllerClass:[FavoritesViewController class] 
                        withArg:nil];              
}

- (IBAction) showBanView: (id) ban
{   
    [self selectControllerClass:[BanViewController class] 
                        withArg:ban];              
}

- (IBAction) showBansView: (id) sender
{
    [self selectControllerClass:[BansViewController class] 
                        withArg:nil];              
}

- (IBAction) showHistoryView: (id) sender
{
    [self selectControllerClass:[HistoryViewController class] 
                        withArg:nil];              
    
}

- (IBAction) toggleHUD: (id) sender
{
    _hudView.isToggled = !_hudView.isToggled;
}

- (IBAction) goBack: (id)sender
{   
    [_historyNav goBack];
}

- (IBAction) goForward: (id) sender
{
    [_historyNav goForward];
}

- (IBAction) loginSamizdat:(id)sender
{
    SamLibUser *user = [SamLibUser currentUser];
    
    NSString * name = user.login;
    NSString * pass = user.pass;
    
    NSView * rootView       = [[NSView alloc] initWithFrame:NSMakeRect(0,0,250,95)];
    NSTextField *nameField  = [[NSTextField alloc] initWithFrame:NSMakeRect(0,75,250,20)];
    NSSecureTextField *passField  = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0,50,250,20)];    
    NSButton *saveButton    = [[NSButton alloc] initWithFrame:NSMakeRect(0, 25, 250, 20)];    
    NSButton *sessionButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 250, 20)];        
    
    [rootView addSubview:nameField];
    [rootView addSubview:passField];
    [rootView addSubview:saveButton];    
    [rootView addSubview:sessionButton];        
   
    [nameField setEditable:YES];
    [nameField setDrawsBackground:NO];
    [[nameField cell] setPlaceholderString: locString(@"input name")];
    [nameField setNextKeyView:passField];
    [[nameField cell] setSendsActionOnEndEditing: YES];
    nameField.stringValue = name.nonEmpty ? name : @"";    
    
    [passField setEditable:YES];
    [passField setDrawsBackground:NO];
    [[passField cell] setPlaceholderString: locString(@"input password")];
    [passField setNextKeyView:nameField];    
    [[passField cell] setSendsActionOnEndEditing: YES];
    passField.stringValue = pass.nonEmpty ? pass : @"";  
    
    [saveButton setButtonType: NSSwitchButton];
    [saveButton setTitle: locString(@"remember password")];
    [saveButton setState: pass.nonEmpty ? NSOnState : NSOffState];
    
    [sessionButton setButtonType: NSSwitchButton];
    [sessionButton setTitle: locString(@"save session")];
    //[sessionButton setEnabled:NO];
    
    NSAlert * alert = [[NSAlert alloc] init]; 
    
    [alert setMessageText:locString(@"Login to Samizdat")];
    [alert setIcon: [NSImage imageNamed:NSImageNameActionTemplate]];
    [alert setInformativeText:locString(@"Enter name and login")];
    [alert setAccessoryView:rootView];    
    
    NSButton * okButton = [alert addButtonWithTitle: locString(@"Login")];    
    [alert addButtonWithTitle: locString(@"Cancel")];
     
    [okButton setEnabled: (name.nonEmpty &&
                           pass.nonEmpty)];
    
    [saveButton setAction: @selector(onSavePassButton:)];
    [saveButton setTarget:self];
    
    [nameField setAction: @selector(onNamePassEnter:)];
    [nameField setTarget:self];
    
    [passField setAction: @selector(onNamePassEnter:)];
    [passField setTarget:self];
    
    [nameField setTag:1];
    [passField setTag:2];    
    [sessionButton setTag:3];    
    
    if ( NSAlertFirstButtonReturn == [alert runModal]) 
    {           
        NSString *nameLogin = nameField.stringValue;
        NSString *passLogin = passField.stringValue;
        BOOL savePass = saveButton.state == NSOnState; 
        BOOL session = sessionButton.state == NSOnState;
        
        DDLogInfo(@"login %@ pass %@", nameLogin, passLogin);
        
        [user loginSamizdat:nameLogin
                       pass:passLogin
                      block:^(SamLibStatus status, NSString *error){
            
            if (SamLibStatusSuccess == status) {
        
                if ([nameLogin isNotEqualTo:name])
                    user.login = nameLogin;
                
                if (savePass) {                    
                    if ([passLogin isNotEqualTo:pass])
                        user.pass = passLogin;
                }
                else {
                    if (pass.nonEmpty)
                        user.pass = @"";
                }

                storeSamLibSessionCookies(session);
                
                [self hudSuccess: locString(@"login success")];
                
            } else {
                
                [self hudWarning: KxUtils.format(locString(@"login failure\r\n%@"), 
                                                 error.nonEmpty ? error : locString(@"invalid name or password"))];
            }
            
        }];
               
    }
    
    KX_RELEASE(alert);
    KX_RELEASE(rootView);
    KX_RELEASE(nameField);
    KX_RELEASE(passField);
    KX_RELEASE(saveButton);
    KX_RELEASE(sessionButton);
    
}

//- (IBAction) onSavePassButton: (id) sender
//{
//    NSButton * sessionButton = [[sender superview] viewWithTag:3];
//    [sessionButton setEnabled: [sender state] == NSOnState];
//}

- (IBAction) onNamePassEnter: (id) sender
{  
    NSTextField * nameField = [[sender superview] viewWithTag:1];
    NSTextField * passField = [[sender superview] viewWithTag:2];    
    NSButton * okButton = [[[[sender superview] superview] superview] viewWithTag:NSAlertFirstButtonReturn];      
    
    [okButton setEnabled: (nameField.stringValue.nonEmpty &&
                           passField.stringValue.nonEmpty)];
}

- (IBAction) logoutSamizdat:(id)sender
{
    [[SamLibUser currentUser] logoutSamizdat:^(SamLibStatus status, NSString *error) {
        
        if (SamLibStatusSuccess == status) {
            
            [self hudSuccess: locString(@"logout success")];
            
            storeSamLibSessionCookies(NO);
            
        } else {
            
            [self hudWarning: KxUtils.format(locString(@"logout failure\r\n%@"), 
                                             error.nonEmpty ? error : locString(@"unknown error"))];                                          
        }

    }]; 
}

- (IBAction) clearCookie:(id)sender
{
    deleteSamLibCookie(@"COMMENT");
    deleteSamLibCookie(@"ZUI");    
}

- (IBAction) deleteAuthor:(id)sender
{
    SamLibAuthor * author = nil;
    
    if ([_activeController isKindOfClass:[AuthorViewController class]]) {
            author = [(AuthorViewController *)_activeController author]; 
    } else if ([_activeController isKindOfClass:[AuthorInfoViewController class]]) {
        author = [(AuthorInfoViewController *)_activeController author]; 
    } else {
        return;
    }
        
    NSAlert * alert = [NSAlert alertWithMessageText:locString(@"Delete Author")
                                      defaultButton:locString(@"Yes")
                                    alternateButton:locString(@"No")
                                        otherButton:nil
                          informativeTextWithFormat:locString(@"Are you sure?\n%@\n%@\n%@"),
                       author.name,author.title,author.url];
    
    [alert setIcon: [NSImage imageNamed:NSImageNameCaution]];
    
    if (NSAlertDefaultReturn == [alert runModal]) {
       
        [[SamLibModel shared] deleteAuthor: author];        
        [self showAuthorsView: nil];
    }

}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(goBack:))
    {
        return [_historyNav canGoBack];
    }
    
    if ([item action] == @selector(goForward:))
    {
        return [_historyNav canGoForward];
    }
    
    if ([item action] == @selector(showAddAuthorView:) ||
        [item action] == @selector(showAuthorsView:) ||
        [item action] == @selector(showFavoritesView:) ||
        [item action] == @selector(showBanView:) ||
        [item action] == @selector(showBansView:) ||        
        [item action] == @selector(showHistoryView:) ||
        [item action] == @selector(toggleHUD:) ||
        [item action] == @selector(clearCookie:))
    {
        return YES;
    }
    
    if ([item action] == @selector(loginSamizdat:))
    {
        return ![SamLibUser currentUser].isLogin;
    }
    
    if ([item action] == @selector(logoutSamizdat:))
    {
        return [SamLibUser currentUser].isLogin;
    }    

    if ([item action] == @selector(deleteAuthor:)) 
    {
        return [_activeController isKindOfClass:[AuthorViewController class]];
    }
    
    return NO;
    
}

- (IBAction) reload: (id) sender
{   
    if (_reloaded)
    {
        if ([_reloaded respondsToSelector:@selector(cancel:)]) {
            [_reloaded performSelector:@selector(cancel:)
                            withObject:sender];
                        
            [self finishReload: -1
                   withMessage: locString(@"canceled")];
        }
        
    } else {
        
        [_activeController reload:sender];
    }
}

- (BOOL) startReload: (id) object
         withMessage: (NSString *) message
{
    if (_reloaded)
        return NO;

    _reloaded = KX_RETAIN(object);   
    
    message = KxUtils.format(locString(@"reload\r\n%@"), message);
    
    if (!_hudSpin) {
        _hudSpin = KX_RETAIN([_hudView spin:message style:0]); 
        _hudSpin.textColor = [NSColor whiteColor];
    }
    else {
        _hudSpin.text = message;
        [_hudSpin reset];
    }
    
    _reloadToolbarItem.image = [NSImage imageNamed:NSImageNameStopProgressTemplate];
    
    return YES;
}

- (void(^)(CGFloat progress)) startReload: (id) object
         withMessage: (NSString *) message
         andProgress: (BOOL) unused
{
    if (_reloaded)
        return nil;
    
    _reloaded = KX_RETAIN(object);   
    
    message = KxUtils.format(locString(@"reload\r\n%@"), message);
    
    if (!_progress) {
        _progress = KX_RETAIN([_hudView progress:message style:2]); 
        _progress.textColor = [NSColor whiteColor];
    }
    else {
        _progress.text = message;
        [_progress reset];
    }
    
    _reloadToolbarItem.image = [NSImage imageNamed:NSImageNameStopProgressTemplate];
    
    void (^block)(CGFloat) = ^(CGFloat progress) {
        _progress.progress = progress;
    };
    
    return [block copy];
}

- (void) finishReload: (NSInteger) status 
          withMessage: (NSString *) message
{
    _hudSpin.isComplete = YES;
    _hudSpin.isPinned = NO; 

    _progress.isPinned = NO; 
    
    KX_RELEASE(_reloaded);
    _reloaded = nil;
    
    _reloadToolbarItem.image = [NSImage imageNamed:NSImageNameRefreshTemplate];
    
    if (message.nonEmpty) {
        switch (status) {
            case SamLibStatusSuccess:
                [self hudSuccess: KxUtils.format(locString(@"reload success\r\n%@"), message)];
                break;
                
            case SamLibStatusNotModifed:
                [self hudInfo: KxUtils.format(locString(@"not modified\r\n%@"), message)];
                break;
                
            case SamLibStatusFailure:
                [self hudWarning: KxUtils.format(locString(@"reload failure\r\n%@"), message)];
                break;   
                
            default:
                [self hudInfo: message];
                break;
        }
    }
    
}


@end
