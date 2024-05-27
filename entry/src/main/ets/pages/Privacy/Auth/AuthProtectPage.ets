// DONE: 未输入内容时，点击下一步，输入框的 placeholder 文案抖动
import { PRIVACY_QUESTION_LIST, PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants';
import { promptAction, router } from '@kit.ArkUI';
import { encryptMD5 } from '../../../manager/encryptMD5';

// 初始化持久化存储
PersistentStorage.persistProp<PrivacySettings>(PRIVACY_SETTINGS, {})

interface RouterParams {
  patternPassword?: number[]
}

@Entry
@Component
struct AuthProtect {
  @StorageProp("topHeight") topHeight: number = 0
  // 双向绑定 Storage 数据
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 问题下标
  @State activeIndex: number = 0
  // 问题答案
  @State answerText: string = ''
  // 错误提示语
  @State errorMessage: string = ''
  // 空状态，输入框抖动效果
  @State inputPaddingLeft: number = 10
  // 路由参数
  @State routerParams: RouterParams = {}

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouterParams
    if (params) {
      this.routerParams = params
    }
  }

  setErrorMessage(message: string) {
    this.errorMessage = message
    this.inputPaddingLeft = 14 // 抖动效果
  }

  clearErrorMessage() {
    this.errorMessage = ''
  }

  // 提交表单
  onSubmit() {
    if (this.answerText.trim() === '') {
      // 空校验提示
      this.setErrorMessage('请填写问题答案')
    } else {
      // 确认密保答案
      this.confirmAnswer()
    }
  }

  // 确认答案

  async confirmAnswer() {
    // 弹窗二次确认
    promptAction.showDialog({
      alignment: DialogAlignment.Center, // 预览器默认居中，模拟器默认靠底部，统一设置居中
      title: '提示',
      message: `你设定的密码保护问题如下\n问题：${PRIVACY_QUESTION_LIST[this.activeIndex].value}\n答案：${this.answerText}\n请确保能够牢记！`,
      buttons: [
        { text: '取消', color: $r('app.color.font_sub') },
        { text: '确定', color: $r('app.color.brand') },
      ]
    })
      .then((res) => {
        console.log("AuthProtectPage:", JSON.stringify(res))
        // 如果点击了确定
        if (res.index === 1) {
          // 持久化存储密码
          this.savePassword()
        }
      })

  }

  // 持久化存储密码
  savePassword() {
    // 1. 保存图形密码
    if (this.routerParams.patternPassword) {
      // 密码保存前，需要通过 MD5 加密存储
      this.privacySettings.patternPassword = encryptMD5(this.routerParams.patternPassword.toString())
    }
    // 2. 保存密保问题 + 答案
    this.privacySettings.protectQuestionIndex = this.activeIndex // 下标不能加密，因为 MD5 为单向加密
    this.privacySettings.protectQuestionAnswer = encryptMD5(this.answerText) // 问题答案需要加密
    console.log("AuthProtectPage:", JSON.stringify(this.privacySettings))

    // 3. 跳转页面
    if (this.routerParams.patternPassword) {
      // 有路由参数，表示首次设置密保，跳转到隐私空间首页
      router.replaceUrl({ url: 'pages/Privacy/PrivacyIndexPage' })
    } else {
      // 没有路由参数，表示修改密保问题，返回上一页即可
      router.back()
    }
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('完成')
        .fontSize(16)
        .fontColor($r('app.color.font'))
        .onClick(() => {
          // TODO：完成
          this.onSubmit()
        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Navigation() {
      Column() {
        Text('设置密码保护问题')
          .fontSize(16)
          .fontColor($r('app.color.font'))
        Text(this.errorMessage ? this.errorMessage : '忘记密码时，可通过密码保护问题重置')
          .fontSize(12)
          .fontColor(this.errorMessage ? $r('app.color.danger') : $r('app.color.font_sub'))
          .lineHeight(25)
        Column() {
          Select(PRIVACY_QUESTION_LIST)
            .value(PRIVACY_QUESTION_LIST[this.activeIndex].value)
            .selected(this.activeIndex)
            .font({ size: 16, weight: 500 })
            .fontColor($r('app.color.font'))
            .selectedOptionFont({ size: 16, weight: 500 })
            .optionFont({ size: 16, weight: 400 })
            .optionBgColor(Color.Transparent)
            .selectedOptionBgColor(Color.Transparent)
            .width('100%')
            .height(56)
            .padding(0)
            .border({ width: { bottom: 1 }, color: $r('app.color.border'), radius: 0 })// 需去除圆角
            .onSelect((index) => {
              this.activeIndex = index
            })

          Row() {
            TextInput({ placeholder: '密保问题答案', text: $$this.answerText })
              .cancelButton({
                style: CancelButtonStyle.INPUT, // 输入时显示清空按钮
                icon: { src: $r('app.media.ic_public_cancel_button') }  // 设置右侧清除按钮样式
              })
              .defaultFocus(true)// 自动获取焦点
              .backgroundColor(Color.Transparent)
              .width('100%')
              .height(56)
              .padding(0)
              .onSubmit(() => {
                // TODO：提交密保问题答案
                this.onSubmit()
              })
          }
          .border({ width: { bottom: 1 }, color: $r('app.color.border'), radius: 0 })
          .padding({ left: this.inputPaddingLeft })
          .animation({
            duration: 400,
            tempo: 4,
            iterations: 2,
            curve: Curve.Linear,
            onFinish: () => {
              // 动画结束，恢复默认值
              this.inputPaddingLeft = 10
            }
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .margin({ top: 20 })
      }
      .padding({ top: 140 })
    }
    .title('设置密保')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus)
    .renderFit(RenderFit.LEFT)
    .padding({ top: this.topHeight })
  }
}