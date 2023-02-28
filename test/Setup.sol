// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

// Test subjects
import "contracts/RMM01Portfolio.sol";
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
    using SafeCastLib for uint;
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

    receive() external payable {}

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
    }

    function setGhostPoolId(uint64 poolId) public virtual {
        _ghost.file("poolId", abi.encode(poolId));
    }

    function setGhostActor(address actor) public virtual {
        _ghost.file("actor", abi.encode(actor));
    }

    function addGhostActor(address actor) public virtual {
        actors().add(actor);
    }

    /**
     * @dev Fetches the ghost state to get information or manipulate it.
     */
    function ghost() public view virtual returns (GhostState memory) {
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
    function subject() public view virtual returns (IHyper) {
        return IHyper(_ghost.subject);
    }

    /**
     * @notice Address that is calling the test subject contract.
     * @dev Uses the existing actor that is being pranked via `useActor` modifier.
     * It uses the `_ghost.actor` instead of `_actor.last` because it can
     * change in the environment.
     */
    function actor() public view virtual returns (address) {
        return _ghost.actor;
    }

    function getActors() public view virtual returns (address[] memory) {
        address[] memory actors = _actors.active;
        return actors;
    }

    function getRandomActor(uint index) public view virtual returns (address) {
        return _actors.rand(index);
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

    modifier usePairTokens(uint amount) {
        // Approve and mint tokens for actor.
        ghost().asset().prepare({owner: actor(), spender: address(subject()), amount: amount});
        ghost().quote().prepare({owner: actor(), spender: address(subject()), amount: amount});
        _;
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

        setGhostPoolId(poolId);
        _;
    }

    modifier defaultControlledConfig() {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .edit("controller", abi.encode(address(this)))
            .generate(address(subject()));

        setGhostPoolId(poolId);
        _;
    }

    modifier sixDecimalQuoteConfig() {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[2])))
            .generate(address(subject()));

        setGhostPoolId(poolId);
        _;
    }

    modifier wethConfig() {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().weth)))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .generate(address(subject()));

        setGhostPoolId(poolId);
        _;
    }

    modifier durationConfig(uint16 duration) {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .edit("duration", abi.encode(duration))
            .generate(address(subject()));

        setGhostPoolId(poolId);
        _;
    }

    modifier volatilityConfig(uint16 volatility) {
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .edit("volatility", abi.encode(volatility))
            .generate(address(subject()));

        setGhostPoolId(poolId);
        _;
    }

    /**
     * @dev Sets internal default jit protection seconds value to 0.
     */
    modifier noJit() {
        uint LIQUIDITY_POLICY_STORAGE_SLOT = 11;
        vm.store(address(subject()), bytes32(LIQUIDITY_POLICY_STORAGE_SLOT), bytes32(0));
        _;
    }

    modifier allocateSome(uint128 amt) {
        subject().multiprocess(EnigmaLib.encodeAllocate(uint8(0), ghost().poolId, 0x0, amt));
        _;
    }

    modifier unallocateSome(uint128 amt) {
        subject().multiprocess(EnigmaLib.encodeUnallocate(uint8(0), ghost().poolId, 0x0, amt));
        _;
    }

    modifier swapSome(uint128 amt, bool direction) {
        uint128 amtOut = subject().getAmountOut(ghost().poolId, direction, amt).safeCastTo128();
        subject().multiprocess(
            Enigma.encodeSwap(uint8(0), ghost().poolId, 0x0, amt, 0x0, amtOut, uint8(direction ? 0 : 1))
        );
        _;
    }

    modifier swapSomeGetOut(
        uint128 amt,
        int amtOutDelta,
        bool direction
    ) {
        uint128 amtOut = subject().getAmountOut(ghost().poolId, direction, amt).safeCastTo128();
        amtOut = amtOutDelta > 0
            ? amtOut + uint(amtOutDelta).safeCastTo128()
            : amtOut - uint(-amtOutDelta).safeCastTo128();

        subject().multiprocess(
            Enigma.encodeSwap(uint8(0), ghost().poolId, 0x0, amt, 0x0, amtOut, uint8(direction ? 0 : 1))
        );
        _;
    }

    modifier setActor(address actor) {
        _ghost.file("actor", abi.encode(actor));
        _;
    }

    // === Gas Utils === //
    function wasteGas(uint256 slots) internal pure {
        assembly {
            let memPtr := mload(0x40)
            mstore(add(memPtr, mul(32, slots)), 1) // Expand memory
        }
    }
}
