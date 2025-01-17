import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { NavigationTitleBuilder } from '../../common/builders'
import { formatByteLength } from '../../common/utils'
import { cleanerManager, themeManager } from '../../manager'
import { promptAction, router } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'

interface RouterParams {
  name: string
}

@Entry
@Component
struct CleanerSelectPage {
  @StorageProp("topHeight") topHeight: number = 0
  @State routerParams: RouterParams | null = null
  @State list: photoAccessHelper.PhotoAsset[] = []
  @State selectedNames: string[] = []
  @State selectedSize: number = 0
  @State @Watch('onSelectChange') selectNames: string[] = []
  @State selectedList: photoAccessHelper.PhotoAsset[] = []

  aboutToAppear() {
    const params = router.getParams() as RouterParams
    if (params) {
      this.routerParams = params
      this.getList()
    }
  }

  onSelectChange() {
    this.selectedList = this.list.filter((v) => this.selectNames.includes(v.uri))
    this.selectedSize = this.selectedList.reduce((acc, item) => {
      return acc + (item.get(photoAccessHelper.PhotoKeys.SIZE) as number) * 0.8
    }, 0)
  }

  async getList() {
    if (this.routerParams?.name === '屏幕截图') {
      this.list = await cleanerManager.getScreenshotList()
    } else if (this.routerParams?.name === '视频文件') {
      this.list = await cleanerManager.getVideoList()
    }
  }

  onPageShow() {
    themeManager.settingStatusBarWhite()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  build() {
    Navigation() {
      Column() {
        Column({ space: 10 }) {
          Text() {
            Span('可节省')
            Span(formatByteLength(this.selectedSize))
          }
          .fontSize(16)
          .fontColor($r('app.color.white'))

          Text(`已选择${this.selectedNames.length}张`)
            .fontSize(12)
            .fontColor($r('app.color.white'))
        }
        .justifyContent(FlexAlign.Center)
        .height(66)

        Scroll() {
          Column() {
            GridRow({ columns: 4, gutter: 8 }) {
              ForEach(this.list, (asset: photoAccessHelper.PhotoAsset) => {
                GridCol() {
                  Stack({ alignContent: Alignment.TopStart }) {
                    if (asset.photoType === photoAccessHelper.PhotoType.IMAGE) {
                      // 图片
                      Image(asset.uri)
                        .width('100%')
                        .aspectRatio(1)
                        .borderRadius(6)
                    } else if (asset.photoType === photoAccessHelper.PhotoType.VIDEO) {
                      // 视频
                      Video({ src: asset.uri })
                        .width('100%')
                        .aspectRatio(1)
                        .borderRadius(6)
                        .autoPlay(true)
                        .muted(true)
                        .controls(false)
                    }
                    Checkbox({ name: asset.uri })
                  }
                  .width('100%')
                  .aspectRatio(1)
                }
              }, ((item: photoAccessHelper.PhotoAsset) => item.uri))

            }

            Blank()
              .layoutWeight(1)
          }
          .padding(15)
        }
        .height('100%')
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .layoutWeight(1)

      Row({ space: 10 }) {
        Column() {
          CheckboxGroup()
            .onChange((event) => {
              this.selectedNames = event.name
            })
          Text('全选')
            .fontColor($r('app.color.font2'))
            .fontSize(12)
        }

        Button('删除')
          .type(ButtonType.Normal)
          .borderRadius(10)
          .layoutWeight(1)
          .height(42)
          .backgroundColor($r('app.color.danger'))
          .onClick(async () => {
            // 删除选中图片
            if (this.selectedNames.length) {
              const res = await cleanerManager.deletePhotos(this.selectedNames)

              if (res) {
                this.list = this.list.filter(item =>!this.selectedNames.includes(item.uri))
              }
              promptAction.showToast({ message: res ? "删除成功" : "取消删除" })
            } else {
              promptAction.showToast({ message: "选定图片后才可删除哦~" })
            }
          })
      }
      .border({ width: { top: 1 }, color: $r('app.color.border') })
      .width('100%')
      .height(76)
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder(this.routerParams?.name))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.3], [$r('app.color.white'), 0.3]]
    })
    .padding({ top: this.topHeight })
  }
}