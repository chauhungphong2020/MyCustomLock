#import <UIKit/UIKit.h>

void checkLicense(NSString *userKey) {
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // THAY LINK GOOGLE SCRIPT CỦA BẠN VÀO GIỮA HAI DẤU " "
    NSString *yourScriptUrl = @"https://script.google.com/macros/s/AKfycbykXu0eesXx8WdPwPnOQrIM7qZSYmcoz16rtH5stDJNuEv8Nn7YXQgEGMCRRfEbZh503w/exec";
    
    NSString *server = [NSString stringWithFormat:@"%@?key=%@&udid=%@", yourScriptUrl, userKey, deviceId];
    NSURL *url = [NSURL URLWithString:server];
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (json && [json[@"status"] isEqualToString:@"success"]) {
                return; 
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ exit(0); });
    }] resume];
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        // Cách lấy Window mới nhất cho iOS 13-18+
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                window = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }

        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        if (!window) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"XÁC THỰC" message:@"Vui lòng nhập Key để mở khóa ứng dụng" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { 
            tf.placeholder = @"Nhập Key tại đây..."; 
            tf.secureTextEntry = NO; 
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"KÍCH HOẠT" style:UIAlertActionStyleDefault handler:^(id act) {
            checkLicense(alert.textFields.firstObject.text);
        }]];

        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
