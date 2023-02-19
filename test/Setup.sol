// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Test subjects
import "contracts/Hyper.sol";
import "solmate/tokens/WETH.sol";

// Test utils
import "forge-std/Test.sol";
import "./HelperActorsLib.sol";
import "./HelperConfigsLib.sol";
import "./HelperGhostLib.sol";
import "./HelperSubjectsLib.sol";
import "./HelperUtils.sol" as Utils;

/**
 * @dev Hyper's test environment is setup to easily extend the tests with new configurations, actors, or environment states.
 *
 * For every test:
 * Do you have the `useActor` modifier?
 * Do you use a config modifier, like `defaultConfig`?
 * Do you check if the test is ready with the `isArmed` modifier?
 *
 * | Problem                                                 | Solution                                                                  |
 * | ------------------------------------------------------- | ------------------------------------------------------------------------- |
 * | Different contracts with same interface                 | Internal virtual function in test setup that returns test subject.        |
 * | Pools with different configurations                     | Virtual function in setup that overrides config.                          |
 * | Redundant inputs per test, e.g. poolId, tokens, actors. | Ghost variable state accessed via a virtual internal function.            |
 * | Multiple tokens and actors                              | Managed via a registry lib with easy ways to fetch, add, and remove them. |
 * | Time based test scenarios                               | Cheatcodes, and maybe a library to manage the time with more granularity. |
 */
contract Setup is Test {
    /**
     * @dev Manages the addresses calling the subjects in the environment.
     */
    ActorsState private _actors;
    /**
     * @dev Manages the contextual state in the environment. Includes subjects/actors.
     */
    GhostState private _ghost;
    /**
     * @dev Manages all the contracts in the environment.
     */
    SubjectsState private _subjects;

    /**
     * @notice Deploys WETH, subject, and three tokens. Creates a default pool.
     * @dev Initializes the actor, subject, and poolId ghost state.
     */
    function setUp() public virtual {
        _subjects
            .startDeploy(vm)
            .wrapper()
            .subject()
            .token("token", abi.encode("Asset-Std", "A-STD-18", uint8(18)))
            .token("token", abi.encode("Quote-Std", "Q-STD-18", uint8(18)))
            .token("token", abi.encode("USDC", "USDC-6", uint8(6)))
            .stopDeploy();

        _ghost = GhostState({actor: _subjects.deployer, subject: address(_subjects.last), poolId: 0});

        console.log("Setup finished");
    }

    function set_pool_id(uint64 poolId) internal virtual {
        _ghost.file("poolId", abi.encode(poolId));
    }

    /**
     * @dev Fetches the ghost state to get information or manipulate it.
     */
    function ghost() internal virtual returns (GhostState memory) {
        return _ghost;
    }

    /**
     * @dev Actors can be this test contract or helper contracts like RevertCatcher, which
     * bubbles errors up using try/catch.
     */
    function actors() internal virtual returns (ActorsState storage) {
        return _actors;
    }

    /**
     * @dev Subjects are the contracts being tested on or used in testing.
     */
    function subjects() internal virtual returns (SubjectsState storage) {
        return _subjects;
    }

    /**
     * @notice Contract that is being tested.
     * @dev Target subject is a ghost variable because it changes in the environment.
     */
    function subject() internal virtual returns (IHyper) {
        return IHyper(_ghost.subject);
    }

    /**
     * @notice Address that is calling the test subject contract.
     * @dev Uses the existing actor that is being pranked via `useActor` modifier.
     * It uses the `_ghost.actor` instead of `_actor.last` because it can
     * change in the environment.
     */
    function actor() internal virtual returns (address) {
        return _ghost.actor;
    }

    // === Modifiers for Tests === //

    modifier isArmed() {
        require(ghost().poolId != 0, "did you forget to use a config modifier?");
        require(ghost().subject != address(0), "did you forget to deploy a subject?");
        require(ghost().actor != address(0), "did you forget to set an actor?");
        _;
    }

    modifier useActor() {
        vm.startPrank(actor());
        _;
        vm.stopPrank();
    }

    /**
     * @dev Uses a default parameter set to create a pool.
     * @custom:example
     * ```
     * function test_basic_deposit() public defaultConfig {...}
     * ```
     */
    modifier defaultConfig() {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .generate(address(subject()));

        set_pool_id(poolId);
        _;
    }

    modifier sixDecimalQuoteConfig() {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[2])))
            .generate(address(subject()));

        set_pool_id(poolId);
        _;
    }

    modifier wethConfig() {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().weth)))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .generate(address(subject()));

        set_pool_id(poolId);
        _;
    }

    modifier durationConfig(uint16 duration) {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .edit("duration", abi.encode(duration))
            .generate(address(subject()));

        set_pool_id(poolId);
        _;
    }

    modifier volatilityConfig(uint16 volatility) {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .edit("volatility", abi.encode(volatility))
            .generate(address(subject()));

        set_pool_id(poolId);
        _;
    }
}
