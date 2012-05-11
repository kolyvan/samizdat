//
//  AFHTTPClient+Kolyvan.h
//  samlib
//
//  Created by Kolyvan on 07.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "AFHTTPClient.h"

@interface AFHTTPClient (Kolyvan)


- (void) getPath:(NSString *)path
      ifModified:(NSString *)ifModified
   handleCookies:(BOOL) handleCookies
         referer:(NSString *)referer
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure ;

- (void)postPath:(NSString *)path
          referer:(NSString *)referer
       parameters:(NSDictionary *)parameters 
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;



- (void) cancelAll;

@end
