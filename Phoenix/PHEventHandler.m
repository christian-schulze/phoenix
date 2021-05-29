/*
 * Phoenix is released under the MIT License. Refer to https://github.com/kasper/phoenix/blob/master/LICENSE.md
 */

@import Cocoa;

#import "PHApp.h"
#import "PHAXObserver.h"
#import "PHEventHandler.h"
#import "PHEventTranslator.h"
#import "PHGlobalEventMonitor.h"
#import "PHWindow.h"
#import "PHEventConstants.h"

@interface PHEventHandler ()

@property (weak) NSNotificationCenter *notificationCenter;
@property (copy) NSString *name;
@property (copy) NSString *notification;

@end

@implementation PHEventHandler

#pragma mark - Initialising

- (instancetype) initWithEvent:(NSString *)event callback:(JSValue *)callback {

    if (self = [super initWithCallback:callback]) {

        self.name = event;
        self.notification = [PHEventTranslator notificationForEvent:event];

        // Event not supported
        if (!self.notification) {
            NSLog(@"Warning: Event “%@” not supported.", event);
            return self;
        }

        // Observe event notification
        self.notificationCenter = [PHEventTranslator notificationCenterForNotification:self.notification];

        [self.notificationCenter addObserver:self
                                    selector:@selector(didReceiveNotification:)
                                        name:self.notification
                                      object:nil];
    }

    return self;
}

#pragma mark - Deallocing

- (void) dealloc {

    [self disable];
}

#pragma mark - Binding

- (void) disable {

    [self.notificationCenter removeObserver:self name:self.notification object:nil];
}

#pragma mark - Notification Handling

- (void) didReceiveNotification:(NSNotification *)notification {

    NSDictionary<NSString *, id> *mouse = notification.userInfo[PHGlobalEventMonitorMouseKey];
    NSRunningApplication *runningApp = notification.userInfo[NSWorkspaceApplicationKey];
    PHWindow *window = notification.userInfo[PHAXObserverWindowKey];
    NSString *dispatchData = notification.userInfo[PHAppleScriptDispatchNotification];

    // Notification for mouse
    if (mouse) {
        [self callWithArguments:@[ mouse, self ]];
        return;
    }

    // Notification for app
    if (runningApp) {
        PHApp *app = [[PHApp alloc] initWithApp:runningApp];
        [self callWithArguments:@[ app, self ]];
        return;
    }

    // Notification for window
    if (window) {
        [self callWithArguments:@[ window, self ]];
        return;
    }

    // AppleScript Dispatch event with data
    if (dispatchData) {
        [self callWithArguments:@[ self, dispatchData ]];
        return;
    }

    [self callWithArguments:@[ self ]];
}

@end
