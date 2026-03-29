#import <UIKit/UIKit.h>

void setLocalExp(long long ts) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ts] forKey:@"Lic_TS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

BOOL isStillValid() {
    NSNumber *ts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Lic_TS"];
    if (!ts) return NO;
    return [[NSDate date] timeIntervalSince1970] < [ts longLongValue];
}

void showPopup(NSString *title, NSString *msg, UIViewController *root, BOOL exitApp) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(id x) { if(exitApp) exit(0); }]];
        [root presentViewController:alert animated:YES completion:nil];
    });
}

void checkWithServer(NSString *k, UIViewController *r) {
    NSString *u = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    // DÁN LINK WEB APP CỦA BẠN VÀO ĐÂY
    NSString *link = @"https://script.google.com/macros/s/AKfycbxx2fRuDqBf05hlKSKQZaOIVEyZ1qU6RTr6YrIaF4DN1-78MgIZaV237tG0V64_NsIhPg/exec";
    
    NSString *urlStr = [NSString stringWithFormat:@"%@?key=%@&udid=%@", link, k, u];
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *res, NSError *e) {
        if (!d) return;
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if ([j[@"status"] isEqualToString:@"ok"]) {
            setLocalExp([j[@"expiry"] longLongValue]);
            showPopup(@"XÁC THỰC", j[@"msg"], r, NO);
        } else {
            showPopup(@"THẤT BẠI", j[@"msg"], r, YES);
        }
    }] resume];
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (isStillValid()) return;

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

        UIAlertController *input = [UIAlertController alertControllerWithTitle:@"BẢN QUYỀN" message:@"Nhập Key để sử dụng ứng dụng" preferredStyle:UIAlertControllerStyleAlert];
        [input addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Nhập Key tại đây..."; }];
        [input addAction:[UIAlertAction actionWithTitle:@"KÍCH HOẠT" style:UIAlertActionStyleDefault handler:^(id x) {
            NSString *val = input.textFields.firstObject.text;
            if (val.length > 0) checkWithServer(val, root); else exit(0);
        }]];
        [root presentViewController:input animated:YES completion:nil];
    });
}
