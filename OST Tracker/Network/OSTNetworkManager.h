//
//  OSTNetworkManager.h
//  OST Tracker
//
//  Created by Luciano Castro on 6/12/17.
//  Copyright © 2017 OST. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"
#import "AFNetworking.h"

typedef void (^VoidBlock)(void);
typedef void (^OSTCompletionNumberBlock)(NSNumber* _Nullable number);
typedef void (^OSTCompletionArrayBlock)(NSArray* records);
typedef void (^OSTCompletionDictionaryBlock)(NSDictionary* records);
typedef void (^OSTCompletionObjectBlock)(id object);
typedef void (^OSTProgressBlock)(NSProgress * _Nonnull uploadProgress);
typedef void (^OSTErrorBlock)(NSError* _Nullable error);

@protocol OSTManagedObjectUpdateKeys

+ (NSString*_Nullable)recordsKey;
+ (NSString*)uniqueId;
+ (NSString*)remoteUniqueId;

@end

@protocol OSTUnManagedObjectUpdateKeys

+ (NSString*)recordsKey;
+ (NSString*)uniqueId;
+ (NSString*)remoteUniqueId;
+ (NSDictionary*)mapping;

@end

@interface OSTNetworkManager : AFHTTPSessionManager

@property (nonatomic,strong) NSString * serviceURL;

- (void)addTokenToHeader: (NSString*) token;

@end
