/*
 * Phoenix is released under the MIT License. Refer to https://github.com/kasper/phoenix/blob/master/LICENSE.md
 */

#import "PHTaskHandler.h"

@interface PHTaskHandler ()

@property NSTask *task;
@property NSMutableData *outputData;
@property NSMutableData *errorData;

@property int status;
@property (copy) NSString *output;
@property (copy) NSString *error;

@end

@implementation PHTaskHandler

#pragma mark - Initialise

- (instancetype) initWithPath:(NSString *)path arguments:(NSArray<NSString *> *)arguments callback:(JSValue *)callback {

    if (self = [super initWithCallback:callback]) {

        self.task = [[NSTask alloc] init];
        self.outputData = [NSMutableData data];
        self.errorData = [NSMutableData data];

        /* Configure task */

        self.task.launchPath = path;
        self.task.standardOutput = [NSPipe pipe];
        self.task.standardError = [NSPipe pipe];

        if (arguments) {
            self.task.arguments = arguments;
        }

        [self setupReadabilityHandlers];
        [self setupTerminationHandler];
        [self launch];
    }

    return self;
}

+ (instancetype) withPath:(NSString *)path arguments:(NSArray<NSString *> *)arguments callback:(JSValue *)callback {

    return [[self alloc] initWithPath:path arguments:arguments callback:callback];
}

#pragma mark - Setup

- (void) setupReadabilityHandlers {

    // Read standard output asynchronously
    [self.task.standardOutput fileHandleForReading].readabilityHandler = ^(NSFileHandle *file) {

        [self.outputData appendData:file.availableData];
    };

    // Read standard error asynchronously
    [self.task.standardError fileHandleForReading].readabilityHandler = ^(NSFileHandle *file) {

        [self.errorData appendData:file.availableData];
    };
}

- (void) setupTerminationHandler {

    PHTaskHandler * __weak weakSelf = self;

    // Wait termination asynchronously
    self.task.terminationHandler = ^(NSTask *task) {

        // Close file handlers
        [task.standardOutput fileHandleForReading].readabilityHandler = nil;
        [task.standardError fileHandleForReading].readabilityHandler = nil;

        weakSelf.status = task.terminationStatus;
        weakSelf.output = [[NSString alloc] initWithData:weakSelf.outputData encoding:NSUTF8StringEncoding];
        weakSelf.error = [[NSString alloc] initWithData:weakSelf.errorData encoding:NSUTF8StringEncoding];

        [weakSelf taskDidTerminate];
    };
}

#pragma mark - Launching

- (void) launch {

    @try {
        [self.task launch];
    }

    @catch (NSException *exception) {
        NSLog(@"Error: Could not run command in path “%@” with arguments “%@”. Exception: %@.", self.task.launchPath, self.task.arguments, exception);
    }
}

#pragma mark - Terminating

- (void) taskDidTerminate {

    [self callWithArguments:@[ self ]];
}

@end
