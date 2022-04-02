//
//  AppDelegate.m
//  TUIKitDemo
//
//  Created by kennethmiao on 2018/10/10.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "AppDelegate.h"
#import "ConversationController.h"
#import "SettingController.h"
#import "ContactsController.h"
#import "TCConstants.h"
#import "TUIDefine.h"
#import "TUIKit.h"
#import "Aspects.h"
#import "TCUtil.h"
#import "TUILoginCache.h"
#import "TUIDarkModel.h"
#import "GenerateTestUserSig.h"
#import "TUILoginCache.h"

#if ENABLELIVE
#import "TRTCSignalFactory.h"
@import TXLiteAVSDK_TRTC;
#endif

#import "TUIBadgeView.h"
#import "AppDelegate+Push.h"
#import "ThemeSelectController.h"
#import "TUIThemeManager.h"
#import "LanguageSelectController.h"

@interface AppDelegate () <UIAlertViewDelegate, V2TIMConversationListener, V2TIMSDKListener, ThemeSelectControllerDelegate, LanguageSelectControllerDelegate>

@property (nonatomic, weak) TUIBadgeView *badgeView;

@end

static AppDelegate *app;

@implementation AppDelegate

+ (instancetype)sharedInstance {
    return app;
}

- (void)login:(NSString *)identifier userSig:(NSString *)sig succ:(TSucc)succ fail:(TFail)fail
{
    [[TUIKit sharedInstance] setupWithAppId:SDKAPPID];
    [[TUIKit sharedInstance] login:identifier userSig:sig succ:^{
        
        [self push_registerIfLogined:identifier];
        self.window.rootViewController = [app getMainController];
        
        [TUITool makeToast:NSLocalizedString(@"AppLoginSucc", nil) duration:1];
        if (succ) {
            succ();
        }
    } fail:^(int code, NSString *msg) {
        self.window.rootViewController = [self getLoginController];
        if (fail) {
            fail(code, msg);
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    app = self;

    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // 设置主题样式
    TUIRegisterThemeResourcePath([NSBundle.mainBundle pathForResource:@"TUIDemoTheme.bundle" ofType:nil], TUIThemeModuleDemo);
    [ThemeSelectController applyTheme:nil];
    
    [self push_init];
    [self setupListener];
    [self setupCustomSticker];
    [self setupGlobalUI];
    [self autoLoginIfNeeded];
    
    return YES;
}

- (void)autoLoginIfNeeded
{
    self.window.rootViewController = [self getLoginController];
    [[TUILoginCache sharedInstance] login:^(NSString * _Nonnull identifier, NSUInteger appId, NSString * _Nonnull userSig) {
        if(appId == SDKAPPID && identifier.length != 0 && userSig.length != 0){
            [self login:identifier userSig:userSig succ:nil fail:nil];
        } else {
            self.window.rootViewController = [self getLoginController];
        }
    }];
}

- (void)setupGlobalUI
{
    [UIViewController aspect_hookSelector:@selector(setTitle:)
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo, NSString *title) {
        UIViewController *vc = aspectInfo.instance;
        vc.navigationItem.titleView = ({
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            titleLabel.text = title;
            titleLabel;
        });
        vc.navigationItem.title = @"";
    } error:NULL];
}

- (void)setupCustomSticker
{
    NSMutableArray *faceGroups = [NSMutableArray arrayWithArray:TUIConfig.defaultConfig.faceGroups];
    
    //4350 group
    NSMutableArray *faces4350 = [NSMutableArray array];
    for (int i = 0; i <= 17; i++) {
        TUIFaceCellData *data = [[TUIFaceCellData alloc] init];
        NSString *name = [NSString stringWithFormat:@"yz%02d", i];
        NSString *path = [NSString stringWithFormat:@"4350/%@", name];
        data.name = name;
        data.path = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:path];
        [faces4350 addObject:data];
    }
    if(faces4350.count != 0){
        TUIFaceGroup *group4350 = [[TUIFaceGroup alloc] init];
        group4350.groupIndex = 1;
        group4350.groupPath = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:@"4350/"]; //TUIChatFaceImagePath(@"4350/");
        group4350.faces = faces4350;
        group4350.rowCount = 2;
        group4350.itemCountPerRow = 5;
        group4350.menuPath = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:@"4350/menu"]; // TUIChatFaceImagePath(@"4350/menu");
        [faceGroups addObject:group4350];
    }
    
    //4351 group
    NSMutableArray *faces4351 = [NSMutableArray array];
    for (int i = 0; i <= 15; i++) {
        TUIFaceCellData *data = [[TUIFaceCellData alloc] init];
        NSString *name = [NSString stringWithFormat:@"ys%02d", i];
        NSString *path = [NSString stringWithFormat:@"4351/%@", name];
        data.name = name;
        data.path = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:path]; // TUIChatFaceImagePath(path);
        [faces4351 addObject:data];
    }
    if(faces4351.count != 0){
        TUIFaceGroup *group4351 = [[TUIFaceGroup alloc] init];
        group4351.groupIndex = 2;
        group4351.groupPath = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:@"4351/"]; // TUIChatFaceImagePath(@"4351/");
        group4351.faces = faces4351;
        group4351.rowCount = 2;
        group4351.itemCountPerRow = 5;
        group4351.menuPath = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:@"4351/menu"]; //TUIChatFaceImagePath(@"4351/menu");
        [faceGroups addObject:group4351];
    }
    
    //4352 group
    NSMutableArray *faces4352 = [NSMutableArray array];
    for (int i = 0; i <= 16; i++) {
        TUIFaceCellData *data = [[TUIFaceCellData alloc] init];
        NSString *name = [NSString stringWithFormat:@"gcs%02d", i];
        NSString *path = [NSString stringWithFormat:@"4352/%@", name];
        data.name = name;
        data.path = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:path]; // TUIChatFaceImagePath(path);
        [faces4352 addObject:data];
    }
    if(faces4352.count != 0){
        TUIFaceGroup *group4352 = [[TUIFaceGroup alloc] init];
        group4352.groupIndex = 3;
        group4352.groupPath = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:@"4352/"]; //TUIChatFaceImagePath(@"4352/");
        group4352.faces = faces4352;
        group4352.rowCount = 2;
        group4352.itemCountPerRow = 5;
        group4352.menuPath = [[[NSBundle mainBundle] pathForResource:@"CustomFaceResource" ofType:@"bundle"] stringByAppendingPathComponent:@"4352/menu"]; // TUIChatFaceImagePath(@"4352/menu");
        [faceGroups addObject:group4352];
    }
    
    TUIConfig.defaultConfig.faceGroups = faceGroups;
}


- (void)handleVCLeak:(UIViewController *)vc oprSeq:(NSString *)seq stackInfo:(NSString *)stack {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"发现内存泄露:%@",vc] message:seq preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self.window.rootViewController presentViewController:ac animated:YES completion:nil];
}

- (void)handleUIViewLeak:(UIView *)view detail:(NSString *)detail hierarchyInfo:(NSString *)hierarchy stackInfo:(NSString *)stack {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"发现内存泄露:%@",view] message:hierarchy preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self.window.rootViewController presentViewController:ac animated:YES completion:nil];
}

- (void)setupListener
{
    [[V2TIMManager sharedInstance] addIMSDKListener:self];
    [[V2TIMManager sharedInstance] addConversationListener:self];
}

void uncaughtExceptionHandler(NSException*exception){
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@",[exception callStackSymbols]);
    // Internal error reporting
}

- (UIViewController *)getLoginController{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    LoginController *login = [board instantiateViewControllerWithIdentifier:@"LoginController"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
    return nav;
}

- (UITabBarController *)getMainController{
    TUITabBarController *tbc = [[TUITabBarController alloc] init];
    NSMutableArray *items = [NSMutableArray array];
    TUITabBarItem *msgItem = [[TUITabBarItem alloc] init];
    msgItem.title = NSLocalizedString(@"TabBarItemMessageText", nil); //@"消息";
    msgItem.selectedImage = TUIDemoDynamicImage(@"tab_msg_selected_img", [UIImage imageNamed:@"session_selected"]);
    msgItem.normalImage = TUIDemoDynamicImage(@"tab_msg_normal_img", [UIImage imageNamed:@"session_normal"]);
    msgItem.controller = [[TUINavigationController alloc] initWithRootViewController:[[ConversationController alloc] init]];
    msgItem.controller.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    msgItem.badgeView = [[TUIBadgeView alloc] init];
    @weakify(self)
    msgItem.badgeView.clearCallback = ^{
        @strongify(self)
        [self push_clearUnreadMessage];
    };
    [items addObject:msgItem];

    TUITabBarItem *contactItem = [[TUITabBarItem alloc] init];
    contactItem.title = NSLocalizedString(@"TabBarItemContactText", nil);
    contactItem.selectedImage = TUIDemoDynamicImage(@"tab_contact_selected_img", [UIImage imageNamed:@"contact_selected"]);
    contactItem.normalImage = TUIDemoDynamicImage(@"tab_contact_normal_img", [UIImage imageNamed:@"contact_normal"]);
    contactItem.controller = [[TUINavigationController alloc] initWithRootViewController:[[ContactsController alloc] init]];
    contactItem.controller.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    contactItem.badgeView = [[TUIBadgeView alloc] init];
    [items addObject:contactItem];
    
    TUITabBarItem *setItem = [[TUITabBarItem alloc] init];
    setItem.title = NSLocalizedString(@"TabBarItemMeText", nil);
    setItem.selectedImage = TUIDemoDynamicImage(@"tab_me_selected_img", [UIImage imageNamed:@"myself_selected"]);
    setItem.normalImage = TUIDemoDynamicImage(@"tab_me_normal_img", [UIImage imageNamed:@"myself_normal"]);
    setItem.controller = [[TUINavigationController alloc] initWithRootViewController:[[SettingController alloc] init]];
    setItem.controller.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    [items addObject:setItem];
    tbc.tabBarItems = items;

    return tbc;
}

- (void)onUserStatus:(TUIUserStatus)status
{
    switch (status) {
        case TUser_Status_ForceOffline:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下线通知" message:@"您的帐号于另一台手机上登录。" delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"重新登录", nil];
            [alertView show];
        }
            break;
        case TUser_Status_ReConnFailed:
        {
            NSLog(@"连网失败");
        }
            break;
        case TUser_Status_SigExpired:
        {
            NSLog(@"userSig过期");
        }
            break;
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [[TUIKit sharedInstance] logout:^{
            NSLog(@"登出成功！");
        } fail:^(int code, NSString *msg) {
            NSLog(@"退出登录");
        }];
        
        self.window.rootViewController = [self getLoginController];
    }
    else
    {
        // 重新登录
        [[TUILoginCache sharedInstance] login:^(NSString * _Nonnull identifier, NSUInteger appId, NSString * _Nonnull userSig) {
            [self login:identifier userSig:userSig succ:^{
                NSLog(@"登录成功！");
                self.window.rootViewController = [self getMainController];
            } fail:^(int code, NSString *msg) {
                NSLog(@"登录失败！");
                self.window.rootViewController = [self getLoginController];
            }];
        }];
    }
}

#pragma mark - V2TIMConversationListener
- (void)onTotalUnreadMessageCountChanged:(UInt64) totalUnreadCount {
    NSLog(@"%s, totalUnreadCount:%llu", __func__, totalUnreadCount);
}

#pragma mark - V2TIMSDKListener

- (void)onKickedOffline {
    [self onUserStatus:TUser_Status_ForceOffline];
}

- (void)onUserSigExpired {
    [self onUserStatus:TUser_Status_SigExpired];
}

- (TUIContactViewDataProvider *)contactDataProvider
{
    if (_contactDataProvider == nil) {
        _contactDataProvider = [[TUIContactViewDataProvider alloc] init];
    }
    return _contactDataProvider;
}

#pragma mark - LanguageSelectControllerDelegate
- (void)onSelectLanguage:(LanguageSelectCellModel *)cellModel {
    // 动态刷新语言的方法: 销毁当前界面，并重新创建后跳转来实现动态刷新语言
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"need_recover_login_page_info"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    // 1. 重新创建登录控制器以及根导航控制器
    UIViewController *loginVc = [self getLoginController];
    UINavigationController *navVc = nil;
    if ([loginVc isKindOfClass:UINavigationController.class]) {
        navVc = (UINavigationController *)loginVc;
    } else {
        navVc = loginVc.navigationController;
    }
    if (navVc == nil) {
        return;
    }
    
    // 2. 创建语言选择页面，并 push
    LanguageSelectController *languageVc = [[LanguageSelectController alloc] init];
    languageVc.delegate = self;
    [navVc pushViewController:languageVc animated:NO];
    
    // 3. 切换根控制器
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication.sharedApplication.keyWindow.rootViewController = navVc;
    });
}

#pragma mark - ThemeSelectControllerDelegate
- (void)onSelectTheme:(ThemeSelectCollectionViewCellModel *)cellModel {
    // 动态刷新主题的方法: 销毁当前界面，并重新创建后跳转来实现动态刷新主题
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"need_recover_login_page_info"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    // 1. 重新创建登录控制器以及根导航控制器
    UIViewController *loginVc = [self getLoginController];
    UINavigationController *navVc = nil;
    if ([loginVc isKindOfClass:UINavigationController.class]) {
        navVc = (UINavigationController *)loginVc;
    } else {
        navVc = loginVc.navigationController;
    }
    if (navVc == nil) {
        return;
    }
    
    // 2. 创建主题选择控制器并 push
    ThemeSelectController *themeVc = [[ThemeSelectController alloc] init];
    themeVc.disable = YES;
    themeVc.delegate = self;
    [themeVc.view makeToastActivity:TUICSToastPositionCenter];
    [navVc pushViewController:themeVc animated:NO];
    
    // 3. 切换根控制器
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication.sharedApplication.keyWindow.rootViewController = navVc;
        if (@available(iOS 13.0, *)) {
            if ([cellModel.themeID isEqual:@"system"]) {
                // 跟随系统
                UIApplication.sharedApplication.keyWindow.overrideUserInterfaceStyle = 0;
            } else if ([cellModel.themeID isEqual:@"dark"]) {
                // 强制切换成黑色
                UIApplication.sharedApplication.keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            } else {
                // 忽略系统的设置，强制修改成白天模式，并应用当前的主题
                UIApplication.sharedApplication.keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
            }
        }
        [themeVc.view hideToastActivity];
        themeVc.disable = NO;
    });
}

@end
