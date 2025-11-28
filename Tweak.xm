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
bool isLongLine = false;

@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    NSString *hwid = getDeviceID();
    NSString *urlString = [NSString stringWithFormat:@"%@?key=%@&hwid=%@", SERVER_URL, key, hwid];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) { completion(NO, @"Error: Check Internet"); return; }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"status"] isEqualToString:@"valid"]) { completion(YES, json[@"message"]); } 
        else { completion(NO, json[@"message"]); }
    }] resume];
}

// ============================================================
// 2. نظام المسح والتعديل التلقائي (Auto Patcher) 🧠
// ============================================================

// دالة للبحث عن كود معين وتغييره
int patch_pattern(const char* pattern, const char* mask, unsigned int newHex) {
    // الحصول على معلومات الذاكرة
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(0);
    uint64_t startAddr = (uint64_t)header;
    uint64_t endAddr = startAddr + 0x3000000; // البحث في أول 50 ميجا (كافية للكود)
    
    size_t len = strlen(mask);
    int patchedCount = 0;

    // المسح
    for (uint64_t i = startAddr; i < endAddr - len; i += 4) {
        bool found = true;
        for (size_t j = 0; j < len; j++) {
            if (mask[j] == 'x' && *(unsigned char*)(i + j) != (unsigned char)pattern[j]) {
                found = false;
                break;
            }
        }

        if (found) {
            // وجدنا الكود! نقوم بتعديله
            kern_return_t err;
            mach_port_t port = mach_task_self();
            
            err = vm_protect(port, (vm_address_t)i, sizeof(newHex), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            if (err == KERN_SUCCESS) {
                vm_write(port, (vm_address_t)i, (vm_offset_t)&newHex, sizeof(newHex));
                vm_protect(port, (vm_address_t)i, sizeof(newHex), NO, VM_PROT_READ | VM_PROT_EXECUTE);
                patchedCount++;
            }
        }
    }
    return patchedCount;
}

void toggleLongLine() {
    isLongLine = !isLongLine;
    if (isLongLine) {
        // 🟢 تفعيل: نبحث عن كود (FMOV S0, #3.0) ونحوله لـ (FMOV S0, #50.0)
        
        // البصمة (Pattern) لـ 3.0: 00 10 28 1E
        // القناع (Mask): xxxx
        // الكود الجديد (50.0): 00 00 48 42  (أو قيمة Hex Float لـ 50.0)
        // ملاحظة: 0x1E281000 هو FMOV S0, #3.0 بالهيكس المعكوس
        
        // سنقوم بمحاولة استبدال تعليمة الطول بقيمة كبيرة
        // Hex for 3.0f return: 00 10 28 1E (ARM64)
        // Hex for 100.0f: 00 50 29 1E (تقريبي لـ FMOV)
        
        // سنجرب تغيير تعليمة mov s0, 3.0 إلى mov s0, 100.0
        // Pattern: 00 10 28 1E
        int count = patch_pattern("\x00\x10\x28\x1E", "xxxx", 0x1E295000); 
        
        // إذا لم نجد 3.0، نجرب 5.0
        // Pattern for 5.0: 00 00 A0 40 (أو FMOV S0, #5.0 = 00 40 28 1E)
         if (count == 0) {
             patch_pattern("\x00\x40\x28\x1E", "xxxx", 0x1E295000);
         }
         
    } else {
        // 🔴 إيقاف: إعادة القيم الأصلية (تحتاج لإعادة تشغيل اللعبة للأمان أو تخزين العناوين)
        // للتبسيط، سنتركها مفعلة أو نطلب إعادة التشغيل
    }
}

// ============================================================
// 3. القائمة والنافذة
// ============================================================

void showMenu() {
    if (!isVerified) return;
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🎱 TakeCare Mod" message:@"Auto Features" preferredStyle:(UIAlertControllerStyle)0];
    
    NSString *state = isLongLine ? @"[ON] Long Line" : @"[OFF] Long Line";
    [menu addAction:[UIAlertAction actionWithTitle:state style:(UIAlertActionStyle)0 handler:^(UIAlertAction *act) {
        toggleLongLine();
        showMenu();
    }]];
    
    [menu addAction:[UIAlertAction actionWithTitle:@"Close" style:(UIAlertActionStyle)1 handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:menu animated:YES completion:nil];
}

void showPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isVerified) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔒 TakeCare" message:@"Enter Key" preferredStyle:(UIAlertControllerStyle)1];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Key"; tf.textAlignment = 1; tf.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedKey"]; }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Login" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *act) {
            checkKey(alert.textFields.firstObject.text, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:alert.textFields[0].text forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        UIAlertController *s = [UIAlertController alertControllerWithTitle:@"✅ Success" message:msg preferredStyle:(UIAlertControllerStyle)1];
                        [s addAction:[UIAlertAction actionWithTitle:@"Start" style:(UIAlertActionStyle)0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:s animated:YES completion:nil];
                    } else { showPopup(); }
                });
            });
        }]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

%hook UIView
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    if ([[event allTouches] count] == 3) showMenu();
}
%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
