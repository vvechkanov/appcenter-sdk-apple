/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSFeatureAbstract.h"
#import "MSFeatureAbstractInternal.h"
#import "MSFeatureAbstractPrivate.h"
#import "MSMobileCenterInternal.h"

@implementation MSFeatureAbstract

@synthesize logManager = _logManager;

- (instancetype)init {
  return [self initWithStorage:kMSUserDefaults];
}

- (instancetype)initWithStorage:(MSUserDefaults *)storage {
  if (self = [super init]) {
    _started = NO;
    _isEnabledKey = [NSString stringWithFormat:@"kMS%@IsEnabledKey", self.storageKey];
    _storage = storage;
  }
  return self;
}

#pragma mark : - MSFeatureCommon

- (BOOL)isEnabled {

  // Get isEnabled value from persistence.
  // No need to cache the value in a property, user settings already have their cache mechanism.
  NSNumber *isEnabledNumber = [_storage objectForKey:_isEnabledKey];

  // Return the persisted value otherwise it's enabled by default.
  return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
}

- (void)setEnabled:(BOOL)isEnabled {
  if (self.isEnabled != isEnabled) {

    // Apply enabled state.
    [self applyEnabledState:isEnabled];

    // Persist the enabled status.
    [self.storage setObject:[NSNumber numberWithBool:isEnabled] forKey:self.isEnabledKey];
  }
}

- (void)applyEnabledState:(BOOL)isEnabled {

  // Propagate isEnabled and delete logs on disabled.
  [self.logManager setEnabled:isEnabled andDeleteDataOnDisabled:YES forPriority:self.priority];
}

- (BOOL)canBeUsed {
  BOOL canBeUsed = [MSMobileCenter sharedInstance].sdkStarted && self.started;
  if (!canBeUsed) {
    MSLogError([MSMobileCenter getLoggerTag],
                @"%@ module hasn't been initialized. You need to call "
                @"[MSMobileCenter start:YOUR_APP_SECRET withFeatures:LIST_OF_FEATURES] first.",
                CLASS_NAME_WITHOUT_PREFIX);
  }
  return canBeUsed;
}

- (BOOL)isAvailable {
  return self.isEnabled && self.started;
}

#pragma mark : - MSFeature

- (void)startWithLogManager:(id<MSLogManager>)logManager {
  self.started = YES;
  self.logManager = logManager;

  // Enable this feature as needed.
  if (self.isEnabled) {
    [self applyEnabledState:self.isEnabled];
  }
}

+ (void)setEnabled:(BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if (![MSMobileCenter isEnabled] && ![MSMobileCenter sharedInstance].enabledStateUpdating) {
        MSLogError([MSMobileCenter getLoggerTag],
                    @"The SDK is disabled. Re-enable the SDK from the core module "
                    @"first before enabling %@ feature.",
                    CLASS_NAME_WITHOUT_PREFIX);
      } else {
        [[self sharedInstance] setEnabled:isEnabled];
      }
    }
  }
}

+ (BOOL)isEnabled {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      return [[self sharedInstance] isEnabled];
    } else {
      return NO;
    }
  }
}

@end
