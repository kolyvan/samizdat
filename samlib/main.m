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
#import "SamLibSearch.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "JSONKit.h"

#define NSNUMBER_SHORTHAND
#import "KxMacros.h"

#import "test.h"

//static int ddLogLevel = LOG_LEVEL_WARN;
//static int ddLogLevel = LOG_LEVEL_VERBOSE;
int ddLogLevel = LOG_LEVEL_INFO;

void test() 
{
   
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
        //test_cache();
        //test_search();                
        
        SamLibAgent.cleanup();        
        
        KxConsole.println(@"finished, bye!");
    }
    return 0;
}

