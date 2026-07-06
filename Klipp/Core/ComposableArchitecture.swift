//
//  ComposableArchitecture.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Combine
import Foundation
import SwiftUI

struct Effect<Action> {
    let run: (@escaping (Action) -> Void) -> Void

    static var none: Self {
        Self { _ in }
    }

    static func send(_ action: Action) -> Self {
        Self { send in send(action) }
    }

    static func fireAndForget(_ work: @escaping () -> Void) -> Self {
        Self { _ in work() }
    }

    static func merge(_ effects: [Effect<Action>]) -> Self {
        Self { send in
            for effect in effects {
                effect.run(send)
            }
        }
    }

    static func merge(_ effects: Effect<Action>...) -> Self {
        merge(effects)
    }

}

final class Store<State, Action>: ObservableObject {
    @Published private(set) var state: State

    private let reducer: (inout State, Action) -> Effect<Action>

    init(
        initialState: State,
        reducer: @escaping (inout State, Action) -> Effect<Action>
    ) {
        self.state = initialState
        self.reducer = reducer
    }

    func send(_ action: Action) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.send(action)
            }
            return
        }

        let effect = reducer(&state, action)
        effect.run { [weak self] action in
            self?.send(action)
        }
    }

    func binding<Value>(
        get: @escaping (State) -> Value,
        send action: @escaping (Value) -> Action
    ) -> Binding<Value> {
        Binding(
            get: { get(self.state) },
            set: { value in
                DispatchQueue.main.async { [weak self] in
                    self?.send(action(value))
                }
            }
        )
    }
}
