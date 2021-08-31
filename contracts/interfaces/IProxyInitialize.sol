// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IProxyInitialize {
    function initialize(string calldata name, string calldata symbol, uint8 decimals, uint256 amount, bool mintable, address owner) external;
}