pragma solidity ^0.8.0;

interface IHyper {
    function JUST_IN_TIME_LIQUIDITY_POLICY() external view returns (uint);
}

contract Basic {
    event AssertionFailed();

    function test_add(uint a) public returns (bool) {
        /* require(a < type(uint256).max);
        require(a + 1 > 1); */
    }

    IHyper h = IHyper(0x1D7022f5B17d2F8B695918FB48fa1089C9f85401);

    function const_jit() public returns (bool) {
        assert(h.JUST_IN_TIME_LIQUIDITY_POLICY() == 3);
        h = h;
    }
}
