// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import {Pair} from "./EnigmaTypes.sol";

import {IHyperGetters} from "./interfaces/IHyper.sol";

contract PriorityAuction {
    address immutable hyper;

    address public controller;

    struct AuctionParams {
        uint256 startPrice;
        uint256 endPrice;
        uint256 fee;
        uint256 length;
    }

    // poolId to auction params
    mapping(uint48 => AuctionParams) auctionParams;

    event SetAuctionParams(uint48 indexed poolId, uint256 startPrice, uint256 endPrice, uint256 fee, uint256 length);
    event FillAuction(
        uint48 indexed poolId,
        address winner,
        uint256 auctionAmount,
        uint256 indexed epochId,
        uint256 epochEndTime
    );

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    constructor(address _hyper, address _controller) {
        hyper = _hyper;
        controller = _controller;
    }

    function setAuctionParams(
        uint48 poolId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 fee,
        uint256 length
    ) external onlyController {
        // todo: add param checks

        AuctionParams storage params = auctionParams[poolId];
        if (startPrice != 0) params.startPrice = startPrice;
        if (endPrice != 0) params.endPrice = endPrice;
        if (fee != 0) params.fee = fee;
        if (length != 0) params.length = length;

        emit SetAuctionParams(poolId, params.startPrice, params.endPrice, params.fee, params.length);
    }

    function fillAuction(
        uint48 poolId,
        address priorityOwner,
        uint128 limitAmount
    ) external {
        require(priorityOwner != address(0));

        // todo: if hyper epoch needs advancing, advance it

        AuctionParams memory poolAuctionParams = auctionParams[poolId];

        uint128 auctionPayment = _calculateAuctionPayment(
            poolAuctionParams.startPrice,
            poolAuctionParams.endPrice,
            0,
            block.timestamp
        );
        require(auctionPayment <= limitAmount);

        uint128 auctionFee = _calculateAuctionFee(auctionPayment, poolAuctionParams.fee);
        uint128 auctionNet = auctionPayment - auctionFee;

        uint16 pairId = uint16(poolId >> 32);
        (, , address tokenQuote, ) = IHyperGetters(hyper).pairs(pairId);
        // transfer in total auction amount, transfer auction net amount to Hyper
        SafeTransferLib.safeTransferFrom(ERC20(tokenQuote), msg.sender, address(this), auctionPayment);
        SafeTransferLib.safeTransferFrom(ERC20(tokenQuote), address(this), hyper, auctionNet);

        // todo: call into hyper to fill priority auction
    }

    function collectFee(address token, uint256 amount) external onlyController {
        SafeTransferLib.safeTransferFrom(ERC20(token), address(this), controller, amount);
    }

    function _calculateAuctionPayment(
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 fillTime
    ) internal returns (uint128 auctionPayment) {
        return 0;
    }

    function _calculateAuctionFee(uint128 auctionPayment, uint256 fee) internal returns (uint128 auctionFee) {
        return 0;
    }
}
