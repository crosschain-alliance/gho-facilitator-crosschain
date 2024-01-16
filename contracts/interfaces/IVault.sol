// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IProver } from "./IProver.sol";

/**
 * @title IVault
 * @author crosschain-alliance
 * @notice Defines the behavior of a Vault used with a Crosschain Gho Facilitator
 */
interface IVault is IProver {
    event AuthorizedMint(address account, uint256 amount);
    event CollateralReleased(address account, uint256 amount);
    event Liquidated(address asset, address account, address liquidator, uint256 amount);

    error InvalidAmount(uint256 amount, uint256 maxAmount);
    error ImpossibleToWithdrawCollateralLeft();

    function canBeLiquidated(address asset, address account) external view returns (bool);

    function mint(address asset, address account, uint256 amount) external;

    function liquidate(
        address asset,
        address account,
        address liquidator,
        uint256 amount,
        Proof calldata proof
    ) external;

    function withdrawLeftCollateral(address asset, address account) external;

    function verifyBurnAndReleaseCollateral(
        address asset,
        address account,
        uint256 amount,
        Proof calldata proof
    ) external;
}
