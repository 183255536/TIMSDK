
#import <Foundation/Foundation.h>
@import ImSDK_Plus;

@class TUIBaseMessageController_Minimalist;
@class TUIMessageCellData;
@class TUIMessageCell;

NS_ASSUME_NONNULL_BEGIN

/////////////////////////////////////////////////////////////////////////////////
//
//                         TUIBaseMessageControllerDelegate
//
/////////////////////////////////////////////////////////////////////////////////

@protocol TUIBaseMessageControllerDelegate_Minimalist <NSObject>

/**
 *  控制器点击回调
 *  您可以通过该回调实现：重置 InputController，收起键盘。
 *
 *  @param controller 委托者，消息控制器
 */
/**
 *  Callback for clicking controller
 *  You can use this callback to: reset the InputController, dismiss the keyboard.
 *
 *  @param controller Delegator, Message Controller
 */
- (void)didTapInMessageController:(TUIBaseMessageController_Minimalist *)controller;

/**
 *  隐藏长按菜单后的回调函数
 *  您可以根据您的需求个性化实现该委托函数。
 *
 *  @param controller 委托者，消息控制器
 */
/**
 *  Callback after hide long press menu button
 *  You can customize the implementation of this delegate function according to your needs.
 *
 *  @param controller Delegator, Message Controller
 */
- (void)didHideMenuInMessageController:(TUIBaseMessageController_Minimalist *)controller;

/**
 *  显示长按菜单前的回调函数
 *  您可以根据您的需求个性化实现该委托函数。
 *
 *  @param controller 委托者，消息控制器
 *  @param view 控制器所在view
 */
/**
 *  Callback before hide long press menu button
 *  You can customize the implementation of this delegate function according to your needs.
 *
 *  @param controller Delegator, Message Controller
 *  @param view The view where the controller is located
 */
- (BOOL)messageController:(TUIBaseMessageController_Minimalist *)controller willShowMenuInCell:(UIView *)view;

/**
 *  收到新消息的函数委托
 *  您可以通过该回调实现：根据传入的 data 初始化新消息并进行新消息提醒。
 *
 *  @param controller 委托者，消息控制器
 *  @param message 新消息
 *
 *  @return 返回需要显示的新消息单元
 */
/**
 *  Callback for receiving new message
 *  You can use this callback to initialize a new message based on the incoming data and perform a new message reminder.
 *
 *  @param controller Delegator, Message Controller
 *  @param message Incoming new message
 *
 *  @return Returns the new message unit that needs to be displayed.
 */
- (TUIMessageCellData *)messageController:(TUIBaseMessageController_Minimalist *)controller onNewMessage:(V2TIMMessage *)message;

/**
 *  显示消息数据委托
 *  您可以通过该回调实现：根据传入的 data 初始化消息气泡并进行显示
 *
 *  @param controller 委托者，消息控制器
 *  @param data 需要显示的消息数据
 *
 *  @return 返回需要显示的消息单元。
 */
/**
 *  Callback for displaying new message
 *  You can use this callback to initialize the message bubble based on the incoming data and display it
 *
 *  @param controller Delegator, Message Controller
 *  @param data Data needed to display
 *
 *  @return Returns the new message unit that needs to be displayed.。
 */
- (TUIMessageCell *)messageController:(TUIBaseMessageController_Minimalist *)controller onShowMessageData:(TUIMessageCellData *)data;

/**
 *  cell 将要显示事件
 *  The callback the cell will be displayed with
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller willDisplayCell:(TUIMessageCell *)cell withData:(TUIMessageCellData *)cellData;

/**
 *  点击消息头像委托
 *  您可以通过该回调实现：跳转到对应用户的详细信息界面。
 *  1、首先拉取用户信息，如果该用户是当前使用者好友，则初始化相应的好友信息界面并进行跳转。
 *  2、如果该用户不是当前使用者好友，则初始化相应的添加好友界面并进行跳转。
 *
 *  Callback for clicking avatar in the message cell
 *  You can use this callback to achieve: jump to the detailed information interface of the corresponding user.
 *  1. First pull user information, if the user is a friend of the current user, initialize the corresponding friend information interface and jump.
 *  2. If the user is not a friend of the current user, the corresponding interface for adding friends is initialized and a jump is performed.
 *
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onSelectMessageAvatar:(TUIMessageCell *)cell;

/**
 *  长按消息头像委托
 *  Callback for long pressing avatar in the message cell
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onLongSelectMessageAvatar:(TUIMessageCell *)cell;

/**
 *  点击消息内容委托
 *  Callback for clicking message content in the message cell
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onSelectMessageContent:(TUIMessageCell *)cell;

/**
 * 长按消息内容弹窗菜单栏，点击菜单选项
 * menuType：点击的菜单类型。 0 - 多选，1 - 转发。
 *
 * After long-pressing the message, the menu bar will pop up, and the callback after clicking the menu option
 * menuType: The type of menu that was clicked. 0 - multiple choice, 1 - forwarding.
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onSelectMessageMenu:(NSInteger)menuType withData:(TUIMessageCellData *)data;

/**
 * 即将回复消息（一般是长按消息内容后点击回复按钮触发）
 * Callback for about to reply to the message (usually triggered by long-pressing the message content and then clicking the reply button)
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onRelyMessage:(TUIMessageCellData *)data;

/**
 * 引用消息（长按消息内容后点击引用按钮）
 * Callback for quoting message (triggered by long-pressing the message content and then clicking the quote button)
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onReferenceMessage:(TUIMessageCellData *)data;

/**
 * 表情回应消息（一般是长按消息内容后点击emoji表情触发）
 * Callback for emoji-reacting message (triggered by long-pressing the message content and then clicking the emoji)
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller modifyMessage:(nonnull TUIMessageCellData *)cellData reactEmoji:(NSString *)emojiName;

/**
 * 点击跳转到表情回应详情页（点击更多emoji表情触发）
 * Click to jump to the emoji response details page (click more emoji expressions to trigger)
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller modifyMessage:(TUIMessageCellData *)data faceList:(NSArray *)listModel;

/**
 * 重新编辑消息（一般用于撤回消息）
 * Callback for re-editing message (usually for re-calling a message)
 */
- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onReEditMessage:(TUIMessageCellData *)data;

/**
 * 拿到自定义Tips的高度（例如Demo中的安全提示）
 * Get the height of custom Tips (such as safety tips in Demo)
 */
- (CGFloat)getTopMarginByCustomView;

- (void)messageController:(TUIBaseMessageController_Minimalist *)controller onSelectMessageWhenMultiCheckboxAppear:(TUIMessageCellData *)data;

@end

NS_ASSUME_NONNULL_END
