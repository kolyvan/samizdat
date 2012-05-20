//
//  KxHUD.m
//  AppKitLab
//
//  Created by Konstantin Boukreev on 29.04.12.
//  Copyright 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "KxHUD.h"
#import "KxArc.h"
#import "KxUtils.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"

#define YPADDING 8
#define XMARGIN 4
#define YMARGIN 4

#define CLOSE_BUTTON_SIZE 16
#define CIRCLE_PROGRESS_SIZE 24

#define BAR_PROGRESS_HEIGHT 12
#define BAR_PROGRESS_WIDTH 36

#define SPIN_BOXES_COUNT 16

#define LEFT_PADDING (XMARGIN + CLOSE_BUTTON_SIZE + XMARGIN)
#define RIGHT_PADDING (XMARGIN + CLOSE_BUTTON_SIZE)

#define TICKTIME 0.1
#define FADETIME 0.8
#define FADETICK 0.1


#pragma mark - Drawing

//
// drawPie & drawAnnularPie is taken from 
// MBRoundProgressView from https://github.com/jdg/MBProgressHUD
//

static void drawAnnularPie(NSRect bounds, CGFloat progress)
{   
    // Draw background
    CGFloat lineWidth = 4.f;
    
    NSBezierPath *processBackgroundPath = [NSBezierPath bezierPath];
    processBackgroundPath.lineWidth = lineWidth;
    processBackgroundPath.lineCapStyle = kCGLineCapRound;
    
    CGPoint center = CGPointMake(bounds.origin.x + 
                                 bounds.size.width/2, 
                                 bounds.origin.y +
                                 bounds.size.height/2);
    
    CGFloat radius = (bounds.size.width - lineWidth)/2;
    
    [processBackgroundPath appendBezierPathWithArcWithCenter:center
                                                      radius:radius
                                                  startAngle:0
                                                    endAngle:360
                                                   clockwise:NO];
    
    [[NSColor colorWithDeviceWhite:1 alpha:0.3] set];
    [processBackgroundPath stroke];
    
    // Draw progress
    NSBezierPath *processPath = [NSBezierPath bezierPath];
    processPath.lineCapStyle = kCGLineCapRound;
    processPath.lineWidth = lineWidth;
    
    [processPath appendBezierPathWithArcWithCenter:center
                                            radius:radius
                                        startAngle:-90
                                          endAngle:-90 - progress * 360.0
                                         clockwise:YES];
    
    [[NSColor whiteColor] set];
    [processPath stroke];    
}

static void drawPie(NSRect bounds, CGFloat progress)
{
    CGRect allRect = bounds;
    CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // Draw background
    CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f); // white
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.1f); // translucent white
    CGContextSetLineWidth(context, 2.0f);
    CGContextFillEllipseInRect(context, circleRect);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // Draw progress
    CGPoint center = CGPointMake(allRect.origin.x + 
                                 allRect.size.width / 2, 
                                 allRect.origin.y +
                                 allRect.size.height / 2);
    CGFloat radius = (allRect.size.width - 4) / 2;
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (progress * 2 * (float)M_PI) + startAngle;
    
    CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f); // white
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
    
}

static void drawBar(NSRect bounds, CGFloat progress)
{
    CGFloat w = bounds.size.width * progress;
    
    [[NSColor colorWithDeviceWhite:1 alpha:0.8] set];    
    NSRect rc = bounds;
    rc.size.width = w;
    NSRectFill(rc); 
    
    [[NSColor colorWithDeviceWhite:1 alpha:0.2] set];    
    rc.origin.x += w;
    rc.size.width = bounds.size.width - w;
    NSRectFill(rc); 
}

static void drawBar2(NSRect bounds, CGFloat progress)
{
    CGFloat x = bounds.origin.x; 
    CGFloat y = bounds.origin.y;    
    CGFloat h = bounds.size.height;
    CGFloat w = 4; 
    CGFloat dw = 6; //bounds.size.width / 6;    
    
    NSRect rcs[] = {
        {x + dw * 0, y, w, h},
        {x + dw * 1, y, w, h},
        {x + dw * 2, y, w, h},
        {x + dw * 3, y, w, h},
        {x + dw * 4, y, w, h},
        {x + dw * 5, y, w, h},        
    };
    
    int count = sizeof(rcs)/sizeof(rcs[0]);
    
    int n = count * progress;

    [[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.5] set];        
    NSRectFillList(rcs, n); 
    
    [[NSColor colorWithDeviceWhite:1 alpha:0.5] set];    
    NSRectFillList(rcs + n, count - n); 
}

static void drawSpin(NSRect bounds, CGFloat progress) 
{  
    
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) / 2;
    
    NSPoint center = NSMakePoint(bounds.origin.x + 
                                 bounds.size.width/2, 
                                 bounds.origin.y +
                                 bounds.size.height/2);
    
    NSPoint left   = NSMakePoint(- radius, 0);    
    NSPoint right  = NSMakePoint(+ radius, 0);    
    
    for (int i = 0; i  < 8; ++i) {
        NSAffineTransform *transform = [NSAffineTransform transform];        
        NSBezierPath *bezierPath = [NSBezierPath bezierPath];            
        
        [transform translateXBy:center.x yBy: center.y];        
        [transform rotateByRadians: M_PI * 2 * progress - i * M_PI_4 * 0.5];

        [bezierPath moveToPoint: left];        
        [bezierPath lineToPoint: right];   
        [bezierPath transformUsingAffineTransform: transform];    
        
        float f = 1.0 - i * 0.1;
        [[NSColor colorWithDeviceRed:f green:f blue:f alpha:f ] set];
        [bezierPath stroke];
    }  
}

static void shuffleArray(char *p, size_t elemSize, size_t count)
{
    srand ( (unsigned int) time (0) );
    
    char buffer[elemSize];
    
    for (size_t i = 0; i < count - 1; i++) 
    {
        // todo: arc4random % (count - i) + 1
        // see http://iphonedevelopment.blogspot.com/2008/10/random-thoughts-rand-vs-arc4random.html
        
        size_t j = i + rand() / (RAND_MAX / (count - i) + 1);
        
        char* to   = p + j * elemSize;
        char* from = p + i * elemSize; 
        
        memcpy (buffer , to, elemSize);
        memcpy (to, from, elemSize);
        memcpy (from, buffer, elemSize);                
    }    
}

static NSRect * makeBoxes()
{
    const CGFloat w  = 3; 
    const CGFloat dw = 4;
    const NSSize  sz = {w, w};
    
    #if SPIN_BOXES_COUNT != 16
    #error makeBoxes() will incorrect and may corrupt heap if SPIN_BOXES_COUNT != 16
    #endif    

    NSRect * boxes = malloc(sizeof(NSRect) * SPIN_BOXES_COUNT);    
    
    for (int x = 0; x  < 4; ++x) {
        for (int y = 0; y  < 4; ++y) {
            
            int i = x * 4 + y;            
            boxes[i].origin.x = x * dw;
            boxes[i].origin.y = y * dw;            
            boxes[i].size = sz; 
        }
    }
      
    shuffleArray((char *)boxes, sizeof(NSRect), SPIN_BOXES_COUNT); 
    return boxes;
}

static void drawBoxes(NSRect bounds, NSRect * boxes, size_t count) 
{   
    if (count == 0)     
        return;
    
    CGFloat nx = bounds.origin.x; 
    CGFloat ny = bounds.origin.y;
    
    NSRect rcs[count];

    for (size_t i = 0; i < count; ++i) {
        NSRect * p = boxes + i;
        rcs[i].origin.x = p->origin.x + nx;
        rcs[i].origin.y = p->origin.y + ny;
        rcs[i].size = p->size; 
    }
    
    if (count > 1) {
        [[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:0.8] set];        
        NSRectFillList(rcs, count - 1); 
    }
    
    [[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.8] set];        
    NSRectFill(rcs[count - 1]);
}

static void drawDashLine(NSPoint from, NSPoint to) 
{
    CGFloat lineDash[2] = {2,2};
    
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];            
    
    [bezierPath setLineDash:lineDash count:2 phase:0.0];        
    [bezierPath setLineWidth: 0];
    [bezierPath moveToPoint: from];        
    [bezierPath lineToPoint: to];   
    [[NSColor darkGrayColor] set];
    [bezierPath stroke];

}

#pragma mark - Helpers

static NSAttributedString* mkAttributesString(NSString * s, NSFont *firstFont, NSFont *tailFont)
{
    NSMutableAttributedString * mas = [[NSMutableAttributedString alloc] init];
    
    NSDictionary *attr;
    attr = [NSDictionary dictionaryWithObject:firstFont forKey:NSFontAttributeName];
    
    NSArray * lines = [s split:@"\r"];
        
    NSAttributedString *as; 
    as = [[NSAttributedString alloc] initWithString:lines.first attributes:attr];    
    [mas appendAttributedString: as];
    KX_RELEASE(as);

    attr = [NSDictionary dictionaryWithObject:tailFont forKey:NSFontAttributeName];
    
    for (NSString * line in lines.tail) {
        
        as = [[NSAttributedString alloc] initWithString:line attributes:attr];        
        [mas appendAttributedString: as];
        KX_RELEASE(as);
    }
    
    return KX_AUTORELEASE(mas);
}

///

static inline BOOL hitTest(NSPoint pt, NSRect rc)
{
    return 
        pt.x > rc.origin.x && 
        pt.x < rc.origin.x + rc.size.width &&
        pt.y > rc.origin.y && 
        pt.y < rc.origin.y + rc.size.height;
}



#pragma  mark - Classes

///

typedef enum { 
    KxHUDRowStateActive,
    KxHUDRowStatePin,        
    KxHUDRowStateFade,            
    KxHUDRowStateHide,    
} KxHUDRowState;


//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

@class KxHUDRowBase;

@interface KxHUDView()

- (void) killTimer;
- (void) setShow: (BOOL) show;
- (void) redraw: (KxHUDRowBase *)row;
- (void) reset: (id) row;
- (void) remove: (id) row;

@end

////


@interface KxHUDRowBase : NSObject<KxHUDRow> {

    NSTextFieldCell *_text;   
    NSButtonCell *_button;
    CGFloat _fadeAlpha;
    NSColor *_fadeColor;

    KxHUDRowState _state;    
    NSDate *_time;
    NSTimeInterval _interval;
    BOOL _needRedraw;
        
    NSPoint _origin;    
    NSSize _size;
    NSSize _textSize;   
    
    KX_WEAK KxHUDView *_view;
}

@property (readonly) NSSize size;
@property (readonly) KxHUDRowState state; 
@property (readonly) NSDate* time; 

@property (readonly) BOOL wantMouseOver;
@property (readonly) BOOL isMouseOver;

@property (readwrite, nonatomic) NSPoint origin;
@property (readonly) NSRect bounds;

@property (readonly) BOOL isVisible;
@property (readwrite, nonatomic) BOOL isActive;
@property (readwrite, nonatomic) BOOL isPinned;
@property (readonly) BOOL isFade;
@property (readonly) BOOL needRedraw;

@property (readwrite, nonatomic, copy) NSString *text;
@property (readwrite, nonatomic, retain) NSColor *textColor;

@property (readonly, nonatomic, KX_PROP_WEAK) KxHUDView *view;

- (id) init: (KxHUDView *)view
       text: (NSString *) text 
      color: (NSColor *) color    
   interval: (NSTimeInterval) interval;

- (void) draw:(NSView *) view;
- (void) setFadeState;
- (BOOL) tick;

- (BOOL) hitTest: (NSPoint) pt;
- (BOOL) click: (NSPoint) pt;

- (void) mouseOver: (NSPoint) pt; 
- (void) mouseLeave; 

- (void) reset;
- (void) remove;

- (void) updateSize;

+ (NSButtonCell *) buttonCell;
+ (NSTextFieldCell *) textCell: (NSString *) text;

@end

///


@implementation KxHUDRowBase

+ (NSButtonCell *) buttonCell
{
    NSImage * image = [NSImage imageNamed:NSImageNameStatusAvailable];
    NSButtonCell *cell  = [[NSButtonCell alloc] initImageCell:image];
    [cell setButtonType: NSToggleButton];
    [cell setBordered:NO];
    [cell setTitle: @""];    
     
     return KX_AUTORELEASE(cell);
}

+(NSTextFieldCell *) textCell: (NSString *) text
{    
    NSTextFieldCell *cell = [[NSTextFieldCell alloc] initTextCell: text];
    
    [cell setEditable:NO];
    [cell setSelectable:NO];        
    [cell setBordered:NO];
    [cell setDrawsBackground:NO];
    [cell setFont:[NSFont systemFontOfSize:14]];
    [cell setBackgroundColor:[NSColor clearColor]]; 
    [cell setEnabled:NO];
    [cell setAllowsEditingTextAttributes: NO];
    [cell setContinuous:NO];
    
    if ([text contains:@"\r"]) {
        NSAttributedString *as = mkAttributesString(text, 
                                                    [NSFont boldSystemFontOfSize:14],
                                                    [NSFont systemFontOfSize:12]);
        [cell setAttributedStringValue:as];
    }    
    
    return KX_AUTORELEASE(cell);
}

@synthesize size = _size;
@synthesize origin = _origin;
@synthesize state = _state;
@synthesize time = _time;
@synthesize needRedraw = _needRedraw;
@synthesize view =_view;

@dynamic isVisible;
@dynamic isActive;
@dynamic isPinned;
@dynamic isFade;
@dynamic bounds;
@dynamic isMouseOver;
@dynamic wantMouseOver;
@dynamic text;
@dynamic textColor;


- (BOOL) isVisible
{
    return _state != KxHUDRowStateHide;
}

- (BOOL) isActive
{
    return _state == KxHUDRowStateActive;
}

- (void) setIsActive:(BOOL) isActive
{
    if (!isActive) {
        
        [self setFadeState];        
        
    } else {
        
        _state = KxHUDRowStateActive;
        _time = KX_RETAIN([NSDate dateWithTimeIntervalSinceNow: _interval]);
        _needRedraw = YES;
    }
}

- (BOOL) isPinned
{
    return _state == KxHUDRowStatePin;    
}

- (void) setIsPinned:(BOOL)isPinned
{
    if (!isPinned && _state == KxHUDRowStatePin) {
        
        [self setFadeState];
        KX_SAFE_RELEASE(_button);
    }
    else if (isPinned && _state != KxHUDRowStatePin) {

        _state = KxHUDRowStatePin;    
        if (!_button)
            _button = KX_RETAIN([self->isa buttonCell]);
        _button.state = NSOffState; 
        _needRedraw = YES;
    }
}

- (BOOL) isFade
{
    return _state == KxHUDRowStateFade;
}

- (NSColor *) textColor
{
    return _text.textColor;
}

- (void) setTextColor:(NSColor *)textColor
{
    _text.textColor = textColor;
    KX_SAFE_RELEASE(_fadeColor);
    _needRedraw = YES;
}

- (NSString *) text
{
    return _text.stringValue;
}

- (void) setText:(NSString *)text
{
    _text.stringValue = text;
    [self updateText];
    [self updateSize];
    _needRedraw = YES;
}

- (NSRect) bounds
{
    NSRect rc = { _origin, _size};
    return rc;
}

- (NSRect) buttonBounds
{
    return NSMakeRect(_origin.x, 
                      _origin.y ,
                      CLOSE_BUTTON_SIZE, 
                      _size.height);    
}

- (NSRect) textBounds
{
    return NSMakeRect(_origin.x + CLOSE_BUTTON_SIZE + XMARGIN, 
                      _origin.y + (_size.height - _textSize.height) / 2, 
                      _textSize.width, 
                      _textSize.height);
}

- (id) init: (KxHUDView *) view
       text: (NSString *) text 
      color: (NSColor *) color 
   interval: (NSTimeInterval) interval
{
    NSAssert(view != nil, @"nil view");    
    NSAssert(text.nonEmpty, @"empty text");
    NSAssert(color != nil, @"nil color");

    self = [super init];
    if (self) {
            
        _view = view;
        
        _text = KX_RETAIN([self->isa textCell: text]);
        [_text setTextColor:color];                        

        [self updateText];
        [self updateSize];
        
        //_textSize = [_text cellSize];        
        //_size.height = MAX(CLOSE_BUTTON_SIZE, _textSize.height);
        //_size.width = CLOSE_BUTTON_SIZE + XMARGIN + _textSize.width;
        
        _interval = interval;
        
        self.isActive = YES;          
    }
    
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_fadeColor);        
    KX_RELEASE(_time);
    KX_RELEASE(_text);
    KX_RELEASE(_button);    
    KX_SUPER_DEALLOC();
}

- (void) reset
{
    self.isActive = YES;
    if (_view)
        [_view reset: self];
}

- (void) remove
{
    if (_view)
        [_view remove: self];    
}

- (void) fadeTick
{
    _fadeAlpha = MAX(0.1, _fadeAlpha - FADETICK);
    KX_SAFE_RELEASE(_fadeColor);
    _needRedraw = YES;
}

- (void) draw: (NSView *) view
{   
    _needRedraw = NO;
    
    if (_button)    {
        [_button drawWithFrame:self.buttonBounds inView:view];        
    }

    NSColor *color = nil;
    
    if (self.isFade) {
        
        if (!_fadeColor)
            _fadeColor = KX_RETAIN([_text.textColor colorWithAlphaComponent: _fadeAlpha]);
        
        color = _text.textColor;
        _text.textColor = _fadeColor;
    }
    
    [_text drawWithFrame:self.textBounds inView:view];
    
    if (color)
        _text.textColor = color;    
}

- (void) setFadeState
{
    _fadeAlpha = 1.0;    
    KX_RELEASE(_time);
    _time = KX_RETAIN([NSDate dateWithTimeIntervalSinceNow:FADETIME]);
    _state = KxHUDRowStateFade;       
}

- (BOOL) tick
{
    BOOL r = NO;
    
    switch(_state)
    {            
        case KxHUDRowStateActive:
            if (NSOrderedAscending == [_time compare: [NSDate date]]) {

                [self setFadeState];             
                r = YES;
            }
            break;
            
        case KxHUDRowStatePin:
            break;
            
        case KxHUDRowStateFade:
            if (NSOrderedAscending == [_time compare: [NSDate date]]) {

                KX_SAFE_RELEASE(_time);
                _state = KxHUDRowStateHide;   
                r = YES;                
            }
            else {
                
                [self fadeTick];
            }
            
            break; 
     
        case KxHUDRowStateHide:
            break;            
    }
    
    return r;
}

- (BOOL) hitTest: (NSPoint) pt
{
    return hitTest(pt, self.bounds);
}

- (BOOL) click: (NSPoint) pt
{
    if (hitTest(pt, self.buttonBounds)) {

        self.isPinned = !self.isPinned; 
        return YES;
    }    
    return NO;
}

- (BOOL) wantMouseOver 
{
    return NO;
}

- (BOOL) isMouseOver
{
    return NO;
}

- (void) mouseOver: (NSPoint) pt
{
}

- (void) mouseLeave
{
}

- (void) updateText
{
    NSString *s = _text.stringValue;
    if ([s contains:@"\r"]) {
        NSAttributedString *as = mkAttributesString(s, 
                                                    [NSFont boldSystemFontOfSize:14],
                                                    [NSFont systemFontOfSize:12]);
        [_text setAttributedStringValue:as];
    }
}

- (void) updateSize
{
    _textSize = [_text cellSize];  
    _size.height = MAX(CLOSE_BUTTON_SIZE, _textSize.height);
    _size.width = CLOSE_BUTTON_SIZE + XMARGIN + _textSize.width;    
}

@end


///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

@interface KxHUDRowProgress : KxHUDRowBase<KxHUDRowWithProgress> {

    CGFloat _progress;  
    NSInteger _style;
}

@property (readonly, nonatomic) NSRect progressBounds;
@property (readwrite, nonatomic) CGFloat progress;

- (id) init: (KxHUDView *) view 
       text: (NSString *) text 
      color: (NSColor *) color  
   interval: (NSTimeInterval) interval
      style: (NSInteger) style;
@end


@implementation KxHUDRowProgress

@dynamic progress;

- (CGFloat) progress
{
    return _progress;
}

- (void) setProgress:(CGFloat)progress
{
    _progress = MAX(0.0, MIN(1.0, progress));
    _needRedraw = YES;
}

- (NSRect) progressBounds
{    
    if (_style == 0 || _style == 1)
        return NSMakeRect(self.textBounds.origin.x + self.textBounds.size.width + XMARGIN, 
                          _origin.y + (_size.height - CIRCLE_PROGRESS_SIZE) / 2, 
                          CIRCLE_PROGRESS_SIZE, 
                          CIRCLE_PROGRESS_SIZE);        
    else
        return NSMakeRect(self.textBounds.origin.x + self.textBounds.size.width + XMARGIN, 
                          _origin.y + (_size.height - BAR_PROGRESS_HEIGHT) / 2, 
                          BAR_PROGRESS_WIDTH, 
                          BAR_PROGRESS_HEIGHT);        
}

- (id) init: (KxHUDView *) view
       text: (NSString *) text
      color: (NSColor *) color 
   interval: (NSTimeInterval) interval
      style: (NSInteger) style

{
    self = [super init: view 
                  text: text
                 color: color
              interval: interval];
    
    if (self) {
        
        _style = style;
        self.isPinned = YES;     
        self.progress = 0;
    }
    return self;
}

- (void) reset
{   
    self.isPinned = YES;
    self.progress = 0;       
    if (_view)
        [_view reset: self];    
}

- (BOOL) tick
{
    BOOL r = [super tick];
    
    if (self.isPinned)        
       _needRedraw = YES;
    return r;
}

- (void) draw: (NSView *) view
{
    [super draw: view];
    
    if (self.isPinned) {
        if (_style == 0)
            drawAnnularPie(self.progressBounds, _progress);
        else if (_style == 1)
            drawPie(self.progressBounds, _progress);    
        else 
            drawBar(self.progressBounds, _progress);
    }
}

- (void) updateSize
{
    [super updateSize];
    
    NSRect rc = self.progressBounds;
    _size.height = MAX(rc.size.height, _size.height);
    _size.width = _size.width + rc.size.width + XMARGIN; // + 44;    
}

@end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////


@interface KxHUDRowSpin: KxHUDRowBase<KxHUDRowWithSpin> {

    NSInteger _style;
    BOOL _isComplete;
    float _progress;    
    NSRect * _boxes;
}

@property (readonly, nonatomic) NSRect spinBounds;
@property (readwrite, nonatomic) BOOL isComplete;

- (id) init: (KxHUDView *) view
       text: (NSString *) text
      color: (NSColor *) color 
   interval: (NSTimeInterval) interval
      style: (NSInteger) style;

@end

@implementation KxHUDRowSpin

@dynamic isComplete;

- (BOOL) isComplete
{
    return _isComplete;
}

- (void) setIsComplete:(BOOL)isComplete
{
    _isComplete = isComplete;
    _needRedraw = YES;
}


- (NSRect) spinBounds
{   
    return NSMakeRect(self.textBounds.origin.x + self.textBounds.size.width + XMARGIN, 
                      _origin.y + (_size.height - CLOSE_BUTTON_SIZE) / 2, 
                      CLOSE_BUTTON_SIZE, 
                      CLOSE_BUTTON_SIZE);
}

/*
- (NSRect) textBounds
{
    return NSMakeRect(self.spinBounds.origin.x + self.spinBounds.size.width + XMARGIN, 
                      _origin.y + (_size.height - _textSize.height) / 2, 
                      _textSize.width, 
                      _textSize.height);
}

- (NSRect) spinBounds
{   
    return NSMakeRect(_origin.x + CLOSE_BUTTON_SIZE + XMARGIN, 
                      _origin.y + (_size.height - CLOSE_BUTTON_SIZE) / 2, 
                      CLOSE_BUTTON_SIZE, 
                      CLOSE_BUTTON_SIZE);
}
*/

- (id) init: (KxHUDView *) view
       text: (NSString *) text
      color: (NSColor *) color    
   interval: (NSTimeInterval) interval
      style: (NSInteger) style
{
    self = [super init: view 
                  text: text
                 color: color
              interval: interval];
    
    if (self) {
        
        _style = style;
        self.isPinned = YES;     
        self.isComplete = NO;
        
    }
    return self;
}

- (void) reset
{
    self.isPinned = YES;     
    self.isComplete = NO;
    if (_view)
        [_view reset: self];    
}

- (void) dealloc
{
    if (_boxes)
        free(_boxes), _boxes = NULL;
    
    KX_SUPER_DEALLOC();
}

- (BOOL) tick
{
    BOOL r = [super tick];
    
    if (!_isComplete && self.isPinned)
        _needRedraw = YES;
    
    return r;
}

- (void) draw: (NSView *) view
{
    [super draw: view];
    
    if (!_isComplete && self.isPinned) {
        
        if (_style == 1) {
            
            if (!_boxes)
                _boxes = makeBoxes();
            drawBoxes(self.spinBounds, _boxes, MIN(SPIN_BOXES_COUNT, _progress * SPIN_BOXES_COUNT + 1)); 
        }
        else {
            drawSpin(self.spinBounds, _progress);
        }
        
        _progress += 0.05;
        if (_progress > 0.99) {
            _progress = 0;
            if (_boxes) {
                shuffleArray((char *)_boxes, sizeof(NSRect), SPIN_BOXES_COUNT);
            }
        }
    }
}

- (void) updateSize
{
    [super updateSize];
    
    NSRect rc = self.spinBounds;
    _size.height = MAX(rc.size.height, _size.height);
    _size.width += rc.size.width + XMARGIN;
}

@end

////


@interface KxHUDRowSelect : KxHUDRowBase {

    NSArray* _cells;
    NSRect* _bounds;
    void(^_block)(id<KxHUDRow> row, NSInteger link);
    NSInteger _selected;
    NSInteger _hovered;    
}

- (id) init: (KxHUDView *) view
       text: (NSString *) text 
      color: (NSColor *) color
   interval: (NSTimeInterval) interval
      links: (NSArray *) links 
      block: (void(^)(id<KxHUDRow> row, NSInteger link)) block;

@end


@implementation KxHUDRowSelect

- (NSRect) actionBound: (NSInteger) idx
{
    NSRect rc = self.textBounds;
    CGFloat x = rc.origin.x + rc.size.width;
    CGFloat y = rc.origin.y;
    NSRect b = _bounds[idx];
    
    b.origin.x += x;
    b.origin.y = y;
    
    return b;
}

- (id) init: (KxHUDView *) view
       text: (NSString *) text 
      color: (NSColor *) color    
   interval: (NSTimeInterval) interval
      links: (NSArray *) links 
      block: (void(^)(id<KxHUDRow> row, NSInteger link)) block
{
    self = [super init: view 
                  text: text
                 color: color
              interval: interval];
    
    if (self) {

        NSMutableArray *p = [NSMutableArray arrayWithCapacity:[links count]];
        
        _bounds = malloc(sizeof(NSRect) * [links count]);
        NSRect *prect = _bounds;
        
        float w = 0;

        for (NSString *link in links) {
            NSString *s = [NSString stringWithFormat:@"(%@)", link];
            NSTextFieldCell *cell = [self->isa textCell: s];

            [cell setTextColor:[NSColor whiteColor]]; // todo: or self.color?
            
            NSSize sz = [cell cellSize];
            
            prect->size = sz;
            prect->origin = NSMakePoint(w, 0);

            w += sz.width + XMARGIN;
            _size.height = MAX(_size.height, sz.height);            
            
            [p addObject:cell];
            prect++;
        }

        _size.width += w;
        
        _cells = [[NSArray alloc] initWithArray:p];   
        
        self.isPinned = YES;
        _selected = -1;
        _hovered = -1;
        
        _block = KX_RETAIN(block);
    }
    return self;
}

- (void) reset
{
    self.isPinned = YES;     
    _selected = -1;
    if (_view)
        [_view reset: self];
}

- (void) dealloc
{
    if (_bounds)
        free(_bounds), _bounds = NULL;
    
    KX_RELEASE(_cells);
    KX_RELEASE(_block);    
    KX_SUPER_DEALLOC();
}

- (void) draw: (NSView *) view
{
    [super draw: view];
    
    //if (self.isPinned) 
    {
        NSInteger i = 0;
        for (NSTextFieldCell *cell in _cells) {
            if (_selected == -1 || _selected == i) {
                [cell drawWithFrame:[self actionBound:i] inView:view];        
            }
            i++;
        }
    }
}

- (BOOL) click: (NSPoint) pt
{
    if([super click: pt])
        return YES;
        
    if (self.isPinned) {
        for (NSInteger i = 0; i < [_cells count]; ++i)
            if (hitTest(pt, [self actionBound:i])) {                 
                self.isPinned = NO;      
                _selected = i;
                _block(self, i);
                //KX_SAFE_RELEASE(_block);
                return YES;
            }
    }        
    
    return NO;
}

- (BOOL) wantMouseOver 
{
    return YES;
}

- (BOOL) isMouseOver
{
    return _hovered != -1;
}

- (void) mouseOver:(NSPoint)pt
{   
    if (self.isPinned) {
        
        for (NSInteger i = 0; i < [_cells count]; ++i) {
            if (hitTest(pt, [self actionBound:i])) {                 
               
                if (_hovered == i)
                    return;
                                    
                if (_hovered != -1)
                    [self mouseLeave];
                
                NSTextField *f;                    
                f = [_cells objectAtIndex:i];
                [f setTextColor:[NSColor redColor]];
                _hovered = i;  
                
                _needRedraw = YES;
                return;
            }
        }

        [self mouseLeave];
         
    }
}

- (void) mouseLeave
{
    if (_hovered != -1) {
        
        NSTextField *f;
        f = [_cells objectAtIndex:_hovered];
        [f setTextColor:[NSColor whiteColor]];
        _hovered = -1;  
        _needRedraw = YES;
    }
}

@end

////

@implementation KxHUDView

@synthesize defaultTextColor = _defaultTextColor;
@synthesize defaultShowTime = _defaultShowTime;
@dynamic isToggled;
@dynamic maxSize;

- (NSSize) maxSize
{
    return _maxSize;
}

- (void) setMaxSize:(NSSize)maxSize
{
    _maxSize = maxSize;
    [self refresh];
}

- (id) init 
{
    self = [super initWithFrame:NSMakeRect(0,0,0,0)];
    
    if (self) {
        
        
        [self setBoxType: NSBoxCustom];
        [self setBorderType: NSNoBorder];
        [self setCornerRadius: 4];
        [self setFillColor: [NSColor colorWithDeviceWhite:0 alpha:0.8]];
        [self setTitlePosition: NSNoTitle];
        [self setTitle:@""];
        
        
        //[self setTransparent:NO];
        
        [self setHidden:YES];    
        [self setAlphaValue: 0];
    
        _defaultShowTime = 3;
        _defaultTextColor = [NSColor highlightColor];
        _maxSize = NSMakeSize(9999,9999);

        _rows = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [self killTimer];    
    KX_RELEASE(_defaultTextColor);
    KX_RELEASE(_rows);    
    KX_SUPER_DEALLOC();
}

- (void) killTimer
{
    [_timer invalidate];
    KX_SAFE_RELEASE(_timer);
}

- (void) addRow: (KxHUDRowBase *)row
{
    [_rows insertObject:row atIndex:0];
    [self refresh];    
}

- (id<KxHUDRow>) message: (NSString *) text 
                   color: (NSColor *) color
                interval: (NSTimeInterval) interval
{    
    KxHUDRowBase * r = [[KxHUDRowBase alloc] init: self
                                             text: text 
                                            color: color 
                                         interval: interval];
    
    [self addRow: r];
    return KX_AUTORELEASE(r);
}

- (id<KxHUDRowWithProgress>) progress: (NSString *) text style: (NSInteger) style
{
    KxHUDRowProgress * r = [[KxHUDRowProgress alloc] init: self
                                                     text: text 
                                                    color: _defaultTextColor
                                                 interval: _defaultShowTime
                                                    style: style];
    

    
    [self addRow: r];
    return KX_AUTORELEASE(r);
}

- (id<KxHUDRowWithSpin>) spin: (NSString *) text style: (NSInteger) style
{
    KxHUDRowSpin * r = [[KxHUDRowSpin alloc] init: self
                                             text: text 
                                            color: _defaultTextColor
                                         interval: _defaultShowTime
                                            style: style];
    
    [self addRow: r];
    return KX_AUTORELEASE(r);
}

- (id<KxHUDRow>) select: (NSString *) text 
                  links: (NSArray *) links 
                  block: (void(^)(id<KxHUDRow> row, NSInteger link)) block
{
    
    KxHUDRowSelect * r = [[KxHUDRowSelect alloc] init: self
                                                 text: text
                                                color: _defaultTextColor
                                             interval: _defaultShowTime
                                                links: links 
                                                block: block];
    
    [self addRow: r];
    return KX_AUTORELEASE(r);
}


- (void) reset:(id) row 
{
    KxHUDRowBase *r = KX_RETAIN(row);
    [_rows removeObject:r];
    [self addRow: r];
    KX_RELEASE(r);
}

- (void) remove:(id) row
{
    [_rows removeObject:row];
    [self refresh];
}

- (void) clear
{
    [_rows removeAllObjects];
}

- (void) refresh
{
    float y = YPADDING;
    float w = 0;
    
    int visibleRow = 0;
    
    NSInteger skip = _scrollPos;
    
    for (KxHUDRowBase * r in _rows) {
        
        if (r.isVisible || _toggled) {
            
            if (_toggled && (skip > 0)) {
                skip--;
                continue;
            }
            
            visibleRow++;
            
            //[r.view setFrameOrigin:NSMakePoint(XPADDING + 20, y)];        
            r.origin = NSMakePoint(XMARGIN, y);
            y += (r.size.height + YMARGIN);
            if (r.size.width > w)
                w = r.size.width;
            
        }
    }
    
    if (visibleRow) {               
        
        NSSize newSize = NSMakeSize(RIGHT_PADDING + w, 
                                    YPADDING + y - YMARGIN); 
        
        newSize.width  = MIN(newSize.width,  _maxSize.width);
        newSize.height = MIN(newSize.height, _maxSize.height); 
                
        NSSize oldSize = [self frame].size;
        
        if (oldSize.width != newSize.width || 
            oldSize.height != newSize.height) {                    

            [self setFrameSize: newSize]; 
        }
        
        if (self.isHidden)
            [self setShow: YES];
        else
            [self setNeedsDisplay:YES];
        
    }
    else {
        
        [self setShow: NO];
        
    }
}

- (void) tick:(NSTimer*)theTimer
{
    NSPoint loc;
    BOOL locValid = NO;
    
    BOOL needRefresh = NO;
    
    BOOL needRedraw = NO;
            
    for (KxHUDRowBase*  r in _rows) {
        if (r.isVisible)
            
            if (_mouseOver &&
                r.wantMouseOver) 
            {
                                
                if (!locValid) {
                    locValid = YES;
                    NSWindow * w = [[NSApp delegate] window];
                    loc = [w mouseLocationOutsideOfEventStream];
                    loc = [self convertPoint: loc fromView: nil];
                }
                
                if ([r hitTest:loc])                    
                    [r mouseOver: loc];
                else if (r.isMouseOver)
                    [r mouseLeave];                
            }
            
        if ([r tick])
            needRefresh = YES;
        
        if (r.needRedraw) {          
            [self redraw:r];
            needRedraw = YES;
        }
    }
    
    if (needRefresh)
        [self refresh];  
    
    if (needRedraw) {
   //     [self displayIfNeeded];
    }
    
}

- (void) setShow: (BOOL) show 
{
    if (show) {
        
        [self setHidden:NO];
        //[self setAlphaValue: 1.0];    
        [[self animator] setAlphaValue: 1.0];    
    
        if (!_timer)
            _timer = KX_RETAIN([NSTimer scheduledTimerWithTimeInterval:TICKTIME
                                                                target:self 
                                                              selector:@selector(tick:) 
                                                              userInfo:nil 
                                                               repeats:YES]);
    }
    else {
        
        [[self animator] setAlphaValue: 0.0];    
        //[self setHidden:YES];
        [self killTimer];
    }
    
    
}

- (void)drawRect:(NSRect)dirtyRect 
{   
    [super drawRect:dirtyRect];
    
    NSInteger skip = _scrollPos;
    
    for (KxHUDRowBase*  r in _rows) {
        if ((r.isVisible || _toggled)) {
            if ([self needsToDrawRect: r.bounds]) {                
                                
                if (_toggled && (skip > 0)) {
                    skip--;
                    continue;
                }
                
                [r draw: self];
                
                CGFloat y = r.bounds.origin.y - 2;
                drawDashLine(NSMakePoint(XMARGIN + CLOSE_BUTTON_SIZE, y),
                             NSMakePoint(self.bounds.size.width - XMARGIN - CLOSE_BUTTON_SIZE, y));
            }            
        }
    }
}

- (void) redraw: (KxHUDRowBase *)row
{
    [self setNeedsDisplayInRect:row.bounds];
}

- (void) setAlphaValue:(CGFloat) value
{
    [super setAlphaValue: value];
    if (value == 0) {
        [self setHidden:YES];
    }
} 

- (void) setHidden:(BOOL)flag
{
    [self willChangeValueForKey: @"isHidden"];
    [super setHidden:flag];
    [self didChangeValueForKey: @"isHidden"];
}

- (BOOL) isToggled
{
    return _toggled;
}

- (void) setIsToggled: (BOOL) value
{
    _toggled = value;
    _scrollPos = 0;
    
    [self refresh];
    
    if (value && self.isHidden) {
        
        //[self setShow:value];        
    }
}

//- (void) mouseUp:(NSEvent *)event
- (void) mouseDown:(NSEvent *)event
{   
   // [super mouseUp:event];
    BOOL toSuper = YES; 
    
    NSPoint loc = [event locationInWindow];
    loc = [self convertPoint: loc fromView: nil];
    
    for (KxHUDRowBase*  r in _rows) {
        if ((r.isVisible || _toggled) && 
            [r hitTest: loc] &&
            [r click: loc])
        {   
            toSuper = NO;
            if (r.needRedraw)
                [self redraw:r];
            break;
            
        }
    }
    
    if (toSuper)
        [super mouseDown:event];
}

////

- (void) tryCreateTrackingRect
{
    if (_trackingRect) {       
        [self removeTrackingRect:_trackingRect];        
        _trackingRect = 0;
    }
    
    BOOL found = NO;
    for (KxHUDRowBase*  r in _rows) {
        if (r.isVisible && r.wantMouseOver) {
            found = YES;
            break;
        }
    }    
    
    if (found) 
    {
        _trackingRect = [self addTrackingRect:[self bounds] 
                                        owner:self 
                                     userData:nil 
                                 assumeInside:NO];
    }
    
}

- (void)viewDidMoveToWindow 
{
    [super viewDidMoveToWindow]; 
    [self tryCreateTrackingRect];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow 
{
    [super viewWillMoveToWindow:newWindow];     
    if ([self window] && _trackingRect) {        
        [self removeTrackingRect:_trackingRect];        
        _trackingRect = 0;
    }    
}

- (void)setFrameSize:(NSSize)newSize
{
    newSize.width  = MIN(newSize.width,  _maxSize.width);
    newSize.height = MIN(newSize.height, _maxSize.height); 
    
    [super setFrameSize:newSize];
    [self tryCreateTrackingRect];
}

- (void) mouseEntered:(NSEvent *)event
{
    [super mouseEntered:event]; 
    _mouseOver = YES;
}

- (void) mouseExited:(NSEvent *)event
{
    [super mouseExited:event]; 
    
    for (KxHUDRowBase*  r in _rows) {
        if (r.isVisible && 
            r.isMouseOver) {            
            [r mouseLeave];
            if (r.needRedraw)
                [self redraw:r];     
            break;
        }
    }            
    
    _mouseOver = NO;
}

- (void)scrollWheel:(NSEvent *)event
{   
    if (_toggled) {
        int delta = event.deltaY > 0 ? +1 : -1;
        NSInteger x = MAX(0, _scrollPos + delta);
        if (x != _scrollPos) {
            _scrollPos = x;
            [self refresh];
        }
    }
}

@end
 