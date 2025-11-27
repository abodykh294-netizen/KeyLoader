#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// ============================================================
// 1. إعدادات السيرفر (KeyLoader)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// متغيرات التفعيل
bool isLongLineActive = false;
bool isNoTrackActive = false;

// تعريفات مساعدة
@interface UIWindow (TakeCare)
- (UIViewController *)visibleViewController;
@end

// ------------------------------------------------------------
// دوال الاتصال بالسيرفر
// ------------------------------------------------------------
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

// ------------------------------------------------------------
// القائمة (Menu UI)
// ------------------------------------------------------------
void showMenu() {
    if (!isVerified) return; // لن تفتح إلا لو مفعل

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🎱 TakeCare Mod"
                                                                  message:@"Select Features:"
                                                           preferredStyle:(UIAlertControllerStyle)0]; // ActionSheet

    // زرار الخط الطويل
    NSString *lineTitle = isLongLineActive ? @"[ON] Long Line ✅" : @"[OFF] Long Line";
    [menu addAction:[UIAlertAction actionWithTitle:lineTitle style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
        isLongLineActive = !isLongLineActive;
        showMenu();
    }]];

    // زرار الحماية (مثال)
    NSString *trackTitle = isNoTrackActive ? @"[ON] Anti-Track ✅" : @"[OFF] Anti-Track";
    [menu addAction:[UIAlertAction actionWithTitle:trackTitle style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
        isNoTrackActive = !isNoTrackActive;
        showMenu();
    }]];

    [menu addAction:[UIAlertAction actionWithTitle:@"Close" style:(UIAlertActionStyle)1 handler:nil]]; // Cancel

    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:menu animated:YES completion:nil];
}

void showLoginPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 TakeCare Login"
                                                                       message:@"Enter Key"
                                                                preferredStyle:(UIAlertControllerStyle)1]; // Alert

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Key...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"];
        }];

        UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"Login" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ Success" message:msg preferredStyle:(UIAlertControllerStyle)1];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"Start" style:(UIAlertActionStyle)0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        showLoginPopup();
                    }
                });
            });
        }];

        [alert addAction:loginAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ============================================================
// 2. الهجوم على اللعبة الأصلية (Blind Hooking)
// ============================================================

// سنحاول عمل Hook على أشهر كلاسات اللعبة (GameWorld / Cue)
// إذا كان الاسم صحيحاً، سيعمل الخط الطويل. إذا تغير، لن يحدث كراش.

// محاولة 1: كلاس العصا (Cue)
%hook Cue
- (float)guidelineLength {
    if (isLongLineActive) return 100.0f; // تفعيل
    return %orig; // الوضع الطبيعي
}
%end

// محاولة 2: كلاس العالم (GameWorld)
%hook GameWorld
- (bool)hasGuideline {
    if (isLongLineActive) return YES;
    return %orig;
}
- (float)getGuidelineLength {
    if (isLongLineActive) return 100.0f;
    return %orig;
}
%end

// ============================================================
// 3. الحماية من الباند (Anti-Ban)
// ============================================================
// إيقاف مكتبات التتبع المعروفة

%hook AppsFlyerLib
- (void)start { return; } // نمنعها من البدء
%end

%hook FIRAnalytics
+ (void)logEventWithName:(id)name parameters:(id)parameters { return; }
%end

// ============================================================
// 4. فتح القائمة (Gesture)
// ============================================================
%hook UIView
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    // فتح القائمة بـ 3 أصابع
    if ([[event allTouches] count] == 3) {
        showMenu();
    }
}
%end

// ============================================================
// 5. التشغيل
// ============================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showLoginPopup();
    });
}
