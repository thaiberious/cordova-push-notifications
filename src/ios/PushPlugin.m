/*
 Copyright 2009-2011 Urban Airship Inc. All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PushPlugin.h"

@implementation PushPlugin

@synthesize notificationMessage;
@synthesize params;
@synthesize isInline;

@synthesize callbackId;
@synthesize notificationCallbackId;
@synthesize callback;


- (void)unregister:(CDVInvokedUrlCommand*)command;
{
  self.callbackId = command.callbackId;

  [[UIApplication sharedApplication] unregisterForRemoteNotifications];
  [self successWithMessage:@"unregistered"];
}

- (void)areNotificationsEnabled:(CDVInvokedUrlCommand*)command;
{
  self.callbackId = command.callbackId;
  BOOL registered;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
  if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
    registered = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
  } else {
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    registered = types != UIRemoteNotificationTypeNone;
  }
#else
  UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
  registered = types != UIRemoteNotificationTypeNone;
#endif
  CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:registered];
  [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
}

- (void)registerUserNotificationSettings:(CDVInvokedUrlCommand*)command;
{
  self.callbackId = command.callbackId;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (![[UIApplication sharedApplication]respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [self successWithMessage:[NSString stringWithFormat:@"%@", @"user notifications not supported for this ios version."]];
        return;
    }

  NSDictionary *options = [command.arguments objectAtIndex:0];
  NSArray *categories = [options objectForKey:@"categories"];
  if (categories == nil) {
    [self failWithMessage:@"No categories specified" withError:nil];
    return;
  }
  NSMutableArray *nsCategories = [[NSMutableArray alloc] initWithCapacity:[categories count]];

  for (NSDictionary *category in categories) {
    // ** 1. create the actions for this category
    NSMutableArray *nsActionsForDefaultContext = [[NSMutableArray alloc] initWithCapacity:4];
    NSArray *actionsForDefaultContext = [category objectForKey:@"actionsForDefaultContext"];
    if (actionsForDefaultContext == nil) {
      [self failWithMessage:@"Category doesn't contain actionsForDefaultContext" withError:nil];
      return;
    }
    if (![self createNotificationAction:category actions:actionsForDefaultContext nsActions:nsActionsForDefaultContext]) {
      return;
    }

    NSMutableArray *nsActionsForMinimalContext = [[NSMutableArray alloc] initWithCapacity:2];
    NSArray *actionsForMinimalContext = [category objectForKey:@"actionsForMinimalContext"];
    if (actionsForMinimalContext == nil) {
      [self failWithMessage:@"Category doesn't contain actionsForMinimalContext" withError:nil];
      return;
    }
    if (![self createNotificationAction:category actions:actionsForMinimalContext nsActions:nsActionsForMinimalContext]) {
      return;
    }

...
