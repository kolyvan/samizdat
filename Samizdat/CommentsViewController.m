//
//  CommentsViewController.m
//  samlib
//
//  Created by Kolyvan on 14.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "CommentsViewController.h"
#import <WebKit/WebKit.h>

#import "KxMacros.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"

#import "DDLog.h"

#import "SamLibModel.h"
#import "AppDelegate.h"
#import "KxHUD.h"

#import "SamLibUser.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibComments.h"

extern int ddLogLevel;


static NSString * mkHTML(SamLibComments * comments)
{  
    static NSString *templateComments = nil;
    static NSString *templateComment = nil;    
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        templateComments = [NSString stringWithContentsOfFile:KxUtils.pathForResource(@"comments.html")
                                                     encoding:NSUTF8StringEncoding 
                                                        error:nil];
                
        templateComments = [templateComments stringByReplacingOccurrencesOfString:@"COMMENTS.CSS"
                                                                       withString:KxUtils.pathForResource(@"comments.css")];
        
        templateComment  = [NSString stringWithContentsOfFile:KxUtils.pathForResource(@"comment.html")
                                                     encoding:NSUTF8StringEncoding 
                                                        error:nil];
    });
    
    NSMutableString * sb = [NSMutableString string];
    
    //NSInteger numberOfNew = comments.numberOfNew;
    
    for (SamLibComment * comment in comments.all) {
        
        NSString 
            *deleteMsg = comment.deleteMsg,
            *replyto = nil, 
            *message = nil, 
            *link = nil, 
            *color = nil, 
            *name = nil,
            *msgid = nil;
        
        if (!deleteMsg.nonEmpty) {
            
            replyto = comment.replyto;
            if (replyto.nonEmpty) {
                NSMutableString * sbx = [NSMutableString string];            
                for (NSString * line in [replyto lines])
                    [sbx appendFormat:@"<span>%@</span>", line];         
                replyto = sbx;
            }       
            
            message = comment.message;
            if (message.nonEmpty) {
                NSMutableString * sbx = [NSMutableString string];            
                for (NSString * line in [message lines])
                    [sbx appendFormat:@"<span>%@</span>", line];         
                message = sbx;
            }       
            
            link = comment.link;
            color = comment.color;
            name = comment.name;
            msgid = comment.msgid;
        }
        
        if (!replyto) replyto = @"";
        if (!message) message = @"";
        if (!link) link = @"";        
        if (!color) color = @"";
        if (!name) name = @"";
        if (!msgid) msgid = @"";     
               
        [sb appendFormat:templateComment, 
         comment.number,
         comment.isSamizdat ? @"" : @"hidden",         
         link,
         link.nonEmpty ? color : @"hidden",
         name,
         link.nonEmpty ? @"hidden" : color,
         name,         
         comment.timestamp ? [comment.timestamp shortRelativeFormatted] : @"",
         deleteMsg.nonEmpty ? KxUtils.format(@"- Удалено %@", comment.deleteMsg) : @"",
         //numberOfNew-- > 0 ? @"new" : @"",
         comment.isNew ? @"new" : @"",
         msgid,
         comment.canDelete ? @"deletelink" : @"hidden",         
         msgid,
         comment.canEdit ? @"editlink" : @"hidden",
         replyto,
         message,
         msgid,
         deleteMsg.nonEmpty ? @"hidden" : @"replylink"         
         ];

    }
    
    return [templateComments stringByReplacingOccurrencesOfString:@"<!-- COMMENTS -->" 
                                                       withString:sb];    
}

////

@interface CommentsViewController () {
    SamLibComments * _comments;
    
    IBOutlet NSTextView * _textView;
    IBOutlet NSTextField * _nameField;
    IBOutlet NSTextField * _urlField;
    IBOutlet NSButton *  _postButton;
    IBOutlet NSButton *  _cancelButton;    
    IBOutlet NSBox * _replyBox;
    
    BOOL _toggleReply;
    NSString * _msgid;
    BOOL _isReply;
    
    id _version;
}

@property (readonly, nonatomic) NSTextField * nameField;
@property (readwrite, nonatomic, copy) id version;

@end


@implementation CommentsViewController

@synthesize nameField = _nameField;
@synthesize version = _version;
 
- (id)init
{
    self = [super initWithNibName:@"CommentsView"];
    if (self) {
    }    
    return self;
}

- (void) dealloc 
{
    KX_RELEASE(_comments);
    KX_RELEASE(_msgid);
    KX_RELEASE(_version);
    KX_SUPER_DEALLOC();
}

- (void) reset: (id) obj
{
    NSAssert([obj isKindOfClass: [SamLibComments class]], @"invalid class");
    SamLibComments * comments = obj;    
    
    if (_comments == comments &&
        [comments.version isEqualTo:_version]) {            

            return;  
    }

    self.version = comments.version;    
    _needReloadWebView = YES;        
    KX_RELEASE(_comments);
    _comments = KX_RETAIN(comments);        
    
    DDLogInfo(@"reload comments view %@", _comments.text.path);        
}

- (void) activate
{
    if (!_toggleReply)
        [self toggleReplyWithAnimation: NO];
    [super activate];
}

- (void) handleReload: (SamLibStatus) status error: (NSString *)error
{
    AppDelegate *app = [NSApp delegate];   
    
    if (status == SamLibStatusSuccess) {
        
        if (_comments.numberOfNew == 0) {
            
            [app finishReload:SamLibStatusNotModifed 
                  withMessage:KxUtils.format(locString(@"comments to %@"), _comments.text.title)];
            
        } else {       
            
            [app finishReload:status 
                  withMessage:KxUtils.format(@"new comments:%ld", _comments.numberOfNew)];            
            [self reloadWebView];
        }
        
    } else {
        [app finishReload:status withMessage:error];
    }
    
}

- (void)reload:(id)sender
{     
    AppDelegate *app = [NSApp delegate];    
    
    if ([app startReload:self 
             withMessage:KxUtils.format(locString(@"comments to %@"), _comments.text.title)]) {
        
        [_comments update:NO 
                    block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
            
            [self handleReload: status error: error]; 
            
        }];
    }
}

- (void) reloadWebView
{
    NSString *html = mkHTML(_comments);
    
    //[html writeToFile:[@"~/tmp/comments.html" stringByExpandingTildeInPath]
    //       atomically:NO 
    //         encoding:NSUTF8StringEncoding 
    //            error:nil];
    
    [self loadWebViewFromHTML:html
                     withPath:@"file://comments"];
}

- (BOOL) navigateUrl: (NSURL *) url
{
    NSString *s  = [url absoluteString];
    
    //if (!s.nonEmpty)
    //    return YES;

    AppDelegate *app = [NSApp delegate];
   
    if ([s isEqualToString:@"file://comments"])
        return YES;
    
    if ([s isEqualToString:@"file://comments/name"]) {
        [app showTextView:_comments.text];        
        return NO;
    }
    
    if ([s isEqualToString:@"file://comments/author"]) {
        [app showAuthorView:_comments.text.author];        
        return NO;
    }
    
    if ([s isEqualToString:@"file://comments/reload"]) {
        [self reload:nil];
        return NO;
    }
    
    if ([s hasPrefix:@"file://comments/reply"]) {
        [self replyToComment: [url lastPathComponent]];
        return NO;
    }
    
    if ([s hasPrefix:@"file://comments/delete"]) {
        [self deleteComment: [url lastPathComponent]];
        return NO;
    }

    if ([s hasPrefix:@"file://comments/edit"]) {
        [self editComment: [url lastPathComponent]];
        return NO;
    }

    
    [[NSWorkspace sharedWorkspace] openURL:url];
    
    return NO;
}

- (void) prepareHTML: (NSURL *)url
{

    WebFrame *mainFrame = [_webView mainFrame];
    DOMDocument * dom = [mainFrame DOMDocument];
    
    [self webViewSetString:_comments.text.author.name 
                     forID:@"authorName" 
                     inDom:dom];
    
    [self webViewSetString:_comments.text.title 
                     forID:@"textName" 
                     inDom:dom];    

    NSString *s = locString(@"none");

    NSInteger numberOfNew = _comments.numberOfNew;
    if (numberOfNew > 0) {
        s = KxUtils.format(@"%ld", numberOfNew);
    } else {
        
        NSInteger deltaComments = _comments.text.deltaComments;
        if (deltaComments > 0)
            s = KxUtils.format(locString(@"%ld available"), deltaComments);
    }
    
    [self webViewSetString: s
                     forID: @"commentsStat" 
                     inDom: dom];    


}

- (void) showReply: (NSString *)msgid 
       withMessage: (NSString *) message
{
    KX_RELEASE(_msgid);
    _msgid = KX_RETAIN(msgid);                
    
    SamLibUser *user = [SamLibUser currentUser];
    
    _nameField.stringValue = user.name;
    [_postButton setEnabled: _nameField.stringValue.nonEmpty];
    
    if (user.isLogin) {
        
        [_urlField setEditable:NO];
        _urlField.stringValue = KxUtils.format(locString(@"logged as %@"), user.login);
        
    } else {
        
        [_urlField setEditable:YES];
        _urlField.stringValue = user.url;    
    }
    
    
    if (_toggleReply)
        [self toggleReplyWithAnimation: YES]; 
    
    [_textView setString:message]; 
}

- (void) replyToComment: (NSString *) msgid 
{        
    NSString *message = @"";
    
    if (msgid) {
    
        for (SamLibComment * comment in _comments.all) {
            if ([comment.msgid isEqualToString:msgid]) {
                
                NSMutableString * ms = [NSMutableString string];
                
                [ms appendFormat: @"> > [%ld.%@]\n", comment.number, comment.name];
                
                for (NSString * s in [comment.message lines]) {
                    if (s.nonEmpty) {
                        [ms appendString:@">"];
                        [ms appendString:s];
                        [ms appendString:@"\n"];
                    }
                }

                message = ms;
                break;
            }
        }
    } 
    
    _isReply = YES;
    [self showReply: msgid withMessage: message];    
}

- (void) deleteComment: (NSString *) msgid
{
    DDLogInfo(@"deleteComment %@", msgid);
    AppDelegate *app = [NSApp delegate];    
    
    if ([app startReload:self 
             withMessage:locString(@"delete comment")]) {
        
        [_comments deleteComment:msgid 
                           block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
            
            [self handleReload: status error: error]; 
            
        }];
    }
    
}

- (void) editComment: (NSString *) msgid
{        
    if (!msgid.nonEmpty)
        return;
    
    NSString *message = @"";
    for (SamLibComment * comment in _comments.all)
        if ([comment.msgid isEqualToString:msgid]) {
            message = comment.message;
            break;
        }
           
    _isReply = NO;
    [self showReply: msgid withMessage:message];
}

- (void) toggleReplyWithAnimation: (BOOL) animated
{
    NSRect rc = [_webView frame];      
    
    const int DMOVE = 220;
    
    if (_toggleReply) { 
        
        rc.size.height -= DMOVE;
        
        [_replyBox setHidden:NO];
        
        if (animated)
        {   
            [[_replyBox animator] setAlphaValue:1.0];                        
            [[_webView animator] setFrame:rc];
        }
        else 
        {
            [_webView setFrame:rc];            
        }
    }
    else {
        
        rc.size.height += DMOVE;
        
        if (animated) {
            
            [[_replyBox animator] setHidden:YES];
            [[_replyBox animator] setAlphaValue:0.0];
            [[_webView animator] setFrame:rc];    
        } 
        else {
            
            [_replyBox setHidden:YES];
            [_webView setFrame:rc];            
        }
    }    
    
    _toggleReply = !_toggleReply;

}

- (IBAction)postComment:(id)sender
{    
    NSString * message = [_textView string];    
    if (!message.nonEmpty)
        return;        
    
    AppDelegate *app = [NSApp delegate];    
    
    if ([app startReload:self 
             withMessage:KxUtils.format(locString(@"post to %@"), _comments.text.title)]) {    
        
        if (!_toggleReply)
            [self toggleReplyWithAnimation: YES];
    
        message = [message copy];
        [_textView setString:@""];    
        
        SamLibUser *user = [SamLibUser currentUser];
        
        NSString *name = _nameField.stringValue;
        if ([user.name isNotEqualTo:name])
            user.name = name;
        
        if (!user.isLogin) {
            NSString *url = _urlField.stringValue;    
            if ([user.url isNotEqualTo:url])
                user.url = url;
        }
        
        [_comments post:message
                msgid:_msgid
                isReply:_isReply
                  block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
            
                     [self handleReload: status error: error]; 
        }];
        
        KX_RELEASE(message);

    }    
}

- (IBAction)cancelPost:(id)sender
{    
    if (!_toggleReply)
        [self toggleReplyWithAnimation: YES];
}

- (IBAction)nameEdited:(id)sender
{
    [_postButton setEnabled: [sender stringValue].nonEmpty];
}

@end
