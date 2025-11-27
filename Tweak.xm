#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات السيرفر (نظامك الخاص)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// تعريف الكلاس الذي وجدته في الصور!
@interface SCLAlertViewBuilder : NSObject
- (id)show;
@end

// --- دوال الاتصال (نفس الكود السابق) ---
NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Connection Error"); return; }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"status"] isEqualToString:@"valid"]) {
            completion(YES, json[@"message"]);
        } else {
            completion(NO, json[@"message"]);
        }
    }] resume];
}

// --- نافذة الدخول الخاصة بك ---
void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎱 TakeCare Mod"
                                                                       message:@"Enter Key"
                                                                preferredStyle:(UIAlertControllerStyle)1]; 

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Key...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"Login" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        UIAlertController *s = [UIAlertController alertControllerWithTitle:@"✅ Active" message:nil preferredStyle:(UIAlertControllerStyle)1];
                        [s addAction:[UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyle)0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:s animated:YES completion:nil];
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

// ============================================================
// 2. الهجوم على المود القديم (بناءً على الصور)
// ============================================================

// 🔴 منع ظهور نافذة المود القديم
%hook SCLAlertViewBuilder

// عندما يحاول المود بناء النافذة وعرضها، نمنعه ونرجع nil
- (id)show {
    return nil; 
}

// دالة أخرى محتملة لإظهار النافذة
- (id)alertIsReady {
    return nil;
}

%end

// 🔴 تفعيل المميزات (عن طريق خداع الذاكرة)
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    // أي مفتاح فيه كلمة VIP أو Key أو Active نخليه True
    if ([key.lowercaseString containsString:@"vip"] || 
        [key.lowercaseString containsString:@"key"] || 
        [key.lowercaseString containsString:@"active"] ||
        [key.lowercaseString containsString:@"subscription"]) {
        return YES;
    }
    return %orig;
}

%end

// ============================================================
// 3. التشغيل
// ============================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
