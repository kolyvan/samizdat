//
//  SamLibUser.h
//  samlib
//
//  Created by Kolyvan on 10.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SamLib.h"

typedef void (^LoginBlock)(SamLibStatus status, NSString *error);

@interface SamLibUser : NSObject

//@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *name;
//@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *login;
//@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *pass;
//@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *email;
//@property (readwrite, nonatomic, KX_PROP_STRONG) NSString *url;
//@property (readonly, nonatomic) NSString *homePage; //only if logged
//@property (readonly, nonatomic) BOOL isLogin;

- (NSString *) name;
- (void) setName:(NSString *)name;
- (NSString *) login;
- (void) setLogin:(NSString *)login;
- (NSString *) pass;
- (void) setPass:(NSString *)pass;
- (NSString *) email;
- (void) setEmail:(NSString *)email;
- (NSString *) url;
- (void) setUrl:(NSString *)url;
- (NSString *) homePage;
- (BOOL) isLogin;

+ (SamLibUser *) currentUser;

- (void) loginSamizdat: (LoginBlock) block;
- (void) logoutSamizdat: (LoginBlock) block;;

- (void) clearCookies;

@end
