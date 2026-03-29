#import <UIKit/UIKit.h>

// Lưu thông tin bản quyền
void saveInfo(NSString *key, long long ts) {
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"Saved_Key"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ts] forKey:@"Lic_TS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Xóa thông tin (khi bị khóa)
void clearInfo() {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Saved_Key"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Lic_TS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

void alert(NSString *t, NSString *m, UIViewController *r, BOOL ex) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *a = [UIAlertController alertControllerWithTitle:t message:m preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:^(id x){ if(ex) exit(0); }]];
        [r presentViewController:a animated:YES completion:nil];
    });
}

// Hàm kiểm tra với Server
void checkKey(NSString *k, UIViewController *r) {
    NSString *u = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // !!! THAY LINK WEB APP CỦA BẠN VÀO ĐÂY !!!
    NSString *link = @"https://script.google.com/macros/s/AKfycbw9lgy1biItSSko9wEfk5cqvrZbzz7Omwz279RVG-qOsgrM4t5AQLCjsWZn6WfQpUxuPg/exec";
    
    NSString *path = [NSString stringWithFormat:@"%@?key=%@&udid=%@", link, k, u];
    NSURL *url = [NSURL URLWithString:[path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *res, NSError *e) {
        if (!d) return;
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if ([j[@"status"] isEqualToString:@"ok"]) {
            saveInfo(k, [j[@"expiry"] longLongValue]);
            alert(@"XÁC THỰC", j[@"msg"], r, NO);
        } else {
            clearInfo(); // Xóa key nếu server báo lỗi/khóa
            alert(@"LỖI", j[@"msg"], r, YES);
        }
    }] resume];
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* s in [UIApplication sharedApplication].connectedScenes) {
                if (s.activationState == UISceneActivationStateForegroundActive) {
                    win = s.windows.firstObject; break;
                }
            }
        } else { win = [UIApplication sharedApplication].keyWindow; }
        
        UIViewController *root = win.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;

        NSString *sk = [[NSUserDefaults standardUserDefaults] stringForKey:@"Saved_Key"];

        if (sk && sk.length > 0) {
            // Luôn kiểm tra server mỗi khi mở app
            checkKey(sk, root);
        } else {
            UIAlertController *i = [UIAlertController alertControllerWithTitle:@"BẢN QUYỀN" message:@"Nhập mã để kích hoạt" preferredStyle:UIAlertControllerStyleAlert];
            [i addTextFieldWithConfigurationHandler:^(UITextField *t){ t.placeholder = @"Nhập Key..."; }];
            [i addAction:[UIAlertAction actionWithTitle:@"KÍCH HOẠT" style:UIAlertActionStyleDefault handler:^(id x){
                NSString *v = i.textFields.firstObject.text;
                if (v.length > 0) checkKey(v, root); else exit(0);
            }]];
            [root presentViewController:i animated:YES completion:nil];
        }
    });
}
