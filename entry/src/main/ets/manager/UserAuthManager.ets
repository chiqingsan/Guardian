import { userAuth } from '@kit.UserAuthenticationKit'

interface returnsResults {
  results: boolean,
  code: number,
  message?: string
}

// 指纹或面容ID（生物特征识别）
class UserAuthManager {
  // 配置认证界面
  private widgetParam: userAuth.WidgetParam
  // 认证信任等级, 默认为级别3
  private authTrustLevel: userAuth.AuthTrustLevel = userAuth.AuthTrustLevel.ATL3
  // 认证类型列表
  private authType: userAuth.UserAuthType[] = [
    userAuth.UserAuthType.PIN, // PIN密码（模拟器支持）
    userAuth.UserAuthType.FINGERPRINT, // 指纹
    userAuth.UserAuthType.FACE// 面容ID
  ]
  // 设置认证参数
  private dynamicArrays: number[] = new Array(6).fill(Math.floor(Math.random() * 255))
  private authParam: userAuth.AuthParam = {
    challenge: new Uint8Array(this.dynamicArrays), // 挑战值，用来防重放攻击。
    authType: this.authType, // 认证类型列表
    authTrustLevel: this.authTrustLevel, // 认证信任等级
  }

  // 初始化认证窗口的标题和认证级别
  constructor(title: string, authTrustLevel?: userAuth.AuthTrustLevel) {
    this.widgetParam = {
      title: title
    }
    this.authTrustLevel = authTrustLevel ?? this.authTrustLevel
  }

  // 查询认证能力是否支持
  checkUserAuthSupport() {
    const authTypeRes = this.authType.map((item) => {
      try {
        // 查询认证能力是否支持,注意这里需要用 try catch
        userAuth.getAvailableStatus(item, this.authTrustLevel)
        return true
      } catch {
        return false
      }
    })
    // 有一项支持即可
    return authTypeRes.some(v => v === true)
  }

  // 发起原生用户认证
  startUserAuth(): Promise<returnsResults> {
    return new Promise((resolve, reject) => {
      try {
        // 获取认证对象
        const userAuthInstance = userAuth.getUserAuthInstance(this.authParam, this.widgetParam)
        // 执行用户认证
        userAuthInstance.start()
        // 订阅用户身份认证结果
        userAuthInstance.on('result', {
          onResult(result) {
            // 判断验证结果
            switch (result.result) {
              case userAuth.UserAuthResultCode.SUCCESS:
                resolve({
                  results: true,
                  code: result.result,
                  message: "用户认证成功"
                })
                break
              case userAuth.UserAuthResultCode.CANCELED:
                resolve({
                  results: false,
                  code: result.result,
                  message: "用户取消认证"
                })
                break
              default:
                resolve({
                  results: false,
                  code: result.result
                })
            }
            // 可在认证结束或其他业务需要场景，取消订阅认证结果
            userAuthInstance.off('result')
          }
        })
      } catch (error) {
        // 打印错误信息
        console.error("UserAuthManager_error:", JSON.stringify(error))
        // 返回错误结果
        reject({
          results: false,
          code: error.code
        })
      }
    })
  }
}

export const userAuthManager = new UserAuthManager("请进行身份认证")