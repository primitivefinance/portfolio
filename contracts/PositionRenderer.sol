// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "openzeppelin/utils/Base64.sol";
import "solmate/tokens/ERC20.sol";

import "./libraries/StringsLib.sol";
import "./libraries/AssemblyLib.sol";
import { PoolIdLib } from "./libraries/PoolLib.sol";
import "./interfaces/IPortfolio.sol";
import "./strategies/NormalStrategy.sol";

/**
 * @title
 * PositionRenderer
 *
 * @author
 * Primitive™
 *
 * @dev
 * Prepares the metadata and generates the visual representation of the
 * liquidity pool tokens.
 * This contract is not meant to be called directly.
 */
contract PositionRenderer {
    using StringsLib for *;

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

    /**
     * @dev Returns the metadata of the required liquidity pool token, following
     * the ERC-1155 standard.
     * @param id Id of the required pool.
     * @return Minified Base64-encoded JSON containing the metadata.
     */
    function uri(uint256 id) external view returns (string memory) {
        Properties memory properties = _getProperties(id);

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        _generateName(properties),
                        '","animation_url":"data:text/html;base64,',
                        Base64.encode(bytes(_generateHTML(properties))),
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

    /**
     * @dev Returns the data associated with the asset / quote pair.
     * @param id Id of the pair associated with the required pool.
     */
    function _getPair(uint256 id) internal view returns (Pair memory) {
        (
            address tokenAsset,
            uint8 decimalsAsset,
            address tokenQuote,
            uint8 decimalsQuote
        ) = IPortfolio(msg.sender).pairs(
            uint24(PoolIdLib.pairId(PoolId.wrap(uint64(id))))
        );

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

    /**
     * @dev Returns the data associated with the current pool.
     * @param id Id of the required pool.
     */
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
            spotPriceWad: spotPriceWad
        });
    }

    /**
     * @dev Returns the data associated with the current pool config.
     * @param id Id of the required pool.
     */
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

    /**
     * @dev Returns all data associated with the current pool packed within a
     * struct.
     * @param id Id of the required pool.
     */
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

    /**
     * @dev Generates the name of the NFT.
     */
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

    /**
     * @dev Outputs all the data associated with the current pair in JSON format.
     */
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

    /**
     * @dev Outputs all the data associated with the current pool in JSON format.
     */
    function _generatePool(Properties memory properties)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            '"asset_reserves":"',
            (properties.pool.virtualX).toString(),
            '",',
            '"quote_reserves":"',
            (properties.pool.virtualY).toString(),
            '",',
            '"spot_price_wad":"',
            (properties.pool.spotPriceWad).toString(),
            '",',
            '"fee_basis_points":"',
            properties.pool.feeBasisPoints.toString(),
            '",',
            '"priority_fee_basis_points":"',
            properties.pool.priorityFeeBasisPoints.toString(),
            '",',
            '"controller":"',
            StringsLib.toHexString(properties.pool.controller),
            '",',
            '"strategy":"',
            StringsLib.toHexString(properties.pool.strategy),
            '"'
        );
    }

    /**
     * @dev Outputs all the data associated with the current pool config in JSON
     * format.
     */
    function _generateConfig(Properties memory properties)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            '"strike_price_wad":"',
            (properties.config.strikePriceWad).toString(),
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

    /**
     * @dev Generates the visual representation of the NFT in HTML.
     */
    function _generateHTML(Properties memory properties)
        private
        view
        returns (string memory)
    {
        string memory color0 = StringsLib.toHexColor(
            bytes3(
                keccak256(
                    abi.encode(properties.pool.poolId, properties.pair.asset)
                )
            )
        );
        string memory color1 = StringsLib.toHexColor(
            bytes3(
                keccak256(
                    abi.encode(properties.pool.poolId, properties.pair.quote)
                )
            )
        );

        string memory title = string.concat(
            properties.pair.assetSymbol,
            "-",
            properties.pair.quoteSymbol,
            " Portfolio LP"
        );

        return string.concat(
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
            _generateFooter(properties),
            "</body></html>"
        );
    }

    /**
     * @dev Generates a <td> element representing a stat.
     * @param label Name of the stat.
     * @param amount Full amount (including the decimals).
     * @param decimals Decimals of the token.
     * @param symbol Ticker of the token.
     */
    function _generateStat(
        string memory label,
        uint256 amount,
        uint8 decimals,
        string memory symbol
    ) private pure returns (string memory) {
        return string.concat(
            '<td><span class="l">',
            label,
            "</span><br />",
            "<script>document.write(new Intl.NumberFormat().format(",
            amount.toString(),
            "n / (10n ** ",
            decimals.toString(),
            "n)))</script> ",
            symbol,
            "</td>"
        );
    }

    /**
     * @dev Generates a <td> element representing a percentage stat.
     * @param label Name of the stat.
     * @param amount Full amount (using a 10,000 base).
     */
    function _generatePercentStat(
        string memory label,
        uint256 amount
    ) private pure returns (string memory) {
        return string.concat(
            '<td><span class="l">',
            label,
            "</span><br />",
            "<script>document.write(new Intl.NumberFormat().format(",
            amount.toString(),
            " / 10000))</script> %</td>"
        );
    }

    /**
     * @dev Generates a <td> element containing the title.
     */
    function _generateTitle(Properties memory properties)
        private
        view
        returns (string memory)
    {
        return string.concat(
            '<td class="t" style="text-align: right">',
            string.concat(
                properties.pair.assetSymbol, "-", properties.pair.quoteSymbol
            ),
            '<br /><span class="l">',
            properties.config.isPerpetual
                ? "Perpetual pool"
                : (
                    properties.config.creationTimestamp
                        + properties.config.durationSeconds
                ).toCountdown(),
            "</span></td>"
        );
    }

    /**
     * @dev Generates the stats <table> element.
     */
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
            _generateTitle(properties),
            "</tr><tr></tr><tr>",
            _generateSpotPrice(properties),
            _generateStrikePrice(properties),
            "</tr><tr>",
            _generateAssetReserves(properties),
            _generateQuoteReserves(properties),
            "</tr><tr>",
            _generatePoolValuation(properties),
            _generateSwapFee(properties),
            "</tr></table>"
        );
    }

    /**
     * @dev Generates the spot price <td> element.
     */
    function _generateSpotPrice(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Spot Price",
                AssemblyLib.scaleFromWadDown(
                    properties.pool.spotPriceWad, properties.pair.quoteDecimals
                ),
                properties.pair.quoteDecimals,
                properties.pair.quoteSymbol
            )
        );
    }

    /**
     * @dev Generates the strike price <td> element.
     */
    function _generateStrikePrice(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Strike Price",
                AssemblyLib.scaleFromWadDown(
                    properties.config.strikePriceWad,
                    properties.pair.quoteDecimals
                ),
                properties.pair.quoteDecimals,
                properties.pair.quoteSymbol
            )
        );
    }

    /**
     * @dev Calculates the asset reserves and generates the <td> element.
     */
    function _generateAssetReserves(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Asset Reserves",
                AssemblyLib.scaleFromWadDown(
                    properties.pool.virtualX, properties.pair.assetDecimals
                ),
                properties.pair.assetDecimals,
                properties.pair.assetSymbol
            )
        );
    }

    /**
     * @dev Calculates the quote reserves and generates the <td> element.
     */
    function _generateQuoteReserves(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generateStat(
                "Asset Reserves",
                AssemblyLib.scaleFromWadDown(
                    properties.pool.virtualY, properties.pair.quoteDecimals
                ),
                properties.pair.quoteDecimals,
                properties.pair.quoteSymbol
            )
        );
    }

    /**
     * @dev Calculates the pool valuation and generates the <td> element.
     */
    function _generatePoolValuation(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        uint256 poolValuation = AssemblyLib.scaleFromWadDown(
            properties.pool.virtualX, properties.pair.assetDecimals
        )
            * AssemblyLib.scaleFromWadDown(
                properties.pool.spotPriceWad, properties.pair.quoteDecimals
            ) / 10 ** properties.pair.assetDecimals
            + AssemblyLib.scaleFromWadDown(
                properties.pool.virtualY, properties.pair.quoteDecimals
            );

        return string.concat(
            _generateStat(
                "Pool Valuation",
                poolValuation,
                properties.pair.quoteDecimals,
                properties.pair.quoteSymbol
            )
        );
    }

    /**
     * @dev Generates the swap fee <td> element.
     */
    function _generateSwapFee(Properties memory properties)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            _generatePercentStat("Swap Fee", properties.pool.feeBasisPoints)
        );
    }

    /**
     * @dev Generates the footer <div> element.
     */
    function _generateFooter(Properties memory properties)
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
                "a custom strategy.",
                "</p></div>"
            )
        );
    }
}
