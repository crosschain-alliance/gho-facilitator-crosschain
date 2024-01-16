pragma solidity ^0.8.20;

interface IGiriGiriBashi {
    function getThresholdHash(uint256 domain, uint256 id) external view returns (bytes32);
}
