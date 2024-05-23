import { Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { calendarManager } from '@kit.CalendarKit';
import { permissionManager } from './PermissionManager';

class UserCalendarManager {
  private permissions: Permissions[] = ["ohos.permission.READ_CALENDAR", "ohos.permission.WRITE_CALENDAR"];

  // 授权弹窗
  async requestPermission() {
    // 申请权限
    const isAuth = await permissionManager.requestPermissions(this.permissions)
    if (isAuth === false) {
      // 未开启弹窗提示
      const dialogRes = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '日历清理功能需要获取权限，请在系统设置中打开日历开关',
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

  // 获取默认日历
  getDefaultCalendar() {
    const calendarMgr = calendarManager.getCalendarManager(getContext())

    return calendarMgr.getCalendar()
  }

  // 添加日历
  async addEvent(event: calendarManager.Event) {
    const calendar = await this.getDefaultCalendar()
    return calendar.addEvent(event)
  }

  // 查询日程
  async queryTheSchedule(event?: calendarManager.EventFilter) {
    const calendar = await this.getDefaultCalendar()
    return event ? calendar.getEvents(event) : calendar.getEvents()
    // return calendar.getEvents(event)
  }

  // 根据标题查询日程
  async searchForAnEvent(keywords: string) {
    const calendar = await this.getDefaultCalendar()
    // 查询条件
    const queryCriteria = calendarManager.EventFilter.filterByTitle(keywords)
    // 返回结果
    return calendar.getEvents(queryCriteria)
  }
}

export const userCalendarManager = new UserCalendarManager()