import { Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'
import { permissionManager } from '.'
import { formatByteLength } from '../common/utils'

// 音频信息
interface AudioInfo {
  date_added: number // 音频创建时间
  duration: number // 音频持续时长
  filePath: string // 音频文件路径
}

class AudioCapturerManager {
  // 录音权限
  private permissions: Permissions[] = ["ohos.permission.MICROPHONE"]
  // 音频流配置，采集器，渲染器 公用相同的配置，工作中可根据需求调整参数
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
    channels: audio.AudioChannel.CHANNEL_2, // 通道
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
  };
  // 音频采集器(录音)配置
  private audioCapturerInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC,
    capturerFlags: 0 // 音频采集器标识，目前只支持 0，0 代表普通音频采集器
  };
  // 音频渲染器(播放)配置
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MOVIE, // 播放类型，MUSIC 表示用喇叭播放，MOVIE 也是喇叭播放，但是不容易卡顿
    rendererFlags: 0 // 音频渲染器标识，目前只支持 0，0 代表普通音频渲染器
  };
  // 音频采集器(录音)实例
  private audioCapturer: audio.AudioCapturer | null = null
  // 音频渲染器(播放)实例
  private audioRenderer: audio.AudioRenderer | null = null
  // 录音文件路径
  private filePath: string = ''
  // 录音创建时间
  private date_added: number = 0

  // 初始化权限
  async requestPermissions() {
    try {
      // 申请权限
      await permissionManager.requestPermissions(this.permissions)
    } catch {
      // 如果未授权，Promise.reject() 会触发 catch，引导去设置页开启授权
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '录音功能需要获取权限，请在系统设置中打开麦克风开关',
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

  // 获取音频采集器实例，用于录音
  async getAudioCapturer() {
    // 如果已经存在，直接返回实例
    if (this.audioCapturer) {
      return this.audioCapturer
    }
    // 创建音频采集器，保存成全局变量方便下次直接获取
    this.audioCapturer = await audio.createAudioCapturer({
      streamInfo: this.audioStreamInfo,
      capturerInfo: this.audioCapturerInfo
    })
    // 返回音频采集器
    return this.audioCapturer
  }

  // 开始录音(音频采集器)
  async startCapturer(filePath: string) {
    // 根据 filePath 打开文件，可读可写模式，如果文件不存在自动创建
    const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
    // 1. 获取音频采集器
    const audioCapturer = await this.getAudioCapturer()
    // 偏移值
    let bufferSize: number = 0
    // 2. 调用on('readData')方法，读取音频采集器的数据流，写入到文件中
    audioCapturer.on('readData', (buffer) => {
      // 把采集的音频信息写入到打开的文件中
      fileIo.writeSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength })
      // 累加偏移值
      bufferSize += buffer.byteLength
      // 测试用的提示，项目上线时记得删除 !!!
      promptAction.showToast({ message: '文件大小:' + formatByteLength(bufferSize) })
    })
    // 3. 开始录音采集
    audioCapturer.start()
    // 保存录音文件路径，用于存储数据库
    this.filePath = filePath
    // 保存录音创建时间，用于计算音频时长
    this.date_added = Date.now()
  }

  /**
   * 结束录音
   * @returns 文件路径、创建时间、持续时长
   */
  async stopCapturer(): Promise<AudioInfo> {
    // 获取音频采集器
    const audioCapturer = await this.getAudioCapturer()
    await audioCapturer.stop() // 停止采集
    audioCapturer.release() // 释放资源(硬件)
    this.audioCapturer = null // 释放变量
    // 返回录音文件关键信息
    return {
      filePath: this.filePath, // 音频文件路径
      date_added: this.date_added, // 音频创建时间
      duration: Date.now() - this.date_added // 音频持续时长
    }
  }

  // 获取音频渲染器，用于播放
  async getAudioRenderer() {
    // 如果已经存在直接返回
    if (this.audioRenderer) {
      return this.audioRenderer
    }
    // 创建音频渲染器
    this.audioRenderer = await audio.createAudioRenderer({
      streamInfo: this.audioStreamInfo,
      rendererInfo: this.audioRendererInfo
    })
    // 返回音频渲染器
    return this.audioRenderer
  }

  // 播放录音(音频渲染器)
  async startRenderer(filePath: string) {
    // 根据路径打开文件
    const file = fileIo.openSync(filePath)
    // 获取文件信息，用于播放时自动停止
    const stat = fileIo.statSync(file.fd)
    // 1. 获取音频渲染器（播放器）
    const audioRenderer = await this.getAudioRenderer()
    // 偏移值
    let bufferSize: number = 0
    // 2. 调用on('writeData')方法，把读取到的文件流，写入到音频渲染器(播放)
    audioRenderer.on('writeData', async (buffer) => {
      // 读取打开的文件，按偏移量读取
      fileIo.readSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength })
      // 累加偏移量
      bufferSize += buffer.byteLength
      // 测试用的，封装完成记得删除
      promptAction.showToast({ message: '文件大小:' + formatByteLength(bufferSize) })
      // 如果偏移量已经超过文件大小，可以停止播放
      if (bufferSize >= stat.size) {
        await audioRenderer.stop() // 停止渲染器(播放器)
        audioRenderer.release() // 释放资源(硬件)
        this.audioRenderer = null // 释放变量
      }
    })
    // 3. 启动音频渲染器（播放器）
    audioRenderer.start()
  }

  // 停止渲染(播放)录音
  async stopRenderer() {
    // 获取音频渲染器（播放器）
    const audioRenderer = await this.getAudioRenderer()
    // RUNNING 和 PAUSED 状态下才能 stop，stop 后自动 release 释放资源(硬件)
    if ([audio.AudioState.STATE_RUNNING, audio.AudioState.STATE_PAUSED].includes(audioRenderer.state)) {
      await audioRenderer.stop() // 停止渲染(播放)
      audioRenderer.release() // 释放资源(硬件)
      this.audioRenderer = null // 释放变量
    }
  }
}

export const audioCapturerManager = new AudioCapturerManager()