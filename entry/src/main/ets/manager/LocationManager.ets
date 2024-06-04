import { Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { permissionManager } from '.';
import { promptAction } from '@kit.ArkUI';

class LocationManager {
  private permissions: Permissions[] = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION',
  ];

  // 申请权限
  async requestPermissions() {
    try {
      // 申请权限
      await permissionManager.requestPermissions(this.permissions)
    } catch {
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '定位功能需要获取权限，请在系统设置中打开定位开关',
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

  // 获取当前位置信息
  async getCurrentAddress() {
    // 1. 获取经纬度
    const location = await geoLocationManager.getCurrentLocation()
    // 2. 把经纬度解析成地址
    const geoAddress = await geoLocationManager.getAddressesFromLocation({
      locale: 'zh', // zh 中文信息
      latitude: location.latitude,
      longitude: location.longitude,
      maxItems: 1
    })
    return geoAddress
  }
}

export const locationManager = new LocationManager()