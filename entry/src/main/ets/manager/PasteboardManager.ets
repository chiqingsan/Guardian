import { pasteboard } from '@kit.BasicServicesKit'

class PasteboardManager {
  // 设置文本到剪贴板 (复制)
  setPasteText(text: string) {
    // 1. 获取系统剪贴板对象
    const systemPasteboard = pasteboard.getSystemPasteboard()
    // 2. 创建一份待写入系统剪贴板的文本数据
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    // 3. 把文本数据设置到系统剪贴板中
    systemPasteboard.setDataSync(pasteData)

  }

  // 获取剪贴板的文本，部分 windows 模拟器读取不到剪贴板会报错
  getPasteText() {
    // 1. 获取系统剪贴板对象
    const systemPasteBoard = pasteboard.getSystemPasteboard()
    // 2. 获取剪贴板数据，在 API 12 版本中，需要申请剪贴板的读取权限
    const pasteData = systemPasteBoard.getDataSync()
    // 3. 提取文本内容
    return pasteData?.getPrimaryText() || ''
  }
}

export const pasteboardManager = new PasteboardManager()