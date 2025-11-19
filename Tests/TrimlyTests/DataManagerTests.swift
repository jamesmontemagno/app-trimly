//
//  DataManagerTests.swift
//  TrimlyTests
//
//  Created by Trimly on 11/19/2025.
//

import XCTest
@testable import Trimly

final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        dataManager = await DataManager(inMemory: true)
    }
    
    override func tearDown() async throws {
        dataManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Weight Entry Tests
    
    @MainActor
    func testAddWeightEntry() throws {
        // Add an entry
        try dataManager.addWeightEntry(
            weightKg: 80.0,
            unit: .kilograms,
            notes: "Test entry"
        )
        
        // Fetch entries
        let entries = dataManager.fetchAllEntries()
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.weightKg, 80.0)
        XCTAssertEqual(entries.first?.notes, "Test entry")
    }
    
    @MainActor
    func testFetchEntriesForDate() throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Add entries for today and yesterday
        try dataManager.addWeightEntry(
            weightKg: 80.0,
            timestamp: today,
            unit: .kilograms
        )
        
        try dataManager.addWeightEntry(
            weightKg: 81.0,
            timestamp: yesterday,
            unit: .kilograms
        )
        
        // Fetch today's entries
        let todayEntries = dataManager.fetchEntriesForDate(today)
        
        XCTAssertEqual(todayEntries.count, 1)
        XCTAssertEqual(todayEntries.first?.weightKg, 80.0)
    }
    
    // MARK: - Goal Tests
    
    @MainActor
    func testSetGoal() throws {
        // Set a goal
        try dataManager.setGoal(
            targetWeightKg: 75.0,
            startingWeightKg: 80.0
        )
        
        // Fetch active goal
        let goal = dataManager.fetchActiveGoal()
        
        XCTAssertNotNil(goal)
        XCTAssertEqual(goal?.targetWeightKg, 75.0)
        XCTAssertEqual(goal?.startingWeightKg, 80.0)
        XCTAssertTrue(goal?.isActive ?? false)
    }
    
    @MainActor
    func testChangeGoal() throws {
        // Set initial goal
        try dataManager.setGoal(
            targetWeightKg: 75.0,
            startingWeightKg: 80.0
        )
        
        // Change goal
        try dataManager.setGoal(
            targetWeightKg: 70.0,
            startingWeightKg: 80.0
        )
        
        // Check active goal changed
        let activeGoal = dataManager.fetchActiveGoal()
        XCTAssertEqual(activeGoal?.targetWeightKg, 70.0)
        
        // Check old goal is in history
        let history = dataManager.fetchGoalHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.targetWeightKg, 75.0)
        XCTAssertFalse(history.first?.isActive ?? true)
    }
    
    // MARK: - Export Tests
    
    @MainActor
    func testExportCSV() throws {
        // Add some entries
        try dataManager.addWeightEntry(
            weightKg: 80.0,
            unit: .kilograms,
            notes: "Entry 1"
        )
        
        try dataManager.addWeightEntry(
            weightKg: 79.5,
            unit: .kilograms,
            notes: "Entry 2"
        )
        
        let csv = dataManager.exportToCSV()
        
        // Check CSV contains headers
        XCTAssertTrue(csv.contains("id,timestamp,normalizedDate"))
        
        // Check CSV contains data
        XCTAssertTrue(csv.contains("80.00"))
        XCTAssertTrue(csv.contains("79.50"))
        XCTAssertTrue(csv.contains("Entry 1"))
        XCTAssertTrue(csv.contains("Entry 2"))
    }
}
