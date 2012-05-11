
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

NSDictionary * loadDictionary(NSString *filepath)
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
                return [NSDictionary dictionary];
            
            id obj = [data objectFromJSONDataWithParseOptions: JKParseOptionNone
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
    } 
    
    return nil;
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
