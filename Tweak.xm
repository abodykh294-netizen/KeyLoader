#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات السيرفر (KeyLoader Configuration)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key" // ⬅️ سيرفرك الخاص
static BOOL isVerified = NO;

// تعريفات للكلاسات القديمة لكي يفهمها الكود
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
    // [Network Logic]
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Error: Check Internet!"); return; }
        NSDictionary *json = [NSSerialization JSONObjectWithData:data options:0 error:nil];
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

        // Fix 1: تحويل صريح لنمط الكنترولر (UIAlertControllerStyle)
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 Security Check"
                                                                       message:@"Enter Your License Key"
                                                                preferredStyle:(UIAlertControllerStyle)1]; 

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Paste Key Here...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"Login" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            alert.message = @"جاري التحقق..."; 
            
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ Success" message:msg preferredStyle:(UIAlertControllerStyle)1];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"Start Game" style:(UIAlertActionStyle)0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        UIAlertController *failAlert = [UIAlertController alertControllerWithTitle:@"❌ Error" message:msg preferredStyle:(UIAlertControllerStyle)1];
                        [failAlert addAction:[UIAlertAction actionWithTitle:@"Try Again" style:(UIAlertActionStyle)2 handler:^(UIAlertAction *action){
                            showPopup();
                        }]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:failAlert animated:YES completion:nil];
                    }
                });
            });
        }];

        // زر شراء (اختياري)
        UIAlertAction *buyAction = [UIAlertAction actionWithTitle:@"Buy Key" style:(UIAlertActionStyle)1 handler:^(UIAlertAction *action){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/YourChannel"] options:@{} completionHandler:nil];
            showPopup();
        }];

        [alert addAction:verifyAction];
        [alert addAction:buyAction];
        
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) topController = topController.presentedViewController;
        [topController presentViewController:alert animated:YES completion:nil];
    });
}


// ============================================================
// 2. الحل: Anti-Crash & Logic Bypass (Final Hooks)
// ============================================================

// 🥇 Anti-Crash / Alert Killer: Hooking UIAlertController (يحل مشكلة الـ Crash الأخيرة)
%hook UIAlertController

// Fix 2: استخدام NSInteger لحل خطأ التجميع
+ (id)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(NSInteger)preferredStyle {
    
    // فحص العنوان والمحتوى لكلمات التحقق
    if ([title containsString:@"License"] || 
        [title containsString:@"Update"] ||
        [title containsString:@"Key"] ||
        [title containsString:@"Subscription"]) {
        
        return nil; // نمنع إنشاء Alert التحقق نهائياً
    }
    // لبقية الـ Alerts، نرجع الكود الأصلي
    return %orig;
}

%end

// 🥈 Activation Logic Bypass: Hooking Menu Manager (لتشغيل التفعيلات)
%hook MenuManager
- (BOOL)isProUser { return YES; } 
- (BOOL)isVip { return YES; } 
- (BOOL)isLogin { return YES; }
- (BOOL)isActivated { return YES; }
- (void)drawLoginWindow:(id)arg1 { /* NOP */ } // منع الرسم كإجراء احتياطي
%end

// 🥉 Safety Net: Hooking NSUserDefaults
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
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
