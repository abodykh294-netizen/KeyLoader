#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. سيرفرك (النافذة بتاعتك)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// (حط هنا دوال getDeviceID و checkKey و showPopup اللي كانت معاك)
// ... اختصاراً للمساحة ...

// ============================================================
// 2. الجوكر: قتل حماية المود القديم (بدون كراش)
// ============================================================

// أ. خداع الذاكرة (أي مود بيسأل الذاكرة: هل أنا مفعل؟)
%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    // لو السؤال فيه ريحة تفعيل، قول "أيوه"
    if ([key.lowercaseString containsString:@"vip"] || 
        [key.lowercaseString containsString:@"active"] || 
        [key.lowercaseString containsString:@"key"] ||
        [key.lowercaseString containsString:@"license"]) {
        return YES; 
    }
    return %orig;
}
// لو سأل عن توكن أو سترنج
- (id)objectForKey:(NSString *)key {
    if ([key.lowercaseString containsString:@"token"] || 
        [key.lowercaseString containsString:@"user"]) {
        return @"User_Hacked_By_Abody";
    }
    return %orig;
}
%end

// ب. قتل نافذة التنبيه القديمة (عشان متظهرش وتطلب كود)
%hook UIAlertController
+ (id)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(NSInteger)preferredStyle {
    if ([title containsString:@"License"] || 
        [title containsString:@"Key"] ||
        [message containsString:@"Enter"] ||
        [title containsString:@"Security"]) {
        return nil; // اقتل النافذة دي
    }
    return %orig;
}
%end

// ج. محاولة أخيرة على كلاسات مشهورة (لو موجودة هتتفعل، لو مش موجودة مش هتضر)
%hook MenuManager
- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }
%end

// ============================================================
// 3. التشغيل
// ============================================================
%ctor {
    // شغل نافذتك أنت بعد 5 ثواني
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // showPopup(); 
    });
}
