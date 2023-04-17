pragma solidity ^0.8.4;

interface PortfolioLike {
    function setProtocolFee(uint256) external;
    function claimFee(address, uint256) external;
}

// Do not use! No protection!
contract SimpleRegistry {
    address public controller;

    constructor() {
        controller = msg.sender;
    }

    modifier useSelfAsController() {
        address prevController = controller;
        controller = address(this);
        _;
        controller = prevController;
    }

    function setFee(
        address portfolio,
        uint256 fee
    ) public useSelfAsController {
        PortfolioLike(portfolio).setProtocolFee(fee);
    }

    function claimFee(
        address portfolio,
        address token,
        uint256 amount
    ) public useSelfAsController {
        PortfolioLike(portfolio).claimFee(token, amount);
    }
}
