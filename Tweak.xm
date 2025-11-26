#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ==========================================================
// الجزء الأول: إعدادات اللودر (KeyLoader)
// ==========================================================

#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"

static BOOL isVerified = NO;

@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// تعريف الكلاسات عشان الكود يفهمها
@interface MenuManager : NSObject
- (void)drawMenuWindow;
@end

NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Check Internet Connection"); return; }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || !json) { completion(NO, @"Server Error"); return; }
        
        if ([json[@"status"] isEqualToString:@"valid"]) {
            completion(YES, json[@"message"]);
        } else {
            completion(NO, json[@"message"]);
        }
    }] resume];
}

void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Activator"
                                                                       message:@"Enter Your Key"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Key...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"Success" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"Start" style:UIAlertActionStyleDefault handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        showPopup();
                    }
                });
            });
        }];

        [alert addAction:loginAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ==========================================================
// الجزء الثاني: كسر حماية المود القديم (The Crack)
// ==========================================================

// 1. السيطرة على OverlayManager (اللي شوفناه في الصورة)
%hook OverlayManager

// أي دالة تفعيل نجاوب عليها بـ نعم
- (BOOL)isLogin { return YES; }
- (BOOL)isVip { return YES; }
- (BOOL)hasKey { return YES; }

%end

// 2. السيطرة على MenuManager (اللي بيترسم جواه)
%hook MenuManager

// لو حد نادى على دالة رسم نافذة الكود..
- (void)drawLoginWindow:(id)arg1 {
    // لو اللودر بتاعك مفعل.. افتح القائمة علطول
    if (isVerified) {
        [self drawMenuWindow];
    }
    // لو مش مفعل.. متعملش حاجة (خلي اللودر بس هو اللي يظهر)
}

%end


// ==========================================================
// نقطة البداية
// ==========================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
