import { Permissions } from '@kit.AbilityKit'
import { dataSharePredicates } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { permissionManager } from '.'
import photoAccessHelper from '@ohos.file.photoAccessHelper'
import { deviceInfo } from '@kit.BasicServicesKit'
import { KILO_BYTE, MEGA_BYTE } from '../common/utils'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'


class CleanerManager {
  // 权限
  private permissions: Permissions[] = ["ohos.permission.READ_IMAGEVIDEO", "ohos.permission.WRITE_IMAGEVIDEO"]
  // 图片字段
  private columns: photoAccessHelper.PhotoKeys[] = [
    photoAccessHelper.PhotoKeys.DATE_ADDED,
    photoAccessHelper.PhotoKeys.SIZE,
  ]

  // 图片权限
  async requestPermissions() {
    try {
      // 申请权限
      await permissionManager.requestPermissions(this.permissions)
    } catch {
      // 未开启弹窗提示
      const dialogRes = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '手机瘦身功能需要获取权限，请在系统设置中打开相册开关',
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

  // 获取图片/视频
  async getAssets() {
    const context = getContext()
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context) // 获取照片访问助手
    const predicates = new dataSharePredicates.DataSharePredicates() // 创建查询条件
    const fetchOption: photoAccessHelper.FetchOptions = {
      fetchColumns: this.columns,
      predicates: predicates
    }
    const assets = await phAccessHelper.getAssets(fetchOption) // 获取资源
    const photoAssets = await assets.getAllObjects() // 获取所有图片
    // this.photoAssets = photoAssets
    // phAccessHelper.release()
    return photoAssets
  }

  // 获取屏幕截图列表
  async getScreenshotList() {
    const photoAssets = await this.getAssets()
    return photoAssets.filter((item) => item.displayName.includes('screenshot'))
  }

  // 获取视频列表
  async getVideoList() {
    const photoAssets = await this.getAssets()
    return photoAssets.filter((item) => item.photoType === photoAccessHelper.PhotoType.VIDEO)
  }

  // 删除图片
  async deletePhotos(uris: string[]) {
    const photoAssets = await this.getAssets()
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext()) // 获取照片访问助手
    // 转换成 PhotoAsset 对象
    const deleteAssets = photoAssets.filter(v => uris.includes(v.uri))
    try {
      await photoAccessHelper.MediaAssetChangeRequest.deleteAssets(getContext(), deleteAssets)
      return true
    } catch (e) {
      return false
    }

    // await phAccessHelper.createDeleteRequest(deleteAssets.map(v => v.uri))

  }

  // 获取大尺寸图片，用于压缩
  async getLargeSizeList() {
    // 获取图片资源
    const photoAssets = await this.getAssets()
    // 大图片的临界点
    const largeSize = deviceInfo.marketName === 'emulator' ? 500 * KILO_BYTE : 2 * MEGA_BYTE
    // 根据临界点筛选出大图
    return photoAssets.filter(v => {
      return (v.get(photoAccessHelper.PhotoKeys.SIZE) as number) > largeSize
    })
  }

  // 压缩图片
  async compressThePicture(uri: string, quality: number = 80) {
    const pictureData = fileIo.openSync(uri)
    const imagePacker = image.createImagePacker()
    const imageSource = image.createImageSource(pictureData.fd)
    const imgArr = await imagePacker.packing(imageSource, { format: "image/jpeg", quality })

    // 完成压缩后图片回显
    // const newImageSource = image.createImageSource(imgArr)
    // const imgPixelMap = await newImageSource.createPixelMap()
    // this.imgPixelMap = imgPixelMap

    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    const assetUri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, "jpg", {
      title: `compressThePicture_${Date.now()}`
    })
    const assetFile = fileIo.openSync(assetUri, fileIo.OpenMode.READ_WRITE)
    fileIo.writeSync(assetFile.fd, imgArr)
    // 关闭读写的文件实例
    fileIo.close(assetFile.fd)

  }
}

export const cleanerManager = new CleanerManager()