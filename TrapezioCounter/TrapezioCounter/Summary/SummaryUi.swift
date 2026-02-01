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

struct SummaryUI: TrapezioUI {
    func map(state: SummaryState, onEvent: @escaping @MainActor (SummaryEvent) -> Void) -> some View {
        VStack(spacing: 30) {
            Text("Summary")
                .font(.title.bold())

            Text("\(state.value)")
                .font(.system(size: 60, weight: .bold, design: .monospaced))

            HStack(spacing: 16) {
                Button("Back") {
                    onEvent(.back)
                }
                .buttonStyle(.bordered)

                Button("Print Current Value") {
                    onEvent(.printValue)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
