//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Committer {
    uint256 public immutable TARGET_CHAIN_ID;

    mapping(address => bytes32) public latestCommitments;
    uint256 public nonce;

    constructor(uint256 targetChainId) {
        TARGET_CHAIN_ID = targetChainId;
    }

    function _generateCommitment(bytes memory data) internal {
        uint256 currentNonce = nonce;
        bytes32 commitment = keccak256(abi.encode(TARGET_CHAIN_ID, data, currentNonce));
        latestCommitments[msg.sender] = commitment;
        unchecked {
            ++nonce;
        }
    }
}
