import Observation

@Observable
public class ObservableState<T> {
    var item: T
    init(item: T) {
        self.item = item
    }
}
