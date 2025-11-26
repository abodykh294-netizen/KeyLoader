#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات سيرفرك (نفس الكود الذي أرسلته لي)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// تعريفات للكلاسات القديمة لكي يفهمها الكود
@interface MenuManager : NSObject
- (void)drawMenuWindow;
@end

@interface OverlayManager : NSObject
- (void)drawMenuWindow;
@end

// --- دالة ID الجهاز ---
NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

// --- دالة الاتصال بالسيرفر ---
void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"تأكد من الاتصال بالإنترنت!"); return; }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || !json) { completion(NO, @"خطأ في السيرفر"); return; }
        
        if ([json[@"status"] isEqualToString:@"valid"]) {
            completion(YES, json[@"message"]);
        } else {
            completion(NO, json[@"message"]);
        }
    }] resume];
}

// --- دالة النافذة المنبثقة (اللودر الخاص بك) ---
void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 تفعيل الحماية"
                                                                       message:@"أدخل كود الاشتراك الخاص بك"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"الكود هنا...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"دخول" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            alert.message = @"جاري التحقق..."; 
            
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES; // ✅ تم التفعيل
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ تم بنجاح" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"ابدأ اللعب" style:UIAlertActionStyleDefault handler:nil]];
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
// 2. منطقة الهجوم (Hooks) - هذا هو الجزء الناقص في ملفك!
// ============================================================

// أ. الهجوم على OverlayManager (الرسم)
%hook OverlayManager
- (void)drawLoginWindow:(id)arg1 {
    // لو المستخدم عدى من اللودر بتاعنا.. افتح القائمة علطول
    if (isVerified) {
        // بنحاول ننادي أي دالة رسم قائمة محتملة
        if ([self respondsToSelector:@selector(drawMenuWindow)]) {
            [self drawMenuWindow];
        } else if ([self respondsToSelector:@selector(drawMenu)]) {
            [self performSelector:@selector(drawMenu)];
        }
    }
}
// إيهام المود بالتفعيل لكي تعمل المميزات
- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }
- (BOOL)isActivated { return YES; }
- (BOOL)hasKey { return YES; }
%end

// ب. الهجوم على MenuManager (التحكم)
%hook MenuManager
- (void)drawLoginWindow:(id)arg1 {
    if (isVerified) {
        if ([self respondsToSelector:@selector(drawMenuWindow)]) {
            [self drawMenuWindow];
        }
    }
}
- (void)performLogin { } // إلغاء زرار الدخول القديم
- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }
- (BOOL)isActivated { return YES; }
- (BOOL)hasKey { return YES; }
%end

// ج. الهجوم على الذاكرة (UserDefaults) - الجوكر
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    // أي سؤال عن VIP أو Key نجاوب بـ نعم
    if ([key.lowercaseString containsString:@"vip"] || 
        [key.lowercaseString containsString:@"activ"] || 
        [key.lowercaseString containsString:@"key"]) {
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
