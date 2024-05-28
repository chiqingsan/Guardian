import { relationalStore, ValuesBucket } from '@kit.ArkData';
import dayjs from 'dayjs';

interface NoteItem extends ValuesBucket {
  id: number | null
  title: string
  content: string
  date_added: number | string
}


@Entry
@Component
struct RdbStorePage {
  val: string = ""
  tableName: string = "chiqingsan"
  createATable: string = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date_added INTEGER NOT NULL
      )`
  private store: relationalStore.RdbStore | null = null

  async createADatabase() {
    if (this.store) {
      return this.store
    }
    this.store = await relationalStore.getRdbStore(getContext(), {
      name: "chiqingsan.db",
      securityLevel: relationalStore.SecurityLevel.S1
    })

    this.store.executeSql(this.createATable)

    return this.store
  }

  // 获取数据库管理对象
  async getStoreInstance() {
    // 如果已经存在，直接返回
    if (this.store) {
      return this.store
    }
    // 获取操作数据库的管理对象(如果数据库文件不存在，会自动创建数据库文件)
    this.store = await relationalStore.getRdbStore(getContext(), {
      name: 'heima.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1, // 数据库安全级别
    })
    // 执行创建表的语句 execute 执行
    this.store.executeSql(this.createATable)
    // 返回 store 对象
    return this.store
  }

  build() {
    Column({ space: 12 }) {
      TextInput()
        .margin(20)
        .onChange((val) => {
          this.val = val
        })
      Button("创建数据库")
        .onClick(async () => {
          this.store = await this.createADatabase()
        })
      Button("删除数据库")
        .onClick(() => {
          relationalStore.deleteRdbStore(getContext(), "chiqingsan.db")
        })
        .backgroundColor(Color.Red)
        .enabled(false)

      Button("插入数据库文件")
        .onClick(async () => {
          const store = await this.createADatabase()
          try {
            // 添加一条数据
            const id = await store.insert(this.tableName, {
              id: null,
              title: `今天天气好_${this.val}`,
              content: '想吃肯德基',
              date_added: Date.now()
            } as NoteItem)
            AlertDialog.show({ message: '新增数组成功，数据的id为：' + id })
          } catch (e) {
            AlertDialog.show({ message: JSON.stringify(e, null, 2) })
          }
        })
      Button("删除数据库数据")
        .onClick(async () => {
          const store = await this.createADatabase()
          const predicate = new relationalStore.RdbPredicates(this.tableName)
          predicate.in("id", [1, 2, 3, 4])
          const delNum = store.delete(predicate)
          AlertDialog.show({ message: `一共删除了${delNum}行数据` })
        })
        .backgroundColor(Color.Red)
      Button("更新数据库数据")
        .onClick(async () => {
          const store = await this.createADatabase()
          const predicate = new relationalStore.RdbPredicates(this.tableName)
          predicate.equalTo("id", 10)
          const modifyNum = await store.update({
            title: `今天天气好_修改_${this.val}`,
            content: "改了改了改了"
          } as NoteItem, predicate)
          AlertDialog.show({ message: `一共修改了${modifyNum}行数据` })

        })
      Button("查询数据库数据字段")
        .onClick(async () => {
          const store = await this.createADatabase()
          const predicate = new relationalStore.RdbPredicates(this.tableName)
          const res = await store?.query(predicate)
          AlertDialog.show({ message: `当前表的字段数:${res.columnNames},当前表一共有${res.rowCount}条数据` })
        })
      Button("查询数据库数据")
        .onClick(async () => {
          const store = await this.createADatabase()
          const predicate = new relationalStore.RdbPredicates(this.tableName)
          predicate.orderByDesc("id")
          predicate.like("title", `%${this.val}%`)
          const res = await store?.query(predicate)
          let list: NoteItem[] = []
          while (res.goToNextRow()) {
            list.push({
              id: res.getLong(res.getColumnIndex("id")),
              title: res.getString(res.getColumnIndex("title")),
              content: res.getString(res.getColumnIndex("content")),
              date_added: dayjs(res.getLong(res.getColumnIndex("date_added"))).format("MM-DD HH:mm:ss")
            })
          }
          console.log("RdbStorePage_list:", JSON.stringify(list))
          AlertDialog.show({ message: JSON.stringify(list, null, 2) })
        })
    }.height("100%").width("100%").justifyContent(FlexAlign.Center)
  }
}