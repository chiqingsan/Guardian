@Entry
@Component
struct UserTextInput {
  @State message: string = 'Hello World';
  @State index: number = 0

  build() {
    Column() {

      Row({ space: 15 }) {
        ForEach(Array.from({ length: 4 }),
          () => {
            TextInput()
              .layoutWeight(1)
              .aspectRatio(1)
          })
      }.width("100%")
    }
  }
}