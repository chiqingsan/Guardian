import { promptAction, router } from '@kit.ArkUI'
import { calendarManager } from '@kit.CalendarKit'
import { NavigationTitleBuilder } from '../../common/builders'
import { themeManager, userCalendarManager } from '../../manager'

@Entry
@Component
struct CalendarIndexPage {
  @StorageProp("topHeight") topHeight: number = 0
  @State isSafe: boolean = true
  @State overdueEvents: calendarManager.Event[] = []
  @State fraudEvents: calendarManager.Event[] = []
  @State isLoading: boolean = false

  onPageShow() {
    themeManager.settingStatusBarWhite()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  aboutToAppear(): void {
    userCalendarManager.requestPermission()
  }

  @Builder
  NavigationMenus() {
    Row() {
      Image($r('app.media.ic_public_search'))
        .width(22)
        .aspectRatio(1)
        .onClick(() => {
          router.pushUrl({ url: 'pages/Calendar/CalendarSearchPage' })
        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Navigation() {
      Stack() {
        if (!this.isLoading) {
          // 主界面
          Column() {
            Column() {
              if (this.fraudEvents.length === 0) {
                Column() {
                  Image($r("app.media.ic_calendar_safe"))
                    .height(88)
                    .margin({ top: 30 })
                  Text('暂未发现诈骗日历')
                    .fontSize(16)
                    .fontColor($r('app.color.white'))
                    .margin({ top: 15, bottom: 5 })
                  Text('建议您输入关键词搜索')
                    .fontSize(14)
                    .fontColor($r('app.color.white'))
                  Button('立即搜索')
                    .height(28)
                    .fontSize(14)
                    .type(ButtonType.Normal)
                    .border({ width: 1, color: $r('app.color.white'), radius: 6 })
                    .fontColor($r('app.color.white'))
                    .backgroundColor(Color.Transparent)
                    .margin({ top: 20 })
                    .onClick(() => {
                      router.pushUrl({ url: 'pages/Calendar/CalendarSearchPage' })
                    })
                }
              } else {
                Column() {
                  Image($r('app.media.ic_calendar_cheat'))
                    .height(88)
                    .margin({ top: 30 })
                  Text(`发现 ${this.fraudEvents.length} 条诈骗日历`)
                    .fontSize(16)
                    .fontColor($r('app.color.white'))
                    .margin({ top: 15, bottom: 5 })
                  Text('建议您立即清理，防止上当受骗')
                    .fontSize(14)
                    .fontColor($r('app.color.white'))
                  Button('立即清理')
                    .height(28)
                    .fontSize(14)
                    .type(ButtonType.Normal)
                    .border({ width: 1, color: $r('app.color.white'), radius: 6 })
                    .fontColor($r('app.color.white'))
                    .backgroundColor(Color.Transparent)
                    .margin({ top: 20 })
                    .onClick(() => {
                      router.pushUrl({ url: 'pages/Calendar/CalendarFraudPge' })
                    })
                }
              }
            }
            .height(250)

            Column({ space: 10 }) {
              CellRow({
                icon: $r('app.media.ic_calendar_overdue'),
                title: '过期日历',
                desc: '发现 - 条过期日历',
                empty: '未发现过期日历',
                count: this.overdueEvents.length
              })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/Calendar/CalendarOverduePage' })
                })

            }
            .padding(10)
            .layoutWeight(1)
            .backgroundColor($r('app.color.white'))

            Column({ space: 10 }) {
              Button('添加普通日程')
                .onClick(async () => {
                  //
                  const id = await userCalendarManager.addEvent({
                    type: calendarManager.EventType.NORMAL,
                    title: `${new Date(Date.now()).toLocaleTimeString()}_普通日程`,
                    startTime: Date.now(),
                    endTime: Date.now() + 1000 * 60
                  } as calendarManager.Event)
                  promptAction.showToast({ message: "添加普通日程成功,id为:" + id })

                })
              Button('添加重要日程')
                .onClick(async () => {
                  //
                  const id = await userCalendarManager.addEvent({
                    type: calendarManager.EventType.IMPORTANT,
                    title: `${new Date(Date.now()).toLocaleTimeString()}_重要日程`,
                    reminderTime: [0, 5, 10, 60],
                    startTime: Date.now(),
                    endTime: Date.now() + 1000 * 60
                  } as calendarManager.Event)
                  promptAction.showToast({ message: "添加重要日程成功,id为:" + id })

                })
              Button('添加过期日程')
                .onClick(async () => {
                  //
                  const id = await userCalendarManager.addEvent({
                    type: calendarManager.EventType.NORMAL,
                    startTime: Date.now() - 1000 * 60 * 60,
                    endTime: Date.now() - 1000 * 60
                  } as calendarManager.Event)
                  promptAction.showToast({ message: "添加过期日程成功,id为:" + id })

                })
              Button("查询日历")
                .onClick(async () => {
                  const conditions = calendarManager.EventFilter.filterById([1, 2, 3])
                  const res = await userCalendarManager.queryTheSchedule(conditions)
                  AlertDialog.show({ message: JSON.stringify(res, null, 2) })
                })
            }
          }
          .height('100%')
        } else {
          // Loading 效果
          Column({ space: 20 }) {
            Image($r('app.media.ic_calendar_loading'))
              .width(100)
            Text('正在检测日历')
              .fontSize(16)
              .fontColor($r('app.color.white'))
          }
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
    }
    .title(NavigationTitleBuilder('日历清理'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .menus(this.NavigationMenus())
    .linearGradient({
      angle: 180,
      colors: !this.isLoading ?
        [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.5], [$r('app.color.white'), 0.5]] :
        [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 1]]
    })
    .padding({ top: this.topHeight })
  }
}

@Component
struct CellRow {
  icon: ResourceStr = $r('app.media.ic_calendar_overdue')
  @Prop title: string = '过期日历'
  @Prop desc: string = '发现-条过期日历'
  @Prop empty: string = ''
  @Prop count: number = 220

  build() {
    Row({ space: 10 }) {
      Image(this.icon)
        .width(40)
        .aspectRatio(1)
      Column({ space: 5 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(500)
          .fontColor($r('app.color.font'))
        Text() {
          if (this.count > 0) {
            Span(this.desc.split('-')[0])
            Span(this.count.toString())
              .fontColor($r('app.color.brand'))
            Span(this.desc.split('-')[1])
          } else {
            Span('未发现过期日历')
          }
        }
        .fontSize(12)
        .fontColor($r('app.color.font_sub'))
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 20 })
    .height(72)
    .border({ width: 1, color: $r('app.color.border'), radius: 6 })
    .width('100%')
  }
}