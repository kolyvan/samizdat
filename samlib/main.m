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
#import "NSObject+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibComments.h"
#import "SamLibUser.h"

#import "test.h"

void test()
{
//    SamLibUser *user = [SamLibUser currentUser];
//    user.pass = @"meg11xxx!";
//    KxConsole.printlnf(@"pass: %@", user.pass);
      
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        KxConsole.println(@"hi, starting ..");        
        
        SamLibAgent.initialize();
        
        //test();
        
        //test_parser_page();
        //test_fetch_comments();        
        //test_fetch_author();
        //test_fetch_textdata2();
        //test_fetch_and_parse_textpage();
        //test_parse_comments();
        test_fetch_comments2();
        //test_post_comment();
        //test_login_logout();
        //test_login_logout2();
        //test_post_comment_with_login();
       
        SamLibAgent.cleanup();        
        
        KxConsole.println(@"finished, bye!");
    }
    return 0;
}

