#import <UIKit/UIKit.h>

// Hàm lưu ngày hết hạn vào máy
void setLocalInfo(long long ts) {
    [[NSUserDefaults standardUserDefaults] setLong:ts forKey:@"App_License_Expiry"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Kiểm tra xem máy đã có Key hợp lệ chưa
BOOL isLicenseValid() {
    long long savedTs = [[NSUserDefaults standardUserDefaults] longForKey:@"App_License_Expiry"];
    return [[NSDate date] timeIntervalSince1970] < savedTs;
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
    
    // !!! THAY LINK WEB APP CỦA BẠN VÀO DÒNG DƯỚI ĐÂY !!!
    NSString *myLink = @"https://script.google.com/macros/s/AKfycbwVt1Lr5YApd_AfcnklPc7z3_QYWdE8zo-zx-rePcVx6NqZtIszi6HfxJ7nEZcOWG77wg/exec";
    
    NSString *fullUrl = [NSString stringWithFormat:@"%@?key=%@&udid=%@", myLink, userKey, udid];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:fullUrl] completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (!data || err) return;
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // Nếu còn hạn thì cho qua luôn
        if (isLicenseValid()) return;

        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;

        UIAlertController *input = [UIAlertController alertControllerWithTitle:@"XÁC THỰC" message:@"Vui lòng nhập mã kích hoạt" preferredStyle:UIAlertControllerStyleAlert];
        [input addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Nhập Key..."; }];
        [input addAction:[UIAlertAction actionWithTitle:@"KÍCH HOẠT" style:UIAlertActionStyleDefault handler:^(id action) {
            verifyWithServer(input.textFields.firstObject.text, root);
        }]];
        [root presentViewController:input animated:YES completion:nil];
    });
}
