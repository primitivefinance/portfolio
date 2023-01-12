pragma solidity ^0.8.0;
contract Helper {
	event AssertionFailed(string msg);
	event LogUint256(string msg, uint256 value);
	event LogBytes(string msg, bytes value);
	event LogAddress(string msg, address tkn);
	event LogInt24(string msg,int24 value);
}