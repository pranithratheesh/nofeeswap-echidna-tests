# NoFeeSwap Echidna Fuzz Tests

Echidna assertion mode fuzz tests for NoFeeSwap core contracts.

## Question 1 - Price.sol

**File:** echidna/PriceTest.sol
**Config:** echidna/echidna.config.Price.yml

### Tests
- storePrice_setter_getter_test
- storePrice_with_height_test
- height_test
- log_test
- sqrt_test
- copyPrice_test
- copyPriceWithHeight_test
- segment_test

### Result
All 8 tests passing - 100,283 calls, 0 failures

## Question 2 - Calldata.sol readModifyPositionInput

**File:** echidna/CalldataTest.sol
**Config:** echidna.config.Calldata.yml

### Tests
- readModifyPositionInput_test - all memory fields match input
- zeroShares_reverts_test - shares == 0 always reverts
- outOfRangeLogPrice_reverts_test - qMin == 0 always reverts
- gapIndependence_test - non-strict encoding, different gaps same result

### Result
All 4 tests passing - 100,285 calls, 0 failures

## Sanity Checks
Both suites verified to catch deliberate bugs instantly.
