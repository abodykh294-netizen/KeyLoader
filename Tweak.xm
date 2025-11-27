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
// 2. دالة تفعيل الهاك (Master Switch Patch) 💉
// ============================================================
void enable_cheats() {
    // 1. الأوفست اللي حسبناه من Ghidra (0x1c3c688 + 8)
    uint64_t offset = 0x1C3C690; 

    // 2. حساب المكان الحقيقي
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    uint64_t address = slide + offset;

    // 3. القيمة (1 = مفعل / VIP)
    unsigned char value = 1;

    // 4. الحقن في الذاكرة
    kern_return_t err;
    mach_port_t port = mach_task_self();
    
    // فك الحماية
    err = vm_protect(port, (vm_address_t)address, sizeof(value), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (err != KERN_SUCCESS) {
        NSLog(@"[TakeCare] Failed to unprotect!");
        return;
    }

    // كتابة التفعيل
    err = vm_write(port, (vm_address_t)address, (vm_offset_t)&value, sizeof(value));
    
    // إرجاع الحماية
    vm_protect(port, (vm_address_t)address, sizeof(value), NO, VM_PROT_READ | VM_PROT_EXECUTE);
    
    NSLog(@"[TakeCare] HACK ACTIVATED! 🔓🔥");
}

// ============================================================
// 3. نافذة الدخول (Popup)
// ============================================================
void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 PUBG Mod"
                                                                       message:@"Enter Key"
                                                                preferredStyle:(UIAlertControllerStyle)1]; 

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Key...";
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
                        
                        // 🔥🔥 هنا اللحظة الحاسمة: تشغيل الهاك بعد قبول الكود
                        enable_cheats(); 
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ Success" message:msg preferredStyle:(UIAlertControllerStyle)1];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"GO" style:(UIAlertActionStyle)0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        // إعادة المحاولة
                        showPopup();
                    }
                });
            });
        }];

        [alert addAction:verifyAction];
        
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) topController = topController.presentedViewController;
        [topController presentViewController:alert animated:YES completion:nil];
    });
}

// ============================================================
// 4. هوكات مساعدة (Anti-Crash & Fake VIP)
// ============================================================

// نقتل نافذة التحذير القديمة لو ظهرت
%hook UIAlertController
+ (id)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(NSInteger)preferredStyle {
    if ([title containsString:@"License"] || 
        [title containsString:@"Key"] ||
        [message containsString:@"expired"]) {
        return nil; 
    }
    return %orig;
}
%end

// نخدع الذاكرة كاحتياطي
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
