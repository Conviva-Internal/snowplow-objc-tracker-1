//
//  SPPayload.m
//  Snowplow
//
//  Copyright (c) 2013-2021 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.
//
//  Authors: Jonathan Almeida, Joshua Beemster
//  Copyright: Copyright (c) 2013-2021 Snowplow Analytics Ltd
//  License: Apache License Version 2.0
//

#import "SPTrackerConstants.h"
#import "SPPayload.h"
#import "SPLogger.h"
#import "SPJSONSerialization.h"

#define SPLogPayloadError(issue, format, ...) if (self.allowDiagnostic) SPLogTrack(issue, format, ##__VA_ARGS__); else SPLogError(format, ##__VA_ARGS__)

@implementation SPPayload {
    NSMutableDictionary * _payload;
}

- (id) init {
    self = [super init];
    if(self) {
        _payload = [[NSMutableDictionary alloc] init];
        self.allowDiagnostic = YES;
    }
    return self;
}

- (id)initWithNSDictionary:(NSDictionary<NSString *, NSObject *> *) dictionary {
    self = [super init];
    if (self) {
        _payload = dictionary.mutableCopy ?: [NSMutableDictionary dictionary];
        self.allowDiagnostic = YES;
    }
    return self;
}

- (void) addValueToPayload:(NSString *)value forKey:(NSString *)key {
    if ([value length] == 0) {
        @synchronized (self) {
            if ([_payload valueForKey:key] != nil) {
                [_payload removeObjectForKey:key];
            }
        }
        return;
    }
    @synchronized (self) {
        [_payload setObject:value forKey:key];
    }
}

- (void) addNumericValueToPayload:(NSNumber *)value forKey:(NSString *)key {
    @synchronized (self) {
        if (value) {
            [_payload setObject:value forKey:key];
        }
        else if ([_payload valueForKey:key]) {
            [_payload removeObjectForKey:key];
        }
    }
}

- (void)addDictionaryToPayload:(NSDictionary<NSString *, NSObject *> *)dictionary {
    if (!dictionary) return;
    [dictionary.copy enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        if ([value isKindOfClass:[NSString class]]) {
            [self addValueToPayload:(NSString *)value forKey:key];
        }
    }];
}

- (void) addJsonToPayload:(NSData *)json
            base64Encoded:(Boolean)encode
          typeWhenEncoded:(NSString *)typeEncoded
       typeWhenNotEncoded:(NSString *)typeNotEncoded {
    NSDictionary *object = [SPJSONSerialization deserializeData:json];
    if (!object) {
        return;
    }
    if (encode) {
        NSString *encodedString = [json base64EncodedStringWithOptions:0];
        
        // We need URL safe with no padding. Since there is no built-in way to do this, we transform
        // the encoded payload to make it URL safe by replacing chars that are different in the URL-safe
        // alphabet. Namely, 62 is - instead of +, and 63 _ instead of /.
        // See: https://tools.ietf.org/html/rfc4648#section-5
        encodedString = [[encodedString stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                         stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
        
        // There is also no padding since the length is implicitly known.
        encodedString = [encodedString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
        
        [self addValueToPayload:encodedString forKey:typeEncoded];
    } else {
        [self addValueToPayload:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] forKey:typeNotEncoded];
    }
}

- (void) addJsonStringToPayload:(NSString *)json
                  base64Encoded:(Boolean)encode
                typeWhenEncoded:(NSString *)typeEncoded
             typeWhenNotEncoded:(NSString *)typeNotEncoded {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];

    [self addJsonToPayload:data
             base64Encoded:encode
           typeWhenEncoded:typeEncoded
        typeWhenNotEncoded:typeNotEncoded];
    
}

- (void)addDictionaryToPayload:(NSDictionary<NSString *, NSObject *> *)dictionary
                 base64Encoded:(Boolean)encode
               typeWhenEncoded:(NSString *)typeEncoded
            typeWhenNotEncoded:(NSString *)typeNotEncoded {
    NSData *data = [SPJSONSerialization serializeDictionary:dictionary];
    if (!data) {
        return;
    }
    [self addJsonToPayload:data
             base64Encoded:encode
           typeWhenEncoded:typeEncoded
        typeWhenNotEncoded:typeNotEncoded];
}

- (NSDictionary<NSString *, NSObject *> *) getAsDictionary {
    @synchronized (self) {
        return _payload;
    }
}

- (NSUInteger)byteSize {
    if (!_payload) {
        return 0;
    }
    NSData *data = nil;
    @synchronized (self) {
        data = [SPJSONSerialization serializeDictionary:_payload];
        if (!data) {
            return 0;
        }
    }
    return data.length;
}

- (NSString *)description {
    return [[self getAsDictionary] description];
}

@end
