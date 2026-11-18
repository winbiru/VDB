#import <Cocoa/Cocoa.h>

static void showResult(NSString *title, NSString *message, BOOL success) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = success ? NSAlertStyleInformational : NSAlertStyleCritical;
    [alert addButtonWithTitle:@"Đóng"];
    [alert runModal];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSBundle *bundle = NSBundle.mainBundle;
        BOOL update = [bundle.infoDictionary[@"VDBUpdate"] boolValue];
        NSString *title = update ? @"VDB Update" : @"VDB Setup";
        NSString *parent = bundle.bundlePath.stringByResolvingSymlinksInPath.stringByDeletingLastPathComponent;
        NSString *script = [parent stringByAppendingPathComponent:update ? @"vdb-setup" : @"install.sh"];
        if (argc == 2 && strcmp(argv[1], "--check") == 0) {
            return [NSFileManager.defaultManager isExecutableFileAtPath:script] ? 0 : 1;
        }

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];

        NSAlert *confirm = [[NSAlert alloc] init];
        confirm.messageText = update ? @"Kiểm tra và cập nhật VDB" : @"Cài đặt VDB Studio";
        confirm.informativeText = update
            ? @"Tải bản ổn định mới hơn từ GitHub Releases, xác minh SHA-256 rồi cài đặt. Hãy đóng VDB Studio trước khi tiếp tục. Dữ liệu được giữ nguyên."
            : @"Cài VDB Studio và CLI cho tài khoản hiện tại, không cần quyền quản trị. Hãy đóng VDB Studio nếu đang mở. Dữ liệu được giữ nguyên.";
        [confirm addButtonWithTitle:update ? @"Kiểm tra và cập nhật" : @"Cài đặt"];
        [confirm addButtonWithTitle:@"Hủy"];
        if ([confirm runModal] != NSAlertFirstButtonReturn) return 0;

        NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 440, 140)
            styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
        panel.title = title;
        NSTextField *label = [NSTextField labelWithString:update ? @"Đang kiểm tra, tải và xác minh bản cập nhật…" : @"Đang kiểm tra và cài đặt VDB…"];
        label.frame = NSMakeRect(24, 86, 392, 24);
        [panel.contentView addSubview:label];
        NSProgressIndicator *progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24, 49, 392, 20)];
        progress.indeterminate = YES;
        progress.style = NSProgressIndicatorStyleBar;
        [panel.contentView addSubview:progress];
        [progress startAnimation:nil];
        [panel center];
        [panel makeKeyAndOrderFront:nil];

        __block NSString *result = @"";
        __block BOOL success = NO;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            @autoreleasepool {
                NSTask *task = [[NSTask alloc] init];
                task.executableURL = [NSURL fileURLWithPath:script];
                task.arguments = update ? @[@"update", @"--yes"] : @[@"--yes"];
                NSMutableDictionary *environment = [NSProcessInfo.processInfo.environment mutableCopy];
                environment[@"PATH"] = @"/usr/bin:/bin:/usr/sbin:/sbin";
                task.environment = environment;
                NSPipe *pipe = [NSPipe pipe];
                task.standardOutput = pipe;
                task.standardError = pipe;
                NSError *error = nil;
                if ([task launchAndReturnError:&error]) {
                    NSData *output = [pipe.fileHandleForReading readDataToEndOfFile];
                    [task waitUntilExit];
                    result = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] ?: @"Không đọc được kết quả.";
                    success = task.terminationStatus == 0;
                } else {
                    result = error.localizedDescription;
                }
                dispatch_async(dispatch_get_main_queue(), ^{ [NSApp stopModal]; });
            }
        });
        [NSApp runModalForWindow:panel];
        [panel orderOut:nil];
        showResult(success ? @"Hoàn tất" : @"Thao tác thất bại", result, success);
        return success ? 0 : 1;
    }
}
