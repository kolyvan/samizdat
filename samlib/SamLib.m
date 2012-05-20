//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt



#import "SamLib.h"
#import "SamLibAgent.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSDictionary+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "DDLog.h"
#import "JSONKit.h"

extern int ddLogLevel;

////

NSString* getStringFromDict(NSDictionary *dict, NSString *name, NSString *path)
{
    id value = [dict get:name];
    if (value &&
        ![value isKindOfClass:[NSString class]]) {
        
        DDLogCWarn(locString(@"invalid '%@' in dictionary: %@"), name, path);
        value = nil;
    }    
    
    return value;
}

NSDate * getDateFromDict(NSDictionary * dict, NSString *name, NSString *path)
{
    id ts = getStringFromDict(dict, name, path);
    if (ts)
        return [NSDate dateWithISO8601String: ts];
    return nil;
}

NSHTTPCookie * searchSamLibCookie(NSString *name)
{
    NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];    
    NSArray * cookies;
    cookies = [storage cookiesForURL: [NSURL URLWithString: @"http://samlib.ru/"]];
    
    for (NSHTTPCookie *cookie in cookies)
        if ([cookie.name isEqualToString: name])            
            return cookie;
    return nil;
}

NSHTTPCookie * deleteSamLibCookie(NSString *name) 
{
    NSHTTPCookieStorage * storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];    
    NSArray * cookies;
    cookies = [storage cookiesForURL: [NSURL URLWithString: @"http://samlib.ru/"]];
    
    for (NSHTTPCookie *cookie in cookies)
        if ([cookie.name isEqualToString: name])            
        {
            NSHTTPCookie *result = [cookies copy];
            [storage deleteCookie:cookie];
            return KX_AUTORELEASE(result);
        }
    
    return nil;
}

NSDictionary * loadDictionaryEx(NSString *filepath, BOOL immutable)
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:filepath];    
    KX_RELEASE(fm);    
    
    if (r) {        
        
        NSError * error = nil;    
        NSData * data = [NSData dataWithContentsOfFile:filepath
                                               options:0
                                                 error:&error];
        if (data) {
            
            if ([data length] == 0) 
                if (immutable)
                    return [NSDictionary dictionary];
                else
                    return [NSMutableDictionary dictionary];
            
            id obj;
            if (immutable)                
                obj = [data objectFromJSONDataWithParseOptions: JKParseOptionNone
                                                         error: &error];
            else
                obj = [data mutableObjectFromJSONDataWithParseOptions: JKParseOptionNone
                                                                error: &error];
                
            if (obj) {
                
                if ([obj isKindOfClass:[NSDictionary class]])     
                    return obj;                
                
                DDLogCError(locString(@"invalid json for file: %@"), filepath);        
                
            } else {
                DDLogCError(locString(@"json error: %@"), 
                            KxUtils.completeErrorMessage(error));
            }
            
        } else {
            DDLogCError(locString(@"file error: %@"), 
                        KxUtils.completeErrorMessage(error));         
        }
    } else {
        
        DDLogCWarn(locString(@"file not found: %@"), filepath);         
        
    }
    
    return nil;
}

NSDictionary * loadDictionary(NSString *filepath)
{
    return loadDictionaryEx(filepath, YES);
}

BOOL saveDictionary(NSDictionary *dict, NSString * filepath)
{
    NSError * error = nil;    
    NSData * json = [dict JSONDataWithOptions:JKSerializeOptionPretty 
                                        error:&error];
    if (!json) {
        
        DDLogCError(locString(@"json error: %@"), 
                    KxUtils.completeErrorMessage(error));        
        return NO;
    }
    
    error = nil;
    if (![json writeToFile:filepath
                   options:0 
                     error:&error]) {
        
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));        
        
        return NO;
    }    
    return YES;
}

NSString * mkHTMLPage(NSString *data,
                      NSString *head,
                      NSString *cssLink, 
                      NSString *jsLink)
{
    NSMutableString *bb = [[NSMutableString alloc] init];
    
    [bb appendString: @"<!DOCTYPE html>\n"];
    [bb appendString: @"<html lang=\"en\">\n"];
    [bb appendString: @"<head>\n"];
    [bb appendString: @"<meta charset=\"utf-8\">\n"];    
    [bb appendString: @"<title>samlib</title>\n"];    
    if (cssLink.nonEmpty)
        [bb appendFormat: @"<link rel=\"stylesheet\" href=\"%@\">\n", cssLink];    
    if (jsLink.nonEmpty)
        [bb appendFormat: @"<script src=\"%@\"></script>\n"];        
    if (head.nonEmpty)
        [bb appendString: head];
    [bb appendString: @"</head>\n"];    
    [bb appendString: @"<body>\n"];   
    [bb appendString: @"<div class='main'>\n"];    
    
    [bb appendString: data];
    [bb appendString: @"\n"];    
    
    [bb appendString: @"</div>\n"];           
    [bb appendString: @"</body>\n"];        
    [bb appendString: @"</html>\n"];
    
    return KX_AUTORELEASE(bb);
}

/////

@implementation SamLibBase

@synthesize path = _path; 
@synthesize timestamp  = _timestamp; 

@dynamic changed;
@dynamic url;
@dynamic relativeUrl;

- (BOOL) changed
{
    return NO;
}

- (NSString *) relativeUrl 
{  
    return @"";
}

- (NSString *) url 
{
    return [SamLibAgent.samlibURL() stringByAppendingPathComponent: self.relativeUrl];
}

- (id) initWithPath: (NSString *)path
{
    NSAssert(path.nonEmpty, @"empty path");
    
    self = [super init];
    if (self) {        
        
        _path = KX_RETAIN(path);
        _timestamp = KX_RETAIN([NSDate date]);
    }
    
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_path);
    KX_RELEASE(_timestamp);    
    KX_SUPER_DEALLOC();
}

@end
