import { permissionManager } from '../../manager';
import { audio } from '@kit.AudioKit';
import { fileIo } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct AudioTestPage {
  @State message: string = 'Hello World';
  filename: string = ""
  recordingInstances: audio.AudioCapturer | null = null
  playAnInstance: audio.AudioRenderer | null = null

  aboutToAppear(): void {
    this.requestARecording()
  }

  //申请权限
  requestARecording() {
    permissionManager.requestPermissions(["ohos.permission.MICROPHONE"])
  }

  // 开始录音
  async recording() {
    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
      channels: audio.AudioChannel.CHANNEL_2, // 通道
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
    };

    let audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };

    let audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: audioStreamInfo,
      capturerInfo: audioCapturerInfo
    };

    // 创建音频文件
    const context = getContext()
    this.filename = `${Date.now()}.wav`
    const filePath = `${context.filesDir}/${this.filename}`
    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
    console.log("AudioTestPage_file:", JSON.stringify(file.fd))


    try {
      // const audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);
      this.recordingInstances = await audio.createAudioCapturer(audioCapturerOptions);

      let bufferSize = 0
      this.recordingInstances.on("readData", (res) => {
        console.log("AudioTestPage_res:", JSON.stringify(res.byteLength))

        fileIo.write(file.fd, res, { length: res.byteLength, offset: bufferSize })
        bufferSize += res.byteLength
      })

      console.log("AudioTestPage_audioCapturer:", JSON.stringify(this.recordingInstances.state))
      this.recordingInstances.start()
    } catch (e) {
      console.error(e)
    }
  }

  // 停止录音
  async stopRecording() {
    promptAction.showToast({ message: "准备停止录音" })
    try {
      await this.recordingInstances?.stop()
      await this.recordingInstances?.release()
    } catch (e) {
      console.log("AudioTestPage_e:", JSON.stringify(e))
    }
    AlertDialog.show({ message: `当前录音的文件名是${this.filename}` })
  }

  //播放录音
  async playTheRecording() {
    promptAction.showToast({ message: "准备播放录音" })
    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
      channels: audio.AudioChannel.CHANNEL_2, // 通道
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
    };

    let audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MOVIE,
      rendererFlags: 0
    };

    let audioRendererOptions: audio.AudioRendererOptions = {
      streamInfo: audioStreamInfo,
      rendererInfo: audioRendererInfo
    };

    this.playAnInstance = await audio.createAudioRenderer(audioRendererOptions);

    let bufferSize: number = 0;


    let path = getContext().cacheDir;
    //确保该路径下存在该资源
    let filePath = path + "/" + this.filename;
    AlertDialog.show({ message: JSON.stringify(`当前播放的文件名是${filePath}}`, null, 2) })
    let file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);

    this.playAnInstance.on('writeData', async (buffer) => {

      fileIo.readSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength });
      bufferSize += buffer.byteLength;
      const size = fileIo.statSync(file.fd).size
      if (bufferSize >= size) {
        await this.playAnInstance?.stop()
        this.playAnInstance?.release()
      }
    });

    try {
      AlertDialog.show({ message: JSON.stringify(this.playAnInstance.state, null, 2) })
      this.playAnInstance.start()
    } catch (e) {
      console.error(e + "error")
    }
  }

  // 停止播放
  async stopPlaying() {
    promptAction.showToast({ message: "准备停止播放" })
    try {
      await this.playAnInstance?.stop()
      await this.playAnInstance?.release()
    } catch (e) {
      console.log("AudioTestPage_e:", JSON.stringify(e))
    }
  }

  build() {
    Column({ space: 20 }) {
      Button("开始录音")
        .onClick(() => {
          this.recording()
        })
      Button("停止录音")
        .onClick(() => {
          this.stopRecording()
        })
      Button("播放录音")
        .onClick(() => {
          this.playTheRecording()
        })
      Button("停止播放")
        .onClick(() => {
          this.stopPlaying()
        })


    }.width("100%").height("100%").justifyContent(FlexAlign.Center)
  }
}