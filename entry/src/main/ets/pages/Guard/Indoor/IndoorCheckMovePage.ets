import { router } from '@kit.ArkUI'
import { sensor } from '@kit.SensorServiceKit'

@Entry
@Component
struct IndoorCheckMovePage {
  @StorageProp("topHeight") topHeight: number = 0
  // 动画旋转角度
  @State gradientRotateAngle: number = 0
  // 是否静止状态
  @State isStatic: boolean = false
  // 传感器数据
  @State sensorResponse: sensor.AccelerometerResponse | null = null

  @Styles
  circleSize(){
    .height(150)
    .aspectRatio(1)
    .borderRadius(150 / 2)
  }

  aboutToAppear() {
    this.startSensor()
  }

  aboutToDisappear() {
    this.stopSensor()
  }

  // 检测移动，比较前后传感器数据
  checkStatic(val: sensor.AccelerometerResponse, oldVal: sensor.AccelerometerResponse) {
    return (
      Math.abs(val.x - oldVal.x) <= 1 &&
        Math.abs(val.y - oldVal.y) <= 1 &&
        Math.abs(val.z - oldVal.z) <= 1
    )
  }

  // 订阅传感器
  startSensor() {
    try {
      // 加速度传感器
      sensor.on(sensor.SensorId.ACCELEROMETER, (data) => {
        // 1. 先记录初始值
        if (this.sensorResponse === null) {
          this.sensorResponse = data
          return
        }
        //  当前值 与 旧值 比较
        if (this.checkStatic(data, this.sensorResponse)) {
          this.isStatic = true
          // this.sensorResponse = data
        } else {
          // 动的状态
          // 手机移动：由静到动情况，需要警报
          if (this.isStatic === true) {
            // 停止传感器
            this.stopSensor()
            // 跳转页面
            router.replaceUrl({ url: 'pages/Guard/Alarm/CountdownPage' })
          }
          this.isStatic = false
        }
        // 保存数据
        this.sensorResponse = data
      }, { interval: "game" })
    } catch (error) {
      AlertDialog.show({ message: '手机硬件不支持' })
    }
  }

  // 取消订阅传感器
  stopSensor() {
    try {
      // 取消订阅加速度传感器
      sensor.off(sensor.SensorId.ACCELEROMETER)
    } catch (error) {
      AlertDialog.show({ message: '手机硬件不支持' })
    }
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 页面内容
        Column({ space: 10 }) {
          Stack() {
            // 背景 1
            Row()
              .circleSize()
              .backgroundColor('#FFFBFCFE')
              .scale({ x: 220 / 150, y: 220 / 150 })
            // 背景 2
            Row()
              .circleSize()
              .backgroundColor('#080A59F7')
              .scale({ x: 180 / 150, y: 180 / 150 })
            // 渐变色 - 带动画效果
            Row()
              .circleSize()
              .linearGradient({ angle: 0, colors: [['#47eeff', 0], ['#29a6ff', 1]] })
              .rotate({ angle: this.gradientRotateAngle })
              .animation({
                duration: 2 * 1000, // 单次时长
                iterations: -1, // 设置-1表示动画无限循环
                curve: Curve.Linear // 匀速动画
              })
              .onAppear(() => {
                this.gradientRotateAngle = 360
              })

            // 图标区域
            Stack() {
              // 点点图
              Image($r('app.media.ic_lab_move_detect_top'))
                .circleSize()
              // 手机扫描中
              Image(this.isStatic ? $r('app.media.ic_lab_move_detect_protect') :
              $r('app.media.ic_lab_move_detect_phone'))
                .height(80)
            }
          }
          .margin({ top: -250 })

          // 提示文字
          Text(this.isStatic ? '保护中' : '扫描中')
            .fontSize(20)
            .fontWeight(500)
            .fontColor($r('app.color.brand'))
          Text('保持手机静止，以激活防移动模式')
            .fontSize(14)
          // Text('是否静止：' + this.isStatic)
          // Text('传感器数据：' + JSON.stringify(this.sensorResponse))
        }
        .justifyContent(FlexAlign.Center)
        .height('100%')

        // 底部按钮
        Column() {
          Button('停止激活')
            .type(ButtonType.Normal)
            .borderRadius(10)
            .width('100%')
            .backgroundColor($r('app.color.brand'))
            .onClick(() => {
              router.back()
            })
        }
        .padding({ left: 20, right: 20, bottom: 30 })
      }
      .width('100%')
      .height('100%')
    }
    .padding({ top: this.topHeight })
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}