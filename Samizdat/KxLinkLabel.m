//
//  KxHyperLinkField.m
//  AppKitLab
//
//  Created by Konstantin Boukreev on 19.04.12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "KxLinkLabel.h"
#import "KxArc.h"
#import "NSString+Kolyvan.h"

static NSDictionary* mkAlignmentStyle (NSTextAlignment alignment)
{    
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:alignment];
    
    NSDictionary *result = [NSDictionary dictionaryWithObject:paraStyle 
                                                       forKey:NSParagraphStyleAttributeName];
    KX_RELEASE(paraStyle);
    return result;
}

static NSMutableAttributedString * mkHyperLink (NSString* s, NSString* url, NSTextAlignment alignment)
{    
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] initWithString: s];
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:alignment];
    
    NSRange range = NSMakeRange(0, [as length]);
            
    [as beginEditing];        
    [as addAttribute:NSLinkAttributeName value:url range:range];
    [as addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];    
    [as addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];        
    [as endEditing];
    
    KX_RELEASE(paraStyle);
    return KX_AUTORELEASE(as);
}

static NSMutableAttributedString * mkUnderline (NSString* s, NSTextAlignment alignment)
{    
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] initWithString: s];  
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:alignment];
    NSRange range = NSMakeRange(0, [as length]);
    
    [as beginEditing];    
    //[as addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];    
    [as addAttribute: NSUnderlineStyleAttributeName 
               value:[NSNumber numberWithInt:NSSingleUnderlineStyle] 
               range:range];        
    [as addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    [as endEditing];
    
    KX_RELEASE(paraStyle);
    return KX_AUTORELEASE(as);
}

static NSMutableAttributedString * mkAttributedString (NSString* s, NSTextAlignment alignment)
{    
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] initWithString: s];  
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:alignment];
    NSRange range = NSMakeRange(0, [as length]);
    
    [as beginEditing];    
    [as addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    [as endEditing];
    
    KX_RELEASE(paraStyle);
    return KX_AUTORELEASE(as);
}


static NSString* determineHyperlink(NSString * s)
{
    if (s.length > 3) {
    
        if ([s hasPrefix:@"http://"])
            return s;
        
        if ([s hasPrefix:@"https://"])
            return s;
        
        if ([s hasPrefix:@"mailto:"])
            return s;
        
        if (s.isEmail)
            return [@"mailto:" stringByAppendingString:s];
        
        // x.xx - minimal url, fast & dirty check
        NSRange range = [s rangeOfString:@"."];
        
        if ((range.location > 0) && 
            (range.location < (s.length - 1)))
            return [@"http://" stringByAppendingString:s];
    }
        
    return nil;
}

@implementation KxLinkLabel

@synthesize url =_url;
@synthesize hoveredColor = _hoveredColor;

// todo: setUrl -> call determineHyperlink

- (void) determineHyperlink
{
    if (!_url) {        
        self.url = determineHyperlink([self toolTip]);
        if (!_url)
            self.url = determineHyperlink([self stringValue]);
    }
}

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    KX_RELEASE(_url);    
    KX_RELEASE(_normalColor);   
    KX_RELEASE(_hoveredColor);
    KX_SUPER_DEALLOC();
}
     
- (void)awakeFromNib
{   
    [super awakeFromNib];
    [self determineHyperlink];
}

- (void)setStringValue:(NSString *)s
{
    [super setStringValue:s];
    [self determineHyperlink];
}

- (void)setToolTip:(NSString *)s
{
    [super setToolTip:s];
    [self determineHyperlink];
}

- (void)viewDidMoveToWindow 
{
    [super viewDidMoveToWindow];    
    // if (_url) 
    {
        trackingRect = [self addTrackingRect:[self bounds] 
                                       owner:self 
                                    userData:nil 
                                assumeInside:NO];    
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow 
{
    [super viewWillMoveToWindow:newWindow];     
    if ([self window] && trackingRect) {        
        [self removeTrackingRect:trackingRect];        
    }    
}

- (void)setBounds:(NSRect)bounds 
{
    [super setBounds:bounds];    
    if (trackingRect) {
        [self removeTrackingRect:trackingRect];        
        trackingRect = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];        
    }
}

-(void)resetCursorRects
{
    [super resetCursorRects];     
    if (_url) {
        [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];    
    }
}

- (void) mouseDown:(NSEvent *)theEvent
{    
    [super mouseDown:theEvent];
    if (_url) {
        NSString * p = determineHyperlink(_url);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:p]];
    }     
}

- (void) mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent]; 
    if (_url) {
        if (_hoveredColor) {
            _normalColor = KX_RETAIN([self textColor]);    
            [self setTextColor:_hoveredColor];        
        }
        [self setAttributedStringValue: mkUnderline(self.stringValue, self.alignment)];    
    }
}

- (void) mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];  
    if (_url) {
        if (_normalColor) {
            [self setTextColor:_normalColor];
            KX_RELEASE(_normalColor);
            _normalColor = nil;
        }
        [self setAttributedStringValue: mkAttributedString(self.stringValue, self.alignment)];
    }
}

@end
