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

// تعريفات
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
// 2. محرك الغش (Guideline Prediction Engine) 🎱
// ============================================================

// دالة البحث عن النمط (Pattern Scanning)
// تبحث عن الرقم 3.0 (طول الخط الأصلي) وتغيره لـ 50.0
void enable_prediction() {
    // 1. تحديد مساحة البحث (نص الكود في الذاكرة)
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(0);
    uint64_t startAddr = (uint64_t)header;
    uint64_t endAddr = startAddr + 0x4000000; // بحث في أول 64 ميجا (كافية)

    // 2. الأكواد السحرية (ARM64 Hex)
    // FMOV S0, #3.0  => 00 10 28 1E
    // FMOV S0, #50.0 => 00 00 48 42 (قيمة تقريبية) أو نستخدم MOVK لتغيير السجل
    
    // للتبسيط والقوة: سنبحث عن القيمة 3.0 كـ Float ونغيرها
    // Float 3.0 = 0x40400000
    unsigned int originalValue = 0x40400000; 
    unsigned int newValue = 0x42480000; // Float 50.0

    int patchCount = 0;
    kern_return_t err;
    mach_port_t port = mach_task_self();

    for (uint64_t addr = startAddr; addr < endAddr; addr += 4) {
        unsigned int currentHex = *(unsigned int *)addr;
        
        // إذا وجدنا كود يمثل 3.0
        if (currentHex == originalValue) {
            // نتأكد أنه ليس في منطقة النظام (اختياري)
            
            // 3. التعديل (Patch)
            err = vm_protect(port, (vm_address_t)addr, sizeof(newValue), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            if (err == KERN_SUCCESS) {
                vm_write(port, (vm_address_t)addr, (vm_offset_t)&newValue, sizeof(newValue));
                vm_protect(port, (vm_address_t)addr, sizeof(newValue), NO, VM_PROT_READ | VM_PROT_EXECUTE);
                patchCount++;
            }
        }
    }
    
    // تفعيل إضافي: محاولة Hook كلاسات معروفة إذا وجدت (بدون كراش)
    if (objc_getClass("GameWorld")) {
        // سنقوم بتفعيل الهوك الديناميكي هنا لاحقاً إذا لزم الأمر
    }
}

// ============================================================
// 3. النافذة والقائمة
// ============================================================

void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 Security"
                                                                       message:@"Enter Key"
                                                                preferredStyle:(UIAlertControllerStyle)1]; 

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Key";
            textField.textAlignment = 1;
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
                        
                        // 🔥 تشغيل الهاك فوراً بعد النجاح
                        enable_prediction(); 
                        
                        UIAlertController *sAlert = [UIAlertController alertControllerWithTitle:@"✅ Active" message:@"Prediction Enabled!" preferredStyle:(UIAlertControllerStyle)1];
                        [sAlert addAction:[UIAlertAction actionWithTitle:@"Play" style:(UIAlertActionStyle)0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:sAlert animated:YES completion:nil];
                    } else {
                        showPopup();
                    }
                });
            });
        }];

        [alert addAction:loginAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ============================================================
// 4. Hooks الحماية ومنع الكراش (أساسية)
// ============================================================

%hook UIAlertController
+ (id)alertControllerWithTitle:(id)title message:(id)message preferredStyle:(NSInteger)preferredStyle {
    if ([title containsString:@"License"] || [title containsString:@"Update"] || [title containsString:@"Key"]) {
        return nil; 
    }
    return %orig;
}
%end

%hook NSUserDefaults
- (BOOL)boolForKey:(NSString *)key {
    if ([key.lowercaseString containsString:@"vip"] || [key.lowercaseString containsString:@"active"]) {
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
