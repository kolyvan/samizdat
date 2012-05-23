//
//  FavoritesViewController.m
//  samlib
//
//  Created by Kolyvan on 17.05.12.
//  Copyright (c) 2012 Konstantin Boukreev. All rights reserved.
//
//  https://github.com/kolyvan/samizdat
//  this file is part of Samizdat
//  Samizdat is licenced under the LGPL v3, see lgpl-3.0.txt

#import "FavoritesViewController.h"
#import "SamLibText.h"
#import "SamLibAuthor.h"
#import "SamLibAgent.h"
#import "KxArc.h"
#import "KxMacros.h"
#import "NSDictionary+Kolyvan.h"
#import "NSString+Kolyvan.h"
#import "NSArray+Kolyvan.h"
#import "SamLibModel.h"

@interface FavoritesViewController () {
    NSArray * _authors;
}

@end

@implementation FavoritesViewController

- (void) dealloc
{
    KX_RELEASE(_authors);
    KX_SUPER_DEALLOC();
}

- (NSArray *) loadContent
{       
    KX_RELEASE(_authors);
    _authors = nil;
    
    NSArray * favorites = [SamLibAgent.settings() get: @"favorites"];

    NSMutableArray * ma = [NSMutableArray array];     
        
    if (favorites.nonEmpty)
    {    
        SamLibModel *model = [SamLibModel shared];        
        for (NSString *key in favorites) {        
            
            SamLibText *text = [model findTextByKey:key];
            if (text) {
                [text commentsObject:YES]; // force to load comments from disk
                [ma push:text];
            }
        }   
        
        NSArray *texts = [ma sortWith:^(id obj1, id obj2) {        
            SamLibText *l = obj1, *r = obj2;
            return [l.author.name compare:r.author.name];
        }];
        
        [ma removeAllObjects];
        
        KX_WEAK SamLibAuthor *author = nil;
        
        NSMutableArray * authors = [NSMutableArray array];
        
        for (SamLibText *text in texts) {
            
            if (author != text.author) {
                author = text.author;
                [ma push:author.name];
                [authors push: author];
            }        
            [ma push:text];
        }
        
        _authors = KX_RETAIN(authors);
    }
    
    return ma;
}

- (void) reload:(id)sender
{
    if (_authors.nonEmpty) {
        [super reloadAuthors:_authors
                 withMessage:locString(@"favorites")];
    }
}

@end
