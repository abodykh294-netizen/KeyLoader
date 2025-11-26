#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات السيرفر (KeyLoader Configuration)
// ============================================================

#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key" // ⬅️ سيرفرك الخاص
static BOOL isVerified = NO;

// تعريف الكلاسات المطلوبة لفك التشفير
@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

@interface SCLAlertView : NSObject
// نعلن عن الدالة الأساسية للعرض لكي نتمكن من اعتراضها
- (instancetype)showTitle:(id)title subTitle:(id)subTitle closeButtonTitle:(id)closeButtonTitle duration:(NSTimeInterval)duration;
- (instancetype)showError:(id)title subTitle:(id)subTitle closeButtonTitle:(id)closeButtonTitle duration:(NSTimeInterval)duration;
@end

@interface MenuManager : NSObject
- (void)drawMenuWindow; // دالة القائمة الأصلية
@end

// ... (نفس دوال checkKey و showPopup التي تم إرسالها سابقًا) ...
// (هنا يجب عليك وضع الكود الكامل لـ getDeviceID, checkKey, و showPopup)

// ============================================================
// 2. منطقة الهجوم (Hooks)
// ============================================================

// 🥇 الهجوم على SCLAlertView (إلغاء نافذة التحقق نهائياً)
%hook SCLAlertView

// اعتراض دالة العرض: نمنعها من إنشاء الـ Alert (بغض النظر عن نوعه)
- (instancetype)showTitle:(id)title subTitle:(id)subTitle closeButtonTitle:(id)closeButtonTitle duration:(NSTimeInterval)duration {
    // نمنع عرض الرسالة ونرجع nil (لا شيء)
    return nil;
}

// نلغي دالة عرض رسالة الخطأ كاحتياطي
- (instancetype)showError:(id)title subTitle:(id)subTitle closeButtonTitle:(id)closeButtonTitle duration:(NSTimeInterval)duration {
    return nil;
}

%end


// 🥈 الهجوم على MenuManager/GameLogic (إيهام المود بالتفعيل)
%hook MenuManager // (أو Kingmod أو GameLogic حسب ما يحدده Ghidra)

// 1. إجابة قاطعة: نعم مفعل دائماً!
- (BOOL)isProUser { return YES; } // أشهر اسم
- (BOOL)isSubscribed { return YES; }
- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }
- (BOOL)hasKey { return YES; }
- (BOOL)checkUserAuth { return YES; } // إجابة على دالة التحقق الأساسية

// 2. إلغاء زرار الدخول القديم (عشان لو حد داس عليه)
- (void)performLogin { 
    // نعمل Hook للدالة ونخليها متنفذش الكود الأصلي خالص
    return;
}

%end

// 🥉 الهجوم على الذاكرة (NSUserDefaults)
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    // أي سؤال عن VIP أو Key أو Subscribed نجاوب بـ نعم
    if ([key.lowercaseString containsString:@"vip"] || 
        [key.lowercaseString containsString:@"subscr"] || 
        [key.lowercaseString containsString:@"key"] || 
        [key.lowercaseString containsString:@"active"]) {
        return YES;
    }
    return %orig;
}
%end

// ============================================================
// 3. التشغيل (Constructor)
// ============================================================
%ctor {
    // تشغيل نافذة اللودر بتاعتك بعد 5 ثواني
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // showPopup(); // ⬅️ شغل دالة النافذة الخاصة بك هنا
    });
}
