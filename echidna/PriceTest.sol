// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";

using PriceLibrary for uint256;

contract PriceTest {

  function storePrice_setter_getter_test(
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer = get_a_price_pointer();
    pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    assert(logPrice == pointer.log());
    assert(sqrtPrice == pointer.sqrt(false));
    assert(sqrtInversePrice == pointer.sqrt(true));
  }

  function storePrice_with_height_test(
    uint16 seed_height,
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X15 heightPrice = get_a_height(seed_height);
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer = get_a_price_pointer();
    pointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
    assert(heightPrice == pointer.height());
    assert(logPrice == pointer.log());
    assert(sqrtPrice == pointer.sqrt(false));
    assert(sqrtInversePrice == pointer.sqrt(true));
  }

  function height_test(
    uint16 seed_height,
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X15 heightPrice = get_a_height(seed_height);
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer = get_a_price_pointer();
    pointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
    assert(heightPrice == pointer.height());
  }

  function log_test(
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer = get_a_price_pointer();
    pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    assert(logPrice == pointer.log());
  }

  function sqrt_test(
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer = get_a_price_pointer();
    pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    assert(sqrtPrice == pointer.sqrt(false));
    assert(sqrtInversePrice == pointer.sqrt(true));
  }

  function copyPrice_test(
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer0 = get_a_price_pointer();
    uint256 pointer1 = get_a_price_pointer();
    pointer1.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
    pointer0.copyPrice(pointer1);
    assert(logPrice == pointer0.log());
    assert(sqrtPrice == pointer0.sqrt(false));
    assert(sqrtInversePrice == pointer0.sqrt(true));
  }

  function copyPriceWithHeight_test(
    uint16 seed_height,
    uint64 seed_log,
    uint216 seed_sqrt,
    uint216 seed_sqrtInverse
  ) public pure {
    X15 heightPrice = get_a_height(seed_height);
    X59 logPrice = get_a_logPrice(seed_log);
    X216 sqrtPrice = X216.wrap(int256(uint256(seed_sqrt)));
    X216 sqrtInversePrice = X216.wrap(int256(uint256(seed_sqrtInverse)));
    uint256 pointer0 = get_a_price_pointer();
    uint256 pointer1 = get_a_price_pointer();
    pointer1.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
    pointer0.copyPriceWithHeight(pointer1);
    assert(heightPrice == pointer0.height());
    assert(logPrice == pointer0.log());
    assert(sqrtPrice == pointer0.sqrt(false));
    assert(sqrtInversePrice == pointer0.sqrt(true));
  }

  function segment_test(
    uint64 seed_b0,
    uint64 seed_b1,
    uint16 seed_c0,
    uint16 seed_c1
  ) public pure {
    X59 b0 = get_a_logPrice(seed_b0);
    X59 b1 = get_a_logPrice(seed_b1);
    X15 c0 = get_a_height(seed_c0);
    X15 c1 = get_a_height(seed_c1);
    (X216 sqrt0, X216 sqrtInverse0) = b0.exp();
    (X216 sqrt1, X216 sqrtInverse1) = b1.exp();
    uint256 pointer = get_a_segment_pointer();
    pointer.storePrice(c0, b0, sqrt0, sqrtInverse0);
    (pointer + 64).storePrice(c1, b1, sqrt1, sqrtInverse1);
    (
      X59 b0Result,
      X59 b1Result,
      X15 c0Result,
      X15 c1Result
    ) = pointer.segment();
    assert(b0Result == b0);
    assert(b1Result == b1);
    assert(c0Result == c0);
    assert(c1Result == c1);
  }

}


