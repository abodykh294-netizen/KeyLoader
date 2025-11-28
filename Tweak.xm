#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>

// ============================================================
// 1. إعدادات السيرفر (KeyLoader)
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// تعريفات الكلاسات
@interface MenuManager : NSObject
- (void)drawMenuWindow;
@end

@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// --- دوال الاتصال ---
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

// ============================================================
// 2. محرك الغش (Guideline Prediction & Long Line) 🎱
// ============================================================

// دالة البحث عن النمط (Pattern Scanning)
// تبحث عن الرقم 3.0 (طول الخط الأصلي) وتغيره لـ 50.0 لتفعيل التنبؤ
void enable_prediction() {
    // 1. تحديد مساحة البحث
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(0);
    uint64_t startAddr = (uint64_t)header;
    uint64_t endAddr = startAddr + 0x4000000; // بحث في أول 64 ميجا

    // Float 3.0 = 0x40400000 (القيمة الأصلية)
    // Float 50.0 = 0x42480000 (قيمة التفعيل)
    unsigned int originalValue = 0x40400000; 
    unsigned int newValue = 0x42480000; 

    kern_return_t err;
    mach_port_t port = mach_task_self();

    // المسح والتعديل
    for (uint64_t addr = startAddr; addr < endAddr; addr += 4) {
        unsigned int currentHex = *(unsigned int *)addr;
        
        if (currentHex == originalValue) {
            // تعديل القيمة في الذاكرة
            err = vm_protect(port, (vm_address_t)addr, sizeof(newValue), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            if (err == KERN_SUCCESS) {
                vm_write(port, (vm_address_t)addr, (vm_offset_t)&newValue, sizeof(newValue));
                vm_protect(port, (vm_address_t)addr, sizeof(newValue), NO, VM_PROT_READ | VM_PROT_EXECUTE);
            }
        }
    }
}

// ============================================================
// 3. واجهة المستخدم (Popup) - مصححة الأخطاء
// ============================================================
void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

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
            
            checkKey(key, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        // 🔥 تشغيل التفعيلات فوراً بعد النجاح
                        enable_prediction(); 
                        
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

        UIAlertAction *buyAction = [UIAlertAction actionWithTitle:@"Get Key" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action){
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
// 4. الحماية ومنع الكراش (Anti-Ban & Anti-Crash)
// ============================================================

// 🛡️ Anti-Ban: تعطيل التتبع
%hook AppsFlyerLib
- (void)start { return; }
%end

%hook FIRAnalytics
+ (void)logEventWithName:(id)name parameters:(id)parameters { return; }
%end

// 🛡️ Anti-Crash: منع ظهور نافذة المود القديم
%hook UIAlertController
+ (id)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(NSInteger)preferredStyle {
    if ([title containsString:@"License"] || 
        [title containsString:@"Update"] ||
        [title containsString:@"Key"] ||
        [title containsString:@"Subscription"]) {
        return nil; 
    }
    return %orig;
}
%end

// 🛡️ Bypass Logic: إيهام اللعبة بالتفعيل
%hook MenuManager
- (BOOL)isProUser { return YES; } 
- (BOOL)isVip { return YES; } 
- (BOOL)isLogin { return YES; }
- (BOOL)isActivated { return YES; }
- (void)drawLoginWindow:(id)arg1 { } 
%end

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
// 5. التشغيل
// ============================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
