#import <UIKit/UIKit.h>

// Hàm lưu ngày hết hạn vào máy (Sửa lỗi setLong)
void setLocalInfo(long long ts) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ts] forKey:@"App_License_Expiry"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Kiểm tra xem máy đã có Key hợp lệ chưa (Sửa lỗi longForKey)
BOOL isLicenseValid() {
    NSNumber *savedTs = [[NSUserDefaults standardUserDefaults] objectForKey:@"App_License_Expiry"];
    if (!savedTs) return NO;
    return [[NSDate date] timeIntervalSince1970] < [savedTs longLongValue];
}

// Hiện thông báo
void showMsg(NSString *title, NSString *content, UIViewController *root, BOOL exitApp) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(id action) {
            if (exitApp) exit(0);
        }]];
        [root presentViewController:alert animated:YES completion:nil];
    });
}

// Gửi dữ liệu lên Google Sheets
void verifyWithServer(NSString *userKey, UIViewController *root) {
    NSString *udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // !!! DÁN LINK WEB APP CỦA BẠN VÀO DÒNG DƯỚI ĐÂY !!!
    NSString *myLink = @"https://script.google.com/macros/s/AKfycbwVt1Lr5YApd_AfcnklPc7z3_QYWdE8zo-zx-rePcVx6NqZtIszi6HfxJ7nEZcOWG77wg/exec";
    
    NSString *urlPath = [NSString stringWithFormat:@"%@?key=%@&udid=%@", myLink, userKey, udid];
    NSURL *url = [NSURL URLWithString:[urlPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (!data || err) {
            showMsg(@"LỖI", @"Không thể kết nối máy chủ!", root, NO);
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json[@"status"] isEqualToString:@"ok"]) {
            setLocalInfo([json[@"expiry"] longLongValue]);
            showMsg(@"THÀNH CÔNG", json[@"msg"], root, NO);
        } else {
            showMsg(@"THẤT BẠI", json[@"msg"], root, YES);
        }
    }] resume];
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // Nếu còn hạn thì cho qua luôn
        if (isLicenseValid()) return;

        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        UIViewController *root = window.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;

        UIAlertController *input = [UIAlertController alertControllerWithTitle:@"XÁC THỰC" message:@"Vui lòng nhập mã kích hoạt" preferredStyle:UIAlertControllerStyleAlert];
        [input addTextFieldWithConfigurationHandler:^(UITextField *tf) { 
            tf.placeholder = @"Nhập Key..."; 
        }];
        
        [input addAction:[UIAlertAction actionWithTitle:@"KÍCH HOẠT" style:UIAlertActionStyleDefault handler:^(id action) {
            NSString *enteredKey = input.textFields.firstObject.text;
            if (enteredKey.length > 0) {
                verifyWithServer(enteredKey, root);
            } else {
                exit(0);
            }
        }]];
        
        [root presentViewController:input animated:YES completion:nil];
    });
}
