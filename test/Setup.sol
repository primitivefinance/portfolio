// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

// Base test contract
import "forge-std/Test.sol";

// Global test configuration for Portfolio
import "./Configuration.sol";

// Test helper types
import { deploy as deployCoin, Coin } from "./utils/CoinType.sol";
import { GhostType, IPortfolioStruct } from "./utils/GhostType.sol";
import { safeCastTo16 } from "./utils/Utility.sol";

// Contracts used in testing
import "solmate/tokens/WETH.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/utils/SafeCastLib.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "solmate/test/utils/weird-tokens/ReturnsTooLittleToken.sol";
import "contracts/interfaces/IPortfolio.sol";
import "contracts/test/FeeOnTransferToken.sol";
import "contracts/test/SimpleRegistry.sol";
import "contracts/Portfolio.sol";

// Strategy to test
import "./strategies/NormalConfiguration.sol";

// Contracts in the test environment
struct SubjectsType {
    address deployer;
    address registry;
    address weth;
    address portfolio;
    address positionRenderer;
}

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

contract Setup is ISetup, Test, ERC1155TokenReceiver {
    using NormalConfiguration for Configuration;
    using SafeCastLib for *;

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

    /// @dev Updates the ghost pool, "pool()".
    function setGhostPoolId(uint64 id) public {
        _ghost_state.file("poolId", abi.encode(id));
    }

    /// @dev Uses the global test Configuration type to create a pool and set the ghost state.
    function activateConfig(Configuration memory config) internal {
        // Creates a pool with poolId and sets the ghost pool id.
        setGhostPoolId(
            config.activate(
                address(subject()), NormalConfiguration.validateNormalStrategy
            )
        );
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
        Configuration memory config = configureNormalStrategy();
        (config.asset, config.quote) = deployDefaultTokenPair();

        activateConfig(config);

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
        Configuration memory config = configureNormalStrategy().editStrategy(
            "strikePriceWad", abi.encode(strikePriceWad)
        ).editStrategy(
            "volatilityBasisPoints", abi.encode(volatilityBasisPoints)
        ).editStrategy("durationSeconds", abi.encode(durationSeconds))
            .editStrategy("isPerpetual", abi.encode(isPerpetual)).editStrategy(
            "priceWad", abi.encode(priceWad)
        ).edit("feeBasisPoints", abi.encode(feeBasisPoints)).edit(
            "priorityFeeBasisPoints", abi.encode(priorityFeeBasisPoints)
        ).edit("controller", abi.encode(controller));

        (config.asset, config.quote) = deployDefaultTokenPair();

        activateConfig(config);
        _;
    }

    modifier defaultControlledConfig() {
        Configuration memory config = configureNormalStrategy();
        (config.asset, config.quote) = deployDefaultTokenPair();

        config.controller = address(this);
        activateConfig(config);
        _;
    }

    modifier stablecoinPortfolioConfig() {
        uint32 duration = type(uint32).max;
        uint32 volatility = uint32(MIN_VOLATILITY);

        Configuration memory config = configureNormalStrategy().editStrategy(
            "durationSeconds", abi.encode(duration)
        ).editStrategy("volatilityBasisPoints", abi.encode(volatility));

        (config.asset, config.quote) = deployDefaultTokenPair();

        activateConfig(config);
        _;
    }

    modifier sixDecimalQuoteConfig() {
        Coin asset = deployCoin("token", abi.encode("asset", "ASSET", 18));
        vm.label(asset.to_addr(), "asset-18");
        Coin quote = deployCoin("token", abi.encode("quote", "QUOTE", 6));
        vm.label(quote.to_addr(), "quote-6");

        Configuration memory config = configureNormalStrategy();
        (config.asset, config.quote) = (asset.to_addr(), quote.to_addr());

        activateConfig(config);
        _;
    }

    modifier feeOnTokenTransferConfig() {
        Coin asset = deployCoin("FOT", abi.encode("asset", "ASSET", 18));
        vm.label(asset.to_addr(), "asset-fot-18");
        Coin quote = deployCoin("FOT", abi.encode("quote", "QUOTE", 18));
        vm.label(quote.to_addr(), "quote-fot-18");

        Configuration memory config = configureNormalStrategy();
        (config.asset, config.quote) = (asset.to_addr(), quote.to_addr());

        activateConfig(config);
        _;
    }

    modifier wethConfig() {
        Coin quote = deployCoin("token", abi.encode("quote", "QUOTE", 18));
        Configuration memory config = configureNormalStrategy();
        (config.asset, config.quote) = (weth(), quote.to_addr());

        activateConfig(config);
        _;
    }

    modifier durationConfig(uint32 durationSeconds) {
        console.log("duration", durationSeconds);
        Configuration memory config = configureNormalStrategy().editStrategy(
            "durationSeconds", abi.encode(durationSeconds)
        );
        (config.asset, config.quote) = deployDefaultTokenPair();

        activateConfig(config);
        _;
    }

    modifier volatilityConfig(uint32 volatilityBasisPoints) {
        Configuration memory config = configureNormalStrategy().editStrategy(
            "volatilityBasisPoints", abi.encode(volatilityBasisPoints)
        );
        (config.asset, config.quote) = deployDefaultTokenPair();

        activateConfig(config);
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
