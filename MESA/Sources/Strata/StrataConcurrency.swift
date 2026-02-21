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

import Foundation

/// Launches work off the main thread and delivers the result to the main thread for state reduction.
///
/// `work` runs in a detached task on the cooperative thread pool — completely off the main thread,
/// whether or not a `StrataInteractor` is used. `reduce` is called on the `@MainActor` once work
/// completes, guaranteeing all UI state updates happen on the main thread.
///
/// ```swift
/// // With interactor
/// let count = state.count
/// strataLaunch(
///     work: { await interactor.execute(params: count) },
///     reduce: { result in
///         result.fold(
///             onSuccess: { data in update { $0.data = data } },
///             onFailure: { error in update { $0.error = error.message } }
///         )
///     }
/// )
///
/// // Without interactor
/// let url = endpoint
/// strataLaunch(
///     work: { await strataRunCatching { try await URLSession.shared.data(from: url) } },
///     reduce: { result in update { $0.data = result.getOrNull() } }
/// )
///
/// // Parallel — replaces nested strataLaunches
/// let (x, y) = (paramA, paramB)
/// strataLaunch(
///     work: {
///         async let a = interactorA.execute(params: x)
///         async let b = interactorB.execute(params: y)
///         return await (a, b)
///     },
///     reduce: { (a, b) in
///         update { $0.a = a.getOrNull(); $0.b = b.getOrNull() }
///     }
/// )
/// ```
@discardableResult
public func strataLaunch<T: Sendable>(
    priority: TaskPriority? = nil,
    work: @escaping @Sendable () async -> T,
    reduce: @escaping @MainActor @Sendable (T) -> Void
) -> Task<Void, Never> {
    Task.detached(priority: priority) {
        let result = await work()
        await MainActor.run { reduce(result) }
    }
}

/// Legacy/migration interop — launches throwing work off the main thread with `@MainActor` reduce and catch.
///
/// `work` runs in a detached task on the cooperative thread pool — completely off the main thread.
/// On success, `reduce` is called on the `@MainActor` with the result value.
/// On failure, `catch` is called on the `@MainActor` with the plain `Error`.
/// No MESA types (`StrataResult`, `StrataException`) are required — use `strataLaunch` with interactors
/// for new code that has fully adopted Strata.
///
/// ```swift
/// // Fire-and-forget with error handling (reduce omitted)
/// strataLaunchInterop(
///     work: { try await legacyService.sync() },
///     catch: { error in update { $0.error = error.localizedDescription } }
/// )
///
/// // With result
/// strataLaunchInterop(
///     work: { try await legacyAPI.fetchItems() },
///     reduce: { items in update { $0.items = items } },
///     catch: { error in update { $0.error = error.localizedDescription } }
/// )
/// ```
@discardableResult
public func strataLaunchInterop<T: Sendable>(
    priority: TaskPriority? = nil,
    work: @escaping @Sendable () async throws -> T,
    reduce: @escaping @MainActor @Sendable (T) -> Void = { _ in },
    catch: @escaping @MainActor @Sendable (Error) -> Void
) -> Task<Void, Never> {
    Task.detached(priority: priority) {
        do {
            let result = try await work()
            await MainActor.run { reduce(result) }
        } catch {
            await MainActor.run { `catch`(error) }
        }
    }
}

/// Launches work off the main thread, wrapping the result in `StrataResult`.
///
/// Returns a `Task` handle for deferred awaiting, parallel execution, or cancellation.
/// The operation closure may throw — errors are caught and returned as `.failure`.
/// When `.value` is awaited from a `@MainActor` context, execution resumes on the main thread.
///
/// ```swift
/// let a = strataLaunchWithResult { try await apiA.fetch() }
/// let b = strataLaunchWithResult { try await apiB.fetch() }
/// let (ra, rb) = await (a.value, b.value)
/// ```
@discardableResult
public func strataLaunchWithResult<T: Sendable>(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> T
) -> Task<StrataResult<T>, Never> {
    Task.detached(priority: priority) {
        await strataRunCatching { try await operation() }
    }
}

/// Collects an `AsyncStream` off the main thread, delivering each value to the main thread.
///
/// Stream iteration runs in a detached task — completely off the main thread.
/// `action` is called on the `@MainActor` for each emitted value, guaranteeing all UI state
/// updates happen on the main thread.
///
/// ```swift
/// strataCollect(observeUseCase.stream) { value in
///     update { $0.latest = value }
/// }
/// ```
@discardableResult
public func strataCollect<T: Sendable>(
    _ stream: AsyncStream<T>,
    priority: TaskPriority? = nil,
    action: @escaping @MainActor @Sendable (T) -> Void
) -> Task<Void, Never> {
    Task.detached(priority: priority) {
        for await value in stream {
            await MainActor.run { action(value) }
        }
    }
}
