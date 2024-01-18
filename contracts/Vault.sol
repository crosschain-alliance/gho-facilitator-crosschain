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
    uint256 public constant LIQUIDATION_BONUS = 500; // 5%
    uint256 public constant ORACLE_PRICE_DIVISOR = 1e8;
    uint256 public constant PERCENTAGE_DIVISOR = 10000;

    IPriceOracle public immutable PRICE_ORACLE;
    address public immutable GHO;

    mapping(address => mapping(address => uint256)) private _collaterals;
    mapping(address => mapping(address => uint256)) private _debts;

    constructor(
        address priceOracle,
        address gho,
        address giriGiriBashi,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 commitmentsSlot
    ) Committer(targetChainId) Prover(sourceChainId, commitmentsSlot, giriGiriBashi) {
        PRICE_ORACLE = IPriceOracle(priceOracle);
        GHO = gho;
    }

    /// @inheritdoc IVault
    function getAssetAccountData(address asset, address account) public view returns (bool, uint256, uint256) {
        uint256 priceCollateralUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        uint256 debt = _debts[asset][account];
        uint256 debtUsd = (debt * priceGhoUsd) / ORACLE_PRICE_DIVISOR;
        uint256 collateral = _collaterals[asset][account];
        uint256 collateralUsd = (_collaterals[asset][account] * priceCollateralUsd) / ORACLE_PRICE_DIVISOR;
        bool canBeLiquidated = debtUsd > (collateralUsd * LTV) / PERCENTAGE_DIVISOR;
        return (canBeLiquidated, debt, collateral);
    }

    // @inheritdoc IVault
    function mint(address asset, address account, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        _collaterals[asset][account] += amount;

        // TODO: handle different number of decimals

        uint256 collateralPriceUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        amount = (amount * collateralPriceUsd) / priceGhoUsd;

        uint256 amountToMint = (amount * LTV) / PERCENTAGE_DIVISOR;
        _debts[asset][account] += amountToMint;

        _generateCommitment(abi.encode(MINT, account, amountToMint));
        emit AuthorizedMint(account, amountToMint);
    }

    // @inheritdoc IVault
    function withdrawLeftCollateral(address asset, address account) external {
        if (_debts[asset][account] != 0) revert ImpossibleToWithdrawCollateralLeft();
        _collaterals[asset][account] = 0;
        IERC20(asset).transfer(account, _collaterals[asset][account]);
    }

    // @inheritdoc IVault
    function verifyBurnAndReleaseCollateral(
        address asset,
        address account,
        uint256 amount /*,
        Proof calldata proof*/
    ) external {
        //_verifyProof(proof, abi.encode(BURN, asset, account, amount));

        // TODO: avoid to revert if the tx fails in order to don't have nonce issues
        if (amount > _debts[asset][account]) revert InvalidAmount(amount, _debts[asset][account]);

        uint256 priceCollateralUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        uint256 collateralRequested = (amount * priceGhoUsd) / priceCollateralUsd;

        _debts[asset][account] -= amount;
        _collaterals[asset][account] -= collateralRequested;

        IERC20(asset).transfer(account, collateralRequested);
        emit CollateralReleased(account, amount);
    }

    // @inheritdoc IVault
    function verifiyInitLiquidationAndLiquidate(
        address asset,
        address account,
        address liquidator,
        uint256 amount /*,
        Proof calldata proof*/
    ) external {
        //_verifyProof(proof, abi.encode(INIT_LIQUIDATION, asset, account, liquidator, amount));
        (bool canBeLiquidated, , ) = getAssetAccountData(asset, account);
        if (!canBeLiquidated) {
            _generateCommitment(abi.encode(REVERT_LIQUIDATION, asset, account, liquidator, amount));
            return;
        }

        // TODO: handle different number of decimals

        uint256 priceCollateralUsd = PRICE_ORACLE.getAssetPrice(address(asset));
        uint256 priceGhoUsd = PRICE_ORACLE.getAssetPrice(GHO);
        uint256 baseCollateral = (amount * priceGhoUsd) / priceCollateralUsd;

        uint256 accountCollateral = _collaterals[asset][account];
        uint256 collateralToLiquidate = 0;

        uint256 maxCollateralToLiquidate = baseCollateral + ((baseCollateral * LIQUIDATION_BONUS) / PERCENTAGE_DIVISOR);
        if (maxCollateralToLiquidate > accountCollateral) {
            collateralToLiquidate = accountCollateral;
            _debts[asset][account] = 0;
        } else {
            collateralToLiquidate = maxCollateralToLiquidate;
            _debts[asset][account] -= amount;
        }

        _collaterals[asset][account] -= collateralToLiquidate;
        IERC20(asset).transfer(liquidator, collateralToLiquidate);

        _generateCommitment(abi.encode(FINALIZE_LIQUIDATION, asset, account, liquidator, amount));
        emit Liquidated(asset, account, liquidator, collateralToLiquidate);
    }
}
