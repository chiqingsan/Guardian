import { abilityAccessCtrl, bundleManager, common, Permissions, Want } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct MyTestPage {
  calendarPermissionGroups: Permissions[] = ["ohos.permission.READ_CALENDAR", "ohos.permission.WRITE_CALENDAR"]

  // 检查是否授权
  checkPermissions(permissions: Permissions[]) {
    // 程序访问控制管理
    const atManager = abilityAccessCtrl.createAtManager();
    // 获取 bundle 信息
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    // 提取 tokenID 标识
    const tokenID = bundleInfo.appInfo.accessTokenId
    // 校验应用是否被授予权限
    const authResults = permissions.map((item) => atManager.checkAccessTokenSync(tokenID, item))
    // 返回是否已授权结果
    // return authResults.every(v => v === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    return authResults
  }

  // 拉起弹框请求用户授权
  async requestPermissions(permissions: Permissions[]) {
    // 程序访问控制管理
    const atManager = abilityAccessCtrl.createAtManager();
    // 拉起弹框请求用户授权
    const grantStatus = await atManager.requestPermissionsFromUser(getContext(), permissions)
    // 相应请求权限的结果
    // return grantStatus.authResults.every(v => v === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    return grantStatus
  }

  build() {
    Row() {
      Column({ space: 12 }) {
        Button("检测权限")
          .onClick(() => {
            const results = this.checkPermissions(this.calendarPermissionGroups)
            AlertDialog.show({ message: JSON.stringify(results, null, 2) })
          })
        Button("申请权限")
          .onClick(async () => {
            const result = await this.requestPermissions(this.calendarPermissionGroups)
            AlertDialog.show({ message: JSON.stringify(result, null, 2) })
          })
        Button("处理授权结果")
          .onClick(async () => {

            const content = getContext() as common.UIAbilityContext
            const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)

            const wantCfg: Want = {
              bundleName: 'com.huawei.hmos.settings',
              abilityName: 'com.huawei.hmos.settings.MainAbility',
              uri: 'application_info_entry',
              parameters: {
                // 按照包名打开对应设置页
                pushParams: bundleInfo.name
              }
            }

            content.startAbility(wantCfg)

          })

        Button("申请权限流程")
          .onClick(async () => {
            // 查询是否已经授权
            const permissionsResult = this.checkPermissions(this.calendarPermissionGroups).every(val => val === -1)
            if (permissionsResult) {


              try {
                // 拉起弹窗,拿到用户是否同意的结果
                const applicationResult = await this.requestPermissions(this.calendarPermissionGroups)
                // 判断同意或者拒绝
                if (applicationResult.authResults.every(val => val === 0)) {
                  AlertDialog.show({ message: JSON.stringify("申请完成,权限已开启", null, 2) })
                } else {
                  AlertDialog.show({ message: JSON.stringify("权限申请失败,用户已拒绝", null, 2) })
                }
              } catch (e) {
                AlertDialog.show({ message: JSON.stringify(e, null, 2) })
              }

            } else {
              // 如果之前同意了,则提示之前已授权
              promptAction.showToast({ message: "已经授权过了" })
            }
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}