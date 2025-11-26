#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات السيرفر (KeyLoader Configuration)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// تعريف الكلاسات المطلوبة
@interface MenuManager : NSObject
- (void)drawMenuWindow;
@end

@interface OverlayManager : NSObject
- (void)drawMenuWindow;
@end

@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end


// --- دوال الاتصال والتحقق (CheckKey and ShowPopup) ---

NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Error: Check Internet!"); return; }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 Security Check"
                                                                       message:@"Enter Your License Key"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Paste Key Here...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            alert.message = @"جاري التحقق..."; 
            
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES; // ✅ تم التفعيل
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ Success" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"Start Game" style:UIAlertActionStyleDefault handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        showPopup(); // ❌ فشل، أعد النافذة
                    }
                });
            });
        }];

        [alert addAction:loginAction];
        
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) topController = topController.presentedViewController;
        [topController presentViewController:alert animated:YES completion:nil];
    });
}


// ============================================================
// 2. الحل: Anti-Crash & Logic Bypass (الأكواد الضرورية)
// ============================================================

// 🥇 Anti-Crash / Alert Killer: Hooking UIAlertController (لمنع الـ Crash)
// نلغي إنشاء أي Alert يحمل كلمات التحقق المسبقة، مما يمنع Alert المود القديم من الظهور.
%hook UIAlertController

+ (id)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(UIAlertControllerControllerStyle)preferredStyle {
    // فحص العنوان والمحتوى لكلمات التحقق
    if ([title containsString:@"License"] || 
        [title containsString:@"Update"] ||
        [title containsString:@"Key"] ||
        [title containsString:@"Subscription"]) {
        
        // نرجع nil لمنع إنشاء Alert التحقق نهائياً
        return nil;
    }
    // لبقية الـ Alerts، نرجع الكود الأصلي
    return %orig;
}

%end

// 🥈 Activation Logic Bypass: Hooking Menu Manager (لتشغيل التفعيلات)
%hook MenuManager // (الكلاس الأقرب للتحكم في حالة اللعب)

// إجابة "نعم" على أي سؤال تفعيل
- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }
- (BOOL)isActivated { return YES; }
- (BOOL)hasKey { return YES; }

// نلغي دالة رسم نافذة الدخول القديمة كاحتياطي أخير
- (void)drawLoginWindow:(id)arg1 {
    // لا تفعل شيئًا، الـ KeyLoader هو المسؤول عن إظهار الواجهة
}

%end

// 🥉 Safety Net: Hooking NSUserDefaults (لتجاوز تفقد الإعدادات)
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    // نرد بـ YES على أي متغير يتعلق بالترخيص
    if ([key.lowercaseString containsString:@"vip"] || 
        [key.lowercaseString containsString:@"key"] || 
        [key.lowercaseString containsString:@"active"]) {
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
