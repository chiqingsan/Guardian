import { PrivacySettings, PRIVACY_SETTINGS } from '../../common/constants';
import { router } from '@kit.ArkUI';

// 初始化持久化存储
PersistentStorage.persistProp<PrivacySettings>(PRIVACY_SETTINGS, {})

@Entry
@Component
struct PersistentStorageTest {
  @StorageProp(PRIVACY_SETTINGS) test: PrivacySettings = {} as PrivacySettings

  build() {
    Row() {
      Column() {
        Text(JSON.stringify(this.test))
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Button("添加/改动数据")
          .onClick(() => {
            const TestData = {
              patternPassword: `test_${new Date(Date.now()).toTimeString()}`
            } as PrivacySettings
            AppStorage.setOrCreate(PRIVACY_SETTINGS, TestData)

          })
        Button("获取数据")
          .onClick(() => {
            const res = AppStorage.get(PRIVACY_SETTINGS) as PrivacySettings
            AlertDialog.show({ message: JSON.stringify(res, null, 2) })
          })
        Button("追加数据")
          .onClick(() => {
            const res = AppStorage.get<PrivacySettings>(PRIVACY_SETTINGS)
            res!.patternPassword += `_${new Date(Date.now()).toTimeString()}`
            AppStorage.set(PRIVACY_SETTINGS, res)
          })
        Button("跳转测试页面2")
          .onClick( () => {
              router.pushUrl({
                url:"pages/Test/PersistentStorageTest2"
              })
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}