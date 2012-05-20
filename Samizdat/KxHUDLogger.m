//
//  KxHUDLogger.m
//  samlib
//
//  Created by Kolyvan on 11.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "KxHUDLogger.h"
#import "KxArc.h"
#import "KxHUD.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"

@interface KxHUDLogger() {

    KX_WEAK KxHUDView * _hudView;
}

@end

@implementation KxHUDLogger

- (id) init: (KxHUDView *) hudView
{
    self = [super init];    
    if (self) {
        _hudView  = hudView;
    }
    return self;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    NSString *logMsg = logMessage->logMsg;
    
    //if (logFormatter)
    //    logMsg = [logFormatter formatLogMessage:logMessage];
    
    if (logMsg.nonEmpty)
    {   
        NSString *message = nil;
        NSColor *color;
        NSTimeInterval interval;
        switch (logMessage->logFlag)
        {
            case LOG_FLAG_ERROR: {
                NSString *s = [NSString stringWithCString:logMessage->file encoding:NSASCIIStringEncoding];
                message = KxUtils.format(@"%@\n%@ %s", logMsg, [s lastPathComponent], logMessage->function);                
                color = [NSColor redColor];
                interval = 8;     
            }
                break;
                
            case LOG_FLAG_WARN:
                message = logMsg; 
                color = [NSColor yellowColor];
                interval = 8;
                break;
                
            case LOG_FLAG_INFO: 
                //message = logMsg; 
                //color = [NSColor lightGrayColor];
                //interval = 3;
                break;                                
                
            default: 
                break;    
        }
        
        if (message) { 
            
            dispatch_queue_t mainQueue = dispatch_get_main_queue(); 
            dispatch_async(mainQueue, ^(void) {
                id<KxHUDRow> r = [_hudView message: message color: color interval: interval]; 
                if (logMessage->logFlag == LOG_FLAG_ERROR) {
                    r.isPinned = YES;
                }
            });
        }
    }
}

@end