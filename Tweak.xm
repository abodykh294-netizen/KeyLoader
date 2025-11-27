#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>

// ============================================================
// 1. إعدادات السيرفر
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// تعريفات
@interface UIWindow (KeyLoader)
- (UIViewController *)visibleViewController;
@end

// --- دوال الاتصال ---
NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

void checkKey(NSString *key, void (^completion)(BOOL success, NSString *msg)) {
    // (نفس كود الاتصال السابق)
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
// 2. المحرك المستمر (Loop Engine) 🔥
// ============================================================

// دالة تفعيل الماستر سويتش (كتابة 1 في الذاكرة)
void force_activate_cheats() {
    // الأوفست اللي جبناه من Ghidra
    uint64_t offset = 0x1C3C690; 
    
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    uint64_t address = slide + offset;
    unsigned char value = 1;

    kern_return_t err;
    mach_port_t port = mach_task_self();
    
    // فك حماية وكتابة
    vm_protect(port, (vm_address_t)address, sizeof(value), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    vm_write(port, (vm_address_t)address, (vm_offset_t)&value, sizeof(value));
    vm_protect(port, (vm_address_t)address, sizeof(value), NO, VM_PROT_READ | VM_PROT_EXECUTE);
}

// دالة البحث عن النوافذ المزعجة وإخفائها (UI Killer)
void hide_annoying_windows() {
    // نلف على كل النوافذ المفتوحة
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        // لو النافذة مش بتاعتنا (مش KeyLoader)
        // بنبص جواها
        for (UIView *view in window.subviews) {
            // بنعمل مسح للنصوص اللي جوا الفيو
            NSString *desc = view.description;
            // أو ندور على Labels
            for (UIView *sub in view.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    NSString *text = ((UILabel *)sub).text;
                    // لو لقينا كلمة Key أو Login أو Expired
                    if ([text containsString:@"Enter Key"] || 
                        [text containsString:@"Login"] ||
                        [text containsString:@"Contact"] ||
                        [text containsString:@"Expired"]) {
                        
                        // 🛑 اخفي النافذة دي فوراً
                        window.hidden = YES;
                        // أو view.hidden = YES;
                    }
                }
            }
        }
    }
}

// ============================================================
// 3. النافذة الخاصة بك
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
                        
                        // 🔥 تشغيل التايمر المستمر (كل ثانية)
                        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                            force_activate_cheats(); // فعل الهاك
                            hide_annoying_windows(); // اخفي النوافذ القديمة
                        }];
                        
                        UIAlertController *s = [UIAlertController alertControllerWithTitle:@"✅ Active" message:nil preferredStyle:1];
                        [s addAction:[UIAlertAction actionWithTitle:@"GO" style:0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:s animated:YES completion:nil];
                    } else {
                        showPopup();
                    }
                });
            });
        }];

        [alert addAction:verifyAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ============================================================
// 4. التشغيل
// ============================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showPopup();
    });
}
