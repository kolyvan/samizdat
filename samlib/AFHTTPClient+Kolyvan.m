//
//  AFHTTPClient+Kolyvan.m
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "AFHTTPClient+Kolyvan.h"
#import "AFURLConnectionOperation.h"
#import "AFHTTPRequestOperation.h"


@implementation AFHTTPClient (Kolyvan)

- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure 
{
    NSAssert(path != nil && path.length > 0, @"empty path");
    
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
    
    [request setHTTPShouldHandleCookies: handleCookies];            
    
    if (referer)
        [request addValue:referer forHTTPHeaderField:@"Referer"];
    
    if (ifModified) {
        [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];        
        [request addValue:ifModified forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];     
    [self enqueueHTTPRequestOperation:operation];
    
}

- (void)postPath:(NSString *)path
         referer:(NSString *)referer
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{    
    NSAssert(path != nil && path.length > 0, @"empty path");
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
    
    [request setHTTPShouldHandleCookies: YES];            
    
    if (referer)
        [request addValue:referer forHTTPHeaderField:@"Referer"];
    
    // this is for Samizdat site 
    // code-monkeys cannot into content-type charset
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];    
    
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];    
}


- (void) cancelAll 
{
    for (NSOperation *operation in [self.operationQueue operations]) {
        if ([operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            [operation cancel];
        }
    }
}


@end
