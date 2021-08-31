// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20Mintable {

    function mintTo(uint256 amount, address recipient) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}
