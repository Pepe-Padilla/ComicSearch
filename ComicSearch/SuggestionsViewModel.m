//
//  SuggestionsViewModel.m
//  ComicSearch
//
//  Created by Guillermo Gonzalez on 15/05/15.
//  Copyright (c) 2015 Agbo. All rights reserved.
//

#import "SuggestionsViewModel.h"
#import "ComicVineClient.h"
#import "Response.h"
#import "Volume.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SuggestionsViewModel ()

@property (copy, nonatomic) NSArray *suggestions;

@end

@implementation SuggestionsViewModel

- (NSUInteger)numberOfSuggestions {
    return self.suggestions.count;
}

- (NSString *)suggestionAtIndex:(NSUInteger)index {
    return self.suggestions[index];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        RACSignal *input = RACObserve(self, query);
        input = [input filter:^BOOL(NSString *value) {
            return value.length > 2;
        }];
        input = [input throttle:.4];
        
        @weakify(self);
        RACSignal *suggestionsSignal = [input flattenMap:^RACStream *(NSString *query) {
            @strongify(self);
            return [self fetchSuggestionsWithQuery:query];
        }];
        
        RAC(self, suggestions) = [suggestionsSignal catch:^RACSignal *(NSError *error) {
            return [RACSignal return:@[error.localizedDescription]];
        }];
        
        _didUpdateSuggestionsSignal = [RACObserve(self, suggestions) mapReplace:nil];
    }
    return self;
}

#pragma mark - Private

- (RACSignal *)fetchSuggestionsWithQuery:(NSString *)query {
    ComicVineClient *client = [ComicVineClient new];
    
    return [[[client fetchSuggestedVolumesWithQuery:query] map:^id(Response *response) {
        NSArray *volumes = response.results;
        NSMutableArray *titles = [NSMutableArray array];
        
        for (Volume *volume in volumes) {
            if ([titles containsObject:volume.title]) {
                continue;
            }
            [titles addObject:volume.title];
        }
        
        return titles;
    }] deliverOnMainThread];
}

@end
