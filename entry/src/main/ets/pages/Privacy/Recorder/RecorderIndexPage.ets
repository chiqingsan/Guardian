import { ValuesBucket } from '@kit.ArkData'
import dayjs from 'dayjs'
import duration from 'dayjs/plugin/duration'
import { EmptyTipsComp } from '../../../common/components'
import { CustomInputDialog } from '../../../common/dialog'
import { fileIo } from '@kit.CoreFileKit'
import { PRIVACY_RECORDER_FOLDER } from '../../../common/constants'
import { audioCapturerManager } from '../../../manager/AudioCapturerManager'
import { privacyRecordingsDB } from '../../../database'
import { it } from '@ohos/hypium'

// 用于把毫秒格式化成 mm:ss 的相对时间插件
dayjs.extend(duration)

// 注意：隐私录音的数据库准备完毕后，请删除这个类型，否者类型可能会冲突
export interface PrivacyRecordingsDBInfo extends ValuesBucket {
  id: number | null // 新增时 id 为 null ，自动生成自增 id
  filePath: string
  title: string
  date_added: number
  duration: number
}

@Entry
@Component
struct RecorderIndexPage {
  @State list: PrivacyRecordingsDBInfo[] = []
  @State tempInputText: string = ''
  @State onConfirmEnable: boolean = true
  @State activeItem: PrivacyRecordingsDBInfo | null = null
  @State isRecording: boolean = false
  @State isPlaying: boolean = false
  @State recordingTime: number = 0
  @State playingTime: number = 0
  // 自定义弹窗层
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomInputDialog({
      title: '重命名音频',
      message: '支持下划线、数宇、英文字母与中文',
      inputText: this.tempInputText,
      onConfirm: async () => {
        // TODO：重命名录音
        this.renameTheRecording()
      },
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  })
  private playingTimerId: number = -1
  private recordingTimerId: number = -1

  async aboutToAppear(): Promise<void> {
    // 初始化录音的存放文件夹
    await audioCapturerManager.requestPermissions()
    this.initFolder()
    this.getList()
  }

  // 创建文件夹
  initFolder() {
    const context = getContext()
    const filesDir = context.filesDir

    const list = fileIo.listFileSync(filesDir)

    if (!list.includes(PRIVACY_RECORDER_FOLDER)) {
      fileIo.mkdirSync(`${filesDir}/${PRIVACY_RECORDER_FOLDER}`)
    }
  }

  // 开始录音
  startRecording() {
    // 1. 显示录音面板
    this.isRecording = true
    // 2. 开启计时效果
    this.startTheTimer()
    // 3. 开启录音采集器，同时准备好文件路径
    const context = getContext()
    // 检查录音文件录音路径，路径拼接时特别容易出错
    const filePath = context.filesDir + '/' + PRIVACY_RECORDER_FOLDER + '/' + Date.now() + '.wav'
    if (AppStorage.get("phoneName") !== "emulator") {
      audioCapturerManager.startCapturer(filePath)
    }
  }

  // 结束录音
  async endTheRecording() {
    // 1. 隐藏录音面板
    this.isRecording = false
    // 2. 结束计时效果
    this.endTheTimer()

    if (AppStorage.get("phoneName") !== "emulator") {
      // 3. 结束录音采集器，返回录音的关键信息
      const audioInfo = await audioCapturerManager.stopCapturer()
      // 4. 把录音的关键信息写入数据库中
      await privacyRecordingsDB.setData<PrivacyRecordingsDBInfo>({
        id: null,
        filePath: audioInfo.filePath,
        title: '录音文件' + audioInfo.date_added,
        date_added: audioInfo.date_added,
        duration: audioInfo.duration
      })
    } else {
      const filename = Date.now()
      await privacyRecordingsDB.setData<PrivacyRecordingsDBInfo>({
        id: null,
        filePath: `${filename}.wav`,
        title: '录音文件' + `${dayjs(filename).format("YYYY-MM-DD HH:mm:ss")}`,
        date_added: filename,
        duration: this.recordingTime * 1000
      })
    }
    // 5. 查询数据库，更新隐私录音列表的视图
    this.getList()
  }

  // 开启计时
  startTheTimer() {
    clearInterval(this.recordingTimerId)
    this.recordingTime = 0
    this.recordingTimerId = setInterval(() => {
      this.recordingTime++
    }, 1000)
  }

  // 结束计时
  endTheTimer() {
    clearInterval(this.recordingTimerId)
  }

  // 获取列表
  async getList() {
    this.list = await privacyRecordingsDB.getTheList()
  }

  // 播放录音
  playTheRecording(item: PrivacyRecordingsDBInfo) {
    this.activeItem = item
    this.playingTime = 0
    this.playingTimerId = setInterval(() => {
      this.playingTime += 20
      if (this.playingTime > item.duration) {
        clearInterval(this.playingTimerId)
      }
    }, 20)
    if (AppStorage.get("phoneName") !== "emulator") {
      audioCapturerManager.startRenderer(item.filePath)
    }
  }

  // 停止播放录音
  stopPlayingTheRecording(item: PrivacyRecordingsDBInfo) {
    this.activeItem = item
    clearInterval(this.playingTimerId)
    if (AppStorage.get("phoneName") !== "emulator") {
      audioCapturerManager.stopRenderer()
    }
  }

  // 删除录音
  async deleteTheRecording(item: PrivacyRecordingsDBInfo) {
    if (AppStorage.get("phoneName") !== "emulator") {
      audioCapturerManager.stopRenderer()
    }
    await privacyRecordingsDB.delData(item.id as number)
    this.getList()
    fileIo.unlink(item.filePath)
  }

  // 重命名
  renameTheRecording() {
    privacyRecordingsDB.upData(this.activeItem?.id as number, {
      title: this.tempInputText
    } as PrivacyRecordingsDBInfo)

    // fileIo.rename(this.activeItem?.filePath,)
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('编辑')
        .fontSize(16)
        .fontColor($r('app.color.font'))
        .onClick(() => {

        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  @Builder
  ListItemSwipeActionEnd() {
    Row() {
      Button("重命名")
        .type(ButtonType.Normal)
        .height('100%')
        .aspectRatio(1)
        .backgroundColor('#CECFCF')
        .onClick(() => {
          // TODO：录音重命名
          this.dialogController.open()
        })
      Button("删除")
        .type(ButtonType.Normal)
        .height('100%')
        .aspectRatio(1)
        .backgroundColor('#FF5E5D')
        .onClick(() => {
          // TODO：删除录音
          this.deleteTheRecording(this.activeItem as PrivacyRecordingsDBInfo)
        })
    }
    .height('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.list.length) {
            List() {
              ListItemGroup() {
                ForEach(this.list, (item: PrivacyRecordingsDBInfo) => {
                  ListItem() {
                    Row({ space: 20 }) {
                      Column({ space: 10 }) {
                        Text(item.title)
                          .fontSize(16)
                          .fontColor($r('app.color.font2'))
                        // 录音进度条
                        if (this.activeItem?.id === item.id && this.isPlaying) {
                          Row({ space: 5 }) {
                            Text(dayjs(this.playingTime)
                              .format('mm:ss'))
                              .fontSize(12)
                              .fontColor($r('app.color.font_sub'))
                            Progress({
                              value: this.playingTime,
                              total: item.duration,
                            })
                          }
                          .padding({ right: 20 })
                        } else {
                          Text(dayjs(item.date_added)
                            .format('YYYY年MM月DD日 HH:mm:ss'))
                            .fontSize(12)
                            .fontColor($r('app.color.font_sub'))
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Column() {
                        Image(
                          this.activeItem?.id === item.id && this.isPlaying ?
                          $r('sys.media.ohos_ic_public_pause') :
                          $r("app.media.ic_public_play")
                        )
                          .width(22)
                          .aspectRatio(1)
                          .fillColor('#A6B6C4')
                        Text(dayjs.duration(item.duration)
                          .format('mm:ss'))
                          .fontSize(12)
                          .fontColor('#A6B6C4')
                          .lineHeight(25)
                      }
                      .justifyContent(FlexAlign.Center)
                      .height('100%')
                      .onClick(() => {
                        // TODO：播放音频
                        this.isPlaying = !this.isPlaying
                        if (this.isPlaying) {
                          this.playTheRecording(item)
                        } else {
                          this.stopPlayingTheRecording(item)
                        }
                      })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .padding({ left: 15, right: 15 })
                  }
                  .height(72)
                  .transition({ type: TransitionType.Delete, opacity: 0 })
                  .swipeAction({
                    end: {
                      builder: this.ListItemSwipeActionEnd(),
                      onStateChange: (state) => {
                        if (state === SwipeActionState.EXPANDED) {
                          // 保存当前滑动的数据
                          this.activeItem = item
                        }
                      }
                    },
                    edgeEffect: SwipeEdgeEffect.None,
                  })
                })
              }
              .padding({ bottom: 126 })
              .divider({
                strokeWidth: 1,
                color: $r('app.color.border'),
                startMargin: 15,
                endMargin: 15
              })
            }
            // 每行之间的分界线
            .width('100%')
            .height('100%')
          } else {
            EmptyTipsComp({ title: '您还没有任何隐私录音\n点击下面的按钮开始创建' })
          }
        }
        .height('100%')

        // 录音按钮
        Column() {
          Image($r('app.media.ic_circle_recorder'))
            .width(56)
            .aspectRatio(1)
            .onClick(() => {
              // TODO：开始录音
              this.startRecording()
            })
        }
        .width('100%')
        .height(126)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 15, right: 15 })

        // 停止录音
        Column({ space: 15 }) {
          Row({ space: 12 }) {
            Row() {
              ForEach(Array.from({ length: 12 }), () => {
                Column()
                  .width(5)
                  .height(16)
                  .backgroundColor('#80ffffff')
                  .borderRadius(5 / 2)
              })
            }
            .width(110)
            .justifyContent(FlexAlign.SpaceBetween)

            // 图标
            Image($r('app.media.ic_recorder_fill'))
              .height('100%')

            Row() {
              ForEach(Array.from({ length: 12 }), () => {
                Column()
                  .width(5)
                  .height(16)
                  .backgroundColor('#80ffffff')
                  .borderRadius(5 / 2)
              })
            }
            .width(110)
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(58)
          .margin({ top: 40 })

          Text(
            dayjs(this.recordingTime * 1000)
              .format(this.recordingTime > 1000 * 60 * 60 ? 'HH:mm:ss' : 'mm:ss')
          )
            .fontSize(18)
            .lineHeight(25)
            .fontWeight(700)
            .fontColor($r('app.color.white'))

          Row() {
            Button('停止录音')
              .type(ButtonType.Normal)
              .width('100%')
              .backgroundColor($r('app.color.brand'))
              .border({ width: 1, color: $r('app.color.white') })
              .borderRadius(10)
              .onClick(() => {
                // TODO：停止录音
                this.endTheRecording()
              })
          }
          .padding({ left: 15, right: 15 })
        }
        .width('101%')
        .height(222)
        .backgroundImage('/common/images/RecorderAddPage_bg_bottom.png')
        .backgroundImageSize(ImageSize.Cover)
        .visibility(this.isRecording ? Visibility.Visible : Visibility.None)
      }
      .height('100%')
    }
    .title('录音')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus)
    .linearGradient({
      angle: 180,
      colors: this.isRecording ? [[$r('app.color.white'), 0.95], [$r('app.color.brand'), 0.95]] :
        [[$r('app.color.white'), 0], [$r('app.color.white'), 1]]
    })
  }
}