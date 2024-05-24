import { PRIVACY_QUESTION_LIST, PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants'
import { promptAction, router } from '@kit.ArkUI'
import { encryptMD5 } from '../../../manager/encryptMD5'

@Entry
@Component
struct ForgetPasswordPage {
  @StorageProp("topHeight") topHeight: number = 0
  // 获取 AppStorage 的数据
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 输入的答案
  @State answerText: string = ''
  // 错误提示语
  @State errorMessage: string = ''
  // 空状态，输入框抖动效果
  @State inputPaddingLeft: number = 10

  aboutToAppear(): void {
    // this.verifyTheSecurity()
  }

  verifyTheSecurity() {
    console.log("ForgetPasswordPage:", JSON.stringify(this.privacySettings))
    if (encryptMD5(this.answerText) === this.privacySettings.protectQuestionAnswer) {
      router.pushUrl({ url: "/pages/Privacy/Auth/AuthPatternLockSettingsPage".slice(1) })
      this.privacySettings = {}
    } else {
      this.answerText ? this.setErrorMessage("密保问题错误!") : this.setErrorMessage("输入不能为空!")
    }
  }

  // 提示错误
  setErrorMessage(message: string) {
    this.answerText = ""
    this.inputPaddingLeft = 16
    this.errorMessage = `${message}`
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('下一步')
        .fontSize(16)
        .fontColor($r('app.color.font'))
        .onClick(() => {
          // TODO：下一步
          this.verifyTheSecurity()

        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Navigation() {
      Column() {
        Text('测试数据：' + JSON.stringify(this.privacySettings))
      }

      Column() {
        Text('重置密码')
          .fontSize(16)
          .fontColor($r('app.color.font'))
        Text(this.errorMessage ? this.errorMessage : '请回答密码保护问题，将密码找回')
          .fontSize(12)
          .fontColor(this.errorMessage ? $r('app.color.danger') : $r('app.color.font_sub'))
          .lineHeight(25)
        Column() {
          Text(PRIVACY_QUESTION_LIST[this.privacySettings.protectQuestionIndex || 0].value)
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#182431')
            .width('100%')
            .padding({ left: 10 })
            .height(56)
            .border({ width: { bottom: 1 }, color: $r('app.color.border'), radius: 0 })
          Row() {
            TextInput({ placeholder: '密保问题答案', text: this.answerText })
              .cancelButton({
                style: CancelButtonStyle.INPUT, // 输入时显示清空按钮
                icon: { src: $r('app.media.ic_public_cancel_button') }  // 设置右侧清除按钮样式
              })
              .defaultFocus(true)// 自动获取焦点
              .backgroundColor(Color.Transparent)
              .padding(0)
              .width('100%')
              .height(56)
              .onChange((text) => {
                this.answerText = text
              })
              .onSubmit(() => {
                // TODO：提交密保问题答案
                this.verifyTheSecurity()
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
    .title('隐私空间')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus)
    .padding({ top: this.topHeight })
  }
}