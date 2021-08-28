// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IERC20Query.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// solhint-disable avoid-tx-origin, no-empty-blocks, no-inline-assembly

contract BSCSwapAgentImpl is Context, Initializable {

    using SafeERC20 for IERC20;

    mapping(address => bool) public registeredERC20;
    mapping(bytes32 => bool) public filledAVAXTx;
    address payable public owner;
    uint256 public swapFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapPairRegister(address indexed sponsor,address indexed erc20Addr, string name, string symbol, uint8 decimals);
    event SwapStarted(address indexed erc20Addr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event SwapFilled(address indexed erc20Addr, bytes32 indexed avaxTxHash, address indexed toAddress, uint256 amount);

    constructor() public {}

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function initialize(uint256 fee, address payable ownerAddr) public initializer {
        swapFee = fee;
        owner = ownerAddr;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
       _;
    }

    function isContract(address addr) internal view returns(bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    function registerSwapPairToAVAX(address erc20Addr) external onlyOwner returns(bool) {
        require(!registeredERC20[erc20Addr], "AVAXSwapAgentImpl: already registered");

        string memory name = IERC20Query(erc20Addr).name();
        string memory symbol = IERC20Query(erc20Addr).symbol();
        uint8 decimals = IERC20Query(erc20Addr).decimals();

        require(bytes(name).length > 0, "AVAXSwapAgentImpl: empty name");
        require(bytes(symbol).length > 0, "AVAXSwapAgentImpl: empty symbol");

        registeredERC20[erc20Addr] = true;

        emit SwapPairRegister(msg.sender, erc20Addr, name, symbol, decimals);
        return true;
    }

    function fillAVAX2BSCSwap(bytes32 avaxTxHash, address erc20Addr, address toAddress, uint256 amount) external onlyOwner returns(bool) {
        require(!filledAVAXTx[avaxTxHash], "BSCSwapAgentImpl: bsc tx filled already");
        require(registeredERC20[erc20Addr], "BSCSwapAgentImpl: not registered token");

        filledAVAXTx[avaxTxHash] = true;
        IERC20(erc20Addr).safeTransfer(toAddress, amount);

        emit SwapFilled(erc20Addr, avaxTxHash, toAddress, amount);
        return true;
    }

    function swapBSC2AVAX(address erc20Addr, uint256 amount) external payable notContract returns(bool) {
        require(registeredERC20[erc20Addr], "BSCSwapAgentImpl: not registered token");
        require(msg.value == swapFee, "BSCSwapAgentImpl: swap fee not equal");

        IERC20(erc20Addr).safeTransferFrom(msg.sender, address(this), amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit SwapStarted(erc20Addr, msg.sender, amount, msg.value);
        return true;
    }
}