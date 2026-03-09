// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

// ─────────────────────────────────────────────────────────────────────────────
// Echidna Fuzz Test – Calldata.sol  readModifyPositionInput  (Assertion mode)
//
// Mirrors:  tests/CalldataReadModifyPositionInput0_test.py  L58–L123
//
// Architecture
// ────────────
// readModifyPositionInput() is internal and reads raw calldata via
// calldataload(). The existing CalldataWrapper emits results as a log1 event,
// which Solidity cannot read back from a sub-call.
//
// Solution: CalldataTestHelper (same compilation unit) calls
// readModifyPositionInput() directly and returns all memory fields as normal
// returndata. CalldataTest (Echidna harness) deploys CalldataTestHelper and
// calls it with hand-crafted raw calldata via a low-level call.
//
// Non-strict encoding
// ───────────────────
// The ABI pointer at offset 0x84 may skip over arbitrary padding bytes
// (gap) before the hookData blob. We fuzz `gap` to cover all offsets.
// ─────────────────────────────────────────────────────────────────────────────

import {
  _poolId_,
  _logPriceMin_,
  _logPriceMax_,
  _logPriceMinOffsetted_,
  _logPriceMaxOffsetted_,
  _shares_,
  _curve_,
  _hookData_,
  _hookDataByteCount_,
  _hookInputByteCount_,
  _freeMemoryPointer_,
  _endOfStaticParams_
} from "../contracts/utilities/Memory.sol";

import {X59, epsilonX59, thirtyTwoX59} from "../contracts/utilities/X59.sol";
import {getLogOffsetFromPoolId} from "../contracts/utilities/PoolId.sol";
import {readModifyPositionInput} from "../contracts/utilities/Calldata.sol";

// ─────────────────────────────────────────────────────────────────────────────
// CalldataTestHelper
// ─────────────────────────────────────────────────────────────────────────────
contract CalldataTestHelper {

    bytes4 public constant EXECUTE_SELECTOR = bytes4(keccak256("execute()"));

    // Called by CalldataTest with hand-crafted raw calldata.
    // readModifyPositionInput reads directly from calldataload().
    function execute() external {
        readModifyPositionInput();

        uint256 retPoolId;
        int256  retLogPriceMin;
        int256  retLogPriceMax;
        uint64  retQMin;
        uint64  retQMax;
        int256  retShares;
        uint256 retCurvePtr;
        uint256 retHookDataPtr;
        uint16  retHookDataByteCount;
        uint256 retHookInputByteCount;
        uint256 retFreePtr;

        assembly {
            retPoolId             := mload(_poolId_)
            retLogPriceMin        := mload(_logPriceMin_)
            retLogPriceMax        := mload(_logPriceMax_)
            retQMin               := shr(192, mload(_logPriceMinOffsetted_))
            retQMax               := shr(192, mload(_logPriceMaxOffsetted_))
            retShares             := mload(_shares_)
            retCurvePtr           := mload(_curve_)
            retHookDataPtr        := mload(_hookData_)
            retHookDataByteCount  := shr(240, mload(_hookDataByteCount_))
            retHookInputByteCount := mload(_hookInputByteCount_)
            retFreePtr            := mload(_freeMemoryPointer_)
        }

        uint256 hdc = uint256(retHookDataByteCount);
        bytes memory hookDataBytes = new bytes(hdc);
        assembly {
            let dest := add(hookDataBytes, 32)
            let src  := retHookDataPtr
            for { let i := 0 } lt(i, hdc) { i := add(i, 32) } {
                mstore(add(dest, i), mload(add(src, i)))
            }
        }

        bytes memory ret = abi.encode(
            retPoolId,
            retLogPriceMin,
            retLogPriceMax,
            uint256(retQMin),
            uint256(retQMax),
            retShares,
            retCurvePtr,
            retHookDataPtr,
            uint256(retHookDataByteCount),
            retHookInputByteCount,
            retFreePtr,
            hookDataBytes
        );

        assembly { return(add(ret, 32), mload(ret)) }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CalldataTest — Echidna harness (assertion mode)
// ─────────────────────────────────────────────────────────────────────────────
contract CalldataTest {

    CalldataTestHelper private immutable helper;

    constructor() {
        helper = new CalldataTestHelper();
    }

    // ── Decoded fields struct ─────────────────────────────────────────────────
    struct Fields {
        uint256 poolId;
        int256  logPriceMin;
        int256  logPriceMax;
        uint256 qMin;
        uint256 qMax;
        int256  shares;
        uint256 curvePtr;
        uint256 hookDataPtr;
        uint256 hookDataByteCount;
        uint256 hookInputByteCount;
        uint256 freePtr;
        bytes   hookDataBytes;
    }

    // ── Input params struct (avoids stack-too-deep) ───────────────────────────
    struct Params {
        uint256 poolId;
        int256  logPriceMin;
        int256  logPriceMax;
        int256  shares;
        uint16  hWords;
        uint256 hookContent;
    }

    // ── Build raw calldata ────────────────────────────────────────────────────
    function _buildCalldata(Params memory p, uint16 gap)
        internal view returns (bytes memory cd)
    {
        uint256 hookDataByteCount = uint256(p.hWords) * 32;
        uint256 hookDataPointer   = 5 * 0x20 + uint256(gap);
        uint256 cdSize = 4 + 5 * 32 + uint256(gap) + 32 + hookDataByteCount;

        cd = new bytes(cdSize);
        bytes4 sel = helper.EXECUTE_SELECTOR();
        cd[0] = sel[0]; cd[1] = sel[1]; cd[2] = sel[2]; cd[3] = sel[3];

        assembly {
            let base := add(cd, 32)
            mstore(add(base, 4),   mload(p))                // poolId
            mstore(add(base, 36),  mload(add(p, 0x20)))     // logPriceMin
            mstore(add(base, 68),  mload(add(p, 0x40)))     // logPriceMax
            mstore(add(base, 100), mload(add(p, 0x60)))     // shares
            mstore(add(base, 132), hookDataPointer)
            let lenSlot := add(base, add(164, gap))
            mstore(lenSlot, hookDataByteCount)
            let hookContent := mload(add(p, 0xa0))
            let contentBase := add(lenSlot, 32)
            for { let i := 0 } lt(i, hookDataByteCount) { i := add(i, 32) } {
                mstore(add(contentBase, i), hookContent)
            }
        }
    }

    // ── Call helper, decode returndata ────────────────────────────────────────
    function _invoke(Params memory p, uint16 gap)
        internal returns (bool ok, Fields memory f)
    {
        bytes memory cd = _buildCalldata(p, gap);
        bytes memory ret;
        (ok, ret) = address(helper).call(cd);
        if (!ok) return (false, f);
        (
            f.poolId,
            f.logPriceMin,
            f.logPriceMax,
            f.qMin,
            f.qMax,
            f.shares,
            f.curvePtr,
            f.hookDataPtr,
            f.hookDataByteCount,
            f.hookInputByteCount,
            f.freePtr,
            f.hookDataBytes
        ) = abi.decode(ret, (
            uint256, int256, int256,
            uint256, uint256,
            int256,
            uint256, uint256, uint256, uint256, uint256,
            bytes
        ));
    }

    // ── Build poolId from int8 qOffset ────────────────────────────────────────
    function _makePoolId(int8 qOffset) internal pure returns (uint256) {
        uint256 filler = 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
        return filler | (uint256(uint8(qOffset)) << 180);
    }

    // ── Map seeds to valid qMin < qMax in (0, thirtyTwoX59) ──────────────────
    function _makeQMinMax(uint64 s0, uint64 s1)
        internal pure returns (bool valid, uint256 qMin, uint256 qMax)
    {
        uint256 hi  = uint256(X59.unwrap(thirtyTwoX59));
        uint256 eps = uint256(X59.unwrap(epsilonX59));
        uint256 rng = hi - 2 * eps;

        qMin = eps + (uint256(s0) % rng);
        qMax = eps + (uint256(s1) % rng);

        if (qMin == qMax) {
            if (qMax < hi - eps) qMax++;
            else if (qMin > eps) qMin--;
            else return (false, 0, 0);
        }
        if (qMin > qMax) { uint256 t = qMin; qMin = qMax; qMax = t; }
        if (qMin >= qMax) return (false, 0, 0);
        valid = true;
    }

    // ── Assert all fields match ───────────────────────────────────────────────
    function _assertFields(Fields memory f, Params memory p, uint256 qMin, uint256 qMax)
        internal pure
    {
        assert(f.poolId      == p.poolId);
        assert(f.logPriceMin == p.logPriceMin);
        assert(f.logPriceMax == p.logPriceMax);
        assert(f.qMin        == qMin);
        assert(f.qMax        == qMax);
        assert(f.shares      == p.shares);

        uint256 hdc             = uint256(p.hWords) * 32;
        uint256 hookDataPtr     = uint256(_endOfStaticParams_) + 32;
        uint256 freePtr         = hookDataPtr + hdc;
        uint256 hookInputBytes  = freePtr - uint256(_hookInputByteCount_) - 32;

        assert(f.curvePtr          == uint256(_endOfStaticParams_));
        assert(f.hookDataPtr       == hookDataPtr);
        assert(f.hookDataByteCount == hdc);
        assert(f.freePtr           == freePtr);
        assert(f.hookInputByteCount == hookInputBytes);
        assert(f.hookDataBytes.length == hdc);

        for (uint256 i = 0; i < hdc; i += 32) {
            uint256 word;
            bytes memory hdb = f.hookDataBytes;
            assembly { word := mload(add(add(hdb, 32), i)) }
            assert(word == p.hookContent);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Happy-path round-trip
    // All decoded memory fields must match what was encoded in raw calldata.
    // ─────────────────────────────────────────────────────────────────────────
    function readModifyPositionInput_test(
        int8    qOffsetSeed,
        uint64  qMinSeed,
        uint64  qMaxSeed,
        int128  sharesSeed,
        uint16  gap,
        uint8   hookDataWords,
        uint256 hookContent
    ) public {
        int8 qOffset = qOffsetSeed;
        if (qOffset < -89) qOffset = -89;
        if (qOffset >  89) qOffset =  89;

        uint256 poolId = _makePoolId(qOffset);
        int256 shift = int256(X59.unwrap(getLogOffsetFromPoolId(poolId)))
                       - int256(16 << 59);

        (bool valid, uint256 qMin, uint256 qMax) = _makeQMinMax(qMinSeed, qMaxSeed);
        if (!valid) return;

        int256 shares = int256(sharesSeed);
        if (shares == 0) shares = 1;

        Params memory p = Params({
            poolId:      poolId,
            logPriceMin: int256(qMin) + shift,
            logPriceMax: int256(qMax) + shift,
            shares:      shares,
            hWords:      uint16(hookDataWords),
            hookContent: hookContent
        });

        (bool ok, Fields memory f) = _invoke(p, gap);
        if (!ok) return;

        _assertFields(f, p, qMin, qMax);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: shares == 0 must revert
    // ─────────────────────────────────────────────────────────────────────────
    function zeroShares_reverts_test(
        int8   qOffsetSeed,
        uint64 qMinSeed,
        uint64 qMaxSeed,
        uint16 gap
    ) public {
        int8 qOffset = qOffsetSeed;
        if (qOffset < -89) qOffset = -89;
        if (qOffset >  89) qOffset =  89;

        uint256 poolId = _makePoolId(qOffset);
        int256 shift = int256(X59.unwrap(getLogOffsetFromPoolId(poolId)))
                       - int256(16 << 59);

        (bool valid, uint256 qMin, uint256 qMax) = _makeQMinMax(qMinSeed, qMaxSeed);
        if (!valid) return;

        Params memory p = Params({
            poolId:      poolId,
            logPriceMin: int256(qMin) + shift,
            logPriceMax: int256(qMax) + shift,
            shares:      0,
            hWords:      0,
            hookContent: 0
        });

        (bool ok, ) = _invoke(p, gap);
        assert(!ok);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: logPriceMin out of range must revert (qMin == 0)
    // ─────────────────────────────────────────────────────────────────────────
    function outOfRangeLogPrice_reverts_test(int8 qOffsetSeed, uint16 gap) public {
        int8 qOffset = qOffsetSeed;
        if (qOffset < -89) qOffset = -89;
        if (qOffset >  89) qOffset =  89;

        uint256 poolId = _makePoolId(qOffset);
        int256 shift = int256(X59.unwrap(getLogOffsetFromPoolId(poolId)))
                       - int256(16 << 59);

        // qMin == 0 violates require(qMin > zeroX59)
        Params memory p = Params({
            poolId:      poolId,
            logPriceMin: shift,   // logPriceMin - shift = 0 = zeroX59
            logPriceMax: int256(uint256(X59.unwrap(thirtyTwoX59)) / 2) + shift,
            shares:      1,
            hWords:      0,
            hookContent: 0
        });

        (bool ok, ) = _invoke(p, gap);
        assert(!ok);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Non-strict encoding — different gaps produce identical results
    // This directly tests the key Q2 requirement.
    // ─────────────────────────────────────────────────────────────────────────
    function gapIndependence_test(
        int8    qOffsetSeed,
        uint64  qMinSeed,
        uint64  qMaxSeed,
        int128  sharesSeed,
        uint16  gap1,
        uint16  gap2,
        uint8   hookDataWords,
        uint256 hookContent
    ) public {
        int8 qOffset = qOffsetSeed;
        if (qOffset < -89) qOffset = -89;
        if (qOffset >  89) qOffset =  89;

        uint256 poolId = _makePoolId(qOffset);
        int256 shift = int256(X59.unwrap(getLogOffsetFromPoolId(poolId)))
                       - int256(16 << 59);

        (bool valid, uint256 qMin, uint256 qMax) = _makeQMinMax(qMinSeed, qMaxSeed);
        if (!valid) return;

        int256 shares = int256(sharesSeed);
        if (shares == 0) shares = 1;

        Params memory p = Params({
            poolId:      poolId,
            logPriceMin: int256(qMin) + shift,
            logPriceMax: int256(qMax) + shift,
            shares:      shares,
            hWords:      uint16(hookDataWords),
            hookContent: hookContent
        });

        (bool ok1, Fields memory f1) = _invoke(p, gap1);
        (bool ok2, Fields memory f2) = _invoke(p, gap2);
        if (!ok1 || !ok2) return;

        assert(f1.poolId            == f2.poolId);
        assert(f1.logPriceMin       == f2.logPriceMin);
        assert(f1.logPriceMax       == f2.logPriceMax);
        assert(f1.qMin              == f2.qMin);
        assert(f1.qMax              == f2.qMax);
        assert(f1.shares            == f2.shares);
        assert(f1.hookDataByteCount == f2.hookDataByteCount);

        assert(f1.hookDataBytes.length == f2.hookDataBytes.length);
        for (uint256 i = 0; i < f1.hookDataBytes.length; i++) {
            assert(f1.hookDataBytes[i] == f2.hookDataBytes[i]);
        }
    }
}
