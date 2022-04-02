//
//  ChatViewController.m
//  TUIKitDemo
//
//  Created by kennethmiao on 2018/10/10.
//  Copyright © 2018年 Tencent. All rights reserved.
//
/** 腾讯云IM Demo 聊天视图
 *  本文件实现了聊天视图
 *  在用户需要收发群组、以及其他用户消息时提供UI
 *
 *  本类依赖于腾讯云 TUIKit和IMSDK 实现
 *
 */
#import "ChatViewController.h"
#import "GroupInfoController.h"
#import "TUserProfileController.h"
#import "TUIC2CChatViewController.h"
#import "TUIGroupChatViewController.h"
#import "TFriendProfileController.h"
#import "TUIVideoMessageCell.h"
#import "TUIFileMessageCell.h"
#import "TUITextMessageCell.h"
#import "TUISystemMessageCell.h"
#import "TUIVoiceMessageCell.h"
#import "TUIImageMessageCell.h"
#import "TUIFaceMessageCell.h"
#import "TUIVideoMessageCell.h"
#import "TUIFileMessageCell.h"
#import "TUIJoinGroupMessageCell.h"
#import "GroupCreateCell.h"
#import "TUIKit.h"
#import "TCUtil.h"
#import "TCConstants.h"
#import "GenerateTestUserSig.h"
#import "TUIChatDataProvider.h"
#import "TUIMessageDataProvider.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "UIView+TUILayout.h"
#import "UIView+TUIToast.h"
#import "TUIGlobalization.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "TUIThemeManager.h"
#import "TUINaviBarIndicatorView.h"

// MLeaksFinder 会对这个类误报，这里需要关闭一下
@implementation UIImagePickerController (Leak)

- (BOOL)willDealloc {
    return NO;
}

@end

@interface ChatViewController () <
TUIChatControllerListener,
V2TIMConversationListener,
TUIJoinGroupMessageCellDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIDocumentPickerDelegate>
@property (nonatomic, strong) TUIBaseChatViewController *chat;
@property (nonatomic, strong) TUINaviBarIndicatorView *titleView;
@end

@implementation ChatViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [[V2TIMManager sharedInstance] addConversationListener:self];
    
    if (self.conversationData.groupID.length > 0) {
        _chat = [[TUIGroupChatViewController alloc] init];
        @weakify(self);
        ((TUIGroupChatViewController *)_chat).openUserProfileVCBlock = ^(TUIGroupPendencyCell * _Nonnull cell) {
            @strongify(self);
            
            TUserProfileController *controller = [[TUserProfileController alloc] init];
            [[V2TIMManager sharedInstance] getUsersInfo:@[cell.pendencyData.fromUser] succ:^(NSArray<V2TIMUserFullInfo *> *profiles) {
                controller.userFullInfo = profiles.firstObject;
                controller.groupPendency = cell.pendencyData;
                controller.actionType = PCA_GROUP_CONFIRM;
                [self.navigationController pushViewController:controller animated:YES];
            } fail:nil];
            
        };
    } else if (self.conversationData.userID.length > 0) {
        _chat = [[TUIC2CChatViewController alloc] init];
    }
    [_chat setDelegate:self];
    [_chat setConversationData:self.conversationData];
    [self addChildViewController:_chat];
    [self.view addSubview:_chat.view];
    
    _titleView = [[TUINaviBarIndicatorView alloc] init];
    self.navigationItem.titleView = _titleView;
    self.navigationItem.title = @"";
    __weak typeof (self)weakSelf = self;
    [[RACObserve(_conversationData, title) distinctUntilChanged] subscribeNext:^(NSString *title) {
        [weakSelf.titleView setTitle:title];
    }];
    [self checkTitle:NO];

    // 导航栏
    [self setupNavigator];

    // 刷新未读数
    [TUIChatDataProvider getTotalUnreadMessageCountWithSuccBlock:^(UInt64 totalCount) {
        [weakSelf onChangeUnReadCount:totalCount];
    } fail:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onFriendInfoChanged:) name:@"FriendInfoChangedNotification" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 发送第一条消息
    if (self.waitToSendMsg) {
        [self.chat sendMessage:self.waitToSendMsg];
        self.waitToSendMsg = nil;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupNavigator
{
    //left
    _unRead = [[TUIUnReadView alloc] init];

//    _unRead.backgroundColor = [UIColor colorWithRed:170/255.0 green:188/255.0 blue:209/255.0 alpha:1/1.0];   // 默认使用红色未读视图
//    UIBarButtonItem *urBtn = [[UIBarButtonItem alloc] initWithCustomView:_unRead];
//    self.navigationItem.leftBarButtonItems = @[urBtn];
//    //既显示返回按钮，又显示未读视图
//    self.navigationItem.leftItemsSupplementBackButton = YES;

    //right，根据当前聊天页类型设置右侧按钮格式
    UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [rightButton addTarget:self action:@selector(rightBarButtonClick) forControlEvents:UIControlEventTouchUpInside];
    UIImage *img = TUIDemoDynamicImage(@"nav_more_menu_img", [UIImage imageNamed:@"nav_more_item"]);
    [rightButton setImage:TUIDemoDynamicImage(@"nav_more_menu_img", [UIImage imageNamed:@"nav_more_item"]) forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0] forState:UIControlStateNormal];
    rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItems = @[rightItem];
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (parent == nil) {
        [_chat saveDraft];
    }
}

#pragma mark - V2TIMConversationListener
- (void)onConversationChanged:(NSArray<V2TIMConversation*> *) conversationList {
    // 聊天窗口标题由上层维护，需要自行设置标题
    for (V2TIMConversation *conv in conversationList) {
        if ([conv.conversationID isEqualToString:self.conversationData.conversationID]) {
            self.conversationData.title = conv.showName;
            break;
        }
    }
}

- (void)onTotalUnreadMessageCountChanged:(UInt64)totalUnreadCount {
    [self onChangeUnReadCount:totalUnreadCount];
}

#pragma mark - TUIChatControllerListener
- (void)chatController:(TUIBaseChatViewController *)controller didSendMessage:(V2TIMMessage *)message {
    //write code
}

- (void)chatController:(TUIBaseChatViewController *)chatController onSelectMoreCell:(TUIInputMoreCell *)cell {
    //write code
}

- (TUIMessageCellData *)chatController:(TUIBaseChatViewController *)controller onNewMessage:(V2TIMMessage *)msg
{
    if (V2TIM_ELEM_TYPE_CUSTOM == msg.elemType) {
        NSDictionary *param = [TCUtil jsonData2Dictionary:msg.customElem.data];
        if (param != nil) {
            NSString *businessID = param[@"businessID"];
            if (![businessID isKindOfClass:[NSString class]]) {
                return nil;
            }
            // 判断是不是群创建自定义消息
            if ([businessID isEqualToString:BussinessID_GroupCreate] || [param.allKeys containsObject:BussinessID_GroupCreate]) {
                GroupCreateCellData *cellData = [[GroupCreateCellData alloc] initWithDirection:msg.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming];
                cellData.content = [NSString stringWithFormat:@"\"%@\"%@",param[@"opUser"],param[@"content"]];
                return cellData;
            }
        }
    }
    return nil;
}

- (TUIMessageCell *)chatController:(TUIBaseChatViewController *)controller onShowMessageData:(TUIMessageCellData *)cellData
{
    if ([cellData isKindOfClass:[GroupCreateCellData class]]) {
        GroupCreateCell *groupCell = [[GroupCreateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GroupCreateCell"];
        [groupCell fillWithData:(GroupCreateCellData *)cellData];
        return groupCell;
    }
    return nil;
}

- (void)chatController:(TUIBaseChatViewController *)controller willDisplayCell:(TUIMessageCell *)cell withData:(TUIMessageCellData *)cellData {
    //对于入群小灰条，需要进一步设置其委托。
    if([cell isKindOfClass:[TUIJoinGroupMessageCell class]]){
        TUIJoinGroupMessageCell *joinCell = (TUIJoinGroupMessageCell *)cell;
        joinCell.joinGroupDelegate = self;
    }
}

- (NSString *)chatController:(TUIBaseChatViewController *)controller onGetMessageAbstact:(V2TIMMessage *)message
{
    if (V2TIM_ELEM_TYPE_CUSTOM == message.elemType) {
        NSDictionary *param = [TCUtil jsonData2Dictionary:message.customElem.data];
        if (param != nil) {
            NSString *businessID = param[@"businessID"];
            // 判断是不是群创建自定义消息
            if ([businessID isKindOfClass:NSString.class] && ([businessID isEqualToString:BussinessID_GroupCreate] || [param.allKeys containsObject:BussinessID_GroupCreate])) {
                return [NSString stringWithFormat:@"\"%@\"%@",param[@"opUser"],param[@"content"]];
            }
        }
    }
    return nil;
}

- (void)chatController:(TUIBaseChatViewController *)controller onSelectMessageAvatar:(TUIMessageCell *)cell {
    @weakify(self);
    [ChatViewController getUserOrFriendProfileVCWithUserID:cell.messageData.identifier
                                                 SuccBlock:^(UIViewController * _Nonnull vc) {
        @strongify(self);
        [self.navigationController pushViewController:(UIViewController *)vc animated:YES];
    } failBlock:^(int code, NSString * _Nonnull desc) {
        [TUITool makeToastError:code msg:desc];
    }];
}

#pragma mark - TUIJoinGroupMessageCellDelegate
- (void)didTapOnRestNameLabel:(TUIJoinGroupMessageCell *)cell withIndex:(NSInteger)index{
    NSString *userId = cell.joinData.userIDList[index];
    
    @weakify(self);
    [ChatViewController getUserOrFriendProfileVCWithUserID:userId SuccBlock:^(UIViewController *vc) {
        @strongify(self);
        [self.navigationController pushViewController:vc animated:YES];
    } failBlock:^(int code, NSString *desc) {
        [TUITool makeToastError:code msg:desc];
    }];
}

#pragma mark - Event Response

- (void)onChangeUnReadCount:(UInt64)totalCount {
    
    // 此处异步的原因：当前聊天页面连续频繁收到消息，可能还没标记已读，此时也会收到未读数变更。理论上此时未读数不会包括当前会话的。
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.unRead setNum:totalCount];
    });
}

- (void)onFriendInfoChanged:(NSNotification *)notice
{
    [self checkTitle:YES];
}

- (void)checkTitle:(BOOL)force {
    
    if (force || self.conversationData.title.length == 0) {
        if (self.conversationData.userID.length > 0) {
            self.conversationData.title = self.conversationData.userID;
            @weakify(self);
            
            [TUIChatDataProvider getFriendInfoWithUserId:self.conversationData.userID
                                             SuccBlock:^(V2TIMFriendInfoResult * _Nonnull friendInfoResult) {
                @strongify(self);
                if (friendInfoResult.relation & V2TIM_FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST
                    && friendInfoResult.friendInfo.friendRemark.length > 0) {
                    self.conversationData.title = friendInfoResult.friendInfo.friendRemark;
                } else {
                    [TUIChatDataProvider getUserInfoWithUserId:self.conversationData.userID
                                                   SuccBlock:^(V2TIMUserFullInfo * _Nonnull userInfo) {
                        if (userInfo.nickName.length > 0) {
                            self.conversationData.title = userInfo.nickName;
                        }
                    } failBlock:nil];
                }
            } failBlock:nil];
        }
        else if (self.conversationData.groupID.length > 0) {
            [TUIChatDataProvider getGroupInfoWithGroupID:self.conversationData.groupID
                                             SuccBlock:^(V2TIMGroupInfoResult * _Nonnull groupResult) {
                if (groupResult.info.groupName.length > 0) {
                    self.conversationData.title = groupResult.info.groupName;
                }
            } failBlock:nil];
        }
    }
}

-(void)leftBarButtonClick
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightBarButtonClick
{
    //当前为用户和用户之间通信时，右侧按钮响应为用户信息视图入口
    if (_conversationData.userID.length > 0) {
        
        @weakify(self);
        [ChatViewController getUserOrFriendProfileVCWithUserID:self.conversationData.userID
                                                      SuccBlock:^(UIViewController * _Nonnull vc) {
            @strongify(self);
            [self.navigationController pushViewController:(UIViewController *)vc animated:YES];
        } failBlock:^(int code, NSString * _Nonnull desc) {
            [TUITool makeToastError:code msg:desc];
        }];

    //当前为群组通信时，右侧按钮响应为群组信息入口
    } else {
        GroupInfoController *groupInfo = [[GroupInfoController alloc] init];
        groupInfo.groupId = _conversationData.groupID;
        [self.navigationController pushViewController:groupInfo animated:YES];
    }
}

+ (void)getUserOrFriendProfileVCWithUserID:(NSString *)userID
                                 SuccBlock:(void(^)(UIViewController *vc))succ
                                 failBlock:(nullable V2TIMFail)fail
{
    [TUIChatDataProvider getFriendInfoWithUserId:userID
                                       SuccBlock:^(V2TIMFriendInfoResult * _Nonnull friendInfoResult) {
        if (friendInfoResult.relation & V2TIM_FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST) {
            // 如果是好友, 则跳转到好友信息页
            TFriendProfileController *vc = [[TFriendProfileController alloc] init];
            vc.friendProfile = friendInfoResult.friendInfo;
            succ((UIViewController *)vc);
            
        } else {
            // 非好友, 则跳转到用户信息页
            [TUIChatDataProvider getUserInfoWithUserId:userID
                                             SuccBlock:^(V2TIMUserFullInfo * _Nonnull userInfo) {
                TUserProfileController *vc = [[TUserProfileController alloc] init];
                vc.userFullInfo = userInfo;
                if ([userInfo.userID isEqualToString:[[V2TIMManager sharedInstance] getLoginUser]]) {
                    vc.actionType = PCA_NONE;
                } else {
                    vc.actionType = PCA_ADD_FRIEND;
                }
                succ((UIViewController *)vc);
                
            } failBlock:fail];
        }
        
    } failBlock:fail];
}
@end
