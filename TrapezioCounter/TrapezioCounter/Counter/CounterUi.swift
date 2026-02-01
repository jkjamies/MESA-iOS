/*
 * Copyright 2026 Jason Jamieson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import SwiftUI
import Trapezio
import TrapezioNavigation

struct CounterUI: TrapezioUI {
    func map(state: CounterState, onEvent: @escaping @MainActor (CounterEvent) -> Void) -> some View {
        VStack(spacing: 30) {
            Text("\(state.count)")
                .font(.system(size: 60, weight: .bold, design: .monospaced))
            
            HStack(spacing: 20) {
                Button("-") { onEvent(.decrement) }
                    .buttonStyle(.bordered)
                
                Button("÷2") { onEvent(.divideByTwo) }
                    .buttonStyle(.borderedProminent)
                
                Button("+") { onEvent(.increment) }
                    .buttonStyle(.bordered)
            }

            Button("Help") { onEvent(.requestHelp) }
                .buttonStyle(.borderless)
            
            Divider().padding(.horizontal)

            Button("Go To Summary") {
                onEvent(.goToSummary)
            }
            .font(.headline)
        }
        .padding()
    }
}
