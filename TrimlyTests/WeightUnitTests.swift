import Foundation
import Testing
@testable import TrimTally

@MainActor
struct WeightUnitTests {
	
	@Test
	func kilograms_toKilograms_isIdentity() async throws {
		let kg = 80.0
		let converted = WeightUnit.kilograms.convert(fromKg: kg)
		#expect(converted == kg)
		
		let backToKg = WeightUnit.kilograms.convertToKg(converted)
		#expect(backToKg == kg)
	}
	
	@Test
	func pounds_conversion_isAccurate() async throws {
		let kg = 80.0
		let expectedPounds = kg * 2.20462
		
		let convertedPounds = WeightUnit.pounds.convert(fromKg: kg)
		#expect(abs(convertedPounds - expectedPounds) < 0.0001)
		
		let backToKg = WeightUnit.pounds.convertToKg(convertedPounds)
		#expect(abs(backToKg - kg) < 0.0001)
	}
	
	@Test
	func stones_conversion_isAccurate() async throws {
		let kg = 80.0
		let expectedStones = kg / 6.35029
		
		let convertedStones = WeightUnit.stones.convert(fromKg: kg)
		#expect(abs(convertedStones - expectedStones) < 0.0001)
		
		let backToKg = WeightUnit.stones.convertToKg(convertedStones)
		#expect(abs(backToKg - kg) < 0.0001)
	}
	
	@Test
	func stones_conversion_commonValues() async throws {
		// Test 70 kg ≈ 11.02 stones
		let kg70 = 70.0
		let stones70 = WeightUnit.stones.convert(fromKg: kg70)
		#expect(abs(stones70 - 11.02) < 0.1) // Allow 0.1 tolerance
		
		// Test 90 kg ≈ 14.17 stones
		let kg90 = 90.0
		let stones90 = WeightUnit.stones.convert(fromKg: kg90)
		#expect(abs(stones90 - 14.17) < 0.1) // Allow 0.1 tolerance
		
		// Test reverse: 10 stones ≈ 63.5 kg
		let stones10 = 10.0
		let kg10 = WeightUnit.stones.convertToKg(stones10)
		#expect(abs(kg10 - 63.5) < 0.1) // Allow 0.1 tolerance
	}
	
	@Test
	func stones_symbol_isCorrect() async throws {
		#expect(WeightUnit.stones.symbol == "st")
		#expect(WeightUnit.pounds.symbol == "lb")
		#expect(WeightUnit.kilograms.symbol == "kg")
	}
	
	@Test
	func stones_roundTripConversion_preservesValue() async throws {
		// Test that converting kg -> stones -> kg preserves the original value
		let originalKg = 75.5
		let stones = WeightUnit.stones.convert(fromKg: originalKg)
		let backToKg = WeightUnit.stones.convertToKg(stones)
		#expect(abs(backToKg - originalKg) < 0.0001)
	}
}
