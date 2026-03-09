# NoFeeSwap Echidna Fuzz Tests

Echidna assertion-mode fuzz tests for NoFeeSwap core contracts.

## Question 1 — Price.sol

**File:** `echidna/PriceTest.sol`  
**Config:** `echidna/echidna.config.Price.yml`

### Tests
- `storePrice_setter_getter_test` — store and read back logPrice, sqrtPrice, sqrtInversePrice
- `storePrice_with_height_test` — same with height field
- `height_test` — height field isolated
- `log_test` — logPrice field isolated
- `sqrt_test` — sqrtPrice field isolated
- `copyPrice_test` — mcopy-based price copy
- `copyPriceWithHeight_test` — copy with height
- `segment_test` — two consecutive prices in memory

### Run
```bash
docker run --rm -v $(pwd):/code ghcr.io/crytic/echidna/echidna:latest \
  echidna /code/echidna/PriceTest.sol \
  --contract PriceTest \
  --config /code/echidna/echidna.config.Price.yml
```

### Result
```
All 8 tests passing — 100,283 calls, 2,255 unique instructions, 0 failures
```

---

## Question 2 — Calldata.sol (readModifyPositionInput)

**File:** `echidna/CalldataTest.sol`  
**Config:** `echidna.config.Calldata.yml`

### Architecture
`readModifyPositionInput()` is internal and reads raw calldata via `calldataload()`. A helper contract `CalldataTestHelper` calls it directly and returns all memory fields as returndata, allowing the Echidna harness to assert on them.

### Tests
- `readModifyPositionInput_test` — all 12 memory fields match input for any valid combination
- `zeroShares_reverts_test` — shares == 0 always reverts
- `outOfRangeLogPrice_reverts_test` — qMin == 0 always reverts
- `gapIndependence_test` — different hookData pointer gaps produce identical decoded fields (non-strict encoding)

### Run
```bash
docker run --rm -v $(pwd):/code ghcr.io/crytic/echidna/echidna:latest \
  echidna /code/echidna/CalldataTest.sol \
  --contract CalldataTest \
  --config /code/echidna.config.Calldata.yml
```

### Result
```
All 4 tests passing — 100,285 calls, 6,093 unique instructions, 0 failures
```

---

## Sanity Checks (deliberate bug injection)

Both test suites were verified to catch bugs:

- **Q1:** Adding 1 to logPrice read → Echidna caught it in under 1 second, shrunk counterexample to `(0,0,0)`
- **Q2:** Adding 1 to logPriceMin read → Echidna caught it, shrunk counterexample to `(0,0,0,0,0,0,0)`
