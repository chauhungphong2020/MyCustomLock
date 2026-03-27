#import <UIKit/UIKit.h>

void checkLicense(NSString *userKey) {
    // Lấy ID máy duy nhất
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // Đường dẫn đến Server Google Sheets của bạn
    NSString *server = [NSString stringWithFormat:@"https://script.google.com/macros/s/AKfycbykXu0eesXx8WdPwPnOQrIM7qZSYmcoz16rtH5stDJNuEv8Nn7YXQgEGMCRRfEbZh503w/exec?key=%@&udid=%@", userKey, deviceId];
    
    NSURL *url = [NSURL URLWithString:server];
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"status"] isEqualToString:@"success"]) {
                return; // Khớp Key và Máy -> Cho phép dùng
            }
        }
        // Sai Key hoặc bị khóa -> Thoát App ngay
        dispatch_async(dispatch_get_main_queue(), ^{ exit(0); });
    }] resume];
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"HỆ THỐNG BẢO MẬT" 
            message:@"Mỗi máy chỉ dùng được 1 Key duy nhất." 
            preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = @"Nhập Key của bạn...";
            tf.secureTextEntry = YES;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"KÍCH HOẠT" style:UIAlertActionStyleDefault handler:^(id act) {
            checkLicense(alert.textFields.firstObject.text);
        }]];

        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
