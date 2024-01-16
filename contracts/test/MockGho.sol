pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockGho is ERC20 {
    constructor() ERC20("Gho Token", "GHO") {}

    function mint(address to, uint256 account) external {
        _mint(to, account);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
