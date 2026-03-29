#import <UIKit/UIKit.h>

void setLocalExp(long long ts) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ts] forKey:@"Key_Exp_TS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

BOOL isValid() {
    NSNumber *ts = [[NSUserDefaults standardUserDefaults] objectForKey:@"Key_Exp_TS"];
    if (!ts) return NO;
    return [[NSDate date] timeIntervalSince1970] < [ts longLongValue];
}

void showA(NSString *t, NSString *m, UIViewController *r, BOOL ex) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:t message:m preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(id x){ if(ex) exit(0); }]];
        [r presentViewController:alert animated:YES completion:nil];
    });
}

void callS(NSString *k, UIViewController *r) {
    NSString *u = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    // DÁN LINK WEB APP CỦA BẠN VÀO ĐÂY
    NSString *link = @"https://script.google.com/macros/s/AKfycby0ntqj-Y7UCqbCWMKWdbg5R8pWYSRrf3QyfJJgQSYtqsOxj9KfroAZyPJQ-DyhsdkTDQ/exec";
    
    NSString *urlPath = [NSString stringWithFormat:@"%@?key=%@&udid=%@", link, k, u];
    NSURL *url = [NSURL URLWithString:[urlPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *res, NSError *e) {
        if (!d) return;
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if ([j[@"status"] isEqualToString:@"ok"]) {
            setLocalExp([j[@"expiry"] longLongValue]);
            showA(@"THÔNG BÁO", j[@"msg"], r, NO);
        } else {
            showA(@"LỖI", j[@"msg"], r, YES);
        }
    }] resume];
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (isValid()) return;

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

        UIAlertController *input = [UIAlertController alertControllerWithTitle:@"BẢN QUYỀN" message:@"Nhập mã để kích hoạt ứng dụng" preferredStyle:UIAlertControllerStyleAlert];
        [input addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Mã Key..."; }];
        [input addAction:[UIAlertAction actionWithTitle:@"XÁC NHẬN" style:UIAlertActionStyleDefault handler:^(id x) {
            NSString *val = input.textFields.firstObject.text;
            if (val.length > 0) callS(val, root); else exit(0);
        }]];
        [root presentViewController:input animated:YES completion:nil];
    });
}
