// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IProver
 * @author crosschain-alliance
 */
interface IProver {
    error InvalidLatestCommitment(bytes32 latestCommitment, bytes32 expectedLatestCommitment);
    error InvalidBlockHeader(bytes32 blockHeaderHash, bytes32 expectedBlockHeaderHash);
    error InvalidAccountStorageRoot();
    error InvalidNonce(uint256 nonce, uint256 expectedNonce);
    error InvalidAccountRlp(bytes accountRlp);

    struct Proof {
        uint256 blockNumber;
        uint256 nonce;
        bytes blockHeader;
        bytes accountProof;
        bytes storageProof;
    }

    function setAccount(address account) external;
}
