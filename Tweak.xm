#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ==========================================================
// الجزء الأول: إعدادات اللودر والسيرفر الجديد (بتاعك)
// ==========================================================

#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"

static BOOL isVerified = NO;

// تعريفات مساعدة
@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// تعريف كلاس المود القديم عشان نقدر نستخدم دواله
@interface OverlayManager : NSObject
- (void)drawMenuWindow; // دالة رسم القائمة
@end

// 1. دالة جلب معرف الجهاز
NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

// 2. دالة التحقق من السيرفر
void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"تأكد من الإنترنت!"); return; }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || !json) { completion(NO, @"خطأ في السيرفر"); return; }
        
        NSString *status = json[@"status"];
        if ([status isEqualToString:@"valid"]) {
            completion(YES, json[@"message"]);
        } else {
            completion(NO, json[@"message"]);
        }
    }] resume];
}

// 3. دالة إظهار نافذة الحماية الخاصة بك
void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ تفعيل الحماية"
                                                                       message:@"أدخل كود الاشتراك الخاص بك"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"الكود هنا...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"دخول" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        // حفظ الكود وتفعيل المتغير
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        // رسالة نجاح
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ تم" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"ابدأ" style:UIAlertActionStyleDefault handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        // إعادة المحاولة
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
// الجزء الثاني: خداع المود القديم (Hooking)
// ==========================================================

%hook OverlayManager

// دي الدالة اللي المود بيناديها عشان يرسم نافذة "الكود القديم"
// إحنا هنعترضها ونقوله: "لا، ارسم القائمة الأصلية بدالها"
- (void)drawLoginWindow:(id)arg1 {
    // 1. هل المستخدم عدى من اللودر بتاعك؟
    if (isVerified) {
        // لو مفعل، افتح القائمة علطول (كده تخطينا الكود القديم)
        [self drawMenuWindow];
    } else {
        // لو مش مفعل، متعملش حاجة (شاشة فاضية) لحد ما اللودر يظهر
        // أو ممكن نسيبها فاضية خالص عشان اللودر بتاعك هو اللي ظاهر
    }
}

// زيادة تأكيد: بنقول للمود إن "التفعيل تمام" لو سأل
- (BOOL)isLogin { return YES; }
- (BOOL)isVip { return YES; }

%end

// ==========================================================
// نقطة البداية
// ==========================================================
%ctor {
    // تشغيل اللودر بتاعك بعد 5 ثواني
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
