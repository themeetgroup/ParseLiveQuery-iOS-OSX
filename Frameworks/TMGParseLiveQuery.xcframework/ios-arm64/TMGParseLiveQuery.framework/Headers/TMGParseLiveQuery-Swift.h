#if 0
#elif defined(__arm64__) && __arm64__
// Generated by Apple Swift version 5.10 (swiftlang-5.10.0.13 clang-1500.3.9.4)
#ifndef TMGPARSELIVEQUERY_SWIFT_H
#define TMGPARSELIVEQUERY_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#if defined(__OBJC__)
#include <Foundation/Foundation.h>
#endif
#if defined(__cplusplus)
#include <cstdint>
#include <cstddef>
#include <cstdbool>
#include <cstring>
#include <stdlib.h>
#include <new>
#include <type_traits>
#else
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#endif
#if defined(__cplusplus)
#if defined(__arm64e__) && __has_include(<ptrauth.h>)
# include <ptrauth.h>
#else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreserved-macro-identifier"
# ifndef __ptrauth_swift_value_witness_function_pointer
#  define __ptrauth_swift_value_witness_function_pointer(x)
# endif
# ifndef __ptrauth_swift_class_method_pointer
#  define __ptrauth_swift_class_method_pointer(x)
# endif
#pragma clang diagnostic pop
#endif
#endif

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...) 
# endif
#endif
#if !defined(SWIFT_RUNTIME_NAME)
# if __has_attribute(objc_runtime_name)
#  define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
# else
#  define SWIFT_RUNTIME_NAME(X) 
# endif
#endif
#if !defined(SWIFT_COMPILE_NAME)
# if __has_attribute(swift_name)
#  define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
# else
#  define SWIFT_COMPILE_NAME(X) 
# endif
#endif
#if !defined(SWIFT_METHOD_FAMILY)
# if __has_attribute(objc_method_family)
#  define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
# else
#  define SWIFT_METHOD_FAMILY(X) 
# endif
#endif
#if !defined(SWIFT_NOESCAPE)
# if __has_attribute(noescape)
#  define SWIFT_NOESCAPE __attribute__((noescape))
# else
#  define SWIFT_NOESCAPE 
# endif
#endif
#if !defined(SWIFT_RELEASES_ARGUMENT)
# if __has_attribute(ns_consumed)
#  define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
# else
#  define SWIFT_RELEASES_ARGUMENT 
# endif
#endif
#if !defined(SWIFT_WARN_UNUSED_RESULT)
# if __has_attribute(warn_unused_result)
#  define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
# else
#  define SWIFT_WARN_UNUSED_RESULT 
# endif
#endif
#if !defined(SWIFT_NORETURN)
# if __has_attribute(noreturn)
#  define SWIFT_NORETURN __attribute__((noreturn))
# else
#  define SWIFT_NORETURN 
# endif
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA 
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA 
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA 
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif
#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif
#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER 
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility) 
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED_OBJC)
# if __has_feature(attribute_diagnose_if_objc)
#  define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
# else
#  define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
# endif
#endif
#if defined(__OBJC__)
#if !defined(IBSegueAction)
# define IBSegueAction 
#endif
#endif
#if !defined(SWIFT_EXTERN)
# if defined(__cplusplus)
#  define SWIFT_EXTERN extern "C"
# else
#  define SWIFT_EXTERN extern
# endif
#endif
#if !defined(SWIFT_CALL)
# define SWIFT_CALL __attribute__((swiftcall))
#endif
#if !defined(SWIFT_INDIRECT_RESULT)
# define SWIFT_INDIRECT_RESULT __attribute__((swift_indirect_result))
#endif
#if !defined(SWIFT_CONTEXT)
# define SWIFT_CONTEXT __attribute__((swift_context))
#endif
#if !defined(SWIFT_ERROR_RESULT)
# define SWIFT_ERROR_RESULT __attribute__((swift_error_result))
#endif
#if defined(__cplusplus)
# define SWIFT_NOEXCEPT noexcept
#else
# define SWIFT_NOEXCEPT 
#endif
#if !defined(SWIFT_C_INLINE_THUNK)
# if __has_attribute(always_inline)
# if __has_attribute(nodebug)
#  define SWIFT_C_INLINE_THUNK inline __attribute__((always_inline)) __attribute__((nodebug))
# else
#  define SWIFT_C_INLINE_THUNK inline __attribute__((always_inline))
# endif
# else
#  define SWIFT_C_INLINE_THUNK inline
# endif
#endif
#if defined(_WIN32)
#if !defined(SWIFT_IMPORT_STDLIB_SYMBOL)
# define SWIFT_IMPORT_STDLIB_SYMBOL __declspec(dllimport)
#endif
#else
#if !defined(SWIFT_IMPORT_STDLIB_SYMBOL)
# define SWIFT_IMPORT_STDLIB_SYMBOL 
#endif
#endif
#if defined(__OBJC__)
#if __has_feature(objc_modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import ObjectiveC;
@import ParseCore;
#endif

#endif
#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"
#pragma clang diagnostic ignored "-Wdollar-in-identifier-extension"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="TMGParseLiveQuery",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif

#if defined(__OBJC__)
@class NSString;

/// This is the ‘advanced’ view of live query subscriptions. It allows you to customize your subscriptions
/// to a live query server, have connections to multiple servers, cleanly handle disconnect and reconnect.
SWIFT_CLASS_NAMED("Client")
@interface PFLiveQueryClient : NSObject
/// Creates a Client which automatically attempts to connect to the custom parse-server URL set in Parse.currentConfiguration().
- (nonnull instancetype)init;
/// Creates a client which will connect to a specific server with an optional application id and client key
/// \param server The server to connect to
///
/// \param applicationId The application id to use
///
/// \param clientKey The client key to use
///
- (nonnull instancetype)initWithServer:(NSString * _Nonnull)server applicationId:(NSString * _Nullable)applicationId clientKey:(NSString * _Nullable)clientKey OBJC_DESIGNATED_INITIALIZER;
@end




@interface PFLiveQueryClient (SWIFT_EXTENSION(TMGParseLiveQuery))
/// Gets or sets shared live query client to be used for default subscriptions
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, strong) PFLiveQueryClient * _Null_unspecified sharedClient;)
+ (PFLiveQueryClient * _Null_unspecified)sharedClient SWIFT_WARN_UNUSED_RESULT;
+ (void)setSharedClient:(PFLiveQueryClient * _Null_unspecified)newValue;
@end



@interface PFLiveQueryClient (SWIFT_EXTENSION(TMGParseLiveQuery))
/// Reconnects this client to the server.
/// This will disconnect and resubscribe all existing subscriptions. This is not required to be called the first time
/// you use the client, and should usually only be called when an error occurs.
- (void)reconnect;
/// Explicitly disconnects this client from the server.
/// This does not remove any subscriptions - if you <code>reconnect()</code> your existing subscriptions will be restored.
/// Use this if you wish to dispose of the live query client.
- (void)disconnect;
@end


@protocol PFLiveQuerySubscriptionHandling;
@class PFLiveQuerySubscription;

@interface PFLiveQueryClient (SWIFT_EXTENSION(TMGParseLiveQuery))
/// Registers a query for live updates, using a custom subscription handler.
/// \param query The query to register for updates.
///
/// \param handler A custom subscription handler.
///
///
/// returns:
/// The subscription that has just been registered.
- (id <PFLiveQuerySubscriptionHandling> _Nonnull)subscribeToQuery:(PFQuery<PFObject *> * _Nonnull)query withHandler:(id <PFLiveQuerySubscriptionHandling> _Nonnull)handler SWIFT_WARN_UNUSED_RESULT;
/// Registers a query for live updates, using the default subscription handler.
/// \param query The query to register for updates.
///
///
/// returns:
/// The subscription that has just been registered.
- (PFLiveQuerySubscription * _Nonnull)subscribeToQuery:(PFQuery<PFObject *> * _Nonnull)query SWIFT_WARN_UNUSED_RESULT;
/// Unsubscribes a specific handler from a query.
/// \param query The query to unsubscribe from.
///
/// \param handler The specific handler to unsubscribe from.
///
- (void)unsubscribeFromQuery:(PFQuery<PFObject *> * _Nonnull)query withHandler:(id <PFLiveQuerySubscriptionHandling> _Nonnull)subscriptionHandler;
@end


@interface PFLiveQueryClient (SWIFT_EXTENSION(TMGParseLiveQuery))
/// Unsubscribes all current subscriptions for a given query.
/// \param query The query to unsubscribe from.
///
- (void)unsubscribeFromQuery:(PFQuery<PFObject *> * _Nonnull)query;
@end



@class PFLiveQueryEvent;
@class NSError;

/// This protocol describes the interface for handling events from a live query client.
/// You can use this protocol on any custom class of yours, instead of Subscription, if it fits your use case better.
SWIFT_PROTOCOL_NAMED("ObjCCompat_SubscriptionHandling")
@protocol PFLiveQuerySubscriptionHandling
@optional
/// Tells the handler that an event has been received from the live query server.
/// \param query The query that the event occurred on.
///
/// \param event The event that has been recieved from the server.
///
/// \param client The live query client which received this event.
///
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didRecieveEvent:(PFLiveQueryEvent * _Nonnull)event inClient:(PFLiveQueryClient * _Nonnull)client;
/// Tells the handler that an error has been received from the live query server.
/// \param query The query that the error occurred on.
///
/// \param error The error that the server has encountered.
///
/// \param client The live query client which received this error.
///
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didEncounterError:(NSError * _Nonnull)error inClient:(PFLiveQueryClient * _Nonnull)client;
/// Tells the handler that a query has been successfully registered with the server.
/// note:
/// This may be invoked multiple times if the client disconnects/reconnects.
/// \param query The query that has been subscribed.
///
/// \param client The live query client which subscribed this query.
///
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didSubscribeInClient:(PFLiveQueryClient * _Nonnull)client;
/// Tells the handler that a query has been successfully deregistered from the server.
/// note:
/// This is not called unless <code>unregister()</code> is explicitly called.
/// \param query The query that has been unsubscribed.
///
/// \param client The live query client which unsubscribed this query.
///
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didUnsubscribeInClient:(PFLiveQueryClient * _Nonnull)client;
@end


/// A type of an update event on a specific object from the live query server.
typedef SWIFT_ENUM(NSInteger, PFLiveQueryEventType, open) {
/// The object has been updated, and is now included in the query.
  PFLiveQueryEventTypeEntered = 0,
/// The object has been updated, and is no longer included in the query.
  PFLiveQueryEventTypeLeft = 1,
/// The object has been created, and is a part of the query.
  PFLiveQueryEventTypeCreated = 2,
/// The object has been updated, and is still a part of the query.
  PFLiveQueryEventTypeUpdated = 3,
/// The object has been deleted, and is no longer included in the query.
  PFLiveQueryEventTypeDeleted = 4,
};


@interface PFQuery<PFGenericObject> (SWIFT_EXTENSION(TMGParseLiveQuery))
/// Register this PFQuery for updates with Live Queries.
/// This uses the shared live query client, and creates a default subscription handler for you.
///
/// returns:
/// The created subscription for observing.
- (PFLiveQuerySubscription * _Nonnull)subscribe SWIFT_WARN_UNUSED_RESULT;
@end



/// A default implementation of the SubscriptionHandling protocol, using blocks for callbacks.
SWIFT_CLASS_NAMED("Subscription")
@interface PFLiveQuerySubscription : NSObject
/// Register a callback for when a client succesfully subscribes to a query.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addSubscribeHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when a query has been unsubscribed.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addUnsubscribeHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an error occurs.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addErrorHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, NSError * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an event occurs.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addEventHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, PFLiveQueryEvent * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an object enters a query.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addEnterHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, PFObject * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an object leaves a query.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addLeaveHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, PFObject * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an object that matches the query is created.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addCreateHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, PFObject * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an object that matches the query is updated.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addUpdateHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, PFObject * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
/// Register a callback for when an object that matches the query is deleted.
/// \param handler The callback to register.
///
///
/// returns:
/// The same subscription, for easy chaining.
- (PFLiveQuerySubscription * _Nonnull)addDeleteHandler:(void (^ _Nonnull)(PFQuery<PFObject *> * _Nonnull, PFObject * _Nonnull))handler SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


@interface PFLiveQuerySubscription (SWIFT_EXTENSION(TMGParseLiveQuery)) <PFLiveQuerySubscriptionHandling>
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didRecieveEvent:(PFLiveQueryEvent * _Nonnull)event inClient:(PFLiveQueryClient * _Nonnull)client;
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didEncounterError:(NSError * _Nonnull)error inClient:(PFLiveQueryClient * _Nonnull)client;
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didSubscribeInClient:(PFLiveQueryClient * _Nonnull)client;
- (void)liveQuery:(PFQuery<PFObject *> * _Nonnull)query didUnsubscribeInClient:(PFLiveQueryClient * _Nonnull)client;
@end

#endif
#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#if defined(__cplusplus)
#endif
#pragma clang diagnostic pop
#endif

#else
#error unsupported Swift architecture
#endif
