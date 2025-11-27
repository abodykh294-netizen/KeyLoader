#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>

// ============================================================
// 1. نظام السيرفر (KeyLoader) - حمايتك الخاصة
// ============================================================
#define SERVER_URL @"https://abodykh294.pythonanywhere.com/check_key"
static BOOL isVerified = NO;

// (هنا بنحط نفس دوال checkKey و showPopup و getDeviceID اللي في الأكواد اللي فاتت)
// ... اختصاراً للمساحة، حطهم هنا ...

// ============================================================
// 2. محرك الغش (Memory Patcher)
// ============================================================
// الدالة دي هي "المفك" اللي بيربط المسمار
void patch_memory(uint64_t offset, uint32_t value) {
    uint64_t slide = _dyld_get_image_vmaddr_slide(0);
    uint64_t address = slide + offset;

    kern_return_t err;
    mach_port_t port = mach_task_self();
    
    // 1. فك الحماية
    err = vm_protect(port, (vm_address_t)address, sizeof(value), NO, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (err != KERN_SUCCESS) return;

    // 2. الكتابة
    err = vm_write(port, (vm_address_t)address, (vm_offset_t)&value, sizeof(value));
    
    // 3. قفل الحماية تاني
    err = vm_protect(port, (vm_address_t)address, sizeof(value), NO, VM_PROT_READ | VM_PROT_EXECUTE);
}

// ============================================================
// 3. التفعيلات (Features)
// ============================================================
bool isLongLine = false;

// 🔴 هنا المكان اللي هنحط فيه الرقم اللي هنجيبه
// مثال: 0x1005A20
#define OFFSET_GUIDELINE  0x0  // <-- غير الصفر ده بالرقم اللي هنجيبه

void toggleLongLine() {
    isLongLine = !isLongLine;
    if (isLongLine) {
        // تفعيل: نغير القيمة لرقم كبير (مثلاً تعليمة MOV بقيمة عالية)
        // القيمة دي (0x42480000) هي الهكس بتاع 50.0 float
        // بس ده لو بنحقن قيمة، لو بنعدل تعليمة هنحتاج كود تاني
        // الأسهل: NOP لإلغاء الحد الأقصى
        // patch_memory(OFFSET_GUIDELINE, 0xD503201F); 
    } else {
        // إيقاف: نرجع الكود الأصلي (لازم نكون عارفينه)
    }
}

// ============================================================
// 4. القائمة (Menu)
// ============================================================
void showMenu() {
    if (!isVerified) return;

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🎱 TakeCare Mod"
                                                                  message:@"Select Features"
                                                           preferredStyle:0]; // ActionSheet

    NSString *lineState = isLongLine ? @"[ON] Long Line" : @"[OFF] Long Line";
    [menu addAction:[UIAlertAction actionWithTitle:lineState style:0 handler:^(UIAlertAction *action) {
        toggleLongLine();
        showMenu();
    }]];

    [menu addAction:[UIAlertAction actionWithTitle:@"Close" style:1 handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:menu animated:YES completion:nil];
}

// فتح القائمة بـ 3 أصابع
%hook UIView
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    if ([[event allTouches] count] == 3) showMenu();
}
%end

// ============================================================
// 5. التشغيل
// ============================================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // showPopup(); // شغل دي لما تخلص
    });
}
