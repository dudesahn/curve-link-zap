// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/curve.sol";

interface IYVault is IERC20 {
    function deposit(uint256 amount, address recipient) external;
}

contract linkZap is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    ICurveFi public pool =
        ICurveFi(address(0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF)); // Curve Iron Bank Pool
    IYVault public yVault =
        IYVault(address(0x96Ea6AF74Af09522fCB4c28C269C26F59a31ced6)); // Curve LINK Pool yVault

    IERC20 public want =
        IERC20(address(0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a)); // LINK pool curve LP Token
    IERC20 public link =
        IERC20(address(0x514910771AF9Ca656af840dff83E8264EcF986CA));

    constructor() public Ownable() {
        want.safeApprove(address(yVault), uint256(-1));
        link.safeApprove(address(pool), uint256(-1));
    }

    function zapLink(uint256 linkAmount) external {
        require(linkAmount != 0, "0 LINK");

        link.transferFrom(msg.sender, address(this), linkAmount);

        uint256 balanceBegin = link.balanceOf(address(this));
        require(balanceBegin >= linkAmount, "NOT ALL LINK RECEIVED");

        pool.add_liquidity([linkBalance, 0], 0);

        uint256 curvePoolTokens = want.balanceOf(address(this));

        yVault.deposit(curvePoolTokens, msg.sender);
    }

    function updateVaultAddress(address _vault) external onlyOwner {
        yVault = IYVault(_vault);
        want.safeApprove(_vault, uint256(-1));
    }
}
