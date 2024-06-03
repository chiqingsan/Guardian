import { Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { contact } from '@kit.ContactsKit'
import { isEmulator } from '../common/dev'
import { permissionManager } from './PermissionManager'

class ContactManager {
  private permissions: Permissions[] = [
    "ohos.permission.READ_CONTACTS",
    "ohos.permission.WRITE_CONTACTS"
  ]

  // 授权弹窗
  async requestPermissions() {
    try {
      // 申请权限
      await permissionManager.requestPermissions(this.permissions)
    } catch {
      // 未开启弹窗提示
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '通讯录功能需要获取权限，请在系统设置中打开通讯录开关',
        buttons: [
          { text: '取消', color: $r('app.color.font_sub') },
          { text: '立即开启', color: $r('app.color.brand') }
        ]
      })
        .then((res) => {
          // 打开设置页
          if (res.index === 1) {
            permissionManager.openPermissionSettingsPage()
          }
        })
    }
  }

  // 获取通讯录所有联系人
  async getContact(): Promise<contact.Contact[]> {
    // 由于模拟器没有通讯录软件，无法获取通讯录信息，可自己模拟一份通讯录数组，用于业务测试
    if (isEmulator()) {
      return [
        {
          name: { fullName: '孙悟空' },
          phoneNumbers: [{ phoneNumber: "10086" }],
          key: "1",
          id: 1
        },
        {
          name: { fullName: '猪八戒' },
          phoneNumbers: [{ phoneNumber: "10000" }],
          key: "2",
          id: 2
        }
      ]
    }
    // 获取通讯录联系人
    return contact.queryContacts(getContext())
  }

  // 获取通讯录群组
  async getGroups(): Promise<contact.Group[]> {
    if (isEmulator()) {
      return [
        { title: '取经小分队', groupId: 1 },
        { title: '天庭小分队', groupId: 2 },
      ]
    }
    // 获取通讯录群组
    return contact.queryGroups(getContext())
  }
}

export const contactManager = new ContactManager()