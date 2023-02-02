// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "solmate/tokens/WETH.sol";
import "solmate/utils/SafeCastLib.sol";
import "contracts/HyperLib.sol";
import "contracts/libraries/Price.sol";

import "forge-std/Test.sol";
import {TestERC20, Hyper, HyperTimeOverride, HyperCatchReverts, RevertCatcher, FixedPointMathLib} from "test/helpers/HyperTestOverrides.sol";

import "test/helpers/HelperHyperActions.sol";
import "test/helpers/HelperHyperInvariants.sol";
import "test/helpers/HelperHyperProfiles.sol";
import "test/helpers/HelperHyperView.sol";

uint constant STARTING_BALANCE = 4000e18;

struct TestScenario {
    TestERC20 asset;
    TestERC20 quote;
    uint64 poolId;
    string label;
}

/** @dev Deploys test contracts, test tokens, sets labels, funds users, and approves contracts to spend tokens. */
contract TestHyperSetup is HelperHyperActions, HelperHyperInvariants, HelperHyperProfiles, HelperHyperView, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;
    using SafeCastLib for uint;

    WETH public __weth__;
    Hyper public __hyper__; // Actual contract
    HyperTimeOverride public __hyperTimeOverride__; // Inherits Hyper, adds block.timestamp and jit policy overrides
    HyperCatchReverts public __hyperTestingContract__; // Inherits HyperTimeOverrides, adds endpoints to process functions.
    RevertCatcher public __revertCatcher__;

    TestERC20 public __usdc__;
    TestERC20 public __token_8__;
    TestERC20 public __token_18__;
    TestERC20 public __token_18__2;
    TestERC20 public __badToken__;

    address[] public __contracts__;
    address[] public __users__;
    address[] public __tokens__;

    TestScenario public defaultScenario;
    TestScenario public _scenario_18_18;
    TestScenario public _scenario_controlled;
    TestScenario[] public scenarios;

    modifier postTestInvariantChecks() virtual {
        _;
        assertSettlementInvariant(address(__hyperTestingContract__), address(defaultScenario.asset), __users__);
        assertSettlementInvariant(address(__hyperTestingContract__), address(defaultScenario.quote), __users__);
    }

    function setUp() public {
        initContracts();
        initUsers();
        initScenarios();
        initPrerequisites();
        afterSetUp();
    }

    function getState() public view returns (HyperState memory) {
        return getState(address(__hyperTestingContract__), defaultScenario.poolId, address(this), __users__);
    }

    /** Hook to override receive. Defaults to just accepting ether sent to this test contract. */
    receive() external payable {
        receiveOverride();
    }

    /** @dev Hook to run after test setup. */
    function afterSetUp() public virtual {}

    function receiveOverride() public virtual {}

    function initContracts() internal {
        __weth__ = new WETH();

        // --- Hyper Contracts --- //
        __hyper__ = new Hyper(address(__weth__));
        __hyperTimeOverride__ = new HyperTimeOverride(address(__weth__));
        __hyperTestingContract__ = new HyperCatchReverts(address(__weth__));
        __revertCatcher__ = new RevertCatcher(address(__hyperTestingContract__));
        __contracts__.push(address(__hyper__));
        __contracts__.push(address(__hyperTimeOverride__));
        __contracts__.push(address(__hyperTestingContract__));
        __contracts__.push(address(__revertCatcher__));

        __usdc__ = new TestERC20("USD Coin", "USDC", 6);
        __token_8__ = new TestERC20("8 Decimals", "8DEC", 8);
        __token_18__ = new TestERC20("18 Decimals", "18DEC", 18);
        __token_18__2 = new TestERC20("18 Decimals #2", "18DEC_2", 18);
        __badToken__ = new TestERC20("Non-standard ERC20", "BAD", 18); // TODO: Add proper bad token.
        __tokens__.push(address(__usdc__));
        __tokens__.push(address(__token_8__));
        __tokens__.push(address(__token_18__));
        __tokens__.push(address(__token_18__2));
        __tokens__.push(address(__badToken__));

        setLabels();
    }

    function initUsers() internal {
        address self = address(this);
        address alicent = address(0x0001);
        address boba = address(0x0002);
        address revertCatcher = address(__revertCatcher__);

        vm.label(self, "Self");
        vm.label(alicent, "Alicent");
        vm.label(boba, "Boba");

        __users__.push(self);
        __users__.push(alicent);
        __users__.push(boba);
        __users__.push(revertCatcher);
    }

    function initScenarios() internal {
        // Create default pool
        bytes memory data = createPool(
            address(__token_18__),
            address(__usdc__),
            address(0),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(DEFAULT_SIGMA),
            uint16(DEFAULT_DURATION_DAYS),
            DEFAULT_JIT,
            DEFAULT_TICK,
            DEFAULT_PRICE
        );

        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "__revertCatcher__ call failed");

        // Create default scenario and add to all scenarios.
        defaultScenario = TestScenario(__token_18__, __usdc__, FIRST_POOL, "Default");
        scenarios.push(defaultScenario);

        data = createPool(
            address(__token_18__),
            address(__token_18__2),
            address(0),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(DEFAULT_SIGMA),
            uint16(DEFAULT_DURATION_DAYS),
            DEFAULT_JIT,
            DEFAULT_TICK,
            DEFAULT_PRICE
        );

        success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "__revertCatcher__ call failed");

        _scenario_18_18 = TestScenario(
            __token_18__,
            __token_18__2,
            Enigma.encodePoolId(
                uint24(__hyperTestingContract__.getPairNonce()),
                false,
                uint32(__hyperTestingContract__.getPoolNonce())
            ),
            "18-18 decimal pair"
        );
        scenarios.push(_scenario_18_18);
    }

    uint64 public constant FIRST_POOL = 0x0000010000000001;
    uint64 public constant SECOND_POOL = 0x0000020000000002;
    uint64 public constant SECOND_POOL_FIRST_PAIR = 0x0000010000000002;

    /** @dev Requires tokens to be spent and spenders to be approved. */
    function initPrerequisites() internal {
        fundUsers();
        approveTokens();
    }

    /** @dev Does not include weth. */
    function approveTokens() internal {
        for (uint x; x != __tokens__.length; ++x) {
            for (uint y; y != __contracts__.length; ++y) {
                for (uint z; z != __users__.length; ++z) {
                    vm.prank(__users__[z]); // Sets caller
                    TestERC20(__tokens__[x]).approve(__contracts__[y], type(uint256).max); // Approves test contracts to spend tokens.
                }
            }
        }
    }

    /** @dev Does not include weth. */
    function fundUsers() internal {
        for (uint i; i != __users__.length; ++i) {
            for (uint j; j != __tokens__.length; ++j) {
                deal(__tokens__[j], __users__[i], STARTING_BALANCE); // TODO: Use regular ERC20, since we can deal.
            }
        }
    }

    function setLabels() internal {
        vm.label(address(this), "Self");
        vm.label(address(__weth__), "Weth");
        vm.label(address(__revertCatcher__), "RevertCatcher");
        vm.label(address(__hyper__), "DefaultHyper");
        vm.label(address(__hyperTimeOverride__), "HyperTimeOverride");
        vm.label(address(__hyperTestingContract__), "HyperCatchReverts");
        vm.label(address(__usdc__), "USDC");
        vm.label(address(__token_8__), "Token8Decimals");
        vm.label(address(__token_18__), "Token18Decimals");
        vm.label(address(__badToken__), "BadToken");
    }

    function createControlledPool() internal {
        bytes memory data = Enigma.encodeCreatePool(
            uint24(1), // first pair, is it good in this test?
            address(this),
            100,
            DEFAULT_FEE,
            DEFAULT_VOLATILITY,
            DEFAULT_DURATION,
            DEFAULT_JIT,
            DEFAULT_MAX_TICK,
            DEFAULT_PRICE
        );

        bool success = __revertCatcher__.process(data);
        assertTrue(success, "controlled pool not created");

        // assumes second pool has not been created...
        // can be fixed by getting pool nonce and encoding pool id.
        uint64 poolId = Enigma.encodePoolId(uint24(1), true, uint32(__hyperTestingContract__.getPoolNonce()));
        _scenario_controlled = TestScenario(__token_18__, __usdc__, poolId, "Controlled");
        scenarios.push(_scenario_controlled);
    }

    function basicSwap() internal {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        (uint output, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            (pool.getMaxSwapAssetInWad() * 1 ether) / 2 ether,
            1
        );

        assertTrue(output > 0, "no swap happened!");
    }

    function _swap(uint64 id) internal {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), id);
        (uint output, ) = __hyperTestingContract__.swap(id, true, (pool.getMaxSwapAssetInWad() * 1 ether) / 2 ether, 1);
        assertTrue(output > 0, "no swap happened!");
    }

    function basicSwapQuoteIn() internal {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        (uint output, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            false,
            (pool.getMaxSwapQuoteInWad() * 1 ether) / 2 ether,
            type(uint256).max
        );

        assertTrue(output > 0, "no swap happened!");
    }

    function basicAllocate() internal {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1 ether);
    }

    function _alloc(uint64 id) internal {
        __hyperTestingContract__.allocate(id, 1 ether);
    }

    function basicUnallocate() internal {
        __hyperTestingContract__.unallocate(defaultScenario.poolId, type(uint).max); // max
    }

    function maxDraw() internal {
        __hyperTestingContract__.draw(
            address(defaultScenario.asset),
            __hyperTestingContract__.getBalance(address(this), address(defaultScenario.asset)),
            address(this)
        );
        __hyperTestingContract__.draw(
            address(defaultScenario.quote),
            __hyperTestingContract__.getBalance(address(this), address(defaultScenario.quote)),
            address(this)
        );
    }

    function defaultPool() internal view returns (HyperPool memory) {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        return pool;
    }

    function defaultRevertCatcherPosition() internal view returns (HyperPosition memory) {
        HyperPosition memory pos = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            defaultScenario.poolId
        );
        return pos;
    }

    function defaultPosition() internal view returns (HyperPosition memory) {
        HyperPosition memory pos = getPosition(
            address(__hyperTestingContract__),
            address(this),
            defaultScenario.poolId
        );
        return pos;
    }

    /** @dev Casted to returns structs as memory */
    function hs() internal view returns (IHyperStruct) {
        return IHyperStruct(address(__hyperTestingContract__));
    }

    function hx() internal view returns (HyperLike) {
        return HyperLike(address(__hyperTestingContract__));
    }
}
