import { promptAction, router } from '@kit.ArkUI'
import dayjs from 'dayjs'
import { PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants'
import { encryptMD5 } from '../../../manager/encryptMD5'
import userIAM_userAuth from '@ohos.userIAM.userAuth';
import { BusinessError } from '@kit.BasicServicesKit'
import userAuth from '@ohos.userIAM.userAuth'
import { userAuthManager } from '../../../manager'

@Entry
@Component
struct AuthPatternLockPage {
  @StorageProp("topHeight") topHeight: number = 0
  // 获取 AppStorage 的数据
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 输入的密码
  @State inputPasswords: number[] = []
  // 错误提示语
  @State errorMessage: string = ''
  // 错误输入次数
  @State @Watch("hackProof") errorInputCount: number = 0
  // 是否允许操作
  @State isEnable: boolean = true
  // 是否开启模糊
  @State isFuzzy: boolean = false
  // 定时器，用于清空提示文案
  private timeoutID: number = -1
  // 用于提示防破解倒计时
  private timer: number = -1
  // 图形密码控制器
  private patternLockController: PatternLockController = new PatternLockController()

  aboutToAppear(): void {
    // 判断是否需要拉起用户认证
    this.privacySettings.isOpenUserAuthLock && this.userAuthentication()
    // 判断之前是否错误锁定
    if (this.privacySettings.antiCrackingLastFailedTimeStamp && this.privacySettings.isOpenAntiCracking) {
      if (Date.now() - this.privacySettings.antiCrackingLastFailedTimeStamp < 1000 * 3600) {
        this.isEnable = false
        const errorTimestamp = this.privacySettings.antiCrackingLastFailedTimeStamp as number

        clearInterval(this.timer)
        // 定时器开始前,先执行一次
        this.timestampCountdown(errorTimestamp)
        this.timer = setInterval(() => {
          this.timestampCountdown(errorTimestamp)
        }, 1000)
      }
    }

  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  // 用户认证
  async userAuthentication() {
    this.isFuzzy = true
    // 拉起用户认证
    try {
      const res = await userAuthManager.startUserAuth()
      if (res.results) {
        router.replaceUrl({ url: "/pages/Privacy/PrivacyIndexPage".slice(1) })
      } else {
        promptAction.showToast({ message: `${res.message}` })
      }
    } catch (e) {
      // 打印错误
      console.error("AuthPatternLockPage_e:", JSON.stringify(e))
    }
    animateTo({ duration: 500, curve: Curve.Ease }, () => {
      this.isFuzzy = false
    })
  }

  // 倒计时
  timestampCountdown(errorTimestamp: number) {
    const countdown = 1000 * 3600 - (Date.now() - errorTimestamp)
    console.log("AuthPatternLockPage_countdown:", JSON.stringify(countdown))
    this.errorMessage = `请等待${dayjs(countdown).format(" mm分 : ss秒 ")}后再试`
  }

  verifyYourPassword(input: number[]) {
    // 保存输入的密码
    this.inputPasswords = input
    if (encryptMD5(this.inputPasswords.toString()) == this.privacySettings.patternPassword) {
      this.patternLockController.setChallengeResult(PatternLockChallengeResult.CORRECT)
      router.replaceUrl({ url: "/pages/Privacy/PrivacyIndexPage".slice(1) })
    } else {
      this.setErrorMessage('手势密码错误，请重新输入')
    }
  }

  // 提示错误
  setErrorMessage(message: string) {
    this.errorInputCount++
    this.errorMessage = `${message} 已错误${this.errorInputCount}次`
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.WRONG)
    this.timeoutID = setTimeout(() => {
      this.patternLockController.reset()
      this.errorInputCount >= 3 || this.clearTheMessage()
    }, 1000)
  }

  clearTheMessage() {
    this.errorMessage = ""
    this.inputPasswords = []
  }

  hackProof() {
    if (this.privacySettings.isOpenAntiCracking) {
      if (this.errorInputCount >= 3) {
        this.privacySettings.antiCrackingLastFailedTimeStamp = Date.now()
        this.isEnable = false
        const errorTimestamp = this.privacySettings.antiCrackingLastFailedTimeStamp as number

        clearInterval(this.timer)
        // 定时器开始前,先执行一次
        this.timestampCountdown(errorTimestamp)
        this.timer = setInterval(() => {
          this.timestampCountdown(errorTimestamp)
        }, 1000)
      }
    }
  }

  build() {
    Column() {
      // 标题
      Navigation() {

        Column({ space: 20 }) {
          Column({ space: 10 }) {
            // 请输入密码
            Text(this.isEnable ? '请输入密码' : '隐私空间已锁定')
              .fontSize(16)
              .fontColor($r('app.color.font'))
            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(12)
                .fontColor($r('app.color.danger'))
            } else {
              Text('输入密码进入隐私空间')
                .fontSize(12)
                .fontColor($r('app.color.font_sub'))
            }
          }

          PatternLock(this.patternLockController)
            .sideLength(320)// 宽高
            .circleRadius(12)// 圆点半径
            .pathStrokeWidth(10)// 线宽度
            .regularColor('#ffd9d9d9')// 未选中圆点色
            .activeColor('#800a59f7')// 经过圆点色
            .selectedColor(this.errorMessage && this.inputPasswords.length !== 0 ? '#ffff5e5d' : '#ff0a59f7')// 选中圆点色
            .pathColor(this.errorMessage && this.inputPasswords.length !== 0 ? '#ccff5e5d' : '#cc0a59f7')// 线颜色
            .enabled(this.isEnable)
            .onDotConnect(() => {
              // 密码输入选中宫格圆点时触发该回调
              clearInterval(this.timeoutID)
              this.clearTheMessage()
            })
            .onPatternComplete((input: number[]) => {
              // TODO：密码输入结束时触发该回调
              this.verifyYourPassword(input)
            })

          Row({ space: 20 }) {
            Text('忘记密码')
              .fontSize(14)
              .fontColor($r('app.color.font2'))
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/Privacy/Auth/ForgetPasswordPage',
                })
              })
          }
        }
        .padding({ top: 140 })
      }
      .title('隐私空间')
      .titleMode(NavigationTitleMode.Mini)
      .mode(NavigationMode.Stack)
      .hideTitleBar(false)
    }
    .height('100%')
    .blur(this.isFuzzy ? 18 : 0)
    .padding({ top: this.topHeight })
  }
}