#import "RNCardVerify.h"
#import <React/RCTBridgeDelegate.h>
@import Foundation;
@import CardVerify;

//MARK: - Verify View Delegate Implementation
@implementation VerifyViewDelegate
    - (void)setCallback:(RCTPromiseResolveBlock)resolve {
        self.resolve = resolve;
    }

    - (void)dismissView {
        UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
        [rootViewController dismissViewControllerAnimated:YES completion:nil];
    }

    - (void)userCanceledScanWithViewController:(VerifyCardSimpleViewController * _Nonnull)viewController  API_AVAILABLE(ios(11.2)){
        [self dismissView];
        self.resolve(@{ @"action": @"canceled",
                        @"canceledReason": @"user_canceled"
                     });

    }

    - (void)userDidScanCardWithViewController:(VerifyCardSimpleViewController * _Nonnull)viewController number:(NSString * _Nonnull)number name:(NSString * _Nullable)name expiryYear:(NSString * _Nullable)expiryYear expiryMonth:(NSString * _Nullable)expiryMonth payload:(NSString * _Nullable)payload  API_AVAILABLE(ios(11.2)){
        [self dismissView];
        self.resolve(@{@"action" : @"scanned",
                       @"payload": @{
                           @"number": number,
                           @"cardholderName": name ?: [NSNull null],
                           @"expiryMonth": expiryMonth ?: [NSNull null],
                           @"expiryYear": expiryYear ?: [NSNull null],
                           @"payloadVersion": @"1",
                           @"verificationPayload": payload ?: [NSNull null]
                       }
                   });
    }

    - (void)userMissingCardWithViewController:(VerifyCardSimpleViewController * _Nonnull)viewController  API_AVAILABLE(ios(11.2)){
        [self dismissView];
        self.resolve(@{ @"action": @"canceled",
                        @"canceledReason": @"user_missing_card"
                     });
    }

@end

//MARK: -RNCardVerify Module Implementation
@implementation RNCardVerify

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (id)init {
    if(self = [super init]) {
        self.verifyViewDelegate = [[VerifyViewDelegate alloc] init];
    }
    return self;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(isSupportedAsync:(RCTPromiseResolveBlock)resolve :(RCTPromiseRejectBlock)reject)
{
    resolve(@([Bouncer isCompatible]));
}

RCT_EXPORT_METHOD(scan:(NSString * _Nullable)requiredIin requiredLastFour:(NSString * _Nullable)requiredLastFour :(RCTPromiseResolveBlock)resolve :(RCTPromiseRejectBlock)reject)
{
    [self.verifyViewDelegate setCallback:resolve];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 11.2, *)) {
            UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            
            UIViewController *vc = [Bouncer createVerifyViewControllerWithLast4:requiredLastFour iin:requiredIin withDelegate:self.verifyViewDelegate];

            [topController presentViewController:vc animated:NO completion:nil];
        } else {
            // Fallback on earlier versions
        }
    });
}

@end
