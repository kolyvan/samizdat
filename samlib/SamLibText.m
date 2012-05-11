//
//  SamLibText.m
//  samlib
//
//  Created by Kolyvan on 09.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//

#import "SamLibText.h"
#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "SamLibParser.h"
#import "NSDictionary+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "NSDate+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "DDLog.h"
#define NSNUMBER_SHORTHAND
#import "KxMacros.h"
#import "KxUtils.h"
#import <DiffMatchPatch/DiffMatchPatch.h>

////

extern int ddLogLevel;

static NSString * prepareText(NSString * text) {
    
    NSArray *lines = [text lines];
    
    lines = [lines filter:^(id elem) {        
        NSString *s = elem;
        return s.nonEmpty;
    }];
    
    return [[lines map:^(id elem){
        NSString *s = elem;            
        if ([s hasPrefix:@"<dd>&nbsp;&nbsp;"])
            return [[s substringFromIndex:16] stringByAppendingString:@"<br />"];
        return s;
    }] mkString: @"\n"];
}

static NSString * prettyHtml (NSMutableArray *diffs)
{
    NSMutableString *html = [NSMutableString string];
    
    for (Diff *aDiff in diffs) {
        
        switch (aDiff.operation) {
            case DIFF_INSERT:
                [html appendFormat:@"<ins style=\"background:#e6ffe6;\">%@</ins>", aDiff.text];
                break;
                
            case DIFF_DELETE:
                [html appendFormat:@"<del style=\"background:#ffe6e6;\">%@</del>", aDiff.text];
                break;
                
            case DIFF_EQUAL:
                //[html appendFormat:@"<span>%@</span>", aDiff.text];
                [html appendString: aDiff.text];
                break;
        }
    }
    
    return html;
}


@interface SamLibText()

@property (readwrite, nonatomic) NSString * copyright;
@property (readwrite, nonatomic) NSString * title;
@property (readwrite, nonatomic) NSString * size;
@property (readwrite, nonatomic) NSString * comments;
@property (readwrite, nonatomic) NSString * note;
@property (readwrite, nonatomic) NSString * genre;
@property (readwrite, nonatomic) NSString * group;
@property (readwrite, nonatomic) NSString * type;
@property (readwrite, nonatomic) NSString * rating;
@property (readwrite, nonatomic) NSString * flagNew;
@property (readwrite, nonatomic) NSString * lastModified;
@property (readwrite, nonatomic) NSString * diffResult;
@property (readwrite, nonatomic) NSDate * filetime;

- (void) updateFromDictionary: (NSDictionary *) dict
                   setChanged: (BOOL) setChanged
                     allowNil: (BOOL) allowNil;

@end

@implementation SamLibText

@synthesize copyright = _copyright;
@synthesize title = _title;
@synthesize size = _size;
@synthesize comments = _comments;
@synthesize note = _note;
@synthesize genre = _genre;
@synthesize group = _group;
@synthesize type = _type;
@synthesize rating = _rating;
@synthesize changedFlag = _changedFlag;
@synthesize flagNew = _flagNew;
//@synthesize favorited = _favorited;
@synthesize author = _author;
@synthesize lastModified = _lastModified;
@synthesize diffResult = _diffResult;
@synthesize filetime = _filetime;

@dynamic key;

@dynamic changedSize;
@dynamic changedNote;
@dynamic changedComments;
@dynamic changedRating;
@dynamic changedCopyright;
@dynamic changedTitle;
@dynamic changedGenre;
@dynamic changedGroup;
@dynamic changedType;
@dynamic isRemoved;
    
- (BOOL) changed            { return _changedFlag != SamLibTextChangedNone; } 
- (BOOL) changedSize        { return 0 != (_changedFlag & SamLibTextChangedSize); }
- (BOOL) changedNote        { return 0 != (_changedFlag & SamLibTextChangedNote); }
- (BOOL) changedComments    { return 0 != (_changedFlag & SamLibTextChangedComments); }
- (BOOL) changedRating      { return 0 != (_changedFlag & SamLibTextChangedRating); }
- (BOOL) changedCopyright   { return 0 != (_changedFlag & SamLibTextChangedCopyright); }
- (BOOL) changedTitle       { return 0 != (_changedFlag & SamLibTextChangedTitle); }
- (BOOL) changedGenre       { return 0 != (_changedFlag & SamLibTextChangedGenre); }
- (BOOL) changedGroup       { return 0 != (_changedFlag & SamLibTextChangedGroup); }
- (BOOL) changedType        { return 0 != (_changedFlag & SamLibTextChangedType); }
- (BOOL) isRemoved          { return 0 != (_changedFlag & SamLibTextChangedRemoved); }

- (void) setChangedFlag:(SamLibTextChanged)changedFlag
{
    if  (changedFlag != _changedFlag) {
        _changedFlag = changedFlag;
        self.timestamp = [NSDate date];
    } 
}

- (NSString *) relativeUrl
{
//    return [NSString stringWithFormat:@"/%c/%@/%@", _author.path.first, _author.path, _path];
    return [_author.relativeUrl stringByAppendingPathComponent:_path];
}

- (NSString *) key
{
    return KxUtils.format(@"%@.%@", _author.path, [_path stringByDeletingPathExtension]);    
}

+ (id) fromDictionary: (NSDictionary *) dict
           withAuthor: (SamLibAuthor *) author;
{
    NSAssert(dict.nonEmpty, @"empty dictionary");
    
    NSString *path = [dict get:@"path"];
    
    if (path == nil || path.isEmpty) {
        DDLogError(locString(@"no path in dictionary for text"));
        return nil;
    }
    
    SamLibText *text = [[SamLibText alloc] initFromDictionary:dict
                                                     withPath:path
                                                    andAuthor:author];
    
    return KX_AUTORELEASE(text);
}

- (id) initFromDictionary: (NSDictionary *) dict
                 withPath: (NSString *)path
                andAuthor: (SamLibAuthor *) author;
{
    NSAssert(author != nil, @"nil author");  
    
    self = [super initWithPath: path];
    if (self) {
        
        _author = author;   
        
        [self updateFromDictionary:dict setChanged:NO allowNil:NO];
        
        //_favorited      = [[dict get: @"favorited" orElse:[NSNumber numberWithBool:NO]] boolValue];    
        _diffResult     = KX_RETAIN(getStringFromDict(dict, @"diffResult", path));
        _lastModified   = KX_RETAIN(getStringFromDict(dict, @"lastModified", path));
        _filetime       = KX_RETAIN(getDateFromDict(dict, @"filetime", path));            
        
        NSDate *dt = getDateFromDict(dict, @"timestamp", path);        
        if (dt) self.timestamp = dt;
    }
    
    return self;
}

- (void) dealloc
{
    KX_RELEASE(_copyright);
    KX_RELEASE(_title);
    KX_RELEASE(_size);
    KX_RELEASE(_comments);        
    KX_RELEASE(_note);
    KX_RELEASE(_genre);
    KX_RELEASE(_group);
    KX_RELEASE(_type);    
    KX_RELEASE(_rating);        
    KX_RELEASE(_flagNew);  
    KX_RELEASE(_lastModified);
    KX_RELEASE(_diffResult);
    KX_RELEASE(_filetime);
    KX_SUPER_DEALLOC();
}

- (void) updateFromDictionary: (NSDictionary *) dict
                   setChanged: (BOOL) setChanged
                     allowNil: (BOOL) allowNil
{
    NSString *copyright  = getStringFromDict(dict, @"copyright", _path);
    NSString *title      = getStringFromDict(dict, @"title", _path);
    NSString *size       = getStringFromDict(dict, @"size", _path);
    NSString *comments   = getStringFromDict(dict, @"comments", _path);
    NSString *note       = getStringFromDict(dict, @"note", _path);
    NSString *genre      = getStringFromDict(dict, @"genre", _path);
    NSString *group      = getStringFromDict(dict, @"group", _path);
    NSString *type       = getStringFromDict(dict, @"type", _type);    
    NSString *rating     = getStringFromDict(dict, @"rating", _path);
    
    self.flagNew = getStringFromDict(dict, @"flagNew", _path); 
    
    SamLibTextChanged s = SamLibTextChangedNone;
    
    if ((size != nil || allowNil) &&
        _size != size && 
        ![_size isEqualToString:size]) {
        
        self.size = size;
        if (setChanged)        
            s |= SamLibTextChangedSize;
    }
    
    if ((note != nil || allowNil) &&
        _note != note && 
        ![_note isEqualToString:note]) {
        
        self.note = note;        
        if (setChanged)        
            s |= SamLibTextChangedNote;
    }      
    
    if ((comments != nil || allowNil) &&
        _comments != comments && 
        ![_comments isEqualToString:comments]) {
        
        self.comments = comments;        
        if (setChanged)        
            s |= SamLibTextChangedComments;
    }   
    
    if ((rating != nil || allowNil) &&
        _rating != rating && 
        ![_rating isEqualToString:rating]) {
        
        self.rating = rating;        
        if (setChanged)        
            s |= SamLibTextChangedRating;
    }    
    
    if ((copyright != nil || allowNil) &&
        _copyright != copyright && 
        ![_copyright isEqualToString:copyright]) {
        
        self.copyright = copyright;
        if (setChanged)
            s |= SamLibTextChangedCopyright;
    }    
    
    if ((title != nil || allowNil) &&
        _title != title && 
        ![_title isEqualToString:title]) {    
        
        self.title = title;
        if (setChanged)        
            s |= SamLibTextChangedTitle;
    }    
    
    if ((genre != nil || allowNil) &&
        _genre != genre && 
        ![_genre isEqualToString:genre]) {
        
        self.genre = genre;        
        if (setChanged)        
            s |= SamLibTextChangedGenre;
    }    
    
    if ((group != nil || allowNil) &&
        _group != group && 
        ![_group isEqualToString:group]) {
        
        self.group = group;        
        if (setChanged)        
            s |= SamLibTextChangedGroup;
    }
    
    if ((type != nil || allowNil) &&
        _type != type  && 
        ![_type isEqualToString:type]) {
        
        self.type = type;        
        if (setChanged)        
            s |= SamLibTextChangedType;
    }
     
    if  (setChanged)
        self.changedFlag = s;
      
}

- (void) updateFromDictionary: (NSDictionary *) dict
{
    [self updateFromDictionary: dict setChanged: YES allowNil:NO];
}

- (void) flagAsRemoved
{
    self.changedFlag = SamLibTextChangedRemoved;
}

- (NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:14];
    
    [dict updateOnly: @"path" valueNotNil: _path];
    [dict updateOnly: @"copyright" valueNotNil: _copyright];    
    [dict updateOnly: @"title" valueNotNil: _title];        
    [dict updateOnly: @"size" valueNotNil:_size];
    [dict updateOnly: @"comments" valueNotNil: _comments];        
    [dict updateOnly: @"note" valueNotNil: _note];    
    [dict updateOnly: @"genre" valueNotNil: _genre];        
    [dict updateOnly: @"group" valueNotNil: _group];        
    [dict updateOnly: @"type" valueNotNil: _type];            
    [dict updateOnly: @"rating" valueNotNil: _rating];
    [dict updateOnly: @"timestamp" valueNotNil: [_timestamp iso8601Formatted]];    
    [dict updateOnly: @"rating" valueNotNil: _flagNew];
    //if (_favorited)
    //    [dict update: @"favorited" value: [NSNumber numberWithBool:YES]];    
    [dict updateOnly: @"lastModified" valueNotNil: _lastModified];
    [dict updateOnly: @"diffResult" valueNotNil: _diffResult];
    [dict updateOnly: @"filetime" valueNotNil: [_filetime iso8601Formatted]];
    
    return dict;
}

////

@dynamic canUpdate,canMakeDiff,htmlFile,diffFile;

- (BOOL) canUpdate
{
    return (self.htmlFile == nil) || 
        (NSOrderedAscending == [_filetime compare:_timestamp]);
}

- (NSString *) htmlPath
{   
    NSString *s = [SamLibAgent.textsPath() stringByAppendingPathComponent:_path];
    return [s stringByAppendingPathExtension:@"html"];
}

- (NSString *) diffPath
{
    NSString *s = [SamLibAgent.textsPath() stringByAppendingPathComponent:_path];
    return [s stringByAppendingPathExtension:@"diff"];
}

- (NSString *) rawPath
{
    NSString *s = [SamLibAgent.textsPath() stringByAppendingPathComponent:_path];
    return [s stringByAppendingPathExtension:@"raw"];    
}

- (NSString *) oldPath
{
    NSString *s = [SamLibAgent.textsPath() stringByAppendingPathComponent:_path];
    return [s stringByAppendingPathExtension:@"old"];    
}

- (NSString *) htmlFile
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:self.htmlPath];    
    KX_RELEASE(fm);    
    return r ? self.htmlPath : nil;
}

- (NSString *) diffFile
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:self.diffPath];    
    KX_RELEASE(fm);
    return r ? self.diffPath : nil;    
}

- (BOOL) canMakeDiff
{
    NSFileManager * fm = [[NSFileManager alloc] init];    
    BOOL r = [fm isReadableFileAtPath:self.oldPath] &&
             [fm isReadableFileAtPath:self.rawPath];    
    KX_RELEASE(fm);     
    return r;
}

- (void) makeDiff: (NSString *(^)(NSString *)) formatter
{   
    NSString *old = [NSString stringWithContentsOfFile:self.oldPath
                                              encoding:NSUTF8StringEncoding                                                    
                                                 error:nil]; 
    
    NSString *now = [NSString stringWithContentsOfFile:self.rawPath
                                              encoding:NSUTF8StringEncoding                                                    
                                                 error:nil]; 
    
    self.diffResult = @"";
    
    if (!old || !now)
        return;
    
    
    DiffMatchPatch *dmp = [DiffMatchPatch new];
    dmp.Diff_Timeout = 5.0;        
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSMutableArray * result = [dmp diff_mainOfOldString:old andNewString:now];
    [dmp diff_cleanupSemantic: result];
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;            
    
    NSInteger delDiffs = 0, insDiffs = 0;
    for (Diff *diff in result) 
        if (diff.operation == DIFF_DELETE)
            delDiffs++;
        else if (diff.operation == DIFF_INSERT)
            insDiffs++;
    
    if (delDiffs > 0 || insDiffs > 0) { 
        
        // yes any diff is found
        NSString *pretty = prettyHtml(result);
        
        NSString *diff = formatter ? formatter(pretty) : pretty;        
        
        // save .diff
        NSError *error; 
        if (![diff writeToFile:self.diffPath
                    atomically:NO 
                      encoding:NSUTF8StringEncoding
                         error:&error]) {
            
            DDLogError(locString(@"file error: %@"), 
                       KxUtils.completeErrorMessage(error));                
        }
        else {
        
            // delete .old 
            NSFileManager *fm = [[NSFileManager alloc] init];
            [fm removeItemAtPath:self.oldPath error:nil];
            KX_RELEASE(fm);
            
        }
        
        self.diffResult = KxUtils.format(@"%ld/%ld", delDiffs, insDiffs);
    } 
    
    KX_RELEASE(dmp); 
    
    DDLogCInfo(@"Diff elapsed time: %.4lf count: %ld dels: %ld ins: %ld", 
               (double)duration, result.count, delDiffs, insDiffs);
}

- (void) saveHTML: (NSString *) data
        formatter: (NSString *(^)(NSString *)) formatter
{       
    NSError *error;
   

    NSFileManager *fm = [[NSFileManager alloc] init];
    
    BOOL diffExists = [fm fileExistsAtPath:self.diffPath];
    BOOL htmlExists = [fm fileExistsAtPath:self.htmlPath];     
    BOOL rawExists = [fm fileExistsAtPath:self.rawPath];     
    BOOL oldExists = [fm fileExistsAtPath:self.oldPath];         

    // delete .diff 
    if (diffExists &&
        ![fm removeItemAtPath:self.diffPath error:&error]) {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));                   
    }    
    
    // delete .html
    if (htmlExists &&
        ![fm removeItemAtPath:self.htmlPath error:&error]) {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));                   
    }  
    
    // delete .old
    if (oldExists &&
        ![fm removeItemAtPath:self.oldPath error:&error]) {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));                   
    }  
    
    // move .raw to .old
    if (rawExists &&
        ![fm moveItemAtPath:self.rawPath toPath:self.oldPath error:&error]) {
        DDLogCError(locString(@"file error: %@"), 
                    KxUtils.completeErrorMessage(error));                   
    }
    
    // save .raw
    data = SamLibParser.scanTextData(data);
    data = prepareText(data);    
    if (![data writeToFile:self.rawPath
                atomically:NO 
                  encoding:NSUTF8StringEncoding
                     error:&error]) {
        
        DDLogError(locString(@"file error: %@"), 
                   KxUtils.completeErrorMessage(error));                
    }  
    
    // save .html
    NSString *html = formatter ? formatter(data) : data;
    if ([html writeToFile:self.htmlPath
               atomically:NO 
                 encoding:NSUTF8StringEncoding
                    error:&error]) {
        
        
        self.filetime = [NSDate date];
        
    } else {
        
        DDLogError(locString(@"file error: %@"), 
                   KxUtils.completeErrorMessage(error));                
    } 
    
    KX_RELEASE(fm);
}



- (void) update: (UpdateTextBlock) block 
      formatter: (NSString *(^)(NSString *)) formatter;
{    
#if __has_feature(objc_arc_weak)    
    __weak SamLibText *this = self;
#else
    SamLibText *this = self;
#endif        
    
    SamLibAgent.fetchData(self.relativeUrl, 
                          _lastModified, 
                          NO,
                          nil,
                          ^(SamLibStatus status, NSString *data, NSString *lastModified) {
                              
                              if (!this)
                                  return;
                              
                              if (status == SamLibStatusSuccess) {
                                  
                                  NSDictionary *dict = SamLibParser.scanTextPage(data);
                                  if (dict.nonEmpty) {
                                      [this updateFromDictionary: dict 
                                                      setChanged: YES 
                                                        allowNil: YES];
                                  }
                                  
                                  this.lastModified = lastModified;
                                  [this saveHTML:data formatter:formatter];                                       
                              }                                            
                              
                              block(this, status, data);         
                          });
    
}

@end
