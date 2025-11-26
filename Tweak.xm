#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

// 1. تعريف الكلاس (يجب أن يكون الاسم صحيحاً تماماً)
@interface SCLAlertView : NSObject
// نعلن عن الدالة الأساسية للعرض لكي نتمكن من اعتراضها
// هذا هو التوقيع الأكثر شيوعاً
- (instancetype)showTitle:(id)title subTitle:(id)subTitle closeButtonTitle:(id)closeButtonTitle duration:(NSTimeInterval)duration;
@end

// 2. الهجوم على SCLAlertView
%hook SCLAlertView

// سنقوم باعتراض دالة العرض ونمنعها من الظهور
- (instancetype)showTitle:(id)title subTitle:(id)subTitle closeButtonTitle:(id)closeButtonTitle duration:(NSTimeInterval)duration {
    // نمنع عرض الرسالة ونرجع nil (لا شيء)
    return nil;
}

%end

// 3. نقطة البداية (لتجنب الـ crash)
%ctor {
    // لا يوجد كود هنا، فقط الـ Hook
}
