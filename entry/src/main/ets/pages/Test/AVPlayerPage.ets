import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { avPlayerManager } from '../../manager/AVPlayerManager';

export class AVPlayerDemo {
  private avPlayer: media.AVPlayer | null = null
  private loop: boolean = false

  // 注册avplayer回调函数
  async setAVPlayerCallback() {
    if (this.avPlayer !== null) {
      return this.avPlayer
    }
    // 状态机变化回调函数
    const avPlayer = await media.createAVPlayer()
    avPlayer.on('stateChange', async (state: string) => {
      // console.log("AVPlayerPage_state:", JSON.stringify(state))
      switch (state) {
        case 'idle': // 成功调用reset接口后触发该状态机上报
          console.info('AVPlayer当前为闲置状态');
        // avPlayer.release(); // 调用release接口销毁实例对象
          break;
        case 'initialized': // avplayer 设置播放源后触发该状态上报
          console.info('AVPlayer初始化');
          avPlayer.prepare();
          break;
        case 'prepared': // prepare调用成功后上报该状态机
          console.info('AVPlayer为准备状态');
        // avPlayer.play(); // 调用播放接口开始播放
          break;
        case 'playing': // play成功调用后触发该状态机上报
          console.info('AVPlayer为播放状态');
          break;
        case 'paused': // pause成功调用后触发该状态机上报
          console.info('AVPlayer为暂停状态');
        // avPlayer.play(); // 再次播放接口开始播放
          break;
        case 'completed': // 播放结束后触发该状态机上报
          console.info('AVPlayer播放完成');
        // avPlayer.play(); //调用播放结束接口
          break;
        case 'stopped': // stop接口成功调用后触发该状态机上报
          console.info('AVPlayer播放停止');
          avPlayer.reset(); // 调用reset接口初始化avplayer状态
          break;
        case 'released':
          console.info('AVPlayer释放了');
          break;
        default:
          console.info('AVPlayer当前状态未知');
          break;
      }
    })
    this.avPlayer = avPlayer
    return this.avPlayer
  }

  // 以下demo为使用资源管理接口获取打包在HAP内的媒体资源文件并通过fdSrc属性进行播放示例
  async avPlayerFdSrcDemo(fileName: string) {
    // 创建avPlayer实例对象
    let avPlayer = await this.setAVPlayerCallback()
    console.log("AVPlayerPage_avPlayer.state:", JSON.stringify(avPlayer.state))
    // 通过UIAbilityContext的resourceManager成员的getRawFd接口获取媒体资源播放地址
    // 返回类型为{fd,offset,length},fd为HAP包fd地址，offset为媒体资源偏移量，length为播放长度
    let context = getContext(this) as common.UIAbilityContext;
    let fileDescriptor = await context.resourceManager.getRawFd(fileName);
    // 为fdSrc赋值触发initialized状态机上报
    avPlayer.fdSrc = fileDescriptor;
    // 创建状态机变化回调函数
    // avPlayer.play()
    return avPlayer
  }
}

const avPlayerClass = new AVPlayerDemo()

@Entry
@Component
struct AVPlayerPage {
  @State message: string = 'Hello World';

  build() {
    Column({ space: 20 }) {
      Button("播放声音")
        .onClick(async () => {

          // const avPlayer = await avPlayerClass.avPlayerFdSrcDemo("lab_call_ring.mp3")
          avPlayerManager.playByRawSrc("lab_call_ring.mp3")
        })
      Button("停止播放")
        .onClick(async () => {
          avPlayerManager.stop()
        })
    }.width("100%").height("100%").justifyContent(FlexAlign.Center)
  }
}