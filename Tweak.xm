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

// تعريفات الواجهة
@interface UIWindow (TakeCare)
- (UIViewController *)visibleViewController;
@end

// --- دوال الاتصال (نفس القديم) ---
NSString* getDeviceID() { return [[[UIDevice currentDevice] identifierForVendor] UUIDString]; }

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Check Internet"); return; }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"status"] isEqualToString:@"valid"]) {
            completion(YES, json[@"message"]);
        } else {
            completion(NO, json[@"message"]);
        }
    }] resume];
}

// ============================================================
// 2. نظام البحث التلقائي (Pattern Scanner) 🕵️‍♂️
// ============================================================

bool patch_memory(void *address, unsigned int newHex) {
    kern_return_t err;
    mach_port_t port = mach_task_self();
    
    // فك الحماية للكتابة
    err = vm_protect(port, (vm_address_t)address, sizeof(newHex), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (err != KERN_SUCCESS) return false;

    // كتابة الكود الجديد
    err = vm_write(port, (vm_address_t)address, (vm_offset_t)&newHex, sizeof(newHex));
    if (err != KERN_SUCCESS) return false;

    // إرجاع الحماية
    vm_protect(port, (vm_address_t)address, sizeof(newHex), NO, VM_PROT_READ | VM_PROT_EXECUTE);
    return true;
}

void scanAndPatch() {
    // 1. الحصول على عنوان بداية اللعبة وحجمها
    const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(0);
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    
    // (تبسيطاً للكود، سنفترض البحث في أول 50 ميجا بايت من الكود، وهذا كافٍ)
    uint64_t startAddress = (uint64_t)header + 0x1000; // تخطي الهيدر
    uint64_t endAddress = startAddress + 0x3000000; // مسح 50MB تقريباً
    
    // 2. البصمة التي نبحث عنها (3.0f)
    // Hex for "FMOV S0, #3.0" (ARM64) = 00 10 28 1E
    unsigned int targetPattern = 0x1E281000; 
    
    // 3. الكود البديل (50.0f)
    // Hex for "FMOV S0, #50.0" (Custom Hex) = 00 00 48 42 (قيمة تقريبية للحقن المباشر)
    // أو نستخدم تعليمة MOV W0, ... لتغيير القيمة
    unsigned int newPattern = 0x1E2A1000; // FMOV S0, #5.0 (أطول شوية) أو نستخدم قيمة أكبر

    int patchCount = 0;

    // 4. عملية المسح (Scanning)
    for (uint64_t addr = startAddress; addr < endAddress; addr += 4) {
        unsigned int currentHex = *(unsigned int *)addr;
        
        if (currentHex == targetPattern) {
            // لقينا الكود! نعدله
            patch_memory((void *)addr, newPattern);
            patchCount++;
        }
    }
    
    if (patchCount > 0) {
        // إظهار رسالة نجاح صغيرة (اختياري)
        /*
        UIAlertController *toast = [UIAlertController alertControllerWithTitle:@"✅ Mod Active" message:[NSString stringWithFormat:@"Patched %d locations", patchCount] preferredStyle:1];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:toast animated:YES completion:nil];
        // إغلاق بعد ثانية
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [toast dismissViewControllerAnimated:YES completion:nil];
        });
        */
    }
}

// ============================================================
// 3. القائمة والنافذة
// ============================================================

void showMenu() {
    if (!isVerified) return;
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🎱 TakeCare Mod" message:@"Features Auto-Active" preferredStyle:0];
    [menu addAction:[UIAlertAction actionWithTitle:@"Long Line: [Active]" style:0 handler:nil]];
    [menu addAction:[UIAlertAction actionWithTitle:@"Close" style:1 handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:menu animated:YES completion:nil];
}

void showLoginPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 TakeCare Login" message:@"Enter Key" preferredStyle:1];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Key"; tf.textAlignment = 1; tf.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"]; }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Login" style:0 handler:^(UIAlertAction *act) {
            checkKey(alert.textFields[0].text, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:alert.textFields[0].text forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        // 🔥 تشغيل المسح التلقائي بعد التفعيل
                        scanAndPatch(); 
                        
                        UIAlertController *s = [UIAlertController alertControllerWithTitle:@"✅ Success" message:msg preferredStyle:1];
                        [s addAction:[UIAlertAction actionWithTitle:@"Start" style:0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:s animated:YES completion:nil];
                    } else { showLoginPopup(); }
                });
            });
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Get Key" style:0 handler:^(UIAlertAction *act) {
             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/YourChannel"] options:@{} completionHandler:nil];
             showLoginPopup();
        }]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// فتح القائمة بـ 3 أصابع
%hook UIView
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    if ([[event allTouches] count] == 3) showMenu();
}
%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showLoginPopup();
    });
}
