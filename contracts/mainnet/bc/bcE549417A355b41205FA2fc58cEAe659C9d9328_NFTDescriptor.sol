// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/BitMath.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import './HexStrings.sol';
import './NFTSVG.sol';

library NFTDescriptor {
    using TickMath for int24;
    using Strings for uint256;
    using HexStrings for uint256;

    uint256 constant sqrt10X128 = 1076067327063303206878105757264492625226;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        address quoteTokenAddress;
        address baseTokenAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        uint8 quoteTokenDecimals;
        uint8 baseTokenDecimals;
        bool flipRatio;
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        int24 tickSpacing;
        uint24 fee;
        address poolAddress;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) public pure returns (string memory) {
        string memory name = generateName(params, feeToPercentString(params.fee));
        string memory descriptionPartOne = generateDescriptionPartOne(
            escapeQuotes(params.quoteTokenSymbol),
            escapeQuotes(params.baseTokenSymbol),
            addressToString(params.poolAddress)
        );
        string memory descriptionPartTwo = generateDescriptionPartTwo(
            params.tokenId.toString(),
            escapeQuotes(params.baseTokenSymbol),
            addressToString(params.quoteTokenAddress),
            addressToString(params.baseTokenAddress),
            feeToPercentString(params.fee)
        );
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "attributes": ',
                                generateAllAttributes(params),
                                ', "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateAllAttributes(ConstructTokenURIParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[',
                    generateAttributeQuoted('Quote Token Address', addressToString(params.quoteTokenAddress)),
                    ',',
                    generateAttributeQuoted('Base Token Address', addressToString(params.baseTokenAddress)),
                    ',',
                    generateAttributeQuoted('Pool Address', addressToString(params.poolAddress)),
                    ',',
                    generateAttribute('Fee', Strings.toString(params.fee)),
                    ',',
                    generateAttribute('Lower Tick', NFTSVG.tickToString(params.tickLower)),
                    ',',
                    generateAttribute('Upper Tick', NFTSVG.tickToString(params.tickUpper)),
                    ',',
                    generateAttribute('Rare', NFTSVG.isRare(params.tokenId, params.poolAddress) ? 'true' : 'false'),
                    ']'
                )
            );
    }

    function generateAttributeQuoted(string memory trait, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', trait, '","value":"', value, '"}'));
    }

    function generateAttribute(string memory trait, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', trait, '","value":', value, '}'));
    }

    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function generateDescriptionPartOne(
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol,
        string memory poolAddress
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'This NFT represents a liquidity position in a ApeSwap V3 ',
                    quoteTokenSymbol,
                    '-',
                    baseTokenSymbol,
                    ' pool. ',
                    'The owner of this NFT can modify or redeem the position.\\n',
                    '\\nPool Address: ',
                    poolAddress,
                    '\\n',
                    quoteTokenSymbol
                )
            );
    }

    function generateDescriptionPartTwo(
        string memory tokenId,
        string memory baseTokenSymbol,
        string memory quoteTokenAddress,
        string memory baseTokenAddress,
        string memory feeTier
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    ' Address: ',
                    quoteTokenAddress,
                    '\\n',
                    baseTokenSymbol,
                    ' Address: ',
                    baseTokenAddress,
                    '\\nFee Tier: ',
                    feeTier,
                    '\\nToken ID: ',
                    tokenId,
                    '\\n\\n',
                    unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated.'
                )
            );
    }

    function generateName(ConstructTokenURIParams memory params, string memory feeTier)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'ApeSwap - ',
                    feeTier,
                    ' - ',
                    escapeQuotes(params.quoteTokenSymbol),
                    '/',
                    escapeQuotes(params.baseTokenSymbol),
                    ' - ',
                    tickToDecimalString(
                        !params.flipRatio ? params.tickLower : params.tickUpper,
                        params.tickSpacing,
                        params.baseTokenDecimals,
                        params.quoteTokenDecimals,
                        params.flipRatio
                    ),
                    '<>',
                    tickToDecimalString(
                        !params.flipRatio ? params.tickUpper : params.tickLower,
                        params.tickSpacing,
                        params.baseTokenDecimals,
                        params.quoteTokenDecimals,
                        params.flipRatio
                    )
                )
            );
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex + 1; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        unchecked {
            while (params.sigfigs > 0) {
                if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                    buffer[params.sigfigIndex--] = '.';
                }
                buffer[params.sigfigIndex--] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
                params.sigfigs /= 10;
            }
        }
        return string(buffer);
    }

    function tickToDecimalString(
        int24 tick,
        int24 tickSpacing,
        uint8 baseTokenDecimals,
        uint8 quoteTokenDecimals,
        bool flipRatio
    ) internal pure returns (string memory) {
        if (tick == (TickMath.MIN_TICK / tickSpacing) * tickSpacing) {
            return !flipRatio ? 'MIN' : 'MAX';
        } else if (tick == (TickMath.MAX_TICK / tickSpacing) * tickSpacing) {
            return !flipRatio ? 'MAX' : 'MIN';
        } else {
            uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
            if (flipRatio) {
                sqrtRatioX96 = uint160(uint256(1 << 192) / sqrtRatioX96);
            }
            return fixedPointToDecimalString(sqrtRatioX96, baseTokenDecimals, quoteTokenDecimals);
        }
    }

    function sigfigsRounded(uint256 value, uint8 digits) private pure returns (uint256, bool) {
        bool extraDigit;
        if (digits > 5) {
            value = value / ((10**(digits - 5)));
        }
        bool roundUp = value % 10 > 4;
        value = value / 10;
        if (roundUp) {
            value = value + 1;
        }
        // 99999 -> 100000 gives an extra sigfig
        if (value == 100000) {
            value /= 10;
            extraDigit = true;
        }
        return (value, extraDigit);
    }

    function adjustForDecimalPrecision(
        uint160 sqrtRatioX96,
        uint8 baseTokenDecimals,
        uint8 quoteTokenDecimals
    ) private pure returns (uint256 adjustedSqrtRatioX96) {
        uint256 difference = abs(int256(uint256(baseTokenDecimals)) - int256(uint256(quoteTokenDecimals)));
        if (difference > 0 && difference <= 18) {
            if (baseTokenDecimals > quoteTokenDecimals) {
                adjustedSqrtRatioX96 = sqrtRatioX96 * (10**(difference / 2));
                if (difference % 2 == 1) {
                    adjustedSqrtRatioX96 = FullMath.mulDiv(adjustedSqrtRatioX96, sqrt10X128, 1 << 128);
                }
            } else {
                adjustedSqrtRatioX96 = sqrtRatioX96 / (10**(difference / 2));
                if (difference % 2 == 1) {
                    adjustedSqrtRatioX96 = FullMath.mulDiv(adjustedSqrtRatioX96, 1 << 128, sqrt10X128);
                }
            }
        } else {
            adjustedSqrtRatioX96 = uint256(sqrtRatioX96);
        }
    }

    function abs(int256 x) private pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    // @notice Returns string that includes first 5 significant figures of a decimal number
    // @param sqrtRatioX96 a sqrt price
    function fixedPointToDecimalString(
        uint160 sqrtRatioX96,
        uint8 baseTokenDecimals,
        uint8 quoteTokenDecimals
    ) internal pure returns (string memory) {
        uint256 adjustedSqrtRatioX96 = adjustForDecimalPrecision(sqrtRatioX96, baseTokenDecimals, quoteTokenDecimals);
        uint256 value = FullMath.mulDiv(adjustedSqrtRatioX96, adjustedSqrtRatioX96, 1 << 64);

        bool priceBelow1 = adjustedSqrtRatioX96 < 2**96;
        if (priceBelow1) {
            // 10 ** 43 is precision needed to retreive 5 sigfigs of smallest possible price + 1 for rounding
            value = FullMath.mulDiv(value, 10**44, 1 << 128);
        } else {
            // leave precision for 4 decimal places + 1 place for rounding
            value = FullMath.mulDiv(value, 10**5, 1 << 128);
        }

        // get digit count
        uint256 temp = value;
        uint8 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        // don't count extra digit kept for rounding
        digits = digits - 1;

        // address rounding
        (uint256 sigfigs, bool extraDigit) = sigfigsRounded(value, digits);
        if (extraDigit) {
            digits++;
        }

        DecimalStringParams memory params;
        if (priceBelow1) {
            // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
            params.bufferLength = uint8(uint8(7) + (uint8(43) - digits));
            params.zerosStartIndex = 2;
            params.zerosEndIndex = uint8(uint256(43) - digits + 1);
            params.sigfigIndex = uint8(params.bufferLength - 1);
        } else if (digits >= 9) {
            // no decimal in price string
            params.bufferLength = uint8(digits - 4);
            params.zerosStartIndex = 5;
            params.zerosEndIndex = uint8(params.bufferLength - 1);
            params.sigfigIndex = 4;
        } else {
            // 5 sigfigs surround decimal
            params.bufferLength = 6;
            params.sigfigIndex = 5;
            params.decimalIndex = uint8(digits - 4);
        }
        params.sigfigs = sigfigs;
        params.isLessThanOne = priceBelow1;
        params.isPercent = false;

        return generateDecimalString(params);
    }

    struct FeeDigits {
        uint24 temp;
        uint8 numSigfigs;
        uint256 digits;
    }

    // @notice Returns string as decimal percentage of fee amount.
    // @param fee fee amount
    function feeToPercentString(uint24 fee) internal pure returns (string memory) {
        if (fee == 0) {
            return '0%';
        }

        FeeDigits memory feeDigits = FeeDigits(fee, 0, 0);
        while (feeDigits.temp != 0) {
            if (feeDigits.numSigfigs > 0) {
                // count all digits preceding least significant figure
                feeDigits.numSigfigs++;
            } else if (feeDigits.temp % 10 != 0) {
                feeDigits.numSigfigs++;
            }
            feeDigits.digits++;
            feeDigits.temp /= 10;
        }

        DecimalStringParams memory params;
        uint256 nZeros;
        if (feeDigits.digits >= 5) {
            // if decimal > 1 (5th digit is the ones place)
            uint256 decimalPlace = feeDigits.digits - feeDigits.numSigfigs >= 4 ? 0 : 1;
            nZeros = feeDigits.digits - 5 < (feeDigits.numSigfigs - 1)
                ? 0
                : feeDigits.digits - 5 - (feeDigits.numSigfigs - 1);
            params.zerosStartIndex = feeDigits.numSigfigs;
            params.zerosEndIndex = uint8(params.zerosStartIndex + nZeros - 1);
            params.sigfigIndex = uint8(params.zerosStartIndex - 1 + decimalPlace);
            params.bufferLength = uint8(nZeros + (feeDigits.numSigfigs + 1) + decimalPlace);
        } else {
            // else if decimal < 1
            nZeros = uint256(5) - feeDigits.digits;
            params.zerosStartIndex = 2;
            params.zerosEndIndex = uint8(nZeros + params.zerosStartIndex - 1);
            params.bufferLength = uint8(nZeros + (feeDigits.numSigfigs + 2));
            params.sigfigIndex = uint8((params.bufferLength) - 2);
            params.isLessThanOne = true;
        }
        params.sigfigs = uint256(fee) / (10**(feeDigits.digits - feeDigits.numSigfigs));
        params.isPercent = true;
        params.decimalIndex = feeDigits.digits > 4 ? uint8(feeDigits.digits - 4) : 0;

        return generateDecimalString(params);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return HexStrings.toHexString(uint256(uint160(addr)), 20);
    }

    function generateSVGImage(ConstructTokenURIParams memory params) public pure returns (string memory svg) {
        int8 overRangeValue = overRange(params.tickLower, params.tickUpper, params.tickCurrent);

        string memory defs = NFTSVG.generateSVGDefs(
            NFTSVG.SVGDefsParams({
                color1: tokenToColorHex(uint256(uint160(params.baseTokenAddress)), 136),
                color2: tokenToColorHex(uint256(uint160(params.quoteTokenAddress)), 0),
                color3: tokenToColorHex(uint256(uint160(params.baseTokenAddress)), 0),
                x1: scale(
                    getCircleCoord(uint256(uint160(params.quoteTokenAddress)), 16, params.tokenId),
                    0,
                    255,
                    50,
                    222
                ),
                y1: scale(
                    getCircleCoord(uint256(uint160(params.baseTokenAddress)), 16, params.tokenId),
                    0,
                    255,
                    50,
                    312
                ),
                x2: scale(
                    getCircleCoord(uint256(uint160(params.quoteTokenAddress)), 32, params.tokenId),
                    0,
                    255,
                    50,
                    222
                ),
                y2: scale(
                    getCircleCoord(uint256(uint160(params.baseTokenAddress)), 32, params.tokenId),
                    0,
                    255,
                    50,
                    312
                ),
                x3: scale(
                    getCircleCoord(uint256(uint160(params.quoteTokenAddress)), 48, params.tokenId),
                    0,
                    255,
                    50,
                    222
                ),
                y3: scale(
                    getCircleCoord(uint256(uint160(params.baseTokenAddress)), 48, params.tokenId),
                    0,
                    255,
                    50,
                    312
                ),
                overRange: overRangeValue
            })
        );

        string memory body = NFTSVG.generateSVGBody(
            NFTSVG.SVGBodyParams({
                quoteToken: addressToString(params.quoteTokenAddress),
                baseToken: addressToString(params.baseTokenAddress),
                poolAddress: params.poolAddress,
                quoteTokenSymbol: params.quoteTokenSymbol,
                baseTokenSymbol: params.baseTokenSymbol,
                feeTier: feeToPercentString(params.fee),
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                tickSpacing: params.tickSpacing,
                overRange: overRangeValue,
                tokenId: params.tokenId
            })
        );

        return NFTSVG.generateSVG(defs, body);
    }

    function overRange(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent
    ) private pure returns (int8) {
        if (tickCurrent < tickLower) {
            return -1;
        } else if (tickCurrent > tickUpper) {
            return 1;
        } else {
            return 0;
        }
    }

    function scale(
        uint256 n,
        uint256 inMn,
        uint256 inMx,
        uint256 outMn,
        uint256 outMx
    ) private pure returns (string memory) {
        return (((n - inMn) * (outMx - outMn)) / (inMx - inMn) + outMn).toString();
    }

    function tokenToColorHex(uint256 token, uint256 offset) internal pure returns (string memory str) {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function getCircleCoord(
        uint256 tokenAddress,
        uint256 offset,
        uint256 tokenId
    ) internal pure returns (uint256) {
        return (sliceTokenHex(tokenAddress, offset) * tokenId) % 255;
    }

    function sliceTokenHex(uint256 token, uint256 offset) internal pure returns (uint256) {
        return uint256(uint8(token >> offset));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@uniswap/v3-core/contracts/libraries/BitMath.sol';
import 'base64-sol/base64.sol';

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    using Strings for uint256;

    string constant curve1 = 'M90.5264 135.526L181.474 226.474';
    string constant curve2 = 'M90.2231 135.526C110.434 165.842 150.855 206.263 181.171 226.474';
    string constant curve3 = 'M90.5518 135.526C110.762 170.895 146.131 206.263 181.499 226.474';
    string constant curve4 = 'M90.2485 135.526C105.406 175.947 140.775 211.316 181.196 226.474';
    string constant curve5 = 'M90.5767 135.526C100.682 181 136.05 216.368 181.524 226.474';
    string constant curve6 = 'M90.2739 135.526C95.3266 186.053 130.695 221.421 181.221 226.474';
    string constant curve7 = 'M90.6084 135.526C90.6084 191.105 126.293 226.474 181.556 226.474';
    string constant curve8 = 'M90.5264 135.526C90.5264 196.158 120.842 226.474 181.474 226.474';

    struct SVGBodyParams {
        string quoteToken;
        string baseToken;
        address poolAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        string feeTier;
        int24 tickLower;
        int24 tickUpper;
        int24 tickSpacing;
        int8 overRange;
        uint256 tokenId;
    }

    struct SVGDefsParams {
        string color1;
        string color2;
        string color3;
        string x1;
        string y1;
        string x2;
        string y2;
        string x3;
        string y3;
        int8 overRange;
    }

    function generateSVG(string memory defs, string memory body) internal pure returns (string memory svg) {
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for Uniswap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        return string(abi.encodePacked(defs, body, '</svg>'));
    }

    function generateSVGBody(SVGBodyParams memory params) internal pure returns (string memory body) {
        return
            string(
                abi.encodePacked(
                    generateSVGBorderText(
                        params.quoteToken,
                        params.baseToken,
                        params.quoteTokenSymbol,
                        params.baseTokenSymbol
                    ),
                    generateSVGCardMantle(params.quoteTokenSymbol, params.baseTokenSymbol, params.feeTier),
                    generageSvgCurve(params.tickLower, params.tickUpper, params.tickSpacing, params.overRange),
                    generateSVGPositionDataAndLocationCurve(
                        params.tokenId.toString(),
                        params.tickLower,
                        params.tickUpper
                    ),
                    generateSVGRareSparkle(params.tokenId, params.poolAddress)
                )
            );
    }

    function generateSVGDefs(SVGDefsParams memory params) public pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="272" height="362" viewBox="0 0 272 362" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>",
                '<defs>',
                '<style type="text/css">'
                "@import url('https://fonts.googleapis.com/css2?family=Azeret+Mono&#38;display=swap');"
                '</style>'
                '<filter id="f1"><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='272' height='362' viewBox='0 0 272 362' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            params.x1,
                            "' cy='",
                            params.y1,
                            "' r='100px' fill='#",
                            params.color1,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='272' height='362' viewBox='0 0 272 362' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            params.x2,
                            "' cy='",
                            params.y2,
                            "' r='100px' fill='#",
                            params.color2,
                            "'/></svg>"
                        )
                    )
                ),
                '" />',
                '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='272' height='362' viewBox='0 0 272 362' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            params.x3,
                            "' cy='",
                            params.y3,
                            "' r='100px' fill='#",
                            params.color3,
                            "'/></svg>"
                        )
                    )
                ),
                '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
                'in="blendOut" stdDeviation="42" /><feComponentTransfer><feFuncA type="linear" slope="0.4"/></feComponentTransfer></filter>',
                '<clipPath id="corners"><rect width="272" height="362" rx="10" ry="10" fill="#F1EADA" /></clipPath>',
                '<path id="text-path-a" d="M19.75 12.25 H252.25 A6 6 0 0 1 259.75 19.75 V342.25 A6 6 0 0 1 252.25 349.75 H19.75 A6 6 0 0 1 12.25 342.25 V19.75 A6 6 0 0 1 19.75 12.25 z" />',
                '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463" />',
                '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>',
                '<linearGradient id="grad-up" x1="0" x2="0" y1="0.6" y2="0.25"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
                '<stop offset=".7" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<linearGradient id="grad-down" x1="0.25" x2=".6" y1="0" y2="0"><stop offset="0.3" stop-color="white" stop-opacity="1" /><stop offset="1" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
                '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
                '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>',
                '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask>',
                '<filter id="background" x="-347" y="-225" width="965" height="812" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="57" result="effect1_foregroundBlur_686_60880"/></filter>',
                '<clipPath id="background-clip-path"><rect width="272" height="362" rx="10"/></clipPath>',
                '</defs>',
                '<g clip-path="url(#corners)">',
                '<g clip-path="url(#background-clip-path)">',
                '<g filter="url(#background)" >',
                '<circle opacity="0.5" cx="1.5" cy="319.5" r="153.5" fill="#F3BA2F"/>',
                '<circle opacity="0.5" cx="182.5" cy="319.5" r="153.5" fill="#93876A"/>',
                '<circle opacity="0.5" cx="147.5" cy="42.5" r="153.5" fill="#FFF0CE"/>',
                '<circle opacity="0.5" cx="350.5" cy="265.5" r="153.5" fill="#FAF4E6"/>',
                '<circle opacity="0.5" cx="-79.5" cy="94.5" r="153.5" fill="#AC752C"/>',
                '<circle opacity="0.5" cx="336.5" cy="58.5" r="153.5" fill="#F3BA2F"/>',
                '</g>',
                '</g>',
                '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
                generateBackgroundBanana(params.overRange),
                '</g>'
            )
        );
    }

    function generateSVGBorderText(
        string memory quoteToken,
        string memory baseToken,
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="#4D4040" font-family="\'Azeret Mono\', monospace " font-size="8px" xlink:href="#text-path-a">',
                baseToken,
                unicode' • ',
                baseTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
                '</textPath> <textPath startOffset="0%" fill="#4D4040" font-family="\'Azeret Mono\', monospace " font-size="8px" xlink:href="#text-path-a">',
                baseToken,
                unicode' • ',
                baseTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
                '<textPath startOffset="50%" fill="#4D4040" font-family="\'Azeret Mono\', monospace " font-size="8px" xlink:href="#text-path-a">',
                quoteToken,
                unicode' • ',
                quoteTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"',
                ' repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="#4D4040" font-family="\'Azeret Mono\', monospace " font-size="8px" xlink:href="#text-path-a">',
                quoteToken,
                unicode' • ',
                quoteTokenSymbol,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
            )
        );
    }

    function generateSVGCardMantle(
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol,
        string memory feeTier
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g mask="url(#fade-symbol)"><rect x="30" y="35" width="',
                uint256((78 * (bytes(quoteTokenSymbol).length + bytes(baseTokenSymbol).length + 4)) / 10).toString(),
                '" height="28" rx="10" fill="#EADFC7" fill-opacity="0.4"/> <text y="53px" x="40.25px" fill="#4D4040" font-family="\'Azeret Mono\', monospace " font-weight="900" font-size="12px">',
                quoteTokenSymbol,
                '/',
                baseTokenSymbol,
                '</text><rect x="30" y="73" width="',
                uint256((78 * (bytes(feeTier).length + 3)) / 10).toString(),
                '" height="28" rx="10" fill="#EADFC7" fill-opacity="0.4"/>',
                '<text y="91px" x="40.25px" fill="#4D4040" font-family="\'Azeret Mono\', monospace " font-weight="600" font-size="12px">',
                feeTier,
                '</text></g>',
                '<rect x="16.75" y="16.75" width="238" height="328.5" rx="6" fill="none" stroke="#4D4040" stroke-opacity="0.2" stroke-width="1.5"/>'
            )
        );
    }

    function generageSvgCurve(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing,
        int8 overRange
    ) private pure returns (string memory svg) {
        string memory fade = overRange == 1 ? '#fade-up' : overRange == -1 ? '#fade-down' : '#none';
        string memory curve = getCurve(tickLower, tickUpper, tickSpacing);
        svg = string(
            abi.encodePacked(
                '<g mask="url(',
                fade,
                ')">',
                '<rect x="-16px" y="-16px" width="304px" height="394px" fill="none" />'
                '<path d="',
                curve,
                '" stroke="#4D4040" opacity="0.4" stroke-width="26px" fill="none" stroke-linecap="round" stroke-linejoin="round" />',
                '</g><g mask="url(',
                fade,
                ')">',
                '<rect x="-16px" y="-16px" width="304px" height="394px" fill="none" />',
                '<path d="',
                curve,
                '" opacity="0.89" stroke="#4D4040" fill="none" stroke-width="3" stroke-linecap="round" /></g>',
                generateSVGCurveCircle(overRange)
            )
        );
    }

    function generateBackgroundBanana(int8 overRange) internal pure returns (string memory background) {
        if (overRange == -1) {
            background = string(
                abi.encodePacked(
                    '<g style="transform:translate(18px, 60px)" opacity="0.5">',
                    '<path d="M153.3 137.4c3.3-2.4 4.2-7.8 4.1-11s-2-26.9-16.9-47.7c-1.5-2.1-2.4-4.9-4.6-6.3-15.8-10.7-33.1 22.1-31.3 25.4 6.6 11.8 14.4 23.7 26.1 31.2 4 2.4 13.7 14.7 22.6 8.4z" fill="#ffc938"/>',
                    '<path d="M153.7 135.2c3.4-5.1 1.7-16.8-2.4-26.3-.4-1.6-10.7-21.8-13.1-27.4-1-2.4-2.3-5.1-4.7-6-1.1-.4-2.3-.4-3.5-.2-4.5.6-8.7 3.4-11 7.2-1.8 3-2.6 6.4-2.9 9.9-1.6 15.3 29.4 47 30.1 46.7.9-.4 4.9-.5 7.5-3.9h0z" fill="#e8b134"/>',
                    '<path d="M203.1 190.1h0c-9 .6-18 .2-26.9-1.3-3.2-.5-11-3.8-11.8-4.5a32.7 32.7 0 0 1-2.7 1.5c-22.4 11.5-38.8-2.7-55.2-20.7-15.3-16.8-26-36.4-26-36.4l40.2-26.4s12.3 20.1 25 32.8c7.8 7.8 13.1 11.1 21 19 3.5 3.5 6.2 8.1 7 12.8 1.2 1.4 2.3 3 3.4 3.9 6.8 5.8 16.6 8.2 25.2 5.7.7-.7.8-1.7 1.1-2.6h0c2.1-6.8 1.3 16.3-.3 16.2zM51.6 113.2c-.1 2.5.8 4.8 1.8 7.1 2.3 5 5.2 9.8 9.2 13.6 1.6 1.5 3.4 2.9 5.5 3.6 2.1.8 4.4.9 6.4 0 2.1-.9 3.6-2.8 4.5-5 .9-2.1 1.2-4.4 1.3-6.7.4-4.8.2-9.8-1.8-14.2s-6-8.1-10.9-8.5c-5.2-.5-15.6 3.8-16 10.1h0z" fill="#ffc938"/>',
                    '<path d="M56.7 112.7c-.1 0-1.8.6-2.3 1.3-.7 1.1-.4 2.5 0 3.7 1.2 3.3 3.3 6.3 5.4 9.1.9 1.1 1.8 2.3 3.2 2.9 1.2.5 2.6.3 3.8-.1 3.3-1.3 6.2-4.4 8.3-7.2 1-1.3 2.4-3.3 1.7-5-.4-1.1-1.6-1.6-2.7-2.1-5.4-2.2-11.6-3.8-17.4-2.6z" fill="#e8b134"/>',
                    '<path d="M52.2 111c10.6-3.2 22.4.1 31.4 6.5 1-.3-7.8-28.5-23.7-16.1-3.2 2.6-5.9 5.9-7.7 9.6h0zm71.6-43.6c10.3.6 13.4 5.9 13.4 5.9s-4.8-3.1-11-.1C112.8 77.8 112.1 96 112.1 96l-13.8-9.8c-.1 0 3.3-18 25.5-18.8z" fill="#fce18b"/><g fill="#e8b134">',
                    '<path d="M165.5 176.6c.2.1.5.2.7.3a1.08 1.08 0 0 1-.7-.3zm1.7.8c.8.4 2.1.8 2.8 1.2-.9-.4-1.9-.7-2.8-1.2zm35.9 12.8c-9 .6-18 .1-26.9-1.4-3.2-.5-11-3.8-11.8-4.5-.8.5-1.7 1-2.6 1.5-22.4 11.5-38.8-2.7-55.2-20.7-15.3-16.8-26-36.4-26-36.4s13.2-7.7 14.3-5c9.2 21.8 25.7 41 47.4 50.4 5.2 2.2 11.6 5.4 18.6 3.6 1.2-.3 2.6-1.2 3.9-1.1 1.2.1 2.4.9 3.6 1.4 7.4 3 15.3 4.2 23.1 5.3 2.3.3 4.6.6 6.9.7 1.4 0 2.8-.4 4.1-.6a81.59 81.59 0 0 0 .6 6.8z"/>',
                    '<path d="M166.7 177.2c-.3-.1-.4-.2-.5-.2h-.1c.3.1.5.2.6.2z"/></g>',
                    '<path d="M55.8 73.1c-5.6-22.2-5.5-39.4 1-46.2 8.7-9.1 15.3-4.1 20.9 3.7 5.2 7.3 7.9 23.5 21.7 45.9 9.6 15.7 20.7 29.3 20.7 29.3l-35.9 22.9c0 .1-22.5-32.3-28.4-55.6z" fill="#fde8c8"/>',
                    '<path d="M55.8 73.1c-5.6-22.2-5.5-39.4 1-46.2 2.7-2.9 5.3-4.4 7.7-4.8-.3.3-12.7 11-1.8 47 5.5 22 26 52.1 28.2 55.3l-6.7 4.2c0 .2-22.5-32.2-28.4-55.5h0z" fill="#edd5b5"/>',
                    '<path d="M79.2 126.7c1-9 7-12 15.2-12.4l7.2 1.8 17.8-15.8s4.1 6.7 10.1 14.9c-2.3-.2-4.7-1.3-7-1.4-2.8-.1-5.7.2-8.3 1.2-3.7 1.3-7.2 4-7.9 7.8-5.2-.2-9.6 4.3-11 9.3s-.3 10.3 1 15.3c.8 3 1.7 6 3 8.8-12.1-14.8-20.1-29.5-20.1-29.5z" fill="#e2a139"/>',
                    '<path d="M101.6 116.1s-11.2-1.2-15 3.3c-8.9 10.5 13.1 37.7 17.9 48.7 3.6 8.3 1.8 12.3-.5 13.6-5 2.9-18.8.2-29.3-16S67 119.2 80 115.8s21.6.3 21.6.3h0z" fill="#ffc938"/>',
                    '<path d="M101.6 116.1s-13.5-2.5-17.4 1.9c-10 11.4 11.8 38 16.5 49 3.6 8.3 3.1 11.9.9 13.2-5 2.9-18.8.2-29.3-16S58.9 133.5 60 128.9c1.5-6 4.5-11.3 17.6-14.7 13-3.2 24 1.9 24 1.9h0z" fill="#fce18b"/>',
                    '<path d="M217.3 171.1c-.4-1.2-.9-2.3-1.9-3-.6-.4-1.3-.6-1.9-.6-2.8-.3-5.6.9-8.2 2.2-.4.2-.8.4-1.1.7-1.1 1.1-.6 2.9-.4 4.4.3 1.8.2 3.7-.2 5.4-.1.5-.3 1-.2 1.6.1.7 10.6-1.1 13.5-2.9 2.6-1.8 1.3-5.5.4-7.8h0z" fill="#937c69"/>',
                    '<path d="M204.4 179.6c1-.7 2.3-.7 3.5-.9 2.9-.3 5.7-1 8.4-2 .6-.2 1.3-.4 1.8 0 .4.3.4.8.4 1.3 0 2.1-1.4 8.9-2.4 9.9-.6.6-1.4 1-2.2 1.4-2.7 1.1-5.7 1.3-8.6 1.4-.8 0-1.7 0-2.3-.5s-.7-1.3-.8-2c-.2-1.4.8-7.7 2.2-8.6h0z" fill="#776057"/>',
                    '<path d="M101.6 116.1s0-10.7 33.5-16.6c56.2 9.3 50.7 16.1 47.3 22.1-3.4 5.9-24.5-9.2-40.8-14.3-23.1-7.2-40 8.8-40 8.8h0z" fill="#ffc938"/>',
                    '<path d="M101.9 114.9s6.3-24.5 28.4-32.1c13.1-4.6 23.6-5.9 41.2 7.9 13.9 10.9 15.6 21.5 12.3 27.4-3.4 5.9-24.5-9.2-40.8-14.3-31.3-5.9-41.1 11.1-41.1 11.1z" fill="#fce18b"/>',
                    '</g>'
                )
            );
        } else if (overRange == 0) {
            background = string(
                abi.encodePacked(
                    '<g style="transform:translate(18px, 62px)" opacity="0.5">',
                    '<path d="M214.4 177.8C138.7 187.9 50.9 132 62.6 57.6c.1-.3.5-.4.8-.6.4-4.1 1.4-10.7 3.8-17.5.2-.5.3-.9.5-1.4-.5-3.3-1-6.7-2.9-9.5-.4-.6-.9-1.2-1.1-2-.1-.7 0-1.4.2-2C64.4 22.4 73 13.1 84 29c1 1.4-1.1 3.3-1.9 4.9-.2.5-.5.8-.7 1.2-.7 2.5-1.5 5.8-2.2 9.9-.8 4.7-.4 9.1.2 12.7 3.7 1.8 7.5 4.7 11 8.8 9.4 11 6.8 25.3 31.2 49.9 24.6 24.8 52.6 35.9 62 38.7 14.6 4.4 30.5 7.1 30.5 7.1l.3 15.6z" fill="#ffc938"/>',
                    '<path d="M216.7 170.9l-2.3 6.9s-19 20.6-81.3 2.8c-46.2-13.2-75.4-57.9-80.1-75.8-6-23 1.7-40.2 9.6-47.3 0 0 .6-7 4.6-18.1.2-.5.3-.9.5-1.4-.5-3.3-3.8-10.7-4-11.4-.1-.7 3.9-7.8 7.9-5.2.5.3-.6 1-.5 1.6.1.5 2.4 4.5 3.6 7.2-.4 4.4-4.3 25.3-5.5 26.4l5.8.8s-2.6 1.9-1.7 15.7c.9 13.4 9.4 46 39.5 67.7 51.7 37.2 97.4 28.9 97.4 28.9s3.3.1 6.5 1.2z" fill="#f2bb40"/>',
                    '<path d="M214 162.2l2.9 5.5a3.02 3.02 0 0 1 .2 2.1l-2.7 8-5-2.9c-.5-.3-.8-.8-.7-1.4l.2-4.9c0-.3.1-.7.4-.9l4.7-5.5h0z" fill="#776057"/>',
                    '<path d="M75.8 14.3c1.2.7 2.3 1.7 3.5 2.5l4.5 3c.6.5 1.2 1.1 1.6 1.7.6 1 .8 2.1.8 3.3s-.3 2.3-.5 3.4c-.2 1-.5 2-1 2.8-.7 1.2-1.9 2-2.6 3.1 0-1.2.3-2.7-.5-3.6-2-2.6-2.8-3.4-6.9-6.4l-3-2.3c-.6-.4-1.3-.7-1.8-1.3s-.6-1.4-.5-2.1.3-1.4.5-2.2c.2-.7.3-1.4.6-2 .4-.9 1.1-1.3 2-1.1 1.2.1 2.3.6 3.3 1.2h0z" fill="#937c69"/>',
                    '<path d="M74.2 14.8c-.2.7-.5 1.3-.8 1.8-.6 1.1-1 2.3-1.3 3.5-.1.5-.2 1-.5 1.3-.2.2-.5.2-.7.2-2.2 0-4.8 1.8-6.7 4.7-.1.2-.2.4-.4.4-.1 0-.2-.2-.2-.4-.1-1 .1-2.2.4-3.3.6-2.5 1.5-5.1 2.7-7.4.6-1.1 1.3-2.2 2.1-2.6.4-.2.8-.2 1.2-.2 1 .1 4.7-.2 4.2 2h0z" fill="#776057"/>',
                    '</g>'
                )
            );
        } else if (overRange == 1) {
            background = string(
                abi.encodePacked(
                    '<g style="transform:translate(18px, 62px)" opacity="0.5">',
                    '<path d="M140.6 189.1c20.9 9.5 37.7 12.4 45.6 7.3 10.5-6.9 6.8-14.4.1-21.2-6.2-6.4-21.7-12-41.3-29.5-13.7-12.3-25.2-25.6-25.2-25.6l-28.9 31.3c0-.1 27.9 27.9 49.7 37.7z" fill="#fde8c8"/>',
                    '<path d="M140.6 189.1c20.9 9.5 37.7 12.4 45.6 7.3 3.3-2.2 5.2-4.4 6.1-6.7-.3.2-.6.4-1 .7-7.9 5.2-24.7 2.2-45.6-7.3-20.6-9.4-46.7-34.9-49.4-37.6l-5.4 5.8c0 0 27.8 28 49.7 37.8h0z" fill="#edd5b5"/>',
                    '<path d="M151.9 114.6c-1-8.4-3.9-16.5-8.5-23.5-.9-1.3-1.9-2.6-3.3-3.1-2.4-.8-5 1.2-6.1 3.5s-1.1 5-1.7 7.5c-1.5 6.3-6.2 11.4-11.2 15.5-5.1 4.2 30.8 26.2 30.8.1h0zm-75.3 24.2c3 4.3 8.2 9.7 5 13.8-14 18.2-38 23.4-50.6 26.3-7.5 1.7-16.5 1.7-23.3 5.2-2 1-4.1 2.5-4.3 4.7-.3 3.1 3.2 5.1 6.2 5.8 17.6 2.2 72-9.1 86.5-24.5 5.1-5.4 6.6-7.8 6.9-12.7.4-6.5-3.7-12.4-8.7-16.5-2.3-2-20.7-6.5-17.7-2.1z" fill="#e8b134"/>',
                    '<path d="M84.1 140.7l-3.4 1.2c-.1-.1-.3-.2-.4-.4l3.8-.8zm149.4-31.8c0 1.9-1.3 3.5-2.7 4.8-8 8.2-18.9 13-29.7 16.9-8.3 3-38 10.6-44.6 11.3-23.6 2.5-13.1 4.1-10.2 7.2 1.2 1.2-26 17.3-28.4 16.9-6.5-1-23.8-20.4-28-26.8l-9.7 2.3c-14.8-14.4-34.4-60.9-19.8-84.4.2-3.8.8-10.7 3-17.7.1-.5.3-.9.4-1.3-.6-3.2-1.2-6.4-3.1-8.9-.4-.6-1-1.1-1.1-1.8-.2-.6 0-1.3.1-2 .6-2.9 10.1-4.2 10.1-4.2s9.3 8.5 7.7 12.3c-.2.4-.4.8-.7 1.2-.6 2.4-1.2 5.6-1.7 9.5-.5 4.5 0 8.7.7 12.1 3.8 1.5 7.8 4.2 11.5 8.2 9.4 10.1 7.5 23.9 31.8 46.3 4.7 4.4 9.5 8.2 14.3 11.6l-.1.1c7.1 2.8 8.5 2.3 16.2 2 27.7-1.1 55-7.8 80.4-18.6 1.7-.8 3.6 1.2 3.6 3z" fill="#ffc938"/>',
                    '<path d="M148.8 148.5c-1.3-6.2-4.1-12.4-9.3-16.1-2.5-1.8-5.8-2.9-8.5-1.5-2.4 1.2-3.6 4-4.3 6.6-1.6 6.2-2.4 12.5-4.2 18.6-1.9 6.3-4.9 9.9-4.6 10.1 2.4.9 7.4-1 9.9-1.6 5.4-1.3 10.6-3.3 15.5-6.1 4.4-2.6 6.6-4.7 5.5-10h0z" fill="#fce18a"/>',
                    '<path d="M90.6 140.2l-9.2 3.4c-15.1-14.5-26.1-32.3-28.8-41.2-6.7-21.7 0-38.4 7.2-45.5.2-.2.5-.4.7-.6.2-3.9.9-10.3 2.9-16.8.1-.4.3-.9.4-1.3-.6-3.2-4.1-10-4.3-10.8-.2-.6 0-1.3.1-1.9.5-2.2 8-5.8 7.2-3.3-.2.5-.6 1-.4 1.5.1.4 2.5 4.2 3.7 6.7-.2 4.2-.9 7.1-1.4 11.5-.4 3.9-.2 8.1-1.6 11.8-.3.8-.7 1.5-1.2 2.2-.2.1-1.1.8-2.2 2.5-2.2 3.2-5.3 10-5.8 23.3-.5 13 9.3 33.7 26.9 52.9 1.2 1.2 4.4 4.3 5.8 5.6z" fill="#e8b134"/>',
                    '<path d="M80.9 24.6c0 1.7-.2 3.4-.8 4.9-.6 1.6-2 2.6-2.8 4.1-.1-1.1.1-2.6-.6-3.5-2-2.4-2.9-3.1-6.9-5.8-.8-.6-2.2-1.5-3-2 0 0-.1-.1-.2-.1-.2.1-.3.1-.5.1-2.1 0 1.3-8.6 3-8 1.4.6 2.7 1.6 4 2.4 3.4 2.1 7.8 3.5 7.8 7.9z" fill="#937c69"/>',
                    '<path d="M66.9 22.3c2-2.3 3.2-7.6 2.3-7.9-1.7-.7-4.7-1.1-6 .4-.5.6-.8 1.3-1.2 1.9-1.1 2.2-1.9 4.7-2.3 7.2-.2 1.1-.3 2.2-.2 3.2 0 .2 0 .4.2.4.1 0 .2-.2.3-.3 1.6-2.6 5-4.5 6.9-4.9z" fill="#776057"/>',
                    '</g>'
                )
            );
        }
    }

    function getCurve(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing
    ) internal pure returns (string memory curve) {
        int24 tickRange = (tickUpper - tickLower) / tickSpacing;
        if (tickRange <= 4) {
            curve = curve1;
        } else if (tickRange <= 8) {
            curve = curve2;
        } else if (tickRange <= 16) {
            curve = curve3;
        } else if (tickRange <= 32) {
            curve = curve4;
        } else if (tickRange <= 64) {
            curve = curve5;
        } else if (tickRange <= 128) {
            curve = curve6;
        } else if (tickRange <= 256) {
            curve = curve7;
        } else {
            curve = curve8;
        }
    }

    function generateSVGCurveCircle(int8 overRange) internal pure returns (string memory svg) {
        string memory curvex1 = '90.5263';
        string memory curvey1 = '135.526';
        string memory curvex2 = '181.474';
        string memory curvey2 = '226.474';
        if (overRange == 1 || overRange == -1) {
            svg = string(
                abi.encodePacked(
                    '<circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="3.5px" fill="#4D4040" />',
                    '<circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="9px" fill-opacity="0.4" fill="#4D4040" />',
                    '<circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="17px" fill-opacity="0.4" fill="#4D4040" />'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    '<circle cx="',
                    curvex1,
                    'px" cy="',
                    curvey1,
                    'px" r="2.5px" fill="#4D4040" />',
                    '<circle cx="',
                    curvex2,
                    'px" cy="',
                    curvey2,
                    'px" r="2.5px" fill="#4D4040" />'
                )
            );
        }
    }

    function generateSVGPositionDataAndLocationCurve(
        string memory tokenId,
        int24 tickLower,
        int24 tickUpper
    ) private pure returns (string memory svg) {
        string memory tickLowerStr = tickToString(tickLower);
        string memory tickUpperStr = tickToString(tickUpper);
        uint256 str1length = bytes(tokenId).length + 4;
        uint256 str2length = bytes(tickLowerStr).length + 10;
        uint256 str3length = bytes(tickUpperStr).length + 10;
        (string memory xCoord, string memory yCoord) = rangeLocation(tickLower, tickUpper);
        svg = string(
            abi.encodePacked(
                ' <g style="transform:translate(30px, 245px)">',
                '<rect width="',
                uint256(7 * (str1length + 3)).toString(),
                'px" height="25px" rx="10px" ry="10px" fill="#EADFC7" fill-opacity="0.4" />',
                '<text font-weight="900" x="11.25px" y="16px" font-family="\'Azeret Mono\', monospace " font-size="10px" fill="#4D4040"><tspan font-weight="normal" fill="#4D4040">ID: </tspan>',
                tokenId,
                '</text></g>',
                ' <g style="transform:translate(30px, 275px)">',
                '<rect width="',
                uint256(7 * (str2length + 3)).toString(),
                'px" height="25px" rx="10px" ry="10px" fill="#EADFC7" fill-opacity="0.4" />',
                '<text font-weight="900" x="11.25px" y="16px" font-family="\'Azeret Mono\', monospace " font-size="10px" fill="#4D4040"><tspan font-weight="normal" fill="#4D4040">Min Tick: </tspan>',
                tickLowerStr,
                '</text></g>',
                ' <g style="transform:translate(30px, 305px)">',
                '<rect width="',
                uint256(7 * (str3length + 3)).toString(),
                'px" height="25px" rx="10px" ry="10px" fill="#EADFC7" fill-opacity="0.4" />',
                '<text font-weight="900" x="11.25px" y="16px" font-family="\'Azeret Mono\', monospace " font-size="10px" fill="#4D4040"><tspan font-weight="normal" fill="#4D4040">Max Tick: </tspan>',
                tickUpperStr,
                '</text></g>'
                '<g style="transform:translate(215px, 305px)">',
                '<rect width="26px" height="26px" rx="5px" ry="5px" fill="#EADFC7" fill-opacity="0.4" />',
                '<path stroke-linecap="round" d="M5 5C5 17 9 21 21 21" fill="none" stroke="#4D4040" />',
                '<circle style="transform:translate3d(',
                xCoord,
                'px, ',
                yCoord,
                'px, 0px)" cx="0px" cy="0px" r="3px" fill="#4D4040"/></g>'
            )
        );
    }

    function tickToString(int24 tick) internal pure returns (string memory) {
        string memory sign = '';
        if (tick < 0) {
            tick = tick * -1;
            sign = '-';
        }
        return string(abi.encodePacked(sign, uint256(uint24(tick)).toString()));
    }

    function rangeLocation(int24 tickLower, int24 tickUpper) internal pure returns (string memory, string memory) {
        int24 midPoint = (tickLower + tickUpper) / 2;
        if (midPoint < -125_000) {
            return ('5', '5'); //
        } else if (midPoint < -75_000) {
            return ('5.2', '8');
        } else if (midPoint < -25_000) {
            return ('5.7', '11');
        } else if (midPoint < -5_000) {
            return ('6.6', '14');
        } else if (midPoint < 0) {
            return ('7.5', '16'); //
        } else if (midPoint < 5_000) {
            return ('9.5', '18'); //
        } else if (midPoint < 25_000) {
            return ('12', '19.3');
        } else if (midPoint < 75_000) {
            return ('15', '20.2');
        } else if (midPoint < 125_000) {
            return ('18', '20.8');
        } else {
            return ('21', '21'); //
        }
    }

    function generateSVGRareSparkle(uint256 tokenId, address poolAddress) private pure returns (string memory svg) {
        if (isRare(tokenId, poolAddress)) {
            svg = string(
                abi.encodePacked(
                    '<g style="transform:translate(215px, 271px)"><rect width="26px" height="26px" rx="5px" ry="5px" fill="#EADFC7" fill-opacity="0.4" />',
                    '<g style="transform:translate(5px, 4px)">',
                    '<defs><path id="A" d="M.2.2h14.6v17.7H.2z"/></defs><clipPath id="B"><use xlink:href="#A"/></clipPath>',
                    '<path d="M8.2 17.9c-.8.1-1.8-.2-1.4-1.1s1.3-1.5 1.9-2.2l1.1-1.5c.3-.5.7-1.1.8-1.7-.1.1-.6 1.2-1.9 2.1-.8.6-1.7 1.1-2.6 1.4-1.1.4-2.2.5-3.3.4-.7-.1-1.5-.2-2.1-.6-.3-.2-.6-.6-.5-1 .1-.5.8-.6 1.3-.7 1.3-.3 2.4-.7 3.5-1.4.8-.5 1.6-1.2 2.2-2 1.3-1.7 2-3.9 1.9-6v-.3s0-.5.3-.7c0 0-.3-1.3-.2-1.6.2-.2 1.2-.3 1.4-.1.1.2.2 1.3.2 1.3.4.1.8.4 1.1.6.6.5 1.1 1.2 1.6 1.9a9.04 9.04 0 0 1 1.1 2.7c.2.9.3 1.9.2 2.8s-.3 1.9-.7 2.7c-.4.9-1.9 2.6-2.6 3.3-.6.6-2.5 1.6-3.3 1.7z" clip-path="url(#B)" fill="#4d4040"/>',
                    '</g></g>'
                )
            );
        } else {
            svg = '';
        }
    }

    function isRare(uint256 tokenId, address poolAddress) internal pure returns (bool) {
        bytes32 h = keccak256(abi.encodePacked(tokenId, poolAddress));
        return uint256(h) < type(uint256).max / (1 + BitMath.mostSignificantBit(tokenId) * 2);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}