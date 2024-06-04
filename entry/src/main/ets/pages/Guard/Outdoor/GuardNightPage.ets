import { Permissions } from '@kit.AbilityKit'
import { promptAction, router } from '@kit.ArkUI'
import { AsyncCallback } from '@kit.BasicServicesKit'
import { map, mapCommon, MapComponent, sceneMap } from '@kit.MapKit'
import { webSocket } from '@kit.NetworkKit'
import { locationManager, permissionManager, themeManager } from '../../../manager'
import { call } from '@kit.TelephonyKit'
import { getEmergencyContactAPI } from '../../../aip'
import { torchManager } from '../../../manager/TorchManager'
import { geoLocationManager } from '@kit.LocationKit'

@Entry
@Component
struct GuardNightPage {
  @StorageLink('topHeight') topHeight: number = 0
  @StorageLink('bottomHeight') bottomHeight: number = 0
  @State isShowMap: boolean = false
  @State placeName: string = ''
  @State emergencyPhone: string = ""
  private permissions: Permissions[] = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION'
  ];
  // 定位
  private mapOption?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  // 分享
  private ws?: webSocket.WebSocket
  private wsReady: boolean = false;

  onPageShow() {
    // 开启沉浸式
    themeManager.enableFullScreen()
  }

  onPageHide() {
    // 关闭沉浸式
    themeManager.disableFullScreen()
  }

  // 页面加载
  async aboutToAppear() {
    await this.requestPermissions()
    // 获取紧急联系人
    this.getEmergencyPhone()
    // 初始化地图
    this.initMap()
  }

  // 页面卸载
  aboutToDisappear() {
    // 关闭手电筒
    torchManager.closeTorch()
  }

  // 定位权限
  async requestPermissions() {
    try {
      // 申请权限
      await permissionManager.requestPermissions(this.permissions)
    } catch {
      // 未开启弹窗提示
      const dialogRes = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '夜路守护功能需要获取定位权限，请在系统设置中打开定位开关',
        buttons: [
          { text: '取消', color: $r('app.color.font_sub') },
          { text: '立即开启', color: $r('app.color.brand') }
        ]
      })
      // 打开设置页
      if (dialogRes.index === 1) {
        permissionManager.openPermissionSettingsPage()
      }
    }
  }

  // 获取定位地址
  async getPlaceName(location: geoLocationManager.Location) {
    const res = await geoLocationManager.getAddressesFromLocation({
      locale: 'zh',
      latitude: location.latitude,
      longitude: location.longitude,
      maxItems: 1
    })
    this.placeName = res?.[0].placeName || ''
  }

  // 设置地图上的定位点
  async setCurrLocation(location: geoLocationManager.Location) {
    // 设置定位点
    this.mapController?.setMyLocation(location)
    const target = await map.convertCoordinate(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02,
      location)
    const updateCamera = map.newCameraPosition({
      target: target,
      zoom: 16
    })
    this.mapController?.animateCamera(updateCamera)
  }

  initMap() {
    // 地图配置
    this.mapOption = {
      position: {
        target: { latitude: 39.9, longitude: 116.4 },
        zoom: 10
      },
    }
    // 显示地图
    this.isShowMap = true
    // 回调函数
    this.callback = async (err, mapController) => {
      if (err) {
        promptAction.showToast({ message: '地图初始化出错' })
        return
      }
      this.mapController = mapController
      this.mapController.on('mapLoad', async () => {
        // 启用我的位置图层
        this.mapController?.setMyLocationEnabled(true)
        // 启用我的位置按钮
        this.mapController?.setMyLocationControlsEnabled(true)
        const location = await geoLocationManager.getCurrentLocation()
        // 获取定位地址信息
        this.getPlaceName(location)
        // 设置地图上的定位点
        this.setCurrLocation(location)
      })
    }
  }

  // 获取紧急联系人
  async getEmergencyPhone() {
    const res = await getEmergencyContactAPI()
    if (res.data.result.phone) {
      this.emergencyPhone = res.data.result.phone
      promptAction.showToast({ message: '已向您的紧急联系人发送夜路守护短信' })
    } else {
      promptAction.showToast({ message: '请设置紧急联系人' })
    }
  }

  // 拨打电话
  makePhoneCall(phoneNumber: string) {
    if (!call.hasCallSync()) {
      call.makeCall(phoneNumber)
    }
  }

  // 停止保护
  stopProtect() {
    AlertDialog.show({
      message: '确定要结束夜路守护吗？',
      alignment: DialogAlignment.Center,
      buttons: [
        {
          value: '取消', fontColor: $r('app.color.font_sub'), action: () => {
        }
        },
        {
          value: '确定', fontColor: $r('app.color.brand'), action: () => {
          router.back()
        }
        }
      ]
    })
  }

  build() {
    Column() {
      Column() {
        if (this.isShowMap) {
          MapComponent({ mapOptions: this.mapOption, mapCallback: this.callback })
            .width('100%')
            .height('100%')
        }
      }
      .layoutWeight(1)

      Column() {
        Row() {
          Row() {
            Text('“深夜人少时，尽量不要和陌生男子共乘同一步电梯”')
              .fontSize(14)
              .fontWeight(500)
              .lineHeight(20)
              .fontColor('#AEAEE6')
              .layoutWeight(1)
              .margin({ top: 25 })
            Image('/common/images/GuardIndoorPage_bozai.png')
              .height(120)
              .width(103)
              .margin({ right: 30 })
          }
          .padding({ left: 20, right: 20 })
          .margin({ top: -30 })
        }
        .width('100%')
        .height(80)
        .backgroundColor('#30307A')

        Column() {
          // 定位文本
          Row() {
            Stack() {
              Row()
                .backgroundColor('#FF4F4F')
                .width(15)
                .height(15)
                .borderRadius(15 / 2)
              Row()
                .backgroundColor('#29FF4F4F')
                .width(15)
                .height(15)
                .borderRadius(15 / 2)
                .scale({ x: 36 / 15, y: 36 / 15 })
            }
            .width(68)

            Column() {
              Text(this.placeName)
                .fontSize(14)
                .fontWeight(500)
                .fontColor('#fff')
                .width('100%')
                .textOverflow({
                  overflow: TextOverflow.Ellipsis
                })
                .maxLines(2)
              Text('您的当前位置正在向紧急恋人实时分享中')
                .fontSize(12)
                .fontColor('#AEAEE6')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .padding({ right: 15 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .height(76)
          .borderRadius(8)
          .backgroundColor('#1affffff')
          .margin({ top: 20 })

          // 夜路防护工具
          Column({ space: 20 }) {
            Row() {
              Image($r('app.media.ic_arrow_right_small'))
                .height(20)
              Text('夜路防护工具')
                .fontSize(16)
                .fontWeight(500)
                .fontColor('#fff')
            }

            Row() {
              ToolButton({ icon: $r('app.media.ic_guard_tool_sdt'), text: '手电筒' })
                .onClick(() => {
                  // TODO：切换手电筒
                  torchManager.toggleTorch()
                })
              ToolButton({ icon: $r('app.media.ic_guard_tool_dyljb'), text: '大音量警报' })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/Guard/Alarm/GuardAlarmPage' })
                })
              ToolButton({ icon: $r('app.media.ic_guard_tool_wzld'), text: '伪装来电' })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/Guard/Fake/FakeTelPage' })
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .margin({ top: 20 })
          .alignItems(HorizontalAlign.Start)

          Column({ space: 20 }) {
            // 标题
            Row() {
              Image($r('app.media.ic_arrow_right_small'))
                .height(20)
              Text('突发情况，快速求助')
                .fontSize(16)
                .fontWeight(500)
                .fontColor('#fff')
            }
            .width('100%')

            GridRow({ gutter: 10, columns: 3 }) {
              GridCol() {
                HelpButton({ icon: $r('app.media.ic_guard_help_hjjjlxr'), text: '呼叫紧急联系人' })
                  .onClick(() => {
                    // TODO：呼叫紧急联系人
                    this.makePhoneCall(this.emergencyPhone)
                  })
              }

              GridCol() {
                HelpButton({ icon: $r('app.media.ic_guard_help_fjpcs'), text: '查看附件派出所' })
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/Guard/Outdoor/GuardPolicePage' })
                  })
              }

              GridCol() {
                HelpButton({ icon: $r('app.media.ic_guard_help_110bj'), text: '110报警' })
                  .onClick(() => {
                    // TODO：拨打报警电话
                    this.makePhoneCall("110")
                  })
              }
            }
          }
          .margin({ top: 20 })
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: 20, right: 20, bottom: 30 })

        Column() {
          Button('结束守护')
            .type(ButtonType.Normal)
            .width('100%')
            .borderRadius(10)
            .backgroundColor(Color.Transparent)
            .linearGradient({
              angle: 150,
              colors: [['#FE956F', 0], ['#FFB772', 1]]
            })
            .onClick(() => {
              router.back()
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .backgroundColor('#2F314F')
        .borderRadius({ topLeft: 12, topRight: 12 })
        .padding({
          top: 20,
          left: 20,
          right: 20,
          bottom: 20 + this.bottomHeight
        })
      }
      .linearGradient({
        angle: 180,
        colors: [['#34398C', 0], ['#4E4492', 0.5], ['#8A76BB', 1]]
      })
      .width('100%')
      .borderRadius({
        topLeft: 12,
        topRight: 12,
        bottomLeft: 0,
        bottomRight: 0
      })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct ToolButton {
  @Prop icon: ResourceStr
  @Prop text: string

  build() {
    Column() {
      Image(this.icon)
        .width(42)
        .aspectRatio(1)
      Text(this.text)
        .fontSize(12)
        .fontWeight(500)
        .fontColor('#fff')
        .margin({ top: 10 })
    }
  }
}

@Component
struct HelpButton {
  @Prop icon: ResourceStr
  @Prop text: string

  build() {
    Column({ space: 5 }) {
      Image(this.icon)
        .width(26)
        .aspectRatio(1)
      Text(this.text)
        .fontSize(12)
        .fontColor('#fff')
    }
    .backgroundColor('#1affffff')
    .borderRadius(8)
    .height(72)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}