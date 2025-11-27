#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات السيرفر (KeyLoader)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// تعريفات
@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// --- دوال الاتصال والتحقق ---
NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Connection Error"); return; }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]; // تم التصحيح
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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 Security"
                                                                       message:@"Enter Key"
                                                                preferredStyle:(UIAlertControllerStyle)1];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Key...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Login" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        // رسالة نجاح صغيرة
                        UIAlertController *s = [UIAlertController alertControllerWithTitle:@"✅" message:nil preferredStyle:1];
                        [s addAction:[UIAlertAction actionWithTitle:@"OK" style:0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:s animated:YES completion:nil];
                    } else {
                        showPopup();
                    }
                });
            });
        }];
        [alert addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ============================================================
// 2. إصلاح الكراش + قتل نافذة التحقق (The Safe Killer)
// ============================================================

%hook UIAlertController

// بدلاً من منع الإنشاء، نتدخل عند الظهور (viewDidAppear)
- (void)viewDidAppear:(BOOL)animated {
    %orig; // شغل الكود الأصلي الأول عشان ميكرش
    
    // هات العنوان والرسالة
    NSString *title = [self title];
    NSString *message = [self message];
    
    // قائمة الكلمات المحظورة (اللي بتظهر في نافذة المود القديم)
    if ([title containsString:@"License"] || 
        [title containsString:@"key"] || 
        [title containsString:@"Key"] || 
        [message containsString:@"expired"] ||
        [message containsString:@"contact"]) {
        
        // 🛑 أغلق النافذة فوراً (بدون أنميشن عشان محدش يلاحظ)
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

%end

// ============================================================
// 3. محاولة تشغيل التفعيلات (ببجي & بلياردو)
// ============================================================

// هوك عام على UserDefaults (لأن ده المكان اللي بيسيفوا فيه التفعيل)
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    // أي حاجة فيها ريحة تفعيل، رجع True
    if ([key.lowercaseString containsString:@"vip"] || 
        [key.lowercaseString containsString:@"active"] || 
        [key.lowercaseString containsString:@"enable"]) {
        return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    // لو سأل عن توكن أو يوزر
    if ([key.lowercaseString containsString:@"token"] || 
        [key.lowercaseString containsString:@"user"]) {
        return @"User123456";
    }
    return %orig;
}

%end

// محاولة أخيرة لكلاسات مشهورة (بدون تحديد دالة معينة عشان الكراش)
// لو الكلاس مش موجود، الهوك مش هيشتغل بس مش هيموت اللعبة
%hook MenuManager
- (BOOL)isVip { return YES; }
%end

%hook OverlayManager
- (BOOL)isVip { return YES; }
%end

// ============================================================
// 4. التشغيل
// ============================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
