/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <ParseCore/ParseClientConfiguration.h>
#import <ParseCore/PFACL.h>
#import <ParseCore/PFAnalytics.h>
#import <ParseCore/PFAnonymousUtils.h>
#import <ParseCore/PFAnonymousUtils+Deprecated.h>
#import <ParseCore/PFCloud.h>
#import <ParseCore/PFCloud+Deprecated.h>
#import <ParseCore/PFCloud+Synchronous.h>
#import <ParseCore/PFConfig.h>
#import <ParseCore/PFConfig+Synchronous.h>
#import <ParseCore/PFConstants.h>
#import <ParseCore/PFDecoder.h>
#import <ParseCore/PFEncoder.h>
#import <ParseCore/PFFileObject.h>
#import <ParseCore/PFFileObject+Deprecated.h>
#import <ParseCore/PFFileObject+Synchronous.h>
#import <ParseCore/PFGeoPoint.h>
#import <ParseCore/PFPolygon.h>
#import <ParseCore/PFObject.h>
#import <ParseCore/PFObject+Subclass.h>
#import <ParseCore/PFObject+Synchronous.h>
#import <ParseCore/PFObject+Deprecated.h>
#import <ParseCore/PFQuery.h>
#import <ParseCore/PFQuery+Synchronous.h>
#import <ParseCore/PFQuery+Deprecated.h>
#import <ParseCore/PFRelation.h>
#import <ParseCore/PFRole.h>
#import <ParseCore/PFSession.h>
#import <ParseCore/PFSubclassing.h>
#import <ParseCore/PFUser.h>
#import <ParseCore/PFUser+Synchronous.h>
#import <ParseCore/PFUser+Deprecated.h>
#import <ParseCore/PFUserAuthenticationDelegate.h>
#import <ParseCore/PFFileUploadResult.h>
#import <ParseCore/PFFileUploadController.h>

#if TARGET_OS_IOS

#import <ParseCore/PFInstallation.h>
#import <ParseCore/PFNetworkActivityIndicatorManager.h>
#import <ParseCore/PFPush.h>
#import <ParseCore/PFPush+Synchronous.h>
#import <ParseCore/PFPush+Deprecated.h>
#import <ParseCore/PFProduct.h>
#import <ParseCore/PFPurchase.h>

#elif PF_TARGET_OS_OSX

#import <ParseCore/PFInstallation.h>
#import <ParseCore/PFPush.h>
#import <ParseCore/PFPush+Synchronous.h>
#import <ParseCore/PFPush+Deprecated.h>

#elif TARGET_OS_TV

#import <ParseCore/PFInstallation.h>
#import <ParseCore/PFPush.h>
#import <ParseCore/PFProduct.h>
#import <ParseCore/PFPurchase.h>

#endif

NS_ASSUME_NONNULL_BEGIN

/**
 The `Parse` class contains static functions that handle global configuration for the ParseCore.framework.
 */
@interface Parse : NSObject

///--------------------------------------
#pragma mark - Connecting to Parse
///--------------------------------------

/**
 Sets the applicationId and clientKey of your application.

 @param applicationId The application id of your Parse application.
 @param clientKey The client key of your Parse application.
 */
+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;

/**
 Sets the configuration to be used for the Parse SDK.

 @note Re-setting the configuration after having previously sent requests through the SDK results in undefined behavior.

 @param configuration The new configuration to set for the SDK.
 */
+ (void)initializeWithConfiguration:(ParseClientConfiguration *)configuration;

/**
 Gets the current configuration in use by the Parse SDK.

 @return The current configuration in use by the SDK. Returns nil if the SDK has not been initialized yet.
 */
@property (nonatomic, nullable, readonly, class) ParseClientConfiguration *currentConfiguration;

/**
 Sets the server URL to connect to Parse Server. The local client cache is not cleared.
 @discussion This can be used to update the server URL after this client has been initialized, without having to destroy this client. An example use case is
 server connection failover, where the clients connects to another URL if the server becomes unreachable at the current URL.
 @warning The new server URL must point to a Parse Server that connects to the same database. Otherwise, issues may arise
 related to locally cached data or delayed methods such as saveEventually.
 @param server  The server URL to set.
 */
+ (void)setServer:(nonnull NSString *)server;

/**
 The current application id that was used to configure ParseCore.framework.
 */
@property (nonatomic, nonnull, readonly, class) NSString *applicationId;

+ (NSString *)getApplicationId PARSE_DEPRECATED("Use applicationId property.");

/**
 The current client key that was used to configure ParseCore.framework.
 */
@property (nonatomic, nullable, readonly, class) NSString *clientKey;

+ (nullable NSString *)getClientKey PARSE_DEPRECATED("Use clientKey property.");

/**
 The current server URL to connect to Parse Server.
 */
@property (nonatomic, nullable, readonly, class) NSString *server;

///--------------------------------------
#pragma mark - Enabling Local Datastore
///--------------------------------------

/**
 Enable pinning in your application. This must be called before your application can use
 pinning. The recommended way is to call this method before `+setApplicationId:clientKey:`.
 */
+ (void)enableLocalDatastore PF_TV_UNAVAILABLE;

/**
 Flag that indicates whether Local Datastore is enabled.

 @return `YES` if Local Datastore is enabled, otherwise `NO`.
 */
@property (nonatomic, readonly, class) BOOL isLocalDatastoreEnabled PF_TV_UNAVAILABLE;

///--------------------------------------
#pragma mark - Enabling Extensions Data Sharing
///--------------------------------------

/**
 Enables data sharing with an application group identifier.

 After enabling - Local Datastore, `PFUser.+currentUser`, `PFInstallation.+currentInstallation` and all eventually commands
 are going to be available to every application/extension in a group that have the same Parse applicationId.

 @warning This method is required to be called before `+setApplicationId:clientKey:`.

 @param groupIdentifier Application Group Identifier to share data with.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier PF_EXTENSION_UNAVAILABLE("Use `enableDataSharingWithApplicationGroupIdentifier:containingApplication:`.") PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/**
 Enables data sharing with an application group identifier.

 After enabling - Local Datastore, `PFUser.+currentUser`, `PFInstallation.+currentInstallation` and all eventually commands
 are going to be available to every application/extension in a group that have the same Parse applicationId.

 @warning This method is required to be called before `+setApplicationId:clientKey:`.
 This method can only be used by application extensions.

 @param groupIdentifier Application Group Identifier to share data with.
 @param bundleIdentifier Bundle identifier of the containing application.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier
                                  containingApplication:(NSString *)bundleIdentifier PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/**
 Application Group Identifier for Data Sharing.

 @return `NSString` value if data sharing is enabled, otherwise `nil`.
 */
+ (NSString *)applicationGroupIdentifierForDataSharing PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

/**
 Containing application bundle identifier for Data Sharing.

 @return `NSString` value if data sharing is enabled, otherwise `nil`.
 */
+ (NSString *)containingApplicationBundleIdentifierForDataSharing PF_WATCH_UNAVAILABLE PF_TV_UNAVAILABLE;

#if TARGET_OS_IOS

///--------------------------------------
#pragma mark - Configuring UI Settings
///--------------------------------------

/**
 Set whether to show offline messages when using a Parse view or view controller related classes.

 @param enabled Whether a `UIAlertView` should be shown when the device is offline
 and network access is required from a view or view controller.

 @deprecated This method has no effect.
 */
+ (void)offlineMessagesEnabled:(BOOL)enabled PARSE_DEPRECATED("This method is deprecated and has no effect.");

/**
 Set whether to show an error message when using a Parse view or view controller related classes
 and a Parse error was generated via a query.

 @param enabled Whether a `UIAlertView` should be shown when an error occurs.

 @deprecated This method has no effect.
 */
+ (void)errorMessagesEnabled:(BOOL)enabled PARSE_DEPRECATED("This method is deprecated and has no effect.");

#endif

///--------------------------------------
#pragma mark - Logging
///--------------------------------------

/**
 Gets or sets the level of logging to display.

 By default:
 - If running inside an app that was downloaded from iOS App Store - it is set to `PFLogLevelNone`
 - All other cases - it is set to `PFLogLevelWarning`

 @return A `PFLogLevel` value.
 @see PFLogLevel
 */
@property (nonatomic, readwrite, class) PFLogLevel logLevel;

@end

///--------------------------------------
#pragma mark - Notifications
///--------------------------------------

/**
 For testing purposes. Allows testers to know when init is complete.
 */
extern NSString *const _Nonnull PFParseInitializeDidCompleteNotification;

NS_ASSUME_NONNULL_END
