#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ==============================================
// 1. كود اللودر والسيرفر (الأساسي بتاعك)
// ==============================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// ... (نفس دوال getDeviceID و checkKey و showPopup اللي كانت معاك) ...
// عشان منكررش الكود وتتلخبط، استخدم نفس الجزء اللي فوق من الكود اللي فات

// ==============================================
// 2. الهجوم الشامل (Hooks)
// ==============================================

// 🔹 الهجوم على OverlayManager
%hook OverlayManager
- (void)drawLoginWindow:(id)arg1 { if (isVerified) [self drawMenuWindow]; } // تخطي النافذة
- (BOOL)isLogin { return YES; }
- (BOOL)isVip { return YES; }
- (BOOL)isActivated { return YES; }
- (BOOL)hasKey { return YES; }
%end

// 🔹 الهجوم على MenuManager (لو موجود)
%hook MenuManager
- (void)drawLoginWindow:(id)arg1 { if (isVerified) [self drawMenuWindow]; }
- (void)performLogin { [self drawMenuWindow]; } // كسر زرار الدخول
- (BOOL)isLogin { return YES; }
- (BOOL)isVip { return YES; }
- (BOOL)isActivated { return YES; }
- (BOOL)hasKey { return YES; }
%end

// 🔹 الهجوم على Kingmod (لو موجود)
%hook Kingmod
- (BOOL)isVip { return YES; }
- (BOOL)isActivated { return YES; }
%end

// 🔹 الهجوم على PreferenceManager (غالباً بيخزنوا التفعيل هنا)
%hook PreferenceManager
- (BOOL)boolForKey:(NSString *)key {
    // لو بيسأل عن أي حاجة فيها "vip" أو "key"، قوله أيوة!
    if ([key containsString:@"vip"] || [key containsString:@"key"] || [key containsString:@"active"]) {
        return YES;
    }
    return %orig;
}
%end

// ==============================================
// 3. التشغيل
// ==============================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // showPopup(); // شغل نافذة الكود بتاعتك
    });
}
