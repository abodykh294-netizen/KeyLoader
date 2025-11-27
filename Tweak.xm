#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>

#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// ============================================================
// 1. تعريفات ومجموعات الهوك (Groups)
// ============================================================

// --- مجموعة 1: هوك المود القديم (الخطير) ---
%group WizardHooks

%hook SCLAlertViewBuilder
- (id)show { return nil; } // اقتل النافذة
- (id)alertIsReady { return nil; }
%end

%hook MenuManager
- (BOOL)isVip { return YES; }
- (BOOL)isProUser { return YES; }
- (BOOL)isLogin { return YES; }
%end

%end // نهاية المجموعة الخطيرة


// --- مجموعة 2: هوك النظام (الآمن) ---
%group SystemHooks

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

%end // نهاية المجموعة الآمنة


// ============================================================
// 2. دوال السيرفر والنافذة (بتاعتك)
// ============================================================

NSString* getDeviceID() {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

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

        UIAlertAction *act = [UIAlertAction actionWithTitle:@"Login" style:(UIAlertActionStyle)0 handler:^(UIAlertAction *action) {
            checkKey(alert.textFields.firstObject.text, ^(BOOL success, NSString *msg) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[NSUserDefaults standardUserDefaults] setObject:alert.textFields[0].text forKey:@"SavedKey"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        isVerified = YES;
                        
                        UIAlertController *s = [UIAlertController alertControllerWithTitle:@"✅ Success" message:nil preferredStyle:1];
                        [s addAction:[UIAlertAction actionWithTitle:@"Start" style:0 handler:nil]];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:s animated:YES completion:nil];
                    } else {
                        showPopup();
                    }
                });
            });
        }];
        [alert addAction:act];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ============================================================
// 3. التشغيل الذكي (Smart Initialization)
// ============================================================
%ctor {
    // 1. شغل الهوكات الآمنة (النظام) فوراً
    %init(SystemHooks);

    // 2. انتظر ثانية واحدة حتى يتم تحميل المود القديم، ثم شغل الهوكات الخطيرة
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // التحقق من وجود الكلاس قبل الهجوم عليه (لمنع الكراش)
        if (objc_getClass("SCLAlertViewBuilder")) {
            %init(WizardHooks); // شغل الهجوم فقط لو الكلاس موجود
        } else {
            NSLog(@"[KeyLoader] Warning: Old Mod class not found!");
        }
        
        // شغل نافذتك
        showPopup();
    });
}
