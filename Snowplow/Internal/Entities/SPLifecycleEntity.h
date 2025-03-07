//
// SPLifecycleEntity.h
// Snowplow
//
// Copyright (c) 2013-2021 Snowplow Analytics Ltd. All rights reserved.
//
// This program is licensed to you under the Apache License Version 2.0,
// and you may not use this file except in compliance with the Apache License
// Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
// http://www.apache.org/licenses/LICENSE-2.0.
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the Apache License Version 2.0 is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the Apache License Version 2.0 for the specific
// language governing permissions and limitations there under.
//
// Copyright: Copyright © 2021 Snowplow Analytics.
// License: Apache License Version 2.0
//

#import "SPEventBase.h"
#import "SPSelfDescribingJson.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Entity that indicates the state of the app is visible (foreground) when the event is tracked.
 */
NS_SWIFT_NAME(LifecycleEntity)
@interface SPLifecycleEntity : SPSelfDescribingJson

extern NSString * const kSPLifecycleEntitySchema;
extern NSString * const kSPLifecycleEntityParamIndex;
extern NSString * const kSPLifecycleEntityParamIsVisible;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIsVisible:(BOOL)isVisible;

SP_BUILDER_DECLARE_NULLABLE(NSNumber *, index)

@end


NS_ASSUME_NONNULL_END
