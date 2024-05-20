import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { NavigationTitleBuilder } from '../../common/builders';
import { themeManager } from '../../manager';
import { permissionManager } from '../../manager/PermissionManager';
import { promptAction } from '@kit.ArkUI';
import { result } from '@wolfx/lodash';
import { notificationManager } from '@kit.NotificationKit';
import { MyPreferences } from '../../common/utils/Preference';

interface PermissionItem {
  name: string
  title: string
  desc: string
  permissions: Permissions[]
  timeStamp: number // 用于更新授权状态
}

@Entry
@Component
struct SettingsPermissionPage {
  @StorageProp("topHeight") topHeight: number = 0
  @State isNotificationEnabled: boolean = false
  @State PageState: boolean = false
  @State permissionList: PermissionItem[] = [
    {
      name: 'notification',
      title: '通知',
      desc: '开启后可以获得安全播报，号码包升级等',
      permissions: [],
      timeStamp: 0
    },
    // 对所有应用开放的权限
    {
      name: 'camera',
      title: '相机',
      desc: '开启后才能使用安全扫码等功能',
      permissions: ['ohos.permission.CAMERA'],
      timeStamp: 0
    },
    {
      name: 'microphone',
      title: '麦克风',
      desc: '开启后才能录制加密视频和音频',
      permissions: ['ohos.permission.MICROPHONE'],
      timeStamp: 0
    },
    {
      name: 'calendar',
      title: '日历',
      desc: '开启后才能帮您清理诈骗日历、过期日历',
      permissions: ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'],
      timeStamp: 0
    },
    {
      name: 'location',
      title: '位置',
      desc: '开启后精准显示空气指数，识别骚扰号码更加精准',
      permissions: ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'],
      timeStamp: 0
    },
    // 允许ACL跨级别申请的权限
    {
      name: 'image_video',
      title: '照片',
      desc: '开启后才能帮您通过照片瘦身节省空间',
      permissions: ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO'],
      timeStamp: 0
    },
    {
      name: 'contacts',
      title: '通讯录',
      desc: '开启后才能帮您进行通讯录的备份、恢复和优化',
      permissions: ['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS'],
      timeStamp: 0
    },
  ]

  onPageShow() {
    themeManager.settingStatusBarWhite()
    this.PageState = true
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
    this.PageState = false
  }

  build() {
    Navigation() {
      Row() {
        Text('建议您开启全部权限\n体验小卫更精准、更贴心的功能！')
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .lineHeight(20)
          .textAlign(TextAlign.Center)
      }
      .height(180 - 56)

      Column() {
        ForEach(this.permissionList, (item: PermissionItem) => {
          Row() {
            Column({ space: 5 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(500)
                .fontColor($r('app.color.font'))
              Text(item.desc)
                .fontSize(12)
                .fontColor($r('app.color.font_sub'))
            }
            .alignItems(HorizontalAlign.Start)

            // 开启权限开关组件
            SetToggle({ item: item, PageIsShow: this.PageState })

          }
          .width('100%')
          .height(64)
          .justifyContent(FlexAlign.SpaceBetween)
        })
        Button('关闭权限')
          .fontColor($r('app.color.font_sub'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 20 })
          .onClick(async () => {
            //关闭权限
            const res = await promptAction.showDialog({
              message: "建议开启全部权限，关闭权限后会影响应用功能",
              buttons: [
                { text: "取消", color: $r("app.color.brand") },
                { text: "确认", color: "#89939C" }
              ]
            })

            if (res.index === 1) {
              permissionManager.openPermissionSettingsPage()
            }

          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder('权限管理'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.25], [$r('app.color.white'), 0.25]]
    })
    .padding({ top: this.topHeight })
  }
}

@Component
struct SetToggle {
  // 控制是否是首次开启
  @State first: boolean = true
  // 控制是否打开开关
  @State isOn: boolean = false
  // 控制是否切换样式
  @State isShow: boolean = false
  item: PermissionItem = {} as PermissionItem
  @Prop @Watch("updateTheStatus") PageIsShow: boolean = false

  aboutToAppear(): void {
    this.first = MyPreferences.getData(this.item.name, true)
  }

  async updateTheStatus() {
    if (this.PageIsShow) {

      if (this.item.name === "notification") {
        this.isShow = await notificationManager.isNotificationEnabled()
      } else {
        this.isShow = permissionManager.checkPermissions(this.item.permissions)
      }
      this.isOn = this.isShow
    }
  }

  build() {
    // 是否已开启权限
    if (this.isShow) {
      Text('已开启')
        .fontSize(14)
        .fontColor($r('app.color.brand'))
    } else {
      Toggle({ type: ToggleType.Switch, isOn: $$this.isOn })
        .onChange(async (val) => {

          // 如果开关为打开
          if (val) {
            try { // 拿到权限开启结果
              if (this.item.name === "notification") {
                await notificationManager.requestEnableNotification()
              } else {
                await permissionManager.requestPermissions(this.item.permissions)
                // AlertDialog.show({ message: JSON.stringify(permissionsResult, null, 2) })
                // 如果开启则切换显示
              }
              this.isShow = true
              this.first = false
              MyPreferences.saveData(this.item.name, this.first)

            } catch (e) {

              if (this.first) {
                // 只提示已拒绝
                promptAction.showToast({ message: "权限已拒绝" })
                // 第一次打开改为否
                this.first = false
                MyPreferences.saveData(this.item.name, this.first)
              } else {
                // 未开启弹窗提示
                const dialogRes = await promptAction.showDialog({
                  alignment: DialogAlignment.Center,
                  title: '温馨提示',
                  message: `${this.item.title}权限已被禁止，请在系统设置中打开权限开关`,
                  buttons: [
                    { text: '取消', color: $r('app.color.error') },
                    { text: '立即开启', color: $r('app.color.brand') }
                  ]
                })
                // 打开设置页
                if (dialogRes.index === 1) {
                  permissionManager.openPermissionSettingsPage()
                }
              }
              this.isOn = false
            }
          }
        })
    }
  }
}

