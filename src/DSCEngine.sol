// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DSCEngine
 * @author Temi Williams
 * @notice This contract is the core of the DSC system. It handles all the logic for minting
 * and redeeming DSC, as well as depositing & withdrawing collateral
 * @notice This contract is very loosely based on the MakerDAO DSS (DAI) system
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg
 * The stable coin has the properties:
 *  - Exogenous Collateral
 *  - Dollar Pegged
 *  - Algorithmically Stable
 *
 * It is similar to DIA if DAI had no governance, no fees, and was only backed by WETH and WBTC
 *
 * Our DSC System should always be 'overcollateralized'. At no point, should the value of all collateral
 * be less than or equal to the $ backed value of all of the DSC
 */

contract DSCEngine is ReentrancyGuard {
    error DSCEngine__NeedsMorethanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) s_collateralDeposited;

    DecentralizedStableCoin private immutable i_dsc;

    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMorethanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    function depositCollateralAndMintDSC() external {}

    /**
     * @notice follows CEI
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amount The amount of collateral to deposit
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amount
    )
        external
        moreThanZero(amount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amount;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amount);
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            (msg.sender),
            address(this),
            amount
        );

        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function gethealthFactor() external view {}
}
