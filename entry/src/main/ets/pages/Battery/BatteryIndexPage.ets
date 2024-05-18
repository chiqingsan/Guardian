import { NavigationTitleBuilder } from '../../common/builders'
import { themeManager } from '../../manager'
import { batteryInfo } from '@kit.BasicServicesKit'

@Entry
@Component
struct BatteryIndexPage {
  // 电池百分比
  @State batterySOC: number = 0
  // 电量消耗速率（假设1%每0.24小时）
  @State consumptionRate: number = 0.24
  // 剩余小时
  @State remainingHours: number = 0
  // 剩余分钟
  @State remainingMinutes: number = 0
  // 电池状态
  batteryHealthStatusListList: string[] = ['未知', '正常', '过热', '过压', '低温', '僵死']
  @State batteryStatus: string = " - "
  // 当前电池是否充电
  batteryChargingList: string[] = ["未充电", "充电中", "停止充电", "已充满"]
  @State batteryCharging: string = " - "
  // 当前电池充电器的类型
  chargerTypeList: string[] = ["未获取", "交流电充电", "USB充电", "无线充电"]
  @State chargerType: string = " - "
  // 当前设备电池的技术型号
  @State batteryModel: string = " - "
  // 当前设备的电压
  @State batteryChargingVoltage: number = 0
  // 当前电池的温度
  @State batteryTemperature: number = 0
  timer: number = -1
  @State Myrotate: number = 0
  @State Myrotate1: number = 0

  onPageShow() {
    themeManager.settingStatusBarWhite()
    // 获取电池电量
    this.getBatteryInfo()
    // 获取电池的健康状态
    this.batteryStatus = this.batteryHealthStatusListList[batteryInfo.healthStatus]

    clearInterval(this.timer)
    this.timer = setInterval(() => {
      // 获取充电状态
      this.batteryCharging = this.batteryChargingList[batteryInfo.chargingStatus]
      // 获取连接充电器的类型
      this.chargerType = this.chargerTypeList[batteryInfo.pluggedType]
      // 获取电池的技术型号
      this.batteryModel = batteryInfo.technology
      // 当前设备的充电的电压
      this.batteryChargingVoltage = batteryInfo.voltage
      // 当前电池的温度
      this.batteryTemperature = batteryInfo.batteryTemperature
    }, 100)
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
    clearInterval(this.timer)
  }

  getBatteryInfo() {
    this.batterySOC = batteryInfo.batterySOC
    // 计算剩余可用时间（剩余电量乘以消耗速率）
    const tempHours = this.batterySOC * this.consumptionRate
    // 格式化剩余时间
    this.remainingHours = Math.floor(tempHours)
    this.remainingMinutes = Math.round((tempHours - this.remainingHours) * 60)
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Column({ space: 15 }) {
          Row({ space: 10 }) {
            // 剩余电池
            Column({ space: 4 }) {


              Row()
                .width(28)
                .height(12)
                .backgroundColor($r('app.color.white'))
                .borderRadius({ topLeft: 6, topRight: 6 })
              Column() {

                Column() {
                  Text(this.batterySOC + '%')
                    .fontSize(32)
                    .fontColor($r('app.color.brand'))
                }
                .height(this.batterySOC + '%')
                .width('100%')
                .backgroundColor($r('app.color.white'))
                .borderRadius(6)
                .justifyContent(FlexAlign.Center)
              }
              .clip(true)
              .width(132)
              .height(186)
              .border({ width: 4, color: $r('app.color.white'), radius: 6 })
              .padding(4)
              .justifyContent(FlexAlign.End)
            }

            Column({ space: 3 }) {
              Text() {
                Span(`当前是否充电: ${this.batteryCharging}\n`)
                Span(`当前连接充电器的类型: ${this.chargerType}\n`)
                Span(`当前设备电池的电压: ${this.batteryChargingVoltage / (1000 * 1000)} 伏\n`)
                Span(`当前设备电池的型号: ${this.batteryModel}\n`)
                Span(`当前设备电池的温度: ${this.batteryTemperature / 10} ℃`)
              }.fontSize(14).fontColor($r("app.color.white")).lineHeight(24)
            }.height(200).alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.End)
          }

          Row() {
            Text('预计可用')
              .fontSize(24)
              .fontColor($r('app.color.white'))

            Text(`当前电池为: ${this.batteryStatus}状态`)
              .fontSize(14)
              .fontColor($r('app.color.white'))
              .margin({ left: 20 })
              .lineHeight(24)
          }.alignItems(VerticalAlign.Bottom)

          // 剩余时间
          Text() {
            Span(this.remainingHours.toString()
              .padStart(2, '0'))
              .fontSize(100)
            Span('小时')
            Span(this.remainingMinutes.toString()
              .padStart(2, '0'))
              .fontSize(100)
            Span('分钟')
          }
          .fontSize(18)
          .fontColor($r('app.color.white'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .height('100%')
      .padding({ bottom: 40 })
    }
    .title(NavigationTitleBuilder('电池管家'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 1]]
    })
  }
}