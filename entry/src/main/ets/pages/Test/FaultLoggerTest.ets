import { FaultLogger } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct FaultLoggerTest {
  @State message: string = 'Hello World';

  build() {
    Column({ space: 20 }) {

      Button("抛出错误")
        .onClick(() => {
          throw new Error("出错了")
        })
      Button("捕获故障日志")
        .onClick(async () => {
          const list = await FaultLogger.query(FaultLogger.FaultType.JS_CRASH)
          AlertDialog.show({ message: JSON.stringify(list, null, 2) })
        })
    }.width("100%").height("100%").justifyContent(FlexAlign.Center)
  }
}