pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IPriceOracle } from "@aave/core-v3/contracts/interfaces/IPriceOracle.sol";
import { IVault } from "./interfaces/IVault.sol";
import { Committer } from "./Committer.sol";
import { Prover } from "./Prover.sol";

contract Vault is IVault, Committer, Prover {
    bytes32 public constant MINT = keccak256("MINT");
    bytes32 public constant BURN = keccak256("BURN");
    bytes32 public constant INIT_LIQUIDATION = keccak256("INIT_LIQUIDATION");
    bytes32 public constant FINALIZE_LIQUIDATION = keccak256("FINALIZE_LIQUIDATION");
    bytes32 public constant REVERT_LIQUIDATION = keccak256("REVERT_LIQUIDATION");

    uint256 public constant LTV = 8500; // 85%;
    uint256 private constant ORACLE_PRICE_DIVISOR = 10 ** 8;
    uint256 private constant LTV_DIVISOR = 10000;

    IPriceOracle public immutable PRICE_ORACLE;
    address public immutable GHO;

    mapping(address => mapping(address => uint256)) private _collaterals;
    mapping(address => mapping(address => uint256)) private _debts;

    constructor(
        address oracle,
        address gho,
        uint256 targetChainId,
        uint256 sourceChainId,
        uint256 commitmentsSlot,
        address giriGiriBashi
    ) Committer(targetChainId) Prover(sourceChainId, commitmentsSlot, giriGiriBashi) {
        PRICE_ORACLE = IPriceOracle(oracle);
        GHO = gho;
    }

    function canBeLiquidated(address asset, address account) public view returns (bool) {
        uint256 priceCollateralUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        uint256 debtUsd = (_debts[asset][account] * priceGhoUsd) / ORACLE_PRICE_DIVISOR;
        uint256 collateralUsd = (_collaterals[asset][account] * priceCollateralUsd) / ORACLE_PRICE_DIVISOR;
        return debtUsd > (collateralUsd * LTV) / LTV_DIVISOR;
    }

    function mint(address asset, address account, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        _collaterals[asset][account] += amount;

        uint256 assetPriceUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        uint256 amountInUsd = (assetPriceUsd * amount) / ORACLE_PRICE_DIVISOR;
        amount = (amountInUsd * ORACLE_PRICE_DIVISOR) / priceGhoUsd;

        uint256 amountToMint = (amount * LTV) / LTV_DIVISOR;
        _debts[asset][account] += amountToMint;

        _generateCommitment(abi.encode(MINT, account, amountToMint));
        emit AuthorizedMint(account, amountToMint);
    }

    function liquidate(
        address asset,
        address account,
        address liquidator,
        uint256 amount,
        Proof calldata proof
    ) external {
        _verifyProof(proof, abi.encode(INIT_LIQUIDATION, asset, account, liquidator, amount));
        if (!canBeLiquidated(asset, account)) {
            _generateCommitment(abi.encode(REVERT_LIQUIDATION, asset, account, liquidator, amount));
            return;
        }

        // TODO: liquidation

        _generateCommitment(abi.encode(FINALIZE_LIQUIDATION, asset, account, liquidator, amount));
        emit Liquidated(asset, account, liquidator, amount);
    }

    function withdrawLeftCollateral(address asset, address account) external {
        if (_debts[asset][account] != 0) revert ImpossibleToWithdrawCollateralLeft();
        _collaterals[asset][account] = 0;
        IERC20(asset).transfer(account, _collaterals[asset][account]);
    }

    function verifyBurnAndReleaseCollateral(
        address asset,
        address account,
        uint256 amount,
        Proof calldata proof
    ) external {
        _verifyProof(proof, abi.encode(BURN, asset, account, amount));

        // TODO: avoid to revert if the tx fails in order to don't have nonce issues
        if (amount > _debts[asset][account]) revert InvalidAmount(amount, _debts[asset][account]);

        uint256 priceCollateralUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        uint256 amountUsd = (amount * priceGhoUsd) / ORACLE_PRICE_DIVISOR;
        uint256 collateralRequested = (amountUsd * ORACLE_PRICE_DIVISOR) / priceCollateralUsd;

        _debts[asset][account] -= amount;
        _collaterals[asset][account] -= collateralRequested;
        //if debtsLeftUsd < ltv * collateralUsd -> possible liquidation

        IERC20(asset).transfer(account, collateralRequested);
        emit CollateralReleased(account, amount);
    }
}
