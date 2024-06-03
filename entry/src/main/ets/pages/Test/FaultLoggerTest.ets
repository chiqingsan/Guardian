import { FaultLogger } from '@kit.PerformanceAnalysisKit';
import axios, { AxiosRequestHeaders } from '@ohos/axios';
import { BASE_URL } from '../../common/constants';

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

      Button("发送请求")
        .onClick(async () => {

          const axiosInstance = axios.create({
            baseURL: BASE_URL
          })

          const res = await axiosInstance.post("/user/login/passwd", new Object({
            phone: "120666666666",
            passwd: "888itcast.CN764%..."
          })) as object

          AlertDialog.show({ message: JSON.stringify(res, null, 2) })
        })
    }.width("100%").height("100%").justifyContent(FlexAlign.Center)
  }
}