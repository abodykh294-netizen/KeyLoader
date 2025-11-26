#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ====================================================
// 1. نظام اللودر الخاص بك (KeyLoader)
// ====================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// (نفس دوال السيرفر والنافذة بتاعتك اللي فاتت بالظبط..)
// ... اختصاراً للمساحة، حط هنا كود getDeviceID و checkKey و showPopup ...
// ... لو مش معاك قولي ابعتهولك كامل تاني ...

// ====================================================
// 2. الهجوم الشامل (Blind Hooking) - ده الجديد والمهم
// ====================================================

// ----------------------------------------------------
// أ. الهجوم على مدير القائمة (MenuManager)
// ----------------------------------------------------
%hook MenuManager

// 1. الرد على أي سؤال تفعيل بـ "نعم"
- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }
- (BOOL)isActivated { return YES; }
- (BOOL)hasKey { return YES; }
- (BOOL)checkKey:(id)arg1 { return YES; }
- (BOOL)isPremium { return YES; }

// 2. كسر زرار الدخول (عشان لو دوست عليه بالغلط ميعملش حاجة)
- (void)performLogin {
    // بدال ما يعمل دخول، نخليه يفتح القائمة أو ميعملش حاجة
}

// 3. إلغاء نافذة الدخول القديمة
- (void)drawLoginWindow:(id)arg1 {
    if (isVerified) {
        // لو عديت من اللودر بتاعك، ارسم القائمة علطول
        // (جربنا self وجربنا MSHookIvar، هنجرب ننادي الدالة مباشرة لو نعرفها)
        // أو نسيبها فاضية فالنافذة متظهرش
    }
}

%end

// ----------------------------------------------------
// ب. الهجوم على مدير الرسم (OverlayManager)
// ----------------------------------------------------
%hook OverlayManager

- (BOOL)isVip { return YES; }
- (BOOL)isLogin { return YES; }

- (void)drawLoginWindow:(id)arg1 {
    // منع رسم نافذة الدخول هنا كمان
}

%end

// ----------------------------------------------------
// ج. الهجوم على مخزن الإعدادات (UserDefaults) - دي قوية جداً
// ----------------------------------------------------
%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    // أي مفتاح فيه كلمة VIP أو Key أو Active هنرجعه True
    if ([key containsString:@"vip"] || [key containsString:@"Vip"] || 
        [key containsString:@"key"] || [key containsString:@"Key"] || 
        [key containsString:@"active"] || [key containsString:@"login"]) {
        return YES;
    }
    return %orig; // رجع القيمة الأصلية للباقي
}

- (id)objectForKey:(NSString *)key {
    // لو بيسأل عن التوكن أو الكود، نرجعله أي كلام وهمي
    if ([key containsString:@"token"] || [key containsString:@"key"]) {
        return @"ValidToken123";
    }
    return %orig;
}

%end

// ====================================================
// 3. التشغيل
// ====================================================
%ctor {
    // تشغيل اللودر بتاعك بعد 5 ثواني
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // showPopup(); // (فعل السطر ده لما تحط كود النافذة فوق)
    });
}
