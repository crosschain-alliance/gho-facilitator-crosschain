import { task, types } from "hardhat/config"
import { utils } from "ethers"

import { verify } from "./verify"

// NOTE: just for testing purposes
task("PriceOracle:deploy", "deploy PriceOracle")
  .addFlag("verify", "whether to verify the contract on Etherscan")
  .setAction(async (_taskArgs, hre) => {
    const PriceOracle = await hre.ethers.getContractFactory("PriceOracle")
    const priceOracle = await PriceOracle.deploy()
    console.log("PriceOracle deployed at: ", priceOracle.address)
    if (_taskArgs.verify) await verify(hre, priceOracle, [])
  })

// NOTE: just for testing purposes
task("Token:deploy", "deploy Token")
  .addParam("name", "Token name", undefined, types.string)
  .addParam("symbol", "Token symbol", undefined, types.string)
  .addParam("totalSupply", "Token total supply", undefined, types.string)
  .addFlag("verify", "whether to verify the contract on Etherscan")
  .setAction(async (_taskArgs, hre) => {
    const Token = await hre.ethers.getContractFactory("Token")
    const constructorArguments = [_taskArgs.name, _taskArgs.symbol, utils.parseUnits(_taskArgs.totalSupply)] as const
    const token = await Token.deploy(...constructorArguments)
    console.log("Token deployed at: ", token.address)
    if (_taskArgs.verify) await verify(hre, token, constructorArguments)
  })

// NOTE: just for testing purposes
task("GHO:deploy", "deploy GHO")
  .addFlag("verify", "whether to verify the contract on Etherscan")
  .setAction(async (_taskArgs, hre) => {
    const GHO = await hre.ethers.getContractFactory("MockGho")
    const gho = await GHO.deploy()
    console.log("GHO deployed at: ", gho.address)
    if (_taskArgs.verify) await verify(hre, gho, [])
  })

task("Vault:deploy", "deploy Vault")
  .addParam("priceOracle", "Oracle prices contract", undefined, types.string)
  .addParam("gho", "Native gho address", undefined, types.string)
  .addParam("giriGiriBashi", "GiriGiriBashi contract", undefined, types.string)
  .addParam("targetChainId", "Target chain id", undefined, types.int)
  .addParam("commitmentsSlot", "Commitment slot", undefined, types.int)
  .addFlag("verify", "whether to verify the contract on Etherscan")
  .setAction(async (_taskArgs, hre) => {
    const Vault = await hre.ethers.getContractFactory("Vault")
    const constructorArguments = [
      _taskArgs.priceOracle,
      _taskArgs.gho,
      _taskArgs.giriGiriBashi,
      _taskArgs.targetChainId,
      _taskArgs.commitmentsSlot,
    ] as const
    const vault = await Vault.deploy(...constructorArguments)
    console.log("Vault deployed at: ", vault.address)
    if (_taskArgs.verify) await verify(hre, vault, constructorArguments)
  })

task("Facilitator:deploy", "deploy Facilitator")
  .addParam("gho", "Native gho address", undefined, types.string)
  .addParam("giriGiriBashi", "GiriGiriBashi contract", undefined, types.string)
  .addParam("targetChainId", "Target chain id", undefined, types.int)
  .addParam("commitmentsSlot", "Commitment slot", undefined, types.int)
  .addFlag("verify", "whether to verify the contract on Etherscan")
  .setAction(async (_taskArgs, hre) => {
    const Facilitator = await hre.ethers.getContractFactory("Facilitator")
    const constructorArguments = [
      _taskArgs.gho,
      _taskArgs.giriGiriBashi,
      _taskArgs.targetChainId,
      _taskArgs.commitmentsSlot,
    ] as const
    const facilitator = await Facilitator.deploy(...constructorArguments)
    console.log("Facilitator deployed at: ", facilitator.address)
    if (_taskArgs.verify) await verify(hre, facilitator, constructorArguments)
  })
