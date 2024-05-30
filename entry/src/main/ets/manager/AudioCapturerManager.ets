import { Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'

// 录音文件关键信息
interface AudioInfo {
  filePath: string // 文件路径
  date_added: number // 创建时间
  duration: number // 持续时长
}

class AudioCapturerManager {
  // 录音权限
  private permissions: Permissions[] = ["ohos.permission.MICROPHONE"]
  // 音频流配置
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
    channels: audio.AudioChannel.CHANNEL_2, // 通道
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
  };
  // 音频采集器配置
  private audioCapturerInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC,
    capturerFlags: 0
  };
  // 音频渲染器配置
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC, // 播放类型，MUSIC 表示用喇叭播放
    rendererFlags: 0
  };
  // 音频采集器实例
  private audioCapturer: audio.AudioCapturer | null = null
  // 音频渲染器实例
  private audioRenderer: audio.AudioRenderer | null = null

  // 获取音频采集器实例
  async getAudioCapturer() {
    // 如果已经存在，直接返回
    if (this.audioCapturer) {
      return this.audioCapturer
    }
    // 创建音频采集器
    this.audioCapturer = await audio.createAudioCapturer({
      streamInfo: this.audioStreamInfo,
      capturerInfo: this.audioCapturerInfo
    })
    // 返回音频采集器
    return this.audioCapturer
  }

  // 获取音频渲染器（播放器）
  async getAudioRenderer() {
    if (this.audioRenderer) {
      return this.audioRenderer
    }
    this.audioRenderer = await audio.createAudioRenderer({
      streamInfo: this.audioStreamInfo,
      rendererInfo: this.audioRendererInfo
    })
    return this.audioRenderer
  }

  // 开始录音
  async startRecorder(filePath: string) {
    // 根据 filePath 打开文件，可读可写模式，如果文件不存在自动创建（模拟器支持文件创建）
    const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
    // 1. 获取音频采集器（模拟器不支持录音）
    const audioCapturer = await this.getAudioCapturer()
    // 偏移值
    let bufferSize: number = 0
    // 2. 调用on('readData')方法，订阅监听音频数据读入回调
    audioCapturer.on('readData', (buffer) => {
      // 把采集的音频信息写入到打开的文件中
      fileIo.writeSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength })
      // 累加偏移值
      bufferSize += buffer.byteLength
    })
    // 3. 开始录音采集
    audioCapturer.start()
  }

  //停止录音采集,并且释放采集器实例
  async stopRecorder() {
    // 获取音频采集器
    const audioCapturer = await this.getAudioCapturer()
    await audioCapturer.stop() // 停止采集
    audioCapturer.release() // 释放资源
    this.audioCapturer = null // 重置采集器变量
    // 返回录音文件关键信息
    // return {
    //   filePath: this.filePath, // 文件路径
    //   date_added: this.date_added, // 创建时间
    //   duration: Date.now() - this.date_added // 持续时长
    // }
  }

  // 播放录音
  async startRenderer(filePath: string) {
    // 1. 获取音频渲染器（播放器）
    const audioRenderer = await this.getAudioRenderer()
    // 偏移值
    let bufferSize: number = 0
    // 根据路径打开文件
    const file = fileIo.openSync(filePath)
    // 2. 调用on('writeData')方法，订阅监听音频数据写入回调
    audioRenderer.on('writeData', (buffer) => {
      fileIo.readSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength })
      bufferSize += buffer.byteLength
      // 测试用的，封装完成记得删除
      promptAction.showToast({ message: bufferSize.toString() })
      // 获取文件信息，如果读取时已经超出文件大小，自动停止
      const stat = fileIo.statSync(file.fd)
      if (bufferSize >= stat.size) {
        // 停止渲染器（播放器）
        this.stopRenderer()
      }
    })
    // 3. 启动音频渲染器（播放器）
    audioRenderer.start()
  }

  // 停止播放录音
  async stopRenderer() {
    // 获取音频渲染器（播放器）
    const audioRenderer = await this.getAudioRenderer()
    await audioRenderer.stop() // 停止
    audioRenderer.release() // 释放资源
    this.audioRenderer = null // 清理变量
  }
}

export const audioCapturerManager = new AudioCapturerManager()