//
//  TaskCancellerStoreTests.swift
//  TaskCancellerStoreTests
//
//  Created by treastrain on 2024/06/02.
//

import XCTest
@testable import TaskCancellerStore

final class TaskCancellerStoreTests: XCTestCase {
    fileprivate final class Object: TaskCancellerStorable {
        var subscriberTask: Task<(), any Error>?
        func subscribe() {
            #if canImport(ObjectiveC)
            let (stream, _) = AsyncThrowingStream.makeStream(of: Void.self)
            subscriberTask = Task { [unowned self] in
                for try await _ in stream {}
                try Task.checkCancellation()
                dummy()
            }
            .storeWhileInstanceActive(self)
            #endif
        }
        
        func dummy() {}
    }
    
    var cancelCallCount = 0
    func testCancelBag() throws {
        #if canImport(ObjectiveC)
        let object = Object()
        object.transientStorage.cancelBag.insert {
            self.cancelCallCount += 1
        }
        addTeardownBlock { [weak object] in
            XCTAssertEqual(self.cancelCallCount, 1)
            XCTAssertNil(object)
        }
        #else
        throw XCTSkip("Objective-C is not available")
        #endif
    }
    
    func testStorageCancelBag() throws {
        #if canImport(ObjectiveC)
        let object = Object()
        let firstCancelBag = object.transientStorage.cancelBag
        let secondCancelBag = object.transientStorage.cancelBag
        XCTAssertIdentical(firstCancelBag, secondCancelBag)
        #else
        throw XCTSkip("Objective-C is not available")
        #endif
    }
    
    func testTaskStoreWhileInstanceActive() async throws {
        #if canImport(ObjectiveC)
        let object = Object()
        object.subscribe()
        let subscriberTask = try XCTUnwrap(object.subscriberTask)
        addTeardownBlock { [weak object] in
            XCTAssertTrue(subscriberTask.isCancelled)
            XCTAssertNil(object)
        }
        #else
        throw XCTSkip("Objective-C is not available")
        #endif
    }
}

extension TaskCancellerStoreTests: @unchecked Sendable {}
extension TaskCancellerStoreTests.Object: @unchecked Sendable {}
