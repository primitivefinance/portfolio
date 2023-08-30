// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "openzeppelin/utils/Base64.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeCastLib.sol";

import "./libraries/StringsLib.sol";
import "./interfaces/IPortfolio.sol";
import "./interfaces/IStrategy.sol";
import "./strategies/NormalStrategy.sol";

/// @dev Contract to render a position.
contract PositionRenderer {
    using Strings for *;
    using SafeCastLib for *;

    struct Pair {
        address asset;
        string assetSymbol;
        string assetName;
        uint8 assetDecimals;
        address quote;
        string quoteSymbol;
        string quoteName;
        uint8 quoteDecimals;
    }

    struct Pool {
        uint256 poolId;
        uint128 virtualX;
        uint128 virtualY;
        uint16 feeBasisPoints;
        uint16 priorityFeeBasisPoints;
        address controller;
        address strategy;
        uint256 spotPriceWad;
        bool hasDefaultStrategy;
    }

    struct Config {
        uint128 strikePriceWad;
        uint32 volatilityBasisPoints;
        uint32 durationSeconds;
        uint32 creationTimestamp;
        bool isPerpetual;
    }

    struct Properties {
        Pair pair;
        Pool pool;
        Config config;
    }

    string private constant PRIMITIVE_LOGO =
        '<svg id="i" viewBox="0 0 139 170" fill="#fff"><path d="M138.739 45.405v-.756C138.235 19.928 118.055 0 93.334 0H0v170.271h33.297V33.55h59.28c7.063 0 12.613 5.549 12.613 12.612v26.739c0 7.063-5.55 12.613-12.613 12.613H56.505l-10.09 33.549h46.919c24.721 0 44.901-19.928 45.405-44.648v-29.01Z" /></svg>';

    string private constant STYLE_0 =
        "<style>body{height:100vh;width:100vw;margin:0;padding:2rem;font-family:monospace;display:flex;flex-direction:column;gap:2rem;color:#fff;background-repeat:no-repeat;box-sizing:border-box;text-rendering:geometricPrecision;justify-content:space-between}#g{background-image:linear-gradient(0,";
    string private constant STYLE_1 =
        ");animation:r 10s linear infinite;background-size:200% 200%;will-change:background-position;width:100vw;height:100vh;position:absolute;top:0;left:0;z-index:-2}#n{height:100vh;width:100vw;position:absolute;top:0;right:0;z-index:-1}@keyframes r{0%,100%{background-position:left top}50%{background-position:right bottom}}#t{font-size:6vh}.s{border-spacing:0 1rem}.s td{font-size:5vh}#i{height:15vh}.l{font-size:3.25vh;opacity:.5}.f{background-color:#00000020;padding:1rem;border-radius:8px}.f p{font-size:3vh;margin:0}</style>";

    function uri(uint256 id) external view returns (string memory) {
        Properties memory properties = _getProperties(id);

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        _generateName(properties),
                        '","animation_url":"',
                        _generateHTML(properties),
                        '","license":"MIT","creator":"primitive.eth",',
                        '"description":"This NFT represents a liquidity position in a Portfolio pool. The owner of this NFT can modify or redeem this position.\\n\\n',
                        unicode"⚠️ WARNING: Transferring this NFT makes the new recipient the owner of the position.",
                        '",',
                        '"properties":{',
                        _generatePair(properties),
                        ",",
                        _generatePool(properties),
                        ",",
                        _generateConfig(properties),
                        "}}"
                    )
                )
            )
        );
    }

    function _getPair(uint256 id) internal view returns (Pair memory) {
        (
            address tokenAsset,
            uint8 decimalsAsset,
            address tokenQuote,
            uint8 decimalsQuote
        ) = IPortfolio(msg.sender).pairs(uint24(id));

        return Pair({
            asset: tokenAsset,
            assetSymbol: ERC20(tokenAsset).symbol(),
            assetName: ERC20(tokenAsset).name(),
            assetDecimals: decimalsAsset,
            quote: tokenQuote,
            quoteSymbol: ERC20(tokenQuote).symbol(),
            quoteName: ERC20(tokenQuote).name(),
            quoteDecimals: decimalsQuote
        });
    }

    function _getPool(uint256 id) internal view returns (Pool memory) {
        (
            uint128 virtualX,
            uint128 virtualY,
            ,
            ,
            uint16 feeBasisPoints,
            uint16 priorityFeeBasisPoints,
            address controller,
            address strategy
        ) = IPortfolio(msg.sender).pools(uint64(id));

        uint256 spotPriceWad = IPortfolio(msg.sender).getSpotPrice(uint64(id));

        return Pool({
            poolId: id,
            virtualX: virtualX,
            virtualY: virtualY,
            feeBasisPoints: feeBasisPoints,
            priorityFeeBasisPoints: priorityFeeBasisPoints,
            controller: controller,
            strategy: strategy,
            spotPriceWad: spotPriceWad,
            hasDefaultStrategy: strategy
                == IPortfolio(msg.sender).DEFAULT_STRATEGY()
        });
    }

    function _getConfig(
        uint256 id,
        address strategy
    ) internal view returns (Config memory) {
        (
            uint128 strikePriceWad,
            uint32 volatilityBasisPoints,
            uint32 durationSeconds,
            uint32 creationTimestamp,
            bool isPerpetual
        ) = NormalStrategy(strategy).configs(uint64(id));

        return Config({
            strikePriceWad: strikePriceWad,
            volatilityBasisPoints: volatilityBasisPoints,
            durationSeconds: durationSeconds,
            creationTimestamp: creationTimestamp,
            isPerpetual: isPerpetual
        });
    }

    function _getProperties(uint256 id)
        private
        view
        returns (Properties memory)
    {
        Pair memory pair = _getPair(id);
        Pool memory pool = _getPool(id);
        Config memory config = _getConfig(id, pool.strategy);

        return Properties({ pair: pair, pool: pool, config: config });
    }

    function _generateName(Properties memory properties)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            "Primitive Portfolio LP ",
            properties.pair.assetSymbol,
            "-",
            properties.pair.quoteSymbol
        );
    }

    function _generatePair(Properties memory properties)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            '"asset_name":"',
            properties.pair.assetName,
            '",',
            '"asset_symbol":"',
            properties.pair.assetSymbol,
            '",',
            '"asset_address":"',
            properties.pair.asset.toHexString(),
            '",',
            '"quote_name":"',
            properties.pair.quoteName,
            '",',
            '"quote_symbol":"',
            properties.pair.quoteSymbol,
            '",',
            '"quote_address":"',
            properties.pair.quote.toHexString(),
            '"'
        );
    }

    function _generatePool(Properties memory properties)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            '"asset_reserves":"',
            (properties.pool.virtualX / 1).toString(),
            '",',
            '"quote_reserves":"',
            (properties.pool.virtualY / 1).toString(),
            '",',
            '"spot_price_wad":"',
            (properties.pool.spotPriceWad / 10 ** 18).toString(),
            '",',
            '"fee_basis_points":"',
            properties.pool.feeBasisPoints.toString(),
            '",',
            '"priority_fee_basis_points":"',
            properties.pool.priorityFeeBasisPoints.toString(),
            '",',
            '"controller":"',
            Strings.toHexString(properties.pool.controller),
            '",',
            '"strategy":"',
            Strings.toHexString(properties.pool.strategy),
            '"'
        );
    }

    function _generateConfig(Properties memory properties)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            '"strike_price_wad":"',
            (properties.config.strikePriceWad / 10 ** 18).toString(),
            '",',
            '"volatility_basis_points":"',
            properties.config.volatilityBasisPoints.toString(),
            '",',
            '"duration_seconds":"',
            properties.config.durationSeconds.toString(),
            '",',
            '"creation_timestamp":"',
            properties.config.creationTimestamp.toString(),
            '",',
            '"is_perpetual":',
            properties.config.isPerpetual ? "true" : "false"
        );
    }

    function _generateHTML(Properties memory properties)
        private
        view
        returns (string memory)
    {
        string memory color0 = Strings.toHexColor(
            bytes3(
                keccak256(abi.encode((properties.pool.poolId >> 232) << 232))
            )
        );
        string memory color1 = Strings.toHexColor(
            bytes3(keccak256(abi.encode(properties.pool.poolId << 232)))
        );

        string memory title = string.concat(
            properties.pair.assetSymbol,
            "-",
            properties.pair.quoteSymbol,
            " Portfolio LP"
        );

        string memory data = string.concat(
            '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>',
            title,
            "</title>",
            STYLE_0,
            color0,
            ",",
            color1,
            STYLE_1,
            "</head><body>",
            '<div id="g"></div>',
            '<svg id="n"><filter id="a"><feTurbulence type="fractalNoise" baseFrequency="1.34" numOctaves="4" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncR type="linear" slope=".46"/><feFuncG type="linear" slope=".46"/><feFuncB type="linear" slope=".46"/><feFuncA type="linear" slope=".56"/></feComponentTransfer><feComponentTransfer><feFuncR type="linear" slope="1.47" intercept="-.23"/><feFuncG type="linear" slope="1.47" intercept="-.23"/><feFuncB type="linear" slope="1.47" intercept="-.23"/></feComponentTransfer></filter><rect width="100%" height="100%" filter="url(#a)"/></svg>',
            _generateStats(properties),
            _generateHTMLFooter(properties),
            "</body></html>"
        );

        return
            string.concat("data:text/html;base64,", Base64.encode(bytes(data)));
    }

    function _generateStat(
        string memory label,
        string memory amount
    ) private pure returns (string memory) {
        return string.concat(
            '<td><span class="l">', label, "</span><br />", amount, "</td>"
        );
    }

    function _generateTitle(
        string memory label,
        string memory amount
    ) private pure returns (string memory) {
        return string.concat(
            '<td class="t" style="text-align: right">',
            label,
            '<br /><span class="l">',
            amount,
            "</span></td>"
        );
    }

    function _generateStats(Properties memory properties)
        private
        view
        returns (string memory)
    {
        return string.concat(
            '<table class="s">',
            "<tr><td>",
            PRIMITIVE_LOGO,
            "</td>",
            _generateHTMLTitle(properties),
            "</tr><tr></tr><tr>",
            _generateHTMLSpotPrice(properties),
            _generateHTMLStrikePrice(properties),
            "</tr><tr>",
            _generateHTMLAssetReserves(properties),
            _generateHTMLQuoteReserves(properties),
            "</tr><tr>",
            _generateHTMLPoolValuation(properties),
            _generateHTMLSwapFee(properties),
            "</tr></table>"
        );
    }

    function _generateHTMLTitle(Properties memory properties)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            _generateTitle(
                string.concat(
                    properties.pair.assetSymbol,
                    "-",
                    properties.pair.quoteSymbol
                ),
                properties.config.isPerpetual
                    ? "Perpetual pool"
                    : _calculateCountdown(
                        properties.config.creationTimestamp
                            + properties.config.durationSeconds
                    )
            )
        );
    }

    function _generateHTMLSpotPrice(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Spot Price",
                string.concat(
                    abbreviateAmount(
                        properties.pool.spotPriceWad / 10 ** 18,
                        properties.pair.quoteDecimals
                    ),
                    " ",
                    properties.pair.quoteSymbol
                )
            )
        );
    }

    function _generateHTMLStrikePrice(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Strike Price",
                string.concat(
                    abbreviateAmount(
                        properties.config.strikePriceWad / 10 ** 18,
                        properties.pair.quoteDecimals
                    ),
                    " ",
                    properties.pair.quoteSymbol
                )
            )
        );
    }

    function _generateHTMLAssetReserves(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Asset Reserves",
                string.concat(
                    abbreviateAmount(
                        properties.pool.virtualX / 10 ** 18,
                        properties.pair.assetDecimals
                    ),
                    " ",
                    properties.pair.assetSymbol
                )
            )
        );
    }

    function _generateHTMLQuoteReserves(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Asset Reserves",
                string.concat(
                    abbreviateAmount(
                        properties.pool.virtualY / 10 ** 18,
                        properties.pair.quoteDecimals
                    ),
                    " ",
                    properties.pair.quoteSymbol
                )
            )
        );
    }

    function _generateHTMLPoolValuation(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        uint256 poolValuation = (
            properties.pool.virtualX * properties.pool.spotPriceWad
        ) / properties.pair.quoteDecimals + properties.pool.virtualY;

        return string.concat(
            _generateStat(
                "Pool Valuation",
                string.concat(
                    abbreviateAmount(
                        poolValuation / 10 ** 18, properties.pair.quoteDecimals
                    ),
                    " ",
                    properties.pair.quoteSymbol
                )
            )
        );
    }

    function _generateHTMLSwapFee(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Swap Fee",
                string.concat(
                    abbreviateAmount(properties.pool.feeBasisPoints, 4), "  %"
                )
            )
        );
    }

    function _generateHTMLFooter(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        string memory controlledLabel = properties.pool.controller == address(0)
            ? "This pool is not controlled"
            : string.concat(
                "This pool is controlled by ",
                properties.pool.controller.toHexString()
            );

        return (
            string.concat(
                '<div class="f"><p>',
                controlledLabel,
                " and uses ",
                properties.pool.hasDefaultStrategy
                    ? "the default strategy."
                    : "a custom strategy.",
                "</p></div>"
            )
        );
    }

    function _calculateCountdown(uint256 deadline)
        internal
        view
        returns (string memory)
    {
        uint256 timeLeft = deadline - block.timestamp;
        uint256 daysLeft = timeLeft / 86400;
        uint256 hoursLeft = (timeLeft % 86400) / 3600;
        uint256 minutesLeft = (timeLeft % 3600) / 60;
        uint256 secondsLeft = timeLeft % 60;

        // TODO: Fix the plurals
        if (daysLeft >= 1) {
            return (string.concat("Expires in ", daysLeft.toString(), " days"));
        }

        if (hoursLeft >= 1) {
            return
                (string.concat("Expires in ", hoursLeft.toString(), " hours"));
        }

        if (minutesLeft >= 1) {
            return (
                string.concat("Expires in ", minutesLeft.toString(), " minutes")
            );
        }

        return
            (string.concat("Expires in ", secondsLeft.toString(), " seconds"));
    }

    /// @dev Escape character for "≥".
    string internal constant SIGN_GE = "&#8805;";

    /// @dev Escape character for ">".
    string internal constant SIGN_GT = "&gt;";

    /// @dev Escape character for "<".
    string internal constant SIGN_LT = "&lt;";

    /// @notice Creates an abbreviated representation of the provided amount, rounded down and prefixed with ">= ".
    /// @dev The abbreviation uses these suffixes:
    /// - "K" for thousands
    /// - "M" for millions
    /// - "B" for billions
    /// - "T" for trillions
    /// For example, if the input is 1,234,567, the output is ">= 1.23M".
    /// @param amount The amount to abbreviate, denoted in units of `decimals`.
    /// @param decimals The number of decimals to assume when abbreviating the amount.
    /// @return abbreviation The abbreviated representation of the provided amount, as a string.
    function abbreviateAmount(
        uint256 amount,
        uint256 decimals
    ) internal pure returns (string memory) {
        if (amount == 0) {
            return "0";
        }

        uint256 truncatedAmount;
        unchecked {
            truncatedAmount = decimals == 0 ? amount : amount / 10 ** decimals;
        }

        // Return dummy values when the truncated amount is either very small or very big.
        if (truncatedAmount < 1) {
            return string.concat(SIGN_LT, " 1");
        } else if (truncatedAmount >= 1e15) {
            return string.concat(SIGN_GT, " 999.99T");
        }

        string[5] memory suffixes = ["", "K", "M", "B", "T"];
        uint256 fractionalAmount;
        uint256 suffixIndex = 0;

        // Truncate repeatedly until the amount is less than 1000.
        unchecked {
            while (truncatedAmount >= 1000) {
                fractionalAmount = (truncatedAmount / 10) % 100; // keep the first two digits after the decimal point
                truncatedAmount /= 1000;
                suffixIndex += 1;
            }
        }

        // Concatenate the calculated parts to form the final string.
        string memory prefix = string.concat(SIGN_GE, " ");
        string memory wholePart = truncatedAmount.toString();
        string memory fractionalPart =
            stringifyFractionalAmount(fractionalAmount);
        return string.concat(
            prefix, wholePart, fractionalPart, suffixes[suffixIndex]
        );
    }

    /// @notice Converts the provided fractional amount to a string prefixed by a dot.
    /// @param fractionalAmount A numerical value with 2 implied decimals.
    function stringifyFractionalAmount(uint256 fractionalAmount)
        internal
        pure
        returns (string memory)
    {
        // Return the empty string if the fractional amount is zero.
        if (fractionalAmount == 0) {
            return "";
        }
        // Add a leading zero if the fractional part is less than 10, e.g. for "1", this function returns ".01%".
        else if (fractionalAmount < 10) {
            return string.concat(".0", fractionalAmount.toString());
        }
        // Otherwise, stringify the fractional amount simply.
        else {
            return string.concat(".", fractionalAmount.toString());
        }
    }

    function toColor(bytes3 data) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789ABCDEF";
        bytes memory result = new bytes(6);

        for (uint256 i = 0; i < 3; i++) {
            result[i * 2] = hexChars[uint8(data[i] >> 4)];
            result[i * 2 + 1] = hexChars[uint8(data[i] & 0x0F)];
        }

        return string(result);
    }
}
