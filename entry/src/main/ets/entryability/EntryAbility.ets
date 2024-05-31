import { AbilityConstant, errorManager, UIAbility, Want } from '@kit.AbilityKit';
import { router, window } from '@kit.ArkUI';
import { FaultLogger, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { PrivacySettings, PRIVACY_SETTINGS } from '../common/constants';

let errorManagerId = -1

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

    //注册错误观察器,来捕获未知的错误
    errorManagerId = errorManager.on("error", {
      async onUnhandledException() {
        const errorInfoList = await FaultLogger.query(FaultLogger.FaultType.JS_CRASH)
        const errorInfo = errorInfoList[0]
        // AlertDialog.show({
        //   message: JSON.stringify(errorInfo, null, 2)
        // })
      }
    })
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');

    errorManager.off("error", errorManagerId)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 在生命周期里, 查询一下设备型号, 保持到全局变量中, 提供给其他页面使用
    const phoneName = deviceInfo.marketName
    AppStorage.setOrCreate("phoneName", phoneName)

    windowStage.loadContent('/pages/Test/FaultLoggerTest'.slice(1), (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');

    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // console.log("EntryAbility:", JSON.stringify(router.getState()))
    // 如果处于隐私页面,则返回首页
    if (router.getState().path.includes("Privacy")) {
      router.back({
        url: "pages/Index"
      })
    }
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
