// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

// Base test contracts
import "forge-std/Test.sol";
import "./Configuration.sol";

// Test types
import { deploy as deployCoin, Coin } from "./utils/CoinType.sol";
import { GhostType, IPortfolioStruct } from "./utils/GhostType.sol";

// Contracts to test
import "solmate/tokens/WETH.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/utils/SafeCastLib.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "solmate/test/utils/weird-tokens/ReturnsTooLittleToken.sol";
import "contracts/interfaces/IPortfolio.sol";
import "contracts/test/FeeOnTransferToken.sol";
import "contracts/test/SimpleRegistry.sol";
import "contracts/Portfolio.sol";

// Types
struct SubjectsType {
    address deployer;
    address registry;
    address weth;
    address portfolio;
    address positionRenderer;
}

// Constants
uint16 constant Setup_DEFAULT_FEE = 30;
uint16 constant Setup_DEFAULT_PRIORITY_FEE = 10;
uint256 constant DefaultStrategy_DEFAULT_STRIKE = 1e18;
uint256 constant DefaultStrategy_DEFAULT_VOLATILITY = 1000;
uint256 constant DefaultStrategy_DEFAULT_DURATION = 1 days;
uint256 constant DefaultStrategy_DEFAULT_PRICE = 1e18;

// Interfaces
interface ISetup {
    /// @dev Overwrites the ghost state poolId with `id`.
    function setGhostPoolId(uint64 id) external;

    /// @dev Returns the current targets for the tests.
    function ghost() external view returns (GhostType memory);

    /// @dev Returns the current subjects for the tests.
    function subjects() external view returns (SubjectsType memory);

    /// @dev Returns the target smart contract being called in tests.
    function subject() external view returns (IPortfolio);

    /// @dev Returns the strategy of the subject and subject pool.
    function strategy() external view returns (IStrategy);

    /// @dev Returns the caller of the unit tests with the modifier `useActor`.
    function actor() external view returns (address);

    /// @dev Returns the specific pool of the unit test.
    function poolId() external view returns (uint256);

    /// @dev Returns the WETH token.
    function weth() external view returns (address);

    /// @dev Returns the registry contract used in the subject.
    function registry() external view returns (address);

    /// @dev Returns the portfolio contract as an address, which is also the subject.
    function portfolio() external view returns (address);

    /// @dev Returns the position renderer contract used in the subject.
    function positionRenderer() external view returns (address);
}

/// Normal strategy test helper
library DefaultStrategy {
    using SafeCastLib for uint256;

    /// @dev Gets the test configuration with default values.
    function getDefaultTestConfig(address portfolio)
        internal
        view
        returns (Configuration memory config)
    {
        return getTestConfig(portfolio, 0, 0, 0, false, 0);
    }

    /// @dev Transforms the necessary parameters and strategy config to a common config.
    function getTestConfig(
        address portfolio,
        uint256 strikePriceWad,
        uint256 volatilityBasisPoints,
        uint256 durationSeconds,
        bool isPerpetual,
        uint256 priceWad
    ) internal view returns (Configuration memory config) {
        if (strikePriceWad == 0) {
            strikePriceWad = DefaultStrategy_DEFAULT_STRIKE;
        }
        if (volatilityBasisPoints == 0) {
            volatilityBasisPoints = DefaultStrategy_DEFAULT_VOLATILITY;
        }
        if (durationSeconds == 0) {
            durationSeconds = DefaultStrategy_DEFAULT_DURATION;
        }
        if (priceWad == 0) priceWad = DefaultStrategy_DEFAULT_PRICE;

        // These get casted down and silently revert if they overflow the target type.
        require(strikePriceWad <= type(uint128).max, "Setup_InvalidStrike");
        require(
            volatilityBasisPoints <= type(uint32).max, "Setup_InvalidVolatility"
        );
        require(durationSeconds <= type(uint32).max, "Setup_InvalidDuration");

        (config.strategyArgs, config.reserveXPerWad, config.reserveYPerWad) =
        INormalStrategy(IPortfolio(portfolio).DEFAULT_STRATEGY())
            .getStrategyData({
            strikePriceWad: strikePriceWad,
            volatilityBasisPoints: volatilityBasisPoints,
            durationSeconds: durationSeconds,
            isPerpetual: isPerpetual,
            priceWad: priceWad
        });

        return config;
    }
}

contract Setup is ISetup, Test, ERC1155TokenReceiver {
    using SafeCastLib for uint256;
    using DefaultStrategy for Configuration;

    // Test ghost state
    GhostType internal _ghost_state;
    SubjectsType internal _subjects;

    // ============= Before Test ============= //

    // Important for making sure the setup went smoothly!
    modifier verifySetup() {
        _;
        require(
            ghost().subject != address(0), "did you forget to deploy a subject?"
        );
        require(ghost().actor != address(0), "did you forget to set an actor?");
    }

    // Setup
    function setUp() public virtual verifySetup {
        _subjects.deployer = address(this);
        vm.label(_subjects.deployer, "deployer");

        _subjects.registry = address(new SimpleRegistry());
        vm.label(_subjects.registry, "registry");

        _subjects.weth = address(new WETH());
        vm.label(_subjects.weth, "weth");

        _subjects.positionRenderer = address(new PositionRenderer());
        vm.label(_subjects.positionRenderer, "position-renderer");

        _subjects.portfolio = address(
            new Portfolio(_subjects.weth, _subjects.registry, _subjects.positionRenderer)
        );
        vm.label(_subjects.portfolio, "portfolio");

        _ghost_state = GhostType({
            actor: address(this),
            subject: _subjects.portfolio,
            poolId: 0
        });

        assertEq(subject().VERSION(), "v1.4.0-beta", "version-not-equal");
    }

    // ============= Edit Test Environment ============= //

    function setGhostPoolId(uint64 id) public {
        _ghost_state.file("poolId", abi.encode(id));
    }

    //  ============= Test Setup Modifiers ============= //

    /// @dev Stop the gas metering, must resume within the test.
    modifier pauseGas() {
        vm.pauseGasMetering();
        _;
    }

    /// @dev Uses the `prank` forge cheat on the actor in the ghost state.
    modifier useActor() {
        vm.startPrank(actor());
        _;
        vm.stopPrank();
    }

    /// @dev Updates the actor in the ghost state, `useActor` should be used after it.
    modifier setActor(address actor_) {
        _ghost_state.file("actor", abi.encode(actor_));
        _;
    }

    // ============= Pool Setup Modifiers  ============= //

    modifier usePairTokens(uint256 amount) {
        // Approve and mint tokens for actor.
        if (ghost().asset().to_addr() != address(subject().WETH())) {
            ghost().asset().prepare({
                owner: actor(),
                spender: address(subject()),
                amount: amount
            });
        }
        if (ghost().quote().to_addr() != address(subject().WETH())) {
            ghost().quote().prepare({
                owner: actor(),
                spender: address(subject()),
                amount: amount
            });
        }
        _;
    }

    // Quick default actions

    modifier allocateSome(uint128 amt) {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                amt,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);
        _;
    }

    modifier deallocateSome(uint128 amt) {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate, (false, ghost().poolId, amt, 0, 0)
        );
        subject().multicall(data);
        _;
    }

    modifier swapSome(uint128 amt, bool sellAsset) {
        uint128 amtOut = subject().getAmountOut(
            ghost().poolId, sellAsset, amt, address(this)
        ).safeCastTo128();

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amt,
            output: amtOut,
            sellAsset: sellAsset
        });

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(IPortfolioActions.swap, (order));
        subject().multicall(data);
        _;
    }

    modifier swapSomeGetOut(uint128 amt, int256 amtOutDelta, bool sellAsset) {
        uint128 amtOut = subject().getAmountOut(
            ghost().poolId, sellAsset, amt, address(this)
        ).safeCastTo128();
        amtOut = amtOutDelta > 0
            ? amtOut + uint256(amtOutDelta).safeCastTo128()
            : amtOut - uint256(-amtOutDelta).safeCastTo128();

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amt,
            output: amtOut,
            sellAsset: sellAsset
        });

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(IPortfolioActions.swap, (order));
        subject().multicall(data);
        _;
    }

    // Modifier configs

    function deployDefaultTokenPair() internal returns (address, address) {
        Coin asset = deployCoin("token", abi.encode("asset", "ASSET", 18));
        Coin quote = deployCoin("token", abi.encode("quote", "QUOTE", 18));

        return (asset.to_addr(), quote.to_addr());
    }

    modifier defaultConfig() {
        Configuration memory config =
            DefaultStrategy.getDefaultTestConfig(address(subject()));
        (config.asset, config.quote) = deployDefaultTokenPair();

        _ghost_state.poolId = config.instantiate(address(subject()));

        _;
    }

    modifier customConfig(
        uint256 feeBasisPoints,
        uint256 priorityFeeBasisPoints,
        address controller,
        uint256 strikePriceWad,
        uint256 volatilityBasisPoints,
        uint256 durationSeconds,
        bool isPerpetual,
        uint256 priceWad
    ) {
        Configuration memory config = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: strikePriceWad,
            volatilityBasisPoints: volatilityBasisPoints,
            durationSeconds: durationSeconds,
            isPerpetual: isPerpetual,
            priceWad: priceWad
        });

        (config.feeBasisPoints, config.priorityFeeBasisPoints) =
            (feeBasisPoints, priorityFeeBasisPoints);

        (config.asset, config.quote) = deployDefaultTokenPair();

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier defaultControlledConfig() {
        Configuration memory config =
            DefaultStrategy.getDefaultTestConfig(address(subject()));
        (config.asset, config.quote) = deployDefaultTokenPair();

        config.controller = address(this);
        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier stablecoinPortfolioConfig() {
        uint16 duration = type(uint16).max;
        uint16 volatility = uint16(MIN_VOLATILITY);

        Configuration memory config = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: 1e18,
            volatilityBasisPoints: volatility,
            durationSeconds: duration, // todo: fix
            isPerpetual: true,
            priceWad: 1e18
        });

        (config.asset, config.quote) = deployDefaultTokenPair();

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier sixDecimalQuoteConfig() {
        Coin asset = deployCoin("token", abi.encode("asset", "ASSET", 18));
        vm.label(asset.to_addr(), "asset-18");
        Coin quote = deployCoin("token", abi.encode("quote", "QUOTE", 6));
        vm.label(quote.to_addr(), "quote-6");

        Configuration memory config =
            DefaultStrategy.getDefaultTestConfig(address(subject()));
        (config.asset, config.quote) = (asset.to_addr(), quote.to_addr());

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier feeOnTokenTransferConfig() {
        Coin asset = deployCoin("FOT", abi.encode("asset", "ASSET", 18));
        vm.label(asset.to_addr(), "asset-fot-18");
        Coin quote = deployCoin("FOT", abi.encode("quote", "QUOTE", 18));
        vm.label(quote.to_addr(), "quote-fot-18");

        Configuration memory config =
            DefaultStrategy.getDefaultTestConfig(address(subject()));
        (config.asset, config.quote) = (asset.to_addr(), quote.to_addr());

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier wethConfig() {
        Coin quote = deployCoin("token", abi.encode("quote", "QUOTE", 18));
        Configuration memory config =
            DefaultStrategy.getDefaultTestConfig(address(subject()));
        (config.asset, config.quote) = (weth(), quote.to_addr());

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier durationConfig(uint16 duration) {
        Configuration memory config = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: 0,
            volatilityBasisPoints: 0,
            durationSeconds: uint32(duration) * 1 days, // todo: fix
            isPerpetual: false,
            priceWad: 0
        });
        (config.asset, config.quote) = deployDefaultTokenPair();

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    modifier volatilityConfig(uint16 volatility) {
        Configuration memory config = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: 0,
            volatilityBasisPoints: volatility,
            durationSeconds: 0, // todo: fix
            isPerpetual: false,
            priceWad: 0
        });
        (config.asset, config.quote) = deployDefaultTokenPair();

        _ghost_state.poolId = config.instantiate(address(subject()));
        _;
    }

    // ============= Test Interface ============= //

    /// @inheritdoc ISetup
    function ghost() public view override returns (GhostType memory) {
        return _ghost_state;
    }

    /// @inheritdoc ISetup
    function subjects() public view returns (SubjectsType memory) {
        return _subjects;
    }

    /// @inheritdoc ISetup
    function actor() public view override returns (address) {
        return _ghost_state.actor;
    }

    /// @inheritdoc ISetup
    function subject() public view override returns (IPortfolio) {
        return IPortfolio(payable(_ghost_state.subject));
    }

    /// @inheritdoc ISetup
    function poolId() public view override returns (uint256) {
        return _ghost_state.poolId;
    }

    /// @inheritdoc ISetup
    function weth() public view override returns (address) {
        return _subjects.weth;
    }

    /// @inheritdoc ISetup
    function registry() public view override returns (address) {
        return _subjects.registry;
    }

    /// @inheritdoc ISetup
    function portfolio() public view override returns (address) {
        return _subjects.portfolio;
    }

    /// @inheritdoc ISetup
    function strategy() public view override returns (IStrategy) {
        return _ghost_state.strategy();
    }

    /// @inheritdoc ISetup
    function positionRenderer() public view override returns (address) {
        return _subjects.positionRenderer;
    }

    receive() external payable { }
}
