//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IGhoToken } from "./interfaces/gho/IGhoToken.sol";
import { IFacilitator } from "./interfaces/IFacilitator.sol";
import { Prover } from "./Prover.sol";
import { Committer } from "./Committer.sol";

contract Facilitator is IFacilitator, Prover, Committer {
    bytes32 public constant MINT = keccak256("MINT");
    bytes32 public constant BURN = keccak256("BURN");
    bytes32 public constant INIT_LIQUIDATION = keccak256("INIT_LIQUIDATION");
    bytes32 public constant FINALIZE_LIQUIDATION = keccak256("FINALIZE_LIQUIDATION");
    bytes32 public constant REVERT_LIQUIDATION = keccak256("REVERT_LIQUIDATION");

    IGhoToken public immutable GHO;

    constructor(
        address gho,
        address giriGiriBashi,
        uint256 targetChainId,
        uint256 commitmentsSlot
    ) Prover(targetChainId, commitmentsSlot, giriGiriBashi) Committer(targetChainId) {
        GHO = IGhoToken(gho);
    }

    /// @inheritdoc IFacilitator
    function burnAndReleaseCollateral(address asset, address account, uint256 amount) external {
        GHO.transferFrom(msg.sender, address(this), amount);
        GHO.burn(amount);
        _generateCommitment(abi.encode(BURN, asset, account, amount));
        emit AuthorizedBurn(asset, account, amount);
    }

    function distributeFeesToTreasury() external {}

    /// @inheritdoc IFacilitator
    function finalizeLiquidation(
        address asset,
        address account,
        address liquidator,
        uint256 amount /*,
        Proof calldata proof*/
    ) external {
        //_verifyProof(proof, abi.encode(FINALIZE_LIQUIDATION, asset, account, liquidator, amount));
        GHO.burn(amount);
        emit FinalizedLiquidation(asset, account, liquidator, amount);
    }

    function getGhoTreasury() external view returns (address) {}

    /// @inheritdoc IFacilitator
    function initLiquidation(address asset, address account, uint256 amount) external {
        GHO.transferFrom(msg.sender, address(this), amount);
        _generateCommitment(abi.encode(INIT_LIQUIDATION, asset, account, amount));
        emit AuthorizedInitLiquidation(asset, account, msg.sender, amount);
    }

    /// @inheritdoc IFacilitator
    function revertLiquidation(
        address asset,
        address account,
        address liquidator,
        uint256 amount /*,
        Proof calldata proof*/
    ) external {
        ///_verifyProof(proof, abi.encode(REVERT_LIQUIDATION, asset, account, liquidator, amount));
        GHO.transfer(liquidator, amount);
        emit RevertedLiquidation(asset, account, liquidator, amount);
    }

    function updateGhoTreasury(address newGhoTreasury) external {}

    /// @inheritdoc IFacilitator
    function verifyProofAndMint(address account, uint256 amount /*, Proof calldata proof*/) external {
        //_verifyProof(proof, abi.encode(MINT, account, amount));
        GHO.mint(account, amount);
    }
}
