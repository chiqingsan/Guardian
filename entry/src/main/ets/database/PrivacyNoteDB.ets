import { relationalStore, ValuesBucket } from '@kit.ArkData'

// 隐私笔记的类型
export interface PrivacyNoteDBInfo extends ValuesBucket {
  id: number | null // 新增时 id 设置为 null ，可实现 id 自增
  title: string
  content: string
  date_added: number
}

class PrivacyNoteDB {
  // 操作数据库的实例
  private store: relationalStore.RdbStore | null = null
  private tableName = 'privacy_note'
  // 创建数据库的语句
  private sqlCreate = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date_added INTEGER NOT NULL
      )`

  async getStoreInstance() {
    // 如果数据库实例已存在，直接返回，没有才创建实例
    if (this.store) {
      return this.store
    }
    // 获取操作数据库的实例
    const store = await relationalStore.getRdbStore(getContext(), {
      name: this.tableName + '.db', // 数据库名称
      securityLevel: relationalStore.SecurityLevel.S1 // 安全等级
    })
    // 执行创建语句
    store.executeSql(this.sqlCreate)
    // 存储起来方便下次直接获取
    this.store = store
    // 返回 store 实例
    return this.store
  }

  // 添加一条数据
  async insert(value: PrivacyNoteDBInfo) {
    const store = await this.getStoreInstance()
    return store.insert(this.tableName, value)
  }

  // 查询表的数据量
  async queryCount() {
    console.log("PrivacyNoteDB_store:", JSON.stringify(this.store))
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    const res = await store.query(predicates)
    return res!.rowCount <= 0 ? 0 : res?.rowCount
  }

  async queryTheList<T>(id?: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    id !== undefined ? predicates.equalTo("id", id) : predicates.orderByDesc("id")
    const res = await store.query(predicates)

    const list: T[] = []
    while (res?.goToNextRow()) {
      list.push(res.getRow() as T)
      // console.log("PrivacyNoteDB_res:", JSON.stringify(res.getRow()))
    }
    return list
  }

  // 更新数据
  async update(val: Partial<PrivacyNoteDBInfo>) {
    if (val.id === undefined) {
      return Promise.reject("id error")
    }
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo("id", val.id)
    return store.update(val, predicates)
  }

  // 删除数据
  async deleteData(id: number) {

    if (id === undefined) {
      return
    }

    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo("id", id)
    return store.delete(predicates)
  }
}

export const privacyNoteDB = new PrivacyNoteDB()