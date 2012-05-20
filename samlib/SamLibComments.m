//
//  SamLibComments.m
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt


#import "SamLibComments.h"
#import "KxArc.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "DDLog.h"
#import "JSONKit.h"
#import "SamLibText.h"
#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "SamLibUser.h"

extern int ddLogLevel;

static NSInteger MAX_COMMENTS = 50;

static NSDate* mkDateFromComment(NSString *dt)
{
    return [NSDate date:dt
                 format:@"yyyy/MM/dd HH:mm" 
                 locale:nil 
               timeZone:[NSTimeZone timeZoneWithName:@"Europe/Moscow"]];
}

/////

@interface SamLibComment() {
    NSDictionary * _dict;
    NSDate * _timestamp;
}
@end

@implementation SamLibComment

@synthesize timestamp = _timestamp;

@dynamic number, deleteMsg, name, link, color, msgid, replyto, message, isSamizdat;

- (NSInteger) number        { return [[_dict get:@"num"] integerValue]; }
- (NSString *) deleteMsg    { return [_dict get: @"deleteMsg"]; }
- (NSString *) name         { return [_dict get: @"name"]; }
- (NSString *) link         { return [_dict get: @"link"]; }
- (NSString *) color        { return [_dict get: @"color"]; }
- (NSString *) msgid        { return [_dict get: @"msgid"]; }
- (NSString *) replyto      { return [_dict get: @"replyto"]; }
- (NSString *) message      { return [_dict get: @"message"]; }
- (BOOL) isSamizdat         { return [_dict contains:@"samizdat"]; }

+ (id) fromDictionary: (NSDictionary *) dict
{ 
    SamLibComment *p = [[SamLibComment alloc] initWithDict:dict];       
    return KX_AUTORELEASE(p);
}

- (NSDictionary *) toDictionary
{    
    return _dict;
}

- (id) initWithDict: (NSDictionary *) dict
{
    NSAssert(dict.nonEmpty, @"empty dict");     
    self = [super init];
    if (self) {
        _dict = KX_RETAIN(dict);
        
        NSString* dt = getStringFromDict(dict, @"date", @"comment");
        if (dt)
            _timestamp = KX_RETAIN(mkDateFromComment(dt));
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_dict);
    KX_RELEASE(_timestamp);
    KX_SUPER_DEALLOC();
}

- (NSComparisonResult) compare: (SamLibComment *) other
{
    if (_timestamp != nil && other.timestamp != nil) {
        NSComparisonResult res = [_timestamp compare:other.timestamp];
        if (res != NSOrderedSame)
            return res;
    }
    
    NSInteger l = self.number;
    NSInteger r = other.number;
    if (l < r)
        return NSOrderedAscending;
    if (l > r)
        return NSOrderedDescending;
    return NSOrderedSame;
}

@end

////

@interface SamLibComments()
@property (readwrite, nonatomic) NSString * lastModified;
@property (readwrite, nonatomic) NSArray * all;
@end

@implementation SamLibComments

@synthesize text = _text;
@synthesize all = _all;
//@synthesize subscribed = _subscribed;
@synthesize lastModified = _lastModified;
@synthesize isDirty = _isDirty;
@synthesize numberOfNew = _numberOfNew;
@dynamic changed;

- (NSString *) relativeUrl
{
    // comment/i/iwanow475_i_i/zaratustra 
    NSString *s = [@"comment" stringByAppendingPathComponent:_text.author.relativeUrl];
    return [s stringByAppendingPathComponent: _path];
}

- (NSString *) filename
{
    return [_text.key stringByAppendingPathExtension:@"comments"];
}

- (BOOL) changed
{
    return _numberOfNew > 0;
}

/*
- (void) setSubscribed:(BOOL)subscribed
{
    if (_subscribed != subscribed) {
        _isDirty = YES;
        _subscribed = subscribed;
    }
}
 */

+ (id) fromDictionary: (NSDictionary *)dict 
             withText: (SamLibText *) text
{

    NSAssert(dict.nonEmpty, @"empty dict");   
    
    SamLibComments * comments = [[SamLibComments alloc] initFromDictionary: dict 
                                                                  withText:text];

    return KX_AUTORELEASE(comments);
}

- (id) initWithText: (SamLibText *) text;
{
    return [self initFromDictionary:nil withText:text];
}

- (id) initFromDictionary: (NSDictionary *)dict 
                 withText: (SamLibText *) text;
{
    NSAssert(text != nil, @"nil text");     
    
    self = [super initWithPath:[text.path stringByDeletingPathExtension]];
    if (self) {
        
        _text = text;
        
        if (dict) {
        
            NSDate * dt = getDateFromDict(dict, @"timestamp", text.path);
            if (dt) self.timestamp = dt;
            
            //_subscribed = [[dict get: @"subscribed" orElse:[NSNumber numberWithBool:NO]] boolValue];    
            
            self.lastModified = getStringFromDict(dict, @"lastModified", text.path);    
            
            id p = [dict get:@"all"];
            if (p) {
                if ([p isKindOfClass:[NSArray class]]) {
                    
                    NSArray * a = p;
                    self.all = [a map:^id(id elem) {
                        return [SamLibComment fromDictionary:elem];
                    }];
                    
                } else {
                    DDLogWarn(locString(@"invalid '%@' in dictionary: %@"), @"all", text.path);
                }
            }
        }
    }
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_lastModified);
    KX_RELEASE(_all);
    KX_SUPER_DEALLOC();
}

- (NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    //if (_subscribed)
    //    [dict update: @"subscribed" value: [NSNumber numberWithBool:YES]];
    
    [dict updateOnly: @"timestamp" valueNotNil: [_timestamp iso8601Formatted]]; 
    [dict updateOnly: @"lastModified" valueNotNil: _lastModified];    
    
    if (_all.nonEmpty) {
        NSArray * a = [_all map:^id(id elem) { return [elem toDictionary]; }];
        [dict update: @"all" value: a]; 
    }
    
    return dict;
}

- (void) updateComments: (NSArray *) fetchedComments
{  
    NSArray *result = [fetchedComments map:^id(id elem) {
        return [SamLibComment fromDictionary:elem];  
    }];
        
    if (_all.nonEmpty) {        

        SamLibComment *first = _all.first;        
        result = [result filter:^BOOL(id elem) {
            return [first isLessThan: elem];            
        }];
    }
    
    if (result.nonEmpty) {
    
        _numberOfNew = result.count;      
                
        NSInteger count = MAX(0, MAX_COMMENTS - result.count);
        if (count > 0) {
            NSArray *old = [_all take: MIN(_all.count, count)];
            result = [result mutableCopy];
            [(NSMutableArray *)result appendAll:old];
        }
        
        self.all = result;     
        self.timestamp = [NSDate date];        
        _isDirty = YES;
    }
}

- (void) update: (UpdateCommentsBlock) block 
           page: (NSInteger) page
         buffer: (NSMutableArray*)buffer
{
    NSString *path = self.relativeUrl;
    if (page > 0) {
        path = [path stringByAppendingFormat:@"?PAGE=%ld", page + 1];
    }
    
    SamLibAgent.fetchData(path, 
                          page ? nil : _lastModified, 
                          YES,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified) {
                              
                              if (status == SamLibStatusSuccess) {
                                  
                                  NSArray *comments = SamLibParser.scanComments(data);
                                  if (comments.nonEmpty) {
                                      
                                      if (lastModified.nonEmpty)
                                          self.lastModified = lastModified;
                                      
                                      // DDLogVerbose(@"fetched %ld comments", comments.count);
                                      
                                      [buffer appendAll:comments];
                                      
                                      if (buffer.count < MAX_COMMENTS)
                                      {                                           
                                          BOOL isContinue = YES;
                                          
                                          if (_all.nonEmpty) {
                                             
                                              SamLibComment *first = _all.first;                                              
                                              SamLibComment *last = [SamLibComment fromDictionary: buffer.last];                                                                                                
                                              isContinue = [first isLessThan: last];
                                          }
                                          
                                          if (isContinue) {
                                              [self update:block 
                                                      page:page + 1 
                                                    buffer:buffer];
                                              return;                                           
                                          }
                                      }
                                  }
                              }    
                              
                              if (buffer.nonEmpty)
                                  [self updateComments: buffer];
                              if (page > 0) { // always success
                                  status = SamLibStatusSuccess;                              
                                  data = nil;
                              }
                              block(self, status, data);
                              
                          });
}

- (void) update: (UpdateCommentsBlock) block
{
    _numberOfNew = 0;
    [self update:block page:0 buffer:[NSMutableArray array]];
}

+ (id) fromFile: (NSString *) filepath 
       withText: (SamLibText *) text
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:filepath];    
    KX_RELEASE(fm);    

    if (!r)
        return KX_AUTORELEASE([[SamLibComments alloc] initWithText:text]);
        
    NSDictionary *dict = loadDictionary(filepath);
    if (dict) {    
        if (dict.nonEmpty)
            return [SamLibComments fromDictionary:dict withText:text];
        return KX_AUTORELEASE([[SamLibComments alloc] initWithText:text]);
    }    
    return nil;
}

- (void) save: (NSString *)folder
{
    if (saveDictionary([self toDictionary], 
                       [folder stringByAppendingPathComponent: self.filename])) {
        _isDirty = NO;
    }
}

- (void) post:(NSString *)message
        block: (UpdateCommentsBlock) block
{
    [self post:message
       replyto: nil
         block:block];
}


- (void) post: (NSString *) message 
      replyto: (NSString *) msgid
        block: (UpdateCommentsBlock) block
{
    SamLibUser *user = [SamLibUser currentUser];
    
    NSMutableDictionary * d = [NSMutableDictionary dictionary];    

    // /i/iwanow475_i_i/zaratustra
    NSString *url = [_text.relativeUrl stringByDeletingPathExtension];
    
    message = [message stringByReplacingOccurrencesOfString:@"\n" 
                                                 withString:@"\r"];
    
    [d update:@"FILE" value:url];
    [d update:@"TEXT" value:message];        
    [d update:@"NAME" value:user.name];
    [d update:@"EMAIL"value:user.email];
    [d update:@"URL"  value:user.isLogin ? user.homePage : user.url];     

    if (msgid.nonEmpty) {
        [d update:@"OPERATION" value:@"store_reply" ];
        [d update:@"MSGID" value:msgid];     
    } else {
        [d update:@"OPERATION" value:@"store_new" ];
        [d update:@"MSGID" value:@""];     
    }
        
    SamLibAgent.postData(@"/cgi-bin/comment",  
                         KxUtils.format(@"http://samlib.ru/cgi-bin/comment?COMMENT=%@", url), 
                         d,
                         ^(SamLibStatus status, NSString *data, NSString *lastModified) {

                             if (status == SamLibStatusSuccess) {
                                 
                                 if (SamLibParser.scanCommentsResponse(data)) {
                                 
                                     NSArray *comments = SamLibParser.scanComments(data);
                                     if (comments.nonEmpty) {
                                         
                                         if (lastModified.nonEmpty)
                                             self.lastModified = lastModified;                                            
                                         [self updateComments: comments];
                                     }
                                                                      
                                 } else {
                                 
                                     data = locString(@"too many comments");
                                     status = SamLibStatusFailure;                                 
                                 }
                             }
                             
                             block(self, status, data);
                         });
    
}

@end
