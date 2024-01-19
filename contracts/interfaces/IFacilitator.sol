// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGhoFacilitator } from "./gho/IGhoFacilitator.sol";
import { IProver } from "./IProver.sol";

/**
 * @title IFacilitator
 * @author crosschain-alliance
 * @notice Defines the behavior of a Cross Chain Gho Facilitator
 */
interface IFacilitator is IGhoFacilitator, IProver {
    event AuthorizedBurn(address asset, address account, uint256 amount);
    event AuthorizedInitLiquidation(address asset, address account, address liquidator, uint256 amount);
    event FinalizedLiquidation(address asset, address account, address liquidator, uint256 amount);
    event RevertedLiquidation(address asset, address account, address liquidator, uint256 amount);

    function burnAndReleaseCollateral(address asset, address account, uint256 amount) external;

    function finalizeLiquidation(
        address asset,
        address account,
        address liquidator,
        uint256 amount,
        Proof calldata proof
    ) external;

    function initLiquidation(address asset, address account, uint256 amount) external;

    function revertLiquidation(
        address asset,
        address account,
        address liquidator,
        uint256 amount,
        Proof calldata proof
    ) external;

    function verifyProofAndMint(address account, uint256 amount) external;
}
