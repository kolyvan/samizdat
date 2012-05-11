//
//  SamLibAgent.m
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibAgent.h"
#import "SamLibAuthor.h"
#import "KxUtils.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "AFHTTPClient+Kolyvan.h"
#import "AFHTTPRequestOperation.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "JSONKit.h"

//static int ddLogLevel = LOG_LEVEL_VERBOSE;
int ddLogLevel = LOG_LEVEL_INFO;
//static int ddLogLevel = LOG_LEVEL_WARN;


#define _DEVELOPMENT_MODE_

//#pragma mark - defaults


static NSString * samlibURL()
{
    static NSString * url = nil;
    
    if (!url) {        
        url = KX_RETAIN([[NSUserDefaults standardUserDefaults] stringForKey:@"samlib"]);
        if (!url)
            url = @"samlib.ru";
    }       
    
    return url;
}

static NSString * authorsPath()
{
    static NSString * path = nil;
    
    if (!path) {
            
#ifdef _DEVELOPMENT_MODE_
        path = [@"~/tmp/samlib/authors/" stringByExpandingTildeInPath];
#else
        path = [KxUtils.privateDataPath() stringByAppendingPathComponent: @"authors"];
#endif              
        KxUtils.ensureDirectory(path);        
    }
    
    return path;
}

static NSString * textsPath()
{
    static NSString * path = nil;
    
    if (!path) {
#ifdef _DEVELOPMENT_MODE_                  
        path = [@"~/tmp/samlib/texts/" stringByExpandingTildeInPath];
#else
        path = [KxUtils.cacheDataPath() stringByAppendingPathComponent: @"texts"];
#endif  
        KxUtils.ensureDirectory(path);                
    }
    
    return path;
}

static NSString * commentsPath()
{
    static NSString * path = nil;
    
    if (!path) {
#ifdef _DEVELOPMENT_MODE_            
        path = [@"~/tmp/samlib/comments/" stringByExpandingTildeInPath];
#else
        path = [KxUtils.cacheDataPath() stringByAppendingPathComponent: @"comments"];
#endif      
        KxUtils.ensureDirectory(path);                
    }
    
    return path;
}

static NSString * settingsPath()
{
    static NSString * path = nil;
    
    if (!path) {
       
#ifdef _DEVELOPMENT_MODE_            
        path = [@"~/tmp/samlib/settings" stringByExpandingTildeInPath];
#else
        path = [KxUtils.privateDataPath() stringByAppendingPathComponent: @"settings"];
#endif        
    }
    
    return path;    
}


NSMutableDictionary * _settings(BOOL save)
{   
    static NSMutableDictionary * dict = nil;
    static NSString *digest = nil;
    
    if (save) {
        
        if (dict.nonEmpty) {
        
            NSString *md5 = [[dict description] md5];
        
            if (![md5 isEqualToString: digest]) {
                
                digest = md5;
                saveDictionary(dict, settingsPath()); 
                
                DDLogCVerbose(@"save settings: %ld", dict.count);
            }
        }
    }
    else {
        
        if (!dict) {
            
            NSDictionary *d = loadDictionary(settingsPath());
            
            if (d) {
                dict = [d mutableCopy];
                digest = [[dict description] md5];
                DDLogCVerbose(@"load settings: %ld", dict.count);
            }
            else
                dict = [NSMutableDictionary dictionary];
               
        }
    }
    
    return dict;
}

NSMutableDictionary * settings()
{       
    return _settings(NO);
}


//#pragma mark - fetching

static AFHTTPClient * httpClient(BOOL cleanup)
{
    static AFHTTPClient *client = nil;
    
    if (cleanup) 
    {
        [client cancelAll];
        KX_RELEASE(client);
        client = nil;
    }
    else if (!client)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            NSIndexSet *codes = [NSIndexSet indexSetWithIndex:304];
            [[AFHTTPRequestOperation class] addAcceptableStatusCodes: codes];
            
            NSSet *contens = [NSSet setWithObject: @"text/html"];    
            [[AFHTTPRequestOperation class] addAcceptableContentTypes: contens];
        });
        
        
        NSString * url = [@"http://" stringByAppendingString: samlibURL()];
        
        client = [[AFHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:url]];
        
        [client setDefaultHeader:@"Accept-Language" value:@"ru-RU, ru, en-US;q=0.8"]; 
        
        //[_client setDefaultHeader:@"User-Agent" value:@"samizdatSpider/0.1, (unknown)"]; 
        [client setDefaultHeader:@"User-Agent" 
                           value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:12.0) Gecko/20100101 Firefox/12.0"]; 
        
        [client setDefaultHeader:@"Pragma" value:@"no-cache"];
        [client setDefaultHeader:@"Cache-Control" value:@"no-cache, max-age=0"];
    }
    
    return client;    
}

static void logResponse(NSHTTPURLResponse * hr)
{
    if (LOG_INFO) {
        DDLogCInfo(@"%ld %@", hr.statusCode, hr.URL);

        if (LOG_VERBOSE) {
            NSDictionary * d = hr.allHeaderFields;
            [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                DDLogCVerbose(@"  %@: %@", key, obj);
            }];
        }
    }
}

static void logRequest(NSURLRequest * req)
{
    if (LOG_INFO) {
        DDLogCInfo(@"%@ %@", req.HTTPMethod, req.URL);
        
        if (LOG_VERBOSE) {
            NSDictionary * d = req.allHTTPHeaderFields;
            [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                DDLogCVerbose(@"  %@: %@", key, obj);
            }];
        }
    }
}

static void handleSuccess(AFHTTPRequestOperation *operation, 
                          id responseObject, 
                          AsyncResultBlock block)
{
    NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
    
    logRequest(operation.request);
    logResponse(response);
    
    if (response.statusCode == 304) {
        block(SamLibStatusNotModifed, nil, nil);
    } else  {
        
        NSString *lastModified = [response.allHeaderFields objectForKey:@"Last-Modified"];
        block(SamLibStatusSuccess, operation.responseString, lastModified);
    }
}

static void handleFailure(AFHTTPRequestOperation *operation, 
                          NSError *error,
                          AsyncResultBlock block)
{
    NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
    
    logRequest(operation.request);
    logResponse(response);
    
    NSString *message = nil;
    
    if (response)
        message = [NSHTTPURLResponse localizedStringForStatusCode: response.statusCode];                  
    else
        message = [error localizedDescription];
    
    block(SamLibStatusFailure, message, nil);      
}

static void fetchData(NSString *path, 
                      NSString *lastModified, 
                      BOOL handleCookies,
                      NSString *referer, 
                      AsyncResultBlock block)
{
    AFHTTPClient *client = httpClient(NO);
    
    [client getPath: path
         ifModified: lastModified
      handleCookies: handleCookies
            referer: referer
            success:^(AFHTTPRequestOperation *operation, id responseObject) {                  
                
                handleSuccess(operation, responseObject, block);
                
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                handleFailure(operation, error, block);
                
            }];
}

static void postData(NSString *path, 
                     NSString *referer, 
                     NSDictionary * parameters,
                     AsyncResultBlock block)
{
    AFHTTPClient *client = httpClient(NO);
    
    NSStringEncoding stringEncoding = client.stringEncoding;
    client.stringEncoding = NSWindowsCP1251StringEncoding;

    [client postPath:path
             referer:referer
          parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 
                 handleSuccess(operation, responseObject, block);
             } 
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 
                handleFailure(operation, error, block);
                 
             }];
    
    client.stringEncoding = stringEncoding; 
}

/*
static void loginSamizdat(NSString *name, 
                          NSString *pass,
                          AsyncResultBlock block)
{
    NSMutableDictionary * d = [NSMutableDictionary dictionary];
    
    [d setValue:@"login" forKey:@"OPERATION"];    
    [d setValue:@"http://samlib.ru/" forKey:@"BACK"];        
    [d setValue:name forKey:@"DATA0"];
    [d setValue:pass forKey:@"DATA1"];    
    
    postData(@"/cgi-bin/login", @"http://samlib.ru/cgi-bin/login", d, block); 
}

static void logoutSamizdat(AsyncResultBlock block)
{
    postData(@"/cgi-bin/logout", @"http://samlib.ru/", nil, block);
}
*/
///

static NSArray* authors()
{    
    NSMutableArray * authors = [NSMutableArray array];
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    NSError *error;
    NSArray * files = [fm contentsOfDirectoryAtPath:authorsPath() 
                                              error:&error];
    if (files) {
        
        for (NSString *filename in files) {
            
            if (filename.first != '.') {
                
                NSString * fullpath = [authorsPath() stringByAppendingPathComponent:filename];
                NSDictionary *attr = [fm attributesOfItemAtPath:fullpath error:nil];
                
                if ([[attr get:NSFileType] isEqualTo: NSFileTypeRegular]) {
                    
                    SamLibAuthor *author = [SamLibAuthor fromFile: filename];
                    if (author) {
                        DDLogCVerbose(@"loaded author: %@", author.path);
                        [authors push: author];
                    }
                }
            }
        }
    } else {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));        
    }
    
    KX_RELEASE(fm);
    return authors;
}

static void removeAuthor(NSString *path)
{
    NSError * error;    
    NSString * fullpath = [authorsPath() stringByAppendingPathComponent:path];
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (![fm removeItemAtPath:fullpath error:&error]) {
        DDLogCError(locString(@"file error: %@"), 
                   KxUtils.completeErrorMessage(error));                   
    }    
    KX_RELEASE(fm);
}

//


static void initialize ()
{
    NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:@"logLevel"];
    if (logLevel)
        ddLogLevel = [logLevel intValue];    
    
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];    
#else    
    DDFileLogger *fileLogger;    
    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;    
    [DDLog addLogger:fileLogger];
    [fileLogger release];    
#endif
    
    
}

static void cleanup ()
{
    httpClient(YES);    // stop and release client
    _settings(YES);     // save settings
}


SamLibAgent_t SamLibAgent = {
    
    initialize,
    cleanup,
    
    samlibURL,
    authorsPath,
    textsPath,
    commentsPath,
    //settingsPath,
    settings,
    
    fetchData,
    postData,
    //loginSamizdat,
    //logoutSamizdat,
    
    authors,
    removeAuthor,
};