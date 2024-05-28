// 页面参数
import { privacyNoteDB, PrivacyNoteDBInfo } from '../../../database'
import { promptAction, router } from '@kit.ArkUI'
import { systemShare } from '@kit.ShareKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { common, UIAbility } from '@kit.AbilityKit'

interface RouterParams {
  id?: number
}

@Entry
@Component
struct NoteDetailPage {
  @StorageProp("topHeight") topHeight: number = 0
  // 标题
  @State title: string = ''
  // 内容
  @State content: string = ''
  // 页面参数
  @State routerParams: RouterParams = {}
  backup: PrivacyNoteDBInfo = {} as PrivacyNoteDBInfo

  aboutToAppear(): void {
    this.getTheRouteParameters()
  }

  onBackPress(): boolean | void {

    if (this.routerParams.id) {
      if (this.title !== this.backup.title || this.content !== this.backup.content) {

        promptAction.showDialog({
          alignment: DialogAlignment.Center,
          title: "提示",
          message: "当前编辑的内容还没有保存, 确定要返回吗?",
          buttons: [
            { text: "确定", color: "#ff0000" },
            { text: "取消", color: "#3366dd" }
          ]
        }).then((res) => {
          if (res.index === 0) {
            router.back()
          }
        })

        return true
      }
      return false
    }

    if (this.title.trim() && this.content.trim()) {

      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: "提示",
        message: "当前有正在编辑内容, 确定要返回吗?",
        buttons: [
          { text: "确定", color: "#ff0000" },
          { text: "取消", color: "#3366dd" }
        ]
      }).then((res) => {
        if (res.index === 0) {
          router.back()
        }
      })

      return true
    }

  }

  // 获取路由参数
  getTheRouteParameters() {
    if (router.getParams()) {
      this.routerParams = router.getParams() as RouterParams
      // 根据id查询笔记内容
      this.queryNotes()
    }
  }

  // 查询笔记内容
  async queryNotes() {
    const res = await privacyNoteDB.queryTheList<PrivacyNoteDBInfo>(this.routerParams.id)
    this.title = res[0].title
    this.content = res[0].content
    this.backup = res[0]
  }

  // 保存笔记
  async saveYourNotes() {
    if (this.routerParams.id) {

      await privacyNoteDB.update(this.routerParams.id, {
        title: this.title,
        content: this.content,
        date_added: Date.now()
      })

      promptAction.showToast({ message: "更新成功" })


    } else {
      await privacyNoteDB.insert<PrivacyNoteDBInfo>({
        id: null,
        title: this.title,
        content: this.content,
        date_added: Date.now()
      })

      promptAction.showToast({ message: "保存成功" })

    }

    // 保存成功后返回
    router.back()
  }

  // 删除数据
  deletionOfData() {
    if (this.routerParams.id !== undefined) {
      privacyNoteDB.deleteData(this.routerParams.id)
      router.back()
    }
  }

  // 分享笔记
  shareNotes() {
    try {
      const data = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        title: this.title,
        content: this.content
      })

      const res = new systemShare.ShareController(data)

      const context = getContext() as common.UIAbilityContext
      res.show(context, {})
    } catch (e) {
      AlertDialog.show({ message: JSON.stringify(e, null, 2) })
    }
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('保存')
        .fontSize(16)
        .fontColor(this.title.trim() !== '' ? $r('app.color.font') : $r('app.color.font_sub'))
        .enabled(this.title.trim() !== '')
        .onClick(() => {
          // TODO：保存/新增
          this.saveYourNotes()
        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column({ space: 10 }) {
          Text('标题')
            .fontSize(14)
            .fontColor($r('app.color.font2'))
            .width('100%')
          TextInput({ placeholder: '请输入笔记标题', text: this.title })
            .backgroundColor($r('app.color.white'))
            .border({ width: 1, color: $r('app.color.border'), radius: 6 })
            .padding({ left: 10 })
            .onChange((text) => {
              this.title = text
            })
            .onSubmit(() => {
              // TODO：提交表单(保存/新增)
              this.saveYourNotes()
            })
          Text('内容')
            .fontSize(14)
            .fontColor($r('app.color.font2'))
            .width('100%')
          TextArea({ placeholder: '请输入笔记内容', text: this.content })
            .backgroundColor($r('app.color.white'))
            .border({ width: 1, color: $r('app.color.border'), radius: 6 })
            .layoutWeight(1)
            .padding(10)
            .onChange((text) => {
              this.content = text
            })
        }
        .padding({ bottom: 160 })

        if (this.routerParams.id) {
          // 底部按钮
          Row({ space: 10 }) {
            Button('删除')
              .type(ButtonType.Normal)
              .backgroundColor('#FF5E5D')
              .borderRadius(10)
              .layoutWeight(1)
              .onClick(() => {
                // TODO：删除
                this.deletionOfData()
              })
            Button('分享')
              .type(ButtonType.Normal)
              .backgroundColor($r('app.color.brand'))
              .borderRadius(10)
              .layoutWeight(1)
              .onClick(() => {
                // TODO：分享
                this.shareNotes()
              })
          }
          .padding({ bottom: 80 })
        }
      }
      .padding({ left: 15, right: 15, top: 20 })

    }
    .title('笔记')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus())
    .padding({ top: this.topHeight })

  }
}