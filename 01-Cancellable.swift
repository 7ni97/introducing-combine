import Combine

/// Anything that implements `cancel` is `Cancellable`.
///
///     /// A protocol indicating that an activity or action supports
///     ///  cancellation.
///     protocol Cancellable {
///         /// Free up any allocated resources, and stop side effects such
///         /// as timers, network access, or disk I/O.
///         func cancel()
///     }
struct MyCancellable: Cancellable {
    func cancel() {
        print("MyCancellable.cancel")
    }
}

let myCancellable = MyCancellable()
myCancellable.cancel()

/// ** Type Erasure **
///
/// Sometimes we have a box with two buttons. But we want people to be able
/// to use only one of the buttons. So we wrap the box in another box that
/// exposes only one of the buttons, and hides the other one.
///
/// `AnyCancellable` is an object that hides the type of a cancellable.
///
///     /// A type-erasing cancellable object.
///     class AnyCancellable : Cancellable, Hashable {
///         init<C>(_ canceller: C) where C : Cancellable
///     }
///
/// A common `Cancellable` is a `Subscription`, which is a `Cancellable`
/// but also more. Subscriber implementations can thus use an `AnyCancellable`
/// to provide a "cancellation token" that makes it possible for a caller to
/// cancel a publisher, but not do any of the other stuff that they would've
/// been able to do if they had been given the original `Subscription` object
/// (e.g. they cannot use the `Subscription` object to request items).
let typedCancellable = MyCancellable()
let typeErasedCancellable = AnyCancellable(typedCancellable)
typeErasedCancellable.cancel()

/// `AnyCancellable` can be created using a closure. When `cancel` is called
/// on the cancellable object, then this cancel-time closure executes.
///
///     ... AnyCancellable ... {
///         init(_ cancel: @escaping () -> Void)
///     }
let cancellableFromClosure = AnyCancellable({
    print("AnyCancellable.cancel")
})
cancellableFromClosure.cancel()

/// An `AnyCancellable` instance automatically calls `cancel` when deinitialized.
do {
    _ = AnyCancellable(MyCancellable())
}

/// This is useful because cancellables can then be put in a collection,
/// all of which can then be cancelled in one go.
///
/// `Cancellable` comes with built in support for doing that.
do {
    var setOfAnyCancellables = Set<AnyCancellable>()
    AnyCancellable(MyCancellable()).store(in: &setOfAnyCancellables)
    AnyCancellable(MyCancellable()).store(in: &setOfAnyCancellables)
}

/// There are actually two separate methods for storing cancellables in
/// collections.
///
///     extension AnyCancellable {
///         func store<C>(in collection: inout C) where C : RangeReplacableCollection, C.Element == AnyCancellable
///         func store(in set: inout Set<AnyCancellable>)
///     }
///
/// One might think that a separate method for storing in sets is because
/// sets are somehow the more preferred mechanism; but no, that's just because
/// sets do not conform to `RangeReplacableCollection`.
///
/// > `Array` conforms to `RangeReplacableCollection`, but `Set` does not,
///   so it needs its own method. ...The only reason to store your subscriptions
///   in a `Set` is if you need to  efficiently remove a single subscription
///   from the set and the set may be large. Otherwise just use an Array.
///
/// https://stackoverflow.com/questions/63543450/what-is-the-reason-to-store-subscription-into-a-subscriptions-set
///
/// But why a separate method to `store`? Surely we can use the existing
/// `Collection` methods to add the any cancellable to the collection?
///
/// This is becase a method on the `AnyCancellable` makes it easier to
/// chain actions:
do {
    var cancellables = [AnyCancellable]()
    // Ignore these two lines for now, this is just inteded to show a
    // chain of actions producing an `AnyCancellable`.
    Empty<Void, Never>()
        .sink(receiveCompletion: { _ in print("completed") }, receiveValue: {})
        // Note how the store can be chained at the end.
        .store(in: &cancellables)
}
