pragma solidity ^0.8.0;
contract Helper {
	event AssertionFailed(string msg);
	event LogUint256(string msg, uint256 value);
	event LogBytes(string msg, bytes value);
	event LogAddress(string msg, address tkn);
	event LogInt24(string msg,int24 value);

	int24 constant MAX_TICK = 887272;
	int24 constant MIN_TICK = -414486;
	uint256 constant BUFFER = 300 seconds;
	uint256 constant MIN_FEE = 1; // 0.01%
	uint256 constant MAX_FEE = 1000; // 10%
	uint256 constant MIN_VOLATILITY = 100; // 1%
	uint256 constant MAX_VOLATILITY = 25_000; // 250%
	uint256 constant MIN_DURATION = 1; // days, but without units
	uint256 constant MAX_DURATION = 500; // days, but without units
	uint256 constant JUST_IN_TIME_MAX = 600 seconds;
	uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4 seconds;	
	
}