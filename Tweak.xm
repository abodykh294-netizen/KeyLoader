#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 🔴 رابط السيرفر بتاعك (تأكد إنه صح)
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"

// تعريف واجهة مساعدة
@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// متغيرات لتتبع حالة التفعيل
static BOOL isVerified = NO;

// --- 1. دالة لجلب معرف الجهاز (HWID) ---
NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

// --- 2. دالة الاتصال بالسيرفر والتحقق ---
void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    
    // تجهيز الرابط
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // إرسال الطلب
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // في حالة خطأ في النت
        if (error) {
            completion(NO, @"خطأ في الاتصال بالإنترنت!");
            return;
        }
        
        // قراءة الرد (JSON)
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || !json) {
            completion(NO, @"خطأ في قراءة رد السيرفر");
            return;
        }
        
        NSString *status = json[@"status"];
        NSString *message = json[@"message"];
        
        // التحقق من الحالة
        if ([status isEqualToString:@"valid"]) {
            completion(YES, message);
        } else {
            completion(NO, message);
        }
    }] resume];
}

// --- 3. دالة إظهار النافذة المنبثقة ---
void showPopup() {
    // التأكد من أن الكود يعمل في الواجهة الرئيسية (Main Thread)
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (isVerified) return; // لو مفعل خلاص

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ تفعيل الحماية"
                                                                       message:@"أدخل كود الاشتراك للمتابعة"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // خانة إدخال الكود
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"ألصق الكود هنا...";
            textField.textAlignment = NSTextAlignmentCenter;
            // استرجاع الكود المحفوظ قديماً لتسهيل الدخول
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        // زر التفعيل
        UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"دخول" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *key = alert.textFields.firstObject.text;
            
            // رسالة انتظار
            alert.message = @"جاري التحقق... ⏳";
            
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        // ✅ نجاح: حفظ الكود وفتح اللعبة
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        isVerified = YES;
                        
                        UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"تم بنجاح ✅" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [successAlert addAction:[UIAlertAction actionWithTitle:@"ابدأ اللعب" style:UIAlertActionStyleDefault handler:nil]];
                        
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:successAlert animated:YES completion:nil];
                        
                    } else {
                        // ❌ فشل: إظهار الخطأ وإعادة النافذة
                        UIAlertController *failAlert = [UIAlertController alertControllerWithTitle:@"خطأ ❌" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [failAlert addAction:[UIAlertAction actionWithTitle:@"حاول مرة أخرى" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                            showPopup(); // إعادة إظهار النافذة لمنع الدخول
                        }]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:failAlert animated:YES completion:nil];
                    }
                });
            });
        }];

        // زر شراء (اختياري)
        UIAlertAction *buyAction = [UIAlertAction actionWithTitle:@"شراء كود" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/YourChannel"] options:@{} completionHandler:nil];
             showPopup(); // إعادة النافذة
        }];

        [alert addAction:verifyAction];
        [alert addAction:buyAction];
        
        // عرض النافذة فوق كل شيء
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        [topController presentViewController:alert animated:YES completion:nil];
    });
}

// --- 4. نقطة البداية (Constructor) ---
%ctor {
    // تشغيل الكود بعد 4 ثواني من فتح اللعبة لضمان تحميل الواجهة
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}