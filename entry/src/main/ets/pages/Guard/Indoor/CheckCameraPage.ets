import { sensor, vibrator } from '@kit.SensorServiceKit'
import { NavigationTitleBuilder } from '../../../common/builders/index'
import { permissionManager, themeManager } from '../../../manager/index'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct CheckCameraPage {
  @StorageProp("topHeight") topHeight: number = 0
  // 传感器数据
  @State sensorResponse: sensor.MagneticFieldResponse | null = null
  // 最大环境磁场强度，单位 : μT
  @State maxData: number = 0
  @State dataList: number[] = []
  // 警报阈值
  private alarmValue: number = 100
  private scroller: Scroller = new Scroller()

  onPageShow() {
    themeManager.settingStatusBarWhite()
    // this.increaseTheData()
    this.startSensor()
  }

  onPageHide() {
    this.stopSensor()
    this.stopVibration()
  }

  increaseTheData() {
    setInterval(() => {
      this.dataList.push(Math.floor(Math.random() * 250 + 50))
    }, 200)
  }

  // 开启环境磁场传感器
  startSensor() {
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (response) => {
        // 保存传感器数据
        this.sensorResponse = response
        // 获取最大值
        this.maxData = Math.max(Math.abs(response.x), Math.abs(response.y), Math.abs(response.z))
        // 追加到数组中
        this.dataList.push(this.maxData)
        // 数组过长时截取
        this.dataList = this.dataList.length > 100 ? this.dataList.slice(-100) : this.dataList
        // 滚动到结束
        this.scroller.scrollEdge(Edge.End)
        // 超过阈值开启马达震动
        if (this.maxData >= this.alarmValue) {
          this.startVibration() // 马达震动
        } else {
          this.stopVibration() // 停止震动
        }
      }, { interval: 10000000 }) // game
    } catch {
      promptAction.showDialog({ message: '硬件不支持' })
    }
  }

  // 关闭环境磁场传感器
  stopSensor() {
    try {
      sensor.off(sensor.SensorId.MAGNETIC_FIELD)
    } catch {
      //
    }
  }

  // 开启震动
  startVibration() {
    vibrator.startVibration({ type: 'time', duration: 500 }, { id: 0, usage: 'alarm' })
  }

  // 关闭震动
  stopVibration() {
    vibrator.stopVibration()
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Text('环境磁场强度')
          .fontSize(14)
          .fontColor($r('app.color.font_sub'))
        Text(this.maxData.toFixed(2) + 'uT')
          .fontSize(30)
          .fontColor(this.maxData >= this.alarmValue ? $r('app.color.danger') : $r('app.color.brand'))
        Text(this.maxData >= this.alarmValue ? '检测到较强信号波动，请留意附近可疑位置' : '未发现异常信号')
          .fontSize(14)
          .fontColor(this.maxData >= this.alarmValue ? $r('app.color.danger') : $r('app.color.white'))
      }
      .padding({ top: 50 })

      Row() {
        Scroll(this.scroller) {
          Row({ space: 4 }) {
            ForEach(this.dataList, (value: number) => {
              Column()
                .height(value > 300 ? 300 : value)
                .width(2)
                .backgroundColor(value >= this.alarmValue ? $r('app.color.danger') : $r('app.color.brand'))
            })
          }
        }
        .enabled(false)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBarWidth(0)
      }
      .backgroundColor('#201F24')
      .width('100%')
      .height(370)
      .margin({ top: 20, bottom: 40 })

      Row() {
        Text('请注意区别其他电器的信号')
          .fontSize(14)
          .fontColor($r('app.color.white'))
      }
    }
    .title(NavigationTitleBuilder('摄像头检测'))
    .hideBackButton(true)
    .padding({ top: this.topHeight })
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .backgroundColor($r('app.color.black'))
  }
}