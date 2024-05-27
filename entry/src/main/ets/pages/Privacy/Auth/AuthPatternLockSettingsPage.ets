import { router } from '@kit.ArkUI'
import { PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants'

interface RouterParams {
  isForgetPassword?: boolean
}

@Entry
@Component
struct AuthPatternLockSettingsPage {
  @StorageProp("topHeight") topHeight: number = 0
  // 获取隐私空间设置
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 正在输入的图形密码
  @State inputPassword: number[] = []
  // 第一次输入的密码
  @State firstPassword: number[] = []
  // 错误提示语
  @State errorMessage: string = ''
  // 路由参数
  @State routerParams: RouterParams = {}
  // 定时器，用于清空提示文案
  private timeoutID: number = -1
  // 控制器
  private patternLockController: PatternLockController = new PatternLockController()

  setErrorMessage(message: string) {
    this.errorMessage = message
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.WRONG)
  }

  clearErrorMessage() {
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.CORRECT)
    this.errorMessage = ''
  }

  // 重置图形密码和临时密码
  resetPattern() {
    // 每次输入结束后，自动清空界面图形
    this.timeoutID = setTimeout(() => {
      // 重置图形密码
      this.patternLockController.reset()
      // 重置临时密码
      this.inputPassword = []
    }, 1000)
  }

  // 手势密码输入完成
  onPatternComplete(input: number[]) {
    // 保存临时密码
    this.inputPassword = input
    // 1. 校验长度，输入长度小于 4，提示重新输入
    if (this.inputPassword.length < 4) {
      // 设置错误提示
      this.setErrorMessage('手势密码长度不能小于4位，请重新输入')
    } else {
      // 清空错误提示
      this.clearErrorMessage()
      // 2. 长度符合规范，同时判断是否为首次输入
      if (this.firstPassword.length === 0) {
        // 2.1 首次输入，直接保存当前输入的密码
        this.firstPassword = input
      } else {
        // 2.2 非首次输入，需判断两次输入的密码是否相同
        if (JSON.stringify(this.firstPassword) === JSON.stringify(this.inputPassword)) {
          // 跳转到密保设置页，并传递当前输入的密码
          router.replaceUrl({
            url: 'pages/Privacy/Auth/AuthProtectPage', // 跳转密保设置页
            params: { patternPassword: this.firstPassword }  // 传递密码
          })
        } else {
          // 2.2.2 如果不同，重置第一次输入的密码
          this.firstPassword = []
          // 显示错误原因，且 1s 后提示自动消失
          this.setErrorMessage('两次手势密码不一致，请重新输入')
        }
      }
    }
    // 每次输入结束后，自动清空界面图形
    this.resetPattern()
  }

  build() {
    Navigation() {
      // Column() {
      //   Text('inputPasswords：' + this.inputPassword)
      //   Text('firstPasswords：' + this.firstPassword)
      // }
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          // 请输入密码
          Text(this.firstPassword.length === 0 ? '设置手势密码' : '再次确认手势密码')
            .fontSize(16)
            .fontColor($r('app.color.font'))
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor($r('app.color.danger'))
          } else {
            Text(this.firstPassword.length === 0 ? '请绘制手势密码，至少链接4个点' : '请再次输入确认手势密码')
              .fontSize(12)
              .fontColor($r('app.color.font_sub'))
          }
        }

        PatternLock(this.patternLockController)
          .sideLength(320)// 宽高
          .circleRadius(12)// 圆点半径
          .pathStrokeWidth(10)// 线宽度
          .regularColor('#d9d9d9')// 未选中圆点色
          .activeColor('#800a59f7')// 经过圆点色
          .selectedColor(this.errorMessage && this.inputPassword.length !== 0 ? '#ffff5e5d' : '#ff0a59f7')// 选中圆点色
          .pathColor(this.errorMessage && this.inputPassword.length !== 0 ? '#ccff5e5d' : '#cc0a59f7')// 线颜色
          .onDotConnect(() => {
            // 密码输入选中宫格圆点时触发该回调
            clearInterval(this.timeoutID)
            this.clearErrorMessage()
          })
          .onPatternComplete((input: number[]) => {
            // TODO：密码输入结束时触发该回调
            // AlertDialog.show({ message: JSON.stringify(input, null, 2) })
            this.onPatternComplete(input)

          })
      }
      .padding({ top: 140 })
    }
    .title('隐私空间')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .padding({ top: this.topHeight })
  }
}