//
//  test.m
//  samlib
//
//  Created by Kolyvan on 09.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "test.h"
#import <Foundation/Foundation.h>
#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "SamLibAuthor.h"
#import "SamLibText.h"
#import "SamLibComments.h"
#import "KxArc.h"
#import "KxUtils.h"
#import "KxConsole.h"
#import "NSObject+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "SamLibUser.h"
#import "JSONKit.h"
#import "GoogleSearch.h"
#import "SamLibCacheNames.h"
#import "SamLibSearch.h"
#import "SamLibStorage.h"
#import "SamLibModerator.h"
#import "DDLog.h"

extern int ddLogLevel;

void test_fetch_page()
{
    __block BOOL finished = NO;
    
    SamLibAgent.fetchData(@"i/iwanow475_i_i/indexdate.shtml", 
                          nil, 
                          NO,
                          nil,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified){
                              
                              finished = YES;
                              
                              KxConsole.printlnf(@"status: %ld length %ld", status, data.length);
                              
                              [data writeToFile:[@"~/tmp/samlib/page.html" stringByExpandingTildeInPath]  
                                     atomically:NO 
                                       encoding:NSUTF8StringEncoding 
                                          error:nil];
                              
                          },
                          nil);
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
}

void test_parser_page()
{
    NSString *s;
    s = [NSString stringWithContentsOfFile:[@"~/tmp/samlib/page.html" stringByExpandingTildeInPath]
                                  encoding:NSUTF8StringEncoding 
                                     error:nil];
    
    NSDictionary *author = SamLibParser.scanAuthorInfo(s);     
    KxConsole.printlnf(@"name: %@", [author get: @"name"]);    
    KxConsole.printlnf(@"title: %@", [author get: @"title"]);        
    KxConsole.printlnf(@"rating: %@", [author get: @"rating"]);    
    KxConsole.printlnf(@"size: %@", [author get: @"size"]);    
    KxConsole.printlnf(@"updated: %@", [author get: @"updated"]);    
    KxConsole.printlnf(@"visitors: %@", [author get: @"visitors"]);    
    KxConsole.printlnf(@"email: %@", [author get: @"email"]);        
    KxConsole.printlnf(@"www: %@", [author get: @"www"]);                
    KxConsole.println(@"\n");
    
    NSString *body;
    body = SamLibParser.scanBody(s);    
    KxConsole.println(body);
    KxConsole.println(@"\n");
    
    for (NSDictionary *d in SamLibParser.scanTexts(body)) {
        KxConsole.printlnf(@"path: %@", [d get: @"path"]);    
        KxConsole.printlnf(@"flagNew: %@", [d get: @"flagNew"]);            
        KxConsole.printlnf(@"title: %@", [d get: @"title"]);    
        KxConsole.printlnf(@"copyright: %@", [d get: @"copyright"]);    
        KxConsole.printlnf(@"size: %@", [d get: @"size"]);    
        KxConsole.printlnf(@"note: %@", [d get: @"note"]);    
        KxConsole.printlnf(@"rating: %@", [d get: @"rating"]);    
        KxConsole.printlnf(@"type: %@", [d get: @"type"]);            
        KxConsole.printlnf(@"group: %@", [d get: @"group"]);    
        KxConsole.printlnf(@"genre: %@", [d get: @"genre"]);            
        KxConsole.printlnf(@"comments: %@", [d get: @"comments"]);                    
        KxConsole.println(@"\n");        
    }
    
}

void test_fetch_textdata()
{
    __block BOOL finished = NO;
    
    SamLibAgent.fetchData(@"http://samlib.ru/i/iwanow475_i_i/metaphysics1.shtml", 
                          nil, 
                          NO,
                          nil,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified){
                              
                              finished = YES;
                              
                              KxConsole.printlnf(@"status: %ld length %ld", status, data.length);
                              
                              data = SamLibParser.scanTextData(data); 
                              
                              [data writeToFile:[@"~/tmp/samlib/text.html" stringByExpandingTildeInPath]  
                                     atomically:NO 
                                       encoding:NSUTF8StringEncoding 
                                          error:nil];
                              
                          },
                          nil);
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
    
}

void test_fetch_comments()
{
    __block BOOL finished = NO;
    
    
    SamLibAgent.fetchData(@"http://samlib.ru/comment/i/iwanow475_i_i/zaratustra", 
                          //@"http://samlib.ru/comment/i/iwanow475_i_i/metaphysics1",
                          nil, 
                          YES,
                          @"http://samlib.ru/comment/i/iwanow475_i_i/",  
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified){
                              
                              finished = YES;
                              
                              KxConsole.printlnf(@"status: %ld length %ld", status, data.length);
                              
                              [data writeToFile:[@"~/tmp/samlib/comments.html" stringByExpandingTildeInPath]  
                                     atomically:NO 
                                       encoding:NSUTF8StringEncoding 
                                          error:nil];
                              
                          },
                          nil);
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
    
}

void test_parse_comments()
{
    NSString *s;
    s = [NSString stringWithContentsOfFile:[@"~/tmp/samlib/comments.html" stringByExpandingTildeInPath]
                                  encoding:NSUTF8StringEncoding 
                                     error:nil];
    
    
    for (NSDictionary *d in SamLibParser.scanComments(s)) {
        KxConsole.printlnf(@"num: %@", [d get: @"num"]);    
        
        NSString *deleteMsg = [d get: @"deleteMsg"];
        if (deleteMsg)
            KxConsole.printlnf(@"delete: %@", deleteMsg);            
        else {
            KxConsole.printlnf(@"name: %@%@", [d contains:@"samizdat"] ? @"*" : @"", [d get: @"name"]);    
            
            KxConsole.printlnf(@"link: %@", [d get: @"link"]);    
            KxConsole.printlnf(@"color: %@", [d get: @"color"]);    
           //NSDate *dt = [d get: @"timestamp"];
            //KxConsole.printlnf(@"timestamp: %@", [dt longDateTimeFormatted]);                
            KxConsole.printlnf(@"date: %@", [d get: @"date"]);                
            KxConsole.printlnf(@"msgid: %@", [d get: @"msgid"]);    
            KxConsole.printlnf(@"replyto: %@", [d get: @"replyto"]);    
            KxConsole.printlnf(@"message: %@", [d get: @"message"]);
        }
        KxConsole.println(@"\n");        
    }
    
}

void test_fetch_author()
{
    __block BOOL finished = NO;
    SamLibAuthor *author = KX_AUTORELEASE([[SamLibAuthor alloc] initWithPath: @"iwanow475_i_i"]);
    //NSString *filepath = [SamLibAgent.authorsPath() stringByAppendingPathComponent: @"iwanow475_i_i"];
    //SamLibAuthor *author = [SamLibAuthor fromFile: filepath];
    
    [author update:^(SamLibAuthor *author, SamLibStatus status, NSString *error) {

        if (status == SamLibStatusSuccess) {
            KxConsole.println(@"updated");    
            if (author.isDirty) {
                KxConsole.println(@"save  ...");    
                [author save:SamLibStorage.authorsPath()];
            }
        } else if (status == SamLibStatusNotModifed) {
            KxConsole.println(@"not modifed");        
        } else if (status == SamLibStatusFailure) {
            KxConsole.printlnf(@"failure %@", error);        
        }

        finished = YES;
    }];
    
     KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
}


void test_fetch_textdata2()
{
    __block BOOL finished = NO;
    //SamLibAuthor *author = [[SamLibAuthor alloc] initWithPath: @"iwanow475_i_i"];
    NSString *filepath = [SamLibStorage.authorsPath() stringByAppendingPathComponent: @"iwanow475_i_i"];
    SamLibAuthor *author = [SamLibAuthor fromFile: filepath];
    
    SamLibText *text = [author.texts objectAtIndex:1];
    
    [text update:^(SamLibText *td, SamLibStatus status, NSString *error) {
        
        if (status == SamLibStatusSuccess) {
            KxConsole.println(@"fetched");            
            
            [td makeDiff:nil];
            
            KxConsole.printlnf(@"make diff: %@", td.diffResult);
            
            //if (td.diffResult.length > 0)
            [author save:SamLibStorage.authorsPath()];
            
            
        } else if (status == SamLibStatusNotModifed) {
            KxConsole.println(@"not modifed");        
        } else if (status == SamLibStatusFailure) {
            KxConsole.printlnf(@"failure %@", error);        
        }
        
        finished = YES;
    }
        progress: nil
       formatter: nil];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    }); 
}


void test_fetch_and_parse_textpage()
{
    __block BOOL finished = NO;
    
    // @"k/kostin_k_k/mp_30.shtml"
    SamLibAgent.fetchData(@"/i/iwanow475_i_i/zaratustra.shtml", 
                          nil, 
                          NO,
                          nil,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified){
                              
                              finished = YES;
                              
                              KxConsole.printlnf(@"status: %ld length %ld", status, data.length);
                              
                              NSDictionary *d = SamLibParser.scanTextPage(data); 
                              
                              KxConsole.printlnf(@"title: %@", [d get: @"title"]);    
                              KxConsole.printlnf(@"copyright: %@", [d get: @"copyright"]);    
                              KxConsole.printlnf(@"size: %@", [d get: @"size"]);
                              KxConsole.printlnf(@"note: %@", [d get: @"note"]);    
                              KxConsole.printlnf(@"rating: %@", [d get: @"rating"]);    
                              KxConsole.printlnf(@"type: %@", [d get: @"type"]);                                       
                              KxConsole.printlnf(@"group: %@", [d get: @"group"]);    
                              KxConsole.printlnf(@"genre: %@", [d get: @"genre"]);            
                              KxConsole.printlnf(@"comments: %@", [d get: @"comments"]);                    
                              
                              
                          },
                          nil);
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });

}


void test_fetch_comments2()
{
    __block BOOL finished = NO;

    NSString *filepath = [SamLibStorage.authorsPath() stringByAppendingPathComponent: @"iwanow475_i_i"];
    SamLibAuthor *author = [SamLibAuthor fromFile: filepath];
    SamLibText *text = [author.texts objectAtIndex:1];
    
    filepath = [SamLibStorage.commentsPath() stringByAppendingPathComponent: text.key];
    filepath = [filepath stringByAppendingPathExtension: @"comments"];
    SamLibComments *comments = [SamLibComments fromFile: filepath withText:text]; 
    
    [comments update:NO 
               block:^(SamLibComments *comments, SamLibStatus status, NSString *error) {
        
        if (status == SamLibStatusSuccess) {
            
            KxConsole.printlnf(@"fetched new comments: %ld", comments.numberOfNew);                        
            if (comments.isDirty)
                [comments save:SamLibStorage.commentsPath()];
            
        } else if (status == SamLibStatusNotModifed) {
            
            KxConsole.println(@"not modifed");        
            
        } else if (status == SamLibStatusFailure) {
            
            KxConsole.printlnf(@"failure %@", error);        
        }
        
        finished = YES;
    }];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
}

void test_post_comment()
{
    __block BOOL finished = NO;
    
    NSString *filepath = [SamLibStorage.authorsPath() stringByAppendingPathComponent: @"iwanow475_i_i"];
    SamLibAuthor *author = [SamLibAuthor fromFile: filepath];
    SamLibText *text = [author.texts objectAtIndex:1];
    
    filepath = [SamLibStorage.commentsPath() stringByAppendingPathComponent: text.key];
    filepath = [filepath stringByAppendingPathExtension: @"comments"];
    SamLibComments *comments = [SamLibComments fromFile: filepath withText:text]; 
    
    [comments post: 
            @"Кто этот окровавленный боец?\r\n"
            @"Он, верно, может сообщить нам вести\r\n"
            @"О мятеже.\r\n"
             block: ^(SamLibComments *comments, SamLibStatus status, NSString *error) {
        
        if (status == SamLibStatusSuccess) {
            
            KxConsole.printlnf(@"fetched new comments: %ld", comments.numberOfNew);                        
            if (comments.isDirty)
                [comments save:SamLibStorage.commentsPath()];
            
        } else if (status == SamLibStatusNotModifed) {
            
            KxConsole.println(@"not modifed");        
            
        } else if (status == SamLibStatusFailure) {
            
            KxConsole.printlnf(@"failure %@", error);        
        }
        
        finished = YES;
    }];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
    
}

void test_login_logout2()
{
    __block BOOL finished = NO;
    
    SamLibUser *user = [SamLibUser currentUser];
    [user loginSamizdat:^(SamLibStatus status, NSString *error) {

        if (status == SamLibStatusSuccess)            
            KxConsole.printlnf(@"login OK");            
        else
            KxConsole.printlnf(@"login FAIL: %@", error);
        
        finished = YES;        
                
    }];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
    
    KxConsole.printlnf(@"user login is: %ld", user.isLogin);
}


void test_post_comment_with_login()
{   
    SamLibUser *user = [SamLibUser currentUser];

    //[user clearCookies];

    test_login_logout2();
    
    if (!user.isLogin)
        return;
    
    user.name = @"Ivanov475";
    user.pass = @"";
 
    __block BOOL finished = NO;
    
    
    NSString *filepath = [SamLibStorage.authorsPath() stringByAppendingPathComponent: @"iwanow475_i_i"];
    SamLibAuthor *author = [SamLibAuthor fromFile: filepath];
    SamLibText *text = [author.texts objectAtIndex:1];
    
    filepath = [SamLibStorage.commentsPath() stringByAppendingPathComponent: text.key];
    filepath = [filepath stringByAppendingPathExtension: @"comments"];
    SamLibComments *comments = [SamLibComments fromFile: filepath withText:text]; 
        
    [comments post: @" О наш отважный брат!* Достойный рыцарь!"
             block: ^(SamLibComments *comments, SamLibStatus status, NSString *error) {
                 
                 if (status == SamLibStatusSuccess) {
                     
                     KxConsole.printlnf(@"fetched new comments: %ld", comments.numberOfNew);                        
                     if (comments.isDirty)
                         [comments save:SamLibStorage.commentsPath()];
                     
                 } else if (status == SamLibStatusNotModifed) {
                     
                     KxConsole.println(@"not modifed");        
                     
                 } else if (status == SamLibStatusFailure) {
                     
                     KxConsole.printlnf(@"failure %@", error);        
                 }
                 
                 finished = YES;
             }];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
    
}


void test_fetch_authors_list()
{
    __block BOOL finished = NO;
        
    SamLibAgent.fetchData(@"/a/", 
                          nil, 
                          NO,
                          nil,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified){
                              
                              finished = YES;
                              
                              KxConsole.printlnf(@"status: %ld length %ld", status, data.length);
                              
                              NSArray *result = SamLibParser.scanAuthors(data); 
                              
                              NSError * error = nil;    
                              NSData * json = [result JSONDataWithOptions:JKSerializeOptionPretty 
                                                                  error:&error];
                              if (!json) {
                                  
                                  KxConsole.printlnf(@"json error: %@",                                               KxUtils.completeErrorMessage(error));        
                                 
                              }
                              else {
                                  error = nil;
                                  if (![json writeToFile:[@"~/tmp/samlib/a_list.json" stringByExpandingTildeInPath]
                                                 options:0 
                                                   error:&error]) {
                                      
                                      KxConsole.printlnf(@"file error: %@",                                                          
                                                  KxUtils.completeErrorMessage(error));        
                                  }    
                              }
                              
                          },
                          nil);
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });

}


void test_vote()
{
     __block BOOL finished = NO;
    
    // dmitriew_p
    NSString *filepath = [SamLibStorage.authorsPath() stringByAppendingPathComponent: @"iwanow475_i_i"];
    SamLibAuthor *author = [SamLibAuthor fromFile: filepath];
    SamLibText *text = [author.texts objectAtIndex:0];
    
    [text vote: 7
         block: ^(SamLibText *text, SamLibStatus status, NSString *error) {
             
             KxConsole.printlnf(@"status %ld %@\n%@", status, text.path, error);        
             
             finished = YES;
         }];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {
        
        return finished;
    });
    
}


void test_search() 
{    
    __block BOOL finished = NO;
    
    [SamLibSearch searchAuthor: @"Смирнов" 
                        byName: YES
                          flag: FuzzySearchFlagAll
                         block:^(NSArray *result) {
                             
                             if (result.nonEmpty) {
                                 
                                 for (NSDictionary *d in result)
                                     KxConsole.printlnf(@"%@ %@ %@ %@", 
                                                        [d get:@"path"], 
                                                        [d get:@"name"],
                                                        [d get:@"distance"],
                                                        [d get:@"from"]);    
                             } else {                                   
                                 
                                 KxConsole.println(@"finish searching");                                       
                                 finished = YES;
                             }
                         }];
    
    KxUtils.waitRunLoop(60, 0.5, ^() {        
        return finished;
    });
}


void test_cache()
{   
    SamLibCacheNames *cache = [[SamLibCacheNames alloc] init];
        
    [cache addPath:@"ivanov"    withName:@"Иванов" withInfo:@"12345"];
    [cache addPath:@"ivanov_s"  withName:@"Иванов Сергей" withInfo:@"ффффффф"];    
    [cache addPath:@"smirnov"   withName:@"Смирнов" withInfo:@"XXXXX"];
    [cache addPath:@"smirnov_a" withName:@"Смирнов Андрей" withInfo:@"YY yy"];
    [cache addPath:@"kolyvan"   withName:@"Колыван" withInfo:@"abcd 123"];    
            
    NSMutableArray *batch = [NSMutableArray array];
    [batch addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Foo Bar", @"name", @"foo", @"path", nil]];
    [batch addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Moo Zoo", @"name", @"moo", @"path", nil]];        
    [cache addBatch:batch];
    
    
    [cache each:^(NSString *path, NSString *name, NSString *info) {       
        KxConsole.printlnf(@"%@|%@|%@", path, name, info);        
    }];
        
    //for (NSDictionary *d in [cache selectByName:@"Смирнов%"])
    //    KxConsole.printlnf(@"%@ %@ %@", [d get:@"path"], [d get:@"name"], [d get:@"info"]);
    //for (NSDictionary *d in [cache selectByPath:@"ivanov%"])
    //    KxConsole.printlnf(@"%@ %@ %@", [d get:@"path"], [d get:@"name"], [d get:@"info"]);
    
    for (NSDictionary *d in [cache selectBySection:'s'])
        KxConsole.printlnf(@"%@ %@ %@", [d get:@"path"], [d get:@"name"], [d get:@"info"]);

    [cache close];
    
    KX_RELEASE(cache);
    
}


void test_for_ban()
{    
    /*
    SamLibBanRule *s1 = [[SamLibBanRule alloc] initFromPattern:@"turok" 
                                                                 category:SamLibBanCategoryName 
                                                                threshold:0.8];
    
    SamLibBanRule *s2 = [[SamLibBanRule alloc] initFromPattern:@"fuck you" 
                                                                 category:SamLibBanCategoryWord 
                                                                threshold:0.6];
    
    SamLibBanRule *s3 = [[SamLibBanRule alloc] initFromPattern:@"turok@mail.ru" 
                                                            category:SamLibBanCategoryEmail];
    
    */
    SamLibBanRule *s4 = [[SamLibBanRule alloc] initFromPattern:@"allah, mega; fuck; fuck off" 
                                                      category:SamLibBanCategoryWord 
                                                     threshold:0.7];

    
    SamLibBan * ban = [[SamLibBan alloc] initWithName:@""
//                                                rules: KxUtils.array(s1, s2, s3, nil) 
                                                rules: KxUtils.array(s4, nil) 
                                            tolerance:2
                                                 path:@""];
    
    NSDictionary *dict = KxUtils.dictionary(@"turok1", @"name", 
                                            @"turok@mail.ru", @"email", 
                                            @"all**h fuck! off! ", @"message", 
                                            nil);
    
    SamLibComment *comment = [SamLibComment fromDictionary:dict];
    
    
    KxConsole.printlnf(@"ban %.3f %d", 
                       [ban computeBan:comment],
                       [ban testForBan:comment withPath:@""]); 
    
    
    //SamLibModerator *moder = [SamLibModerator shared];
    //[moder addBan:ban];
    //[moder save];
    
    KX_RELEASE(s1);
    KX_RELEASE(s2);
    KX_RELEASE(ban);
}




