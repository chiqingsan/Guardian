import { dataSharePredicates } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import dayjs from 'dayjs';
import { KILO_BYTE } from '../../common/utils';
import { permissionManager } from '../../manager';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';


@Entry
@Component
struct ImageCompression {
  @State imageUri: string = ''
  @State imageSize: number = 0
  @State imageDateAdded: number = 0
  // 相册
  @State albumCoverUri: string = ''
  @State albumAlbumName: string = ''
  @State albumCount: number = 0
  @State imgPixelMap: PixelMap = {} as PixelMap

  aboutToAppear() {
    this.requestPermission()
  }

  // 官方文档：https://docs.openharmony.cn/pages/v4.1/zh-cn/application-dev/reference/apis-media-library-kit/js-apis-photoAccessHelper.md#getassets-2
  async example() {
    // 获取相册管理模块的实例，用于访问和修改相册中的媒体文件。
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    // 查询条件
    let predicates = new dataSharePredicates.DataSharePredicates()
    // 获取图片和视频资源 核心 API： getAssets，
    let fetchResult = await phAccessHelper.getAssets({
      // 检索条件，指定列名查询，如果该参数为空时默认查询uri、name、photoType
      fetchColumns: [photoAccessHelper.PhotoKeys.SIZE, photoAccessHelper.PhotoKeys.DATE_ADDED],
      predicates: predicates  // 谓词查询，显示过滤条件。
    })
    // 获取第一 图片/视频 资源
    let photoAsset = await fetchResult.getLastObject()
    // AlertDialog.show({ message: JSON.stringify(photoAsset.uri, null, 2) })
    // uri 格式 "file://xxxx"   是图片资源定位符（可以理解为访问路径）
    this.imageUri = photoAsset.uri
    // photoAsset.displayName // 媒体名称
    // photoAsset.photoType // 媒体类型（1为图片 / 2为视频）
    // ------- 获取 文件大小（单位：字节）等更多信息 -----
    // 1. 在 fetchColumns 中添加其他属性字段（容易忘记）
    // 2. 用 get 接口去获取其他属性，返回值为联合类型，再通过 as 断言指定类型
    this.imageSize = photoAsset.get(photoAccessHelper.PhotoKeys.SIZE) as number
    // 添加日期（添加文件时间距1970年1月1日的秒数值），秒数值转换成毫秒值需要 * 1000
    this.imageDateAdded = photoAsset.get(photoAccessHelper.PhotoKeys.DATE_ADDED) as number
  }

  // 申请图库（图片与视频）权限
  async requestPermission() {
    try {
      // 申请权限
      await permissionManager.requestPermissions(
        [
          'ohos.permission.READ_IMAGEVIDEO',
          'ohos.permission.WRITE_IMAGEVIDEO'
        ]
      )
    } catch {
      // 未开启弹窗提示
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '手机瘦身功能需要获取权限，请在系统设置中打开图片与视频开关',
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

  // 删除图片
  // deleteAssets11+
  // static deleteAssets(context: Context, assets: Array<PhotoAsset>): Promise<void>
  // 删除媒体文件，删除的文件进入到回收站，使用Promise方式返回结果。
  async deletePhotos() {
    // 1. 找出待删除的图片资源，类型为 PhotoAsset
    //  1.1 获取相册管理模块的实例
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    //  1.2 准备查询条件
    const predicates = new dataSharePredicates.DataSharePredicates()
    //  1.3 获取资源，返回值类型为  photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>
    const fetchResult = await phAccessHelper.getAssets({
      fetchColumns: [],
      predicates: predicates
    })
    //  1.4 获取图片资源，删除图片 API 的第二个参数 photoAccessHelper.PhotoAsset[]
    const photoAsset = await fetchResult.getLastObject()
    // 2. 调用 deleteAssets API 实现删除
    photoAccessHelper.MediaAssetChangeRequest.deleteAssets(getContext(), [photoAsset])
  }

  // 获取用户相册
  // phAccessHelper.getAlbums
  async getAlbums() {
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    // getAssets   获取 图片/视频
    // getAlbums   获取 相册
    const fetchResult = await phAccessHelper.getAlbums(
      photoAccessHelper.AlbumType.USER, // 一级相册类型（用户相册，系统相册）
      photoAccessHelper.AlbumSubtype.USER_GENERIC // 二级相册类型（用户相册，收藏夹 等）
    )
    // 获取第一个对象
    const album = await fetchResult.getFirstObject()
    // 相册封面图
    this.albumCoverUri = album.coverUri
    // 相册名称
    this.albumAlbumName = album.albumName
    // 相册数量
    this.albumCount = album.count
  }

  async compressThePicture() {
    // AlertDialog.show({ message: JSON.stringify(this.imageUri, null, 2) })
    await this.example()
    const pictureData = fileIo.openSync(this.imageUri)
    const imagePacker = image.createImagePacker()
    const imageSource = image.createImageSource(pictureData.fd)
    const imgArr = await imagePacker.packing(imageSource, { format: "image/jpeg", quality: 80 })
    // AlertDialog.show({ message: JSON.stringify(imgArr.byteLength, null, 2).slice(0, 1000) })
    // const imgPixelMap = await image.createPixelMap(imgArr, {
    //   alphaType: 0,
    //   editable: true,
    //   pixelFormat: 0,
    //   scaleMode: 0,
    //   size: { height: 100, width: 100 }
    // })
    // imageSource.createPixelMap()
    // 完成压缩后图片回显
    const newImageSource = image.createImageSource(imgArr)
    const imgPixelMap = await newImageSource.createPixelMap()
    this.imgPixelMap = imgPixelMap

    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
    const assetUri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, "jpg", {
      title: `${Date.now()}_Image`
    })
    const assetFile = fileIo.openSync(assetUri, fileIo.OpenMode.READ_WRITE)
    fileIo.writeSync(assetFile.fd, imgArr)
    // 关闭读写的文件实例
    fileIo.close(assetFile.fd)
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Button('获取图片信息')
            .onClick(() => {
              this.example()
            })
          Image(this.imageUri)
            .width(100)
          Text('图片文件大小：' + (this.imageSize / KILO_BYTE).toFixed(2) + 'KB')
          Text('图片添加日期(秒数值)：' + this.imageDateAdded)
          Text('Date.now()时间戳：' + Date.now())
          if (this.imageDateAdded > 0) {
            Text('时间格式化：' + dayjs(this.imageDateAdded * 1000)
              .format('YYYY-MM-DD HH:mm:ss'))
          }

          Button('删除图片到回收站')
            .onClick(() => {
              this.deletePhotos()
            })

          Button('获取用户相册')
            .onClick(() => {
              this.getAlbums()
            })
          Button("压缩图片")
            .onClick(() => {
              this.compressThePicture()
            })
          Column() {
            Image(this.albumCoverUri)
              .width(100)
              .height(100)
            Text(this.albumAlbumName)
            Text(this.albumCount.toString())
            Image(this.imgPixelMap)
              .width(250)
          }

        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('Media Library Kit（媒体文件管理服务）')
    .titleMode(NavigationTitleMode.Mini)
  }
}