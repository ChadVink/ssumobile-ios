//
//  SSUDirectoryModule.m
//  SSUMobile
//
//  Created by Eric Amorde on 9/8/15.
//  Copyright (c) 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSUDirectoryModule.h"
#import "SSUDirectoryBuilder.h"
#import "SSUMoonlightCommunicator.h"
#import "SSULogging.h"
#import "SSUConfiguration.h"
#import "SSUDirectorySpotlightUtilities.h"
#import "SSUDirectoryViewController.h"

@import CoreSpotlight;
@import MobileCoreServices;

@interface SSUDirectoryModule()

@end

@implementation SSUDirectoryModule

+ (instancetype) sharedInstance {
    static SSUDirectoryModule * instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - SSUModule

- (nonnull NSString *) title {
    return NSLocalizedString(@"Directory",
                             @"The campus directory containing the contact information of faculty and staff");
}

- (nonnull NSString *) identifier {
    return @"directory";
}

- (UIView *) viewForHomeScreen {
    //return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directory_icon"]];
    UIImage * image = [UIImage imageNamed:@"directory_icon"];
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    button.contentMode = UIViewContentModeScaleAspectFit;
    return button;
}

- (UIImage *) imageForHomeScreen {
    return [UIImage imageNamed:@"directory_icon"];
}

- (BOOL) showModuleInNavigationBar {
    return NO;
}

- (BOOL) shouldNavigateToModule {
    return YES;
}

- (void) selectHomeScreenView:(UIView *)view {
    UIButton * button = (UIButton *)view;
    [button setHighlighted:YES];
}

- (void) deselectHomeScreenView:(UIView *)view {
    UIButton * button = (UIButton *)view;
    [button setHighlighted:NO];
}

- (UIViewController *) initialViewController {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Directory_iPhone"
                                                          bundle:[NSBundle bundleForClass:[self class]]];
    return [storyboard instantiateInitialViewController];
}

- (void) setup {
    NSManagedObjectModel * model = [self modelWithName:@"Directory"];
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinatorWithName:@"Directory" model:model];
    self.context = [self contextWithPersistentStoreCoordinator:coordinator];
    self.backgroundContext = [self backgroundContextFromContext:self.context];
}

- (void) clearCachedData {
    //TODO: implement clearCachedData
}

- (void) updateData:(void (^)())completion {
    SSULogDebug(@"Update Directory NEW");
    NSDate * date = [[SSUConfiguration sharedInstance] dateForKey:SSUDirectoryUpdatedDateKey];
    [SSUMoonlightCommunicator getJSONFromPath:@"directory" sinceDate:date completion:^(id json, NSError *error) {
        if (error != nil) {
            SSULogError(@"Error while attemping to update directory: %@", error);
            if (completion) {
                completion();
            }
        }
        else {
            [[SSUConfiguration sharedInstance] setDate:[NSDate date] forKey:SSUDirectoryUpdatedDateKey];
            [self.backgroundContext performBlock:^{
                [self buildJSON:json];
                if (completion) {
                    completion();
                }
                [SSUDirectorySpotlightUtilities populateIndex:[CSSearchableIndex defaultSearchableIndex] context:self.backgroundContext domain:nil];
            }];
        }
        SSULogDebug(@"Finish %@",self.title);
    }];
}

#pragma mark - Private

- (void) buildJSON:(id)json {
    SSUDirectoryBuilder * builder = [[SSUDirectoryBuilder alloc] init];
    builder.context = self.backgroundContext;
    [builder build:json];
}

#pragma mark - Spotlight

- (void) searchableIndex:(CSSearchableIndex *)index reindexItemWithIdentifier:(NSString *)identifier {
    [SSUDirectorySpotlightUtilities searchableIndex:index reindexItem:identifier inContext:self.backgroundContext domain:self.identifier];
}

- (void) searchAbleIndexRequestingUpdate:(CSSearchableIndex *)index {
    [SSUDirectorySpotlightUtilities populateIndex:index context:self.backgroundContext domain:self.identifier];
}

- (BOOL) recognizesIdentifier:(NSString *)identifier {
    return YES;
}

- (UIViewController *) viewControllerForSearchableItemWithIdentifier:(NSString *)identfier {
    SSUDirectoryViewController * vc = [SSUDirectoryViewController instantiateFromStoryboard];
    vc.objectToDisplay = [SSUDirectorySpotlightUtilities objectForIdentifier:identfier];
    return vc;
}

@end
