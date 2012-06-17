//
//  GoogleSearch.m
//  samlib
//
//  Created by Kolyvan on 17.06.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "GoogleSearch.h"
#import "KxMacros.h"
#import "KxUtils.h"
#import "NSArray+Kolyvan.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "AFHTTPClient+Kolyvan.h"
#import "AFHTTPRequestOperation.h"
#import "JSONKit.h"
#import "DDLog.h"
//#import "SamLib.h"

extern int ddLogLevel;

/*
 query samples:
    site:samlib.ru/k inurl:indexdate.shtml
    site:samlib.ru/i intitle:Иванов inurl:indexdate.shtml 
    site:samlib.ru/s intitle:Смирнов intitle:Василий inurl:indexdate.shtml 
*/

typedef void (^GetGoogleSearchResult)(GoogleSearchStatus status, NSString *details, NSDictionary *data);

static void getGoogleSearch(AFHTTPClient *client, NSDictionary *parameters, GetGoogleSearchResult block)
{ 
    [client getPath: @"ajax/services/search/web"
       ifModified: nil
    handleCookies: NO
          referer: nil
       parameters: parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {                  
              
              NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
              
              DDLogCInfo(@"%ld %@", response.statusCode, response.URL);
              
              NSError *error;
              NSDictionary *json;
              json =[operation.responseString objectFromJSONStringWithParseOptions:JKParseOptionNone 
                                                                             error:&error];
              if (json) {
                  
                  NSInteger status = [[json get: @"responseStatus"] integerValue];
                  if (status == 200) {
                      
                      NSDictionary *data = [json get: @"responseData"];
                      block(GoogleSearchStatusSuccess, nil, data);                      
                      
                  } else {
                      
                      NSString * details = [json get: @"responseDetails"];                      
                      block(GoogleSearchStatusResponseFailure, KxUtils.format(@"%d(%@)", status, details), nil);
                  }
                  
                  
              } else {
                      
                  NSString * details = KxUtils.completeErrorMessage(error);
                  block(GoogleSearchStatusJSONFailure, details, nil);
              }
             
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              NSHTTPURLResponse * response = (NSHTTPURLResponse *)operation.response;
              
              DDLogCInfo(@"%ld %@", response.statusCode, response.URL);
              
              NSString *message = nil;
              
              if (response)
                  message = [NSHTTPURLResponse localizedStringForStatusCode: response.statusCode];                  
              else
                  message = [error localizedDescription];
           
              block(GoogleSearchStatusHTTPFailure, message, nil);
              
          }
         progress:nil];
}

static void nextGoogleSearch(AFHTTPClient *client, 
                             NSDictionary *parameters, 
                             NSArray *pages, 
                             NSMutableArray *results,
                             GoogleSearchResult block)
{
    NSDictionary *page = pages.first;
    NSMutableDictionary *parameters_ = [parameters mutableCopy];    
    NSString *start = [page get:@"start"];
    [parameters_ update:@"start" value:start];    
    
    getGoogleSearch(client, 
                    parameters_, 
                    ^(GoogleSearchStatus status, NSString *details, NSDictionary *data) {
        
        if (status == GoogleSearchStatusSuccess) {
            
            NSArray *r = [data get:@"results"];   
            
            //DDLogCInfo(@"get page %@ = %ld", [page get:@"label"], r.count);
            
            [results appendAll:r];
            
            if (pages.count > 1)                
                nextGoogleSearch(client, parameters, pages.tail, results, block);
            else
                block(GoogleSearchStatusSuccess, nil, results);            
            
        } else {
            
            DDLogCWarn(@"googleSearch failure: %d %@", status, details);            
            
            // at least one request has been received successfully            
            block(GoogleSearchStatusSuccess, nil, results); 
        }
    });    
}

void googleSearch(NSString *query, GoogleSearchResult finalBlock)
{
    // example
    // http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=site:samlib.ru/k%20inurl:indexdate.shtml&start=0
    
    AFHTTPClient *client;
    client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://ajax.googleapis.com/"]];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [parameters update:@"v" value:@"1.0"];
    [parameters update:@"rsz" value:@"8"];
    [parameters update:@"start" value:@"0"];
    [parameters update:@"q" value:query];
     
    getGoogleSearch(client, 
                    parameters, 
                    ^(GoogleSearchStatus status, NSString *details, NSDictionary *data) {
               
        if (status == GoogleSearchStatusSuccess) {
                         
            //saveObject(data, [@"~/tmp/google.json" stringByExpandingTildeInPath]);
            
            NSMutableArray *results = [[data get:@"results"] mutableCopy];                        
            NSDictionary *cursor = [data get:@"cursor"];
            NSArray *pages = [cursor get:@"pages"];
            
            //DDLogCInfo(@"get page %@ = %ld", [pages.first get:@"label"], results.count);

            if (pages.count > 1)
                nextGoogleSearch(client, parameters, pages.tail, results, finalBlock);
            else
                finalBlock(GoogleSearchStatusSuccess, nil, results);
            
            /*
            
             opps, google doesn't like such simultaneous requests            
             
            if (pages.count > 1) {
                __block NSInteger count = pages.count - 1;
                for (NSDictionary *page in pages.tail) {
                    
                    NSMutableDictionary *parameters_ = [parameters mutableCopy];
                    NSString *start = [page get:@"start"];
                    [parameters_ update:@"start" value:start];    
                    
                    getGoogleSearch(client, parameters_, ^(GoogleSearchStatus status, NSString *details, NSDictionary *data) {
                        
                        if (status == GoogleSearchStatusSuccess) {
                            
                            NSArray *r = [data get:@"results"];   
                            
                            DDLogCInfo(@"get page %@ = %ld", [page get:@"label"], r.count);
                            
                            [results appendAll:r];                                                                        
                            
                        } else {
                            
                            DDLogCWarn(@"googleSearch failure: %d %@", status, details);
                        }
                        
                        if (--count == 0)                        
                            finalBlock(GoogleSearchStatusSuccess, nil, results);                                        
                    });     
                }
            } else {
                finalBlock(GoogleSearchStatusSuccess, nil, results);
            }
            */
            
        } else {
                
            finalBlock(status, details, nil);                                        
        }       
    });
}
