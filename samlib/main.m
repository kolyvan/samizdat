//
//  main.m
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "KxUtils.h"
#import "KxConsole.h"
#import "KxTuple2.h"
#import "NSObject+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibAuthor.h"
#import "SamLibComments.h"
#import "SamLibUser.h"
#import "SamLibModel.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "JSONKit.h"
#import "GoogleSearch.h"
#import "test.h"


//static int ddLogLevel = LOG_LEVEL_WARN;
//static int ddLogLevel = LOG_LEVEL_VERBOSE;
int ddLogLevel = LOG_LEVEL_INFO;

void test() 
{    
    // "site:samlib.ru/i intitle:Иванов inurl:indexdate.shtml"
    // "site:samlib.ru/k inurl:indexdate.shtml"
    //
    
    __block BOOL finished = NO;
    googleSearch(@"site:samlib.ru/s intitle:Смирнов intitle:Василий inurl:indexdate.shtml", 
                 ^(GoogleSearchStatus status, NSString *details, NSArray *results) {
                     
                     DDLogCInfo(@"\n%ld %@ %ld\n", status,details, results.count);
                     
                     if (status == GoogleSearchStatusSuccess) {
                         
                         NSMutableSet *ms = [NSMutableSet set];
                         
                         for (NSDictionary * dict in results) {
                             
                             NSString * url =[dict get:@"url"];
                             
                             if ([url hasPrefix:@"http://samlib.ru/k/"])
                                 url = [url drop: @"http://samlib.ru/k/".length];
                             
                             if ([url hasSuffix:@"/indexdate.shtml"])
                                 url = [url take: url.length - @"/indexdate.shtml".length];
                             
                             [ms addObject:url];
                             DDLogCInfo(@"%@", url);
                         }
                         
                         DDLogCInfo(@"total: %ld\n%@", ms.count, ms);
                         
                         saveObject(results, [@"~/tmp/googlesearch.json" stringByExpandingTildeInPath]); 
                     }
                     
                     finished = YES;
                     
                 });
    
    
    KxUtils.waitRunLoop(60, 0.5, ^() {        
        return finished;
    });
}


void initLogger()
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

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        KxConsole.println(@"hi, starting ..");        
        
        initLogger();
        SamLibAgent.initialize();
        
        test();
        
        // ******************
        // test purpose only !
        // ******************
        
        //test_parser_page();
        //test_fetch_comments();        
        //test_fetch_author();
        //test_fetch_textdata2();
        //test_fetch_and_parse_textpage();
        //test_parse_comments();
        //test_fetch_comments2();
        //test_post_comment();
        //test_login_logout();
        //test_login_logout2();
        //test_post_comment_with_login();
        //test_fetch_authors_list();
        //test_vote();
       
        SamLibAgent.cleanup();        
        
        KxConsole.println(@"finished, bye!");
    }
    return 0;
}

