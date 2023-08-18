// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "openzeppelin/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeCastLib.sol";
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
        uint128 virtualX;
        uint128 virtualY;
        uint16 feeBasisPoints;
        uint16 priorityFeeBasisPoints;
        address controller;
        address strategy;
        uint256 spotPriceWad;
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
        '<path fill-rule="evenodd" clip-rule="evenodd" d="M339.976 134.664h41.048L256 340.586 130.976 134.664h41.047V98H64.143L256 414 447.857 98H339.976v36.664Zm-38.759 0V98h-90.436v36.664h90.436Z" fill="#fff" style="transform:scale(0.25)"/>';

    function uri(uint256 id) external view returns (string memory) {
        Properties memory properties = _getProperties(id);

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        _generateName(properties),
                        '","image":"',
                        _generateImage(properties),
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

    function _generateImage(Properties memory properties)
        private
        view
        returns (string memory)
    {
        return string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(_generateSVG(properties)))
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
            virtualX: virtualX,
            virtualY: virtualY,
            feeBasisPoints: feeBasisPoints,
            priorityFeeBasisPoints: priorityFeeBasisPoints,
            controller: controller,
            strategy: strategy,
            spotPriceWad: spotPriceWad
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
            properties.config.strikePriceWad.toString(),
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

    function _generateSVG(Properties memory properties)
        private
        view
        returns (string memory)
    {
        return string.concat(
            '<svg width="600" height="600" fill="none" xmlns="http://www.w3.org/2000/svg">',
            _generateSVGNoise(),
            _generateSVGGradient(),
            '<rect fill="url(#MyGradient)" x="0" y="0" width="600" height="600" />'
            '<rect width="100%" height="100%" filter="url(#noise-filter)"/>',
            PRIMITIVE_LOGO,
            _generateStats(properties),
            "</svg>"
        );
    }

    function _generateStats(Properties memory properties)
        private
        view
        returns (string memory)
    {
        return string.concat(
            _generateSVGTitle(properties),
            _generateSVGSpotPrice(properties),
            _generateSVGStrikePrice(properties),
            _generateSVGReserves(properties),
            _generateSVGPoolValuation(properties),
            _generateSVGSwapFee(properties)
        );
    }

    function _generateSVGNoise() internal pure returns (string memory) {
        return
        '<filter id="noise-filter"><feTurbulence type="fractalNoise" baseFrequency="1.3" numOctaves="4" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncR type="linear" slope="0.28"/><feFuncG type="linear" slope="0.28"/><feFuncB type="linear" slope="0.28"/>       <feFuncA type="linear" slope="0.56"/>     </feComponentTransfer>     <feComponentTransfer>       <feFuncR type="linear" slope="1.47" intercept="-0.23"/>       <feFuncG type="linear" slope="1.47" intercept="-0.23"/>       <feFuncB type="linear" slope="1.47" intercept="-0.23"/>     </feComponentTransfer>   </filter>';
    }

    function _generateSVGGradient() internal pure returns (string memory) {
        return string.concat(
            '<defs><linearGradient id="MyGradient" gradientTransform="rotate(45)"><stop offset="0%" stop-color="',
            "gold",
            '" /><stop offset="100%" stop-color="',
            "green",
            '" /></linearGradient></defs>'
        );
    }

    function _generateSVGTitle(Properties memory properties)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            _drawText(
                550,
                75,
                "#fff",
                "3.25em",
                "monospace",
                "end",
                string.concat(
                    properties.pair.assetSymbol,
                    " - ",
                    properties.pair.quoteSymbol
                )
            ),
            _drawText(
                550,
                100,
                "#ffffff80",
                "1.75em",
                "monospace",
                "end",
                properties.config.isPerpetual
                    ? "Never expires"
                    : _calculateCountdown(
                        properties.config.creationTimestamp
                            + properties.config.durationSeconds
                    )
            )
        );
    }

    function _generateSVGSpotPrice(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _drawText(
                50,
                200,
                "#ffffff80",
                "1.75em",
                "monospace",
                "start",
                "Spot Price"
            ),
            _drawText(
                50,
                240,
                "#fff",
                "2.5em",
                "monospace",
                "start",
                string.concat(
                    properties.pool.spotPriceWad.toString(),
                    " ",
                    properties.pair.quoteSymbol
                )
            )
        );
    }

    function _generateSVGStrikePrice(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _drawText(
                325,
                200,
                "#ffffff80",
                "1.75em",
                "monospace",
                "start",
                "Strike Price"
            ),
            _drawText(
                325,
                240,
                "#fff",
                "2.5em",
                "monospace",
                "start",
                string.concat(
                    properties.config.strikePriceWad.toString(),
                    " ",
                    properties.pair.quoteSymbol
                )
            )
        );
    }

    function _generateSVGReserves(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return (
            string.concat(
                _drawText(
                    50,
                    320,
                    "#ffffff80",
                    "1.75em",
                    "monospace",
                    "start",
                    "Asset Reserve"
                ),
                _drawText(
                    50,
                    360,
                    "#fff",
                    "2.5em",
                    "monospace",
                    "start",
                    string.concat(
                        properties.pool.virtualX.toString(),
                        " ",
                        properties.pair.assetSymbol
                    )
                ),
                _drawText(
                    325,
                    320,
                    "#ffffff80",
                    "1.75em",
                    "monospace",
                    "start",
                    "Quote Reserve"
                ),
                _drawText(
                    325,
                    360,
                    "#fff",
                    "2.5em",
                    "monospace",
                    "start",
                    string.concat(
                        properties.pool.virtualY.toString(),
                        " ",
                        properties.pair.quoteSymbol
                    )
                )
            )
        );
    }

    function _generateSVGPoolValuation(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return (
            string.concat(
                _drawText(
                    50,
                    440,
                    "#ffffff80",
                    "1.75em",
                    "monospace",
                    "start",
                    "Pool Valuation"
                ),
                _drawText(
                    50,
                    480,
                    "#fff",
                    "2.5em",
                    "monospace",
                    "start",
                    string.concat(
                        properties.config.strikePriceWad.toString(),
                        " ",
                        properties.pair.quoteSymbol
                    )
                )
            )
        );
    }

    function _generateSVGSwapFee(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return (
            string.concat(
                _drawText(
                    325,
                    440,
                    "#ffffff80",
                    "1.75em",
                    "monospace",
                    "start",
                    "Swap Fee"
                ),
                _drawText(
                    325,
                    480,
                    "#fff",
                    "2.5em",
                    "monospace",
                    "start",
                    string.concat(
                        properties.pool.feeBasisPoints.toString(), " %"
                    )
                )
            )
        );
    }

    function _drawText(
        uint256 x,
        uint256 y,
        string memory fill,
        string memory fontSize,
        string memory fontFamily,
        string memory textAnchor,
        string memory text
    ) internal pure returns (string memory) {
        return string.concat(
            '<text x="',
            x.toString(),
            '" y="',
            y.toString(),
            '" fill="',
            fill,
            '" text-anchor="',
            textAnchor,
            '" font-size="',
            fontSize,
            '" font-family="',
            fontFamily,
            '">',
            text,
            "</text>"
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
}

/*
<svg width="600" height="600" fill="none" xmlns="http://www.w3.org/2000/svg">
  <filter id="noise-filter">
    <feTurbulence type="fractalNoise" baseFrequency="1.3" numOctaves="4" stitchTiles="stitch"/>
    <feColorMatrix type="saturate" values="0"/>
    <feComponentTransfer>
      <feFuncR type="linear" slope="0.28"/>
      <feFuncG type="linear" slope="0.28"/>
      <feFuncB type="linear" slope="0.28"/>
      <feFuncA type="linear" slope="0.56"/>
    </feComponentTransfer>
    <feComponentTransfer>
      <feFuncR type="linear" slope="1.47" intercept="-0.23"/>
      <feFuncG type="linear" slope="1.47" intercept="-0.23"/>
      <feFuncB type="linear" slope="1.47" intercept="-0.23"/>
    </feComponentTransfer>
  </filter>
    <defs>
    <linearGradient id="MyGradient" gradientTransform="rotate(45)">
      <stop offset="0%" stop-color="green" />
      <stop offset="100%" stop-color="gold" />
    </linearGradient>
  </defs>
  <rect fill="url(#MyGradient)" x="0" y="0" width="600" height="600" />
  <rect width="100%" height="100%" filter="url(#noise-filter)"/>

  <path fill-rule="evenodd" clip-rule="evenodd" d="M339.976 134.664h41.048L256 340.586 130.976 134.664h41.047V98H64.143L256 414 447.857 98H339.976v36.664Zm-38.759 0V98h-90.436v36.664h90.436Z" fill="#fff" style="transform:scale(0.25)"/>

   <text x="550" y="75" text-anchor="end" fill="#fff" font-size="3.25em" font-family="monospace">USDT - USDC</text>
     <text x="550" y="100" text-anchor="end" fill="#ffffff80" font-size="1.75em" font-family="monospace">Expires in 66 days</text>

  <text x="50" y="200" fill="#ffffff80" font-size="1.75em" font-family="monospace">Spot Price</text>
  <text x="50" y="240" fill="#fff" font-size="2.5em" font-family="monospace">0.99 USDC</text>

    <text x="325" y="200" fill="#ffffff80" font-size="1.75em" font-family="monospace">Strike Price</text>
  <text x="325" y="240" fill="#fff" font-size="2.5em" font-family="monospace">1.00 USDC</text>

    <text x="50" y="320" fill="#ffffff80" font-size="1.75em" font-family="monospace">Asset Reserve</text>
  <text x="50" y="360" fill="#fff" font-size="2.5em" font-family="monospace">435,235 USDT</text>

    <text x="325" y="320" fill="#ffffff80" font-size="1.75em" font-family="monospace">Quote Reserve</text>
  <text x="325" y="360" fill="#fff" font-size="2.5em" font-family="monospace">452,673 USDC</text>

      <text x="50" y="440" fill="#ffffff80" font-size="1.75em" font-family="monospace">Pool Valuation</text>
  <text x="50" y="480" fill="#fff" font-size="2.5em" font-family="monospace">883,555.65 USDC</text>
</svg>
*/
