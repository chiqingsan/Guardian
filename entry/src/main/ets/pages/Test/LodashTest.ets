import _ from "@wolfx/lodash"
import dayjs from 'dayjs';
import { userCalendarManager } from '../../manager';
import { calendarManager } from '@kit.CalendarKit';

interface item {
  a: number
}

interface data {
  data: string,
  list: calendarManager.Event[]
}

@Entry
@Component
struct LodashTest {
  @State message: data[] = []

  build() {
    Column() {
      Button("测试Lodash")
        .onClick(async () => {
          // const res =
          //   _.maxBy<item>([{ a: 10 }, { a: 12 }, { a: 10 }], (item: item) => item.a)
          // AlertDialog.show({ message: JSON.stringify(res, null, 2) })
          // _([1, 2, 3, 4, 5, 6]).forEach(
          //   (v) => {
          //     console.log("LodashTest:", JSON.stringify(v))
          //   }
          // )
          const resData = await userCalendarManager.getDefaultCalendar()
          const res = await resData.getEvents()
          const lodashData = _.groupBy(res, res => dayjs(res.startTime).format("YYYY年"))
          AlertDialog.show({ message: JSON.stringify(lodashData, null, 2) })
          this.message = _.map(lodashData, (val, key): data => {
            return {
              data: key,
              list: val
            }
          })
        })

      List() {
        ForEach(this.message, (item: data) => {
          ListItemGroup({
            header: this.listG(item.data)
          }) {
            ForEach(
              item.list, (val: calendarManager.Event) => {
              ListItem() {
                Row() {
                  Text(JSON.stringify(val).slice(0, 1000))
                }
              }
            }
            )
          }
        })
      }
    }.width("100%")
  }

  @Builder
  listG(text: string) {
    Text(text)
  }
}