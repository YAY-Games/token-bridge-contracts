// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IProxyInitialize.sol";
import "./interfaces/IERC20Mintable.sol";
import "./erc20/ERC20UpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

// solhint-disable avoid-tx-origin, no-empty-blocks, no-inline-assembly

contract AVAXSwapAgentImpl is Context, Initializable {

    using SafeERC20 for IERC20;

    mapping(address => address) public swapMappingBSC2AVAX;
    mapping(address => address) public swapMappingAVAX2BSC;
    mapping(bytes32 => bool) public filledBSCTx;

    address payable public owner;
    address public avaxTokenProxyAdmin;
    address public avaxTokenImplementation;
    uint256 public swapFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapPairCreated(bytes32 indexed bscRegisterTxHash, address indexed avaxTokenAddr, address indexed bscTokenAddr, string symbol, string name, uint8 decimals);
    event SwapStarted(address indexed avaxTokenAddr, address indexed bscTokenAddr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event SwapFilled(address indexed avaxTokenAddr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 amount);

    constructor() public {}

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
       _;
    }

    function initialize(address avaxTokenImpl, uint256 fee, address payable ownerAddr, address avaxTokenProxyAdminAddr) public initializer {
        avaxTokenImplementation = avaxTokenImpl;
        swapFee = fee;
        owner = ownerAddr;
        avaxTokenProxyAdmin = avaxTokenProxyAdminAddr;
    }

    function isContract(address addr) internal view returns (bool) {
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

    function createSwapPair(bytes32 bscTxHash, address bscTokenAddr, string calldata name, string calldata symbol, uint8 decimals) external onlyOwner returns(address) {
        require(swapMappingBSC2AVAX[bscTokenAddr] == address(0), "AVAXSwapAgentImpl: duplicated swap pair");

        ERC20UpgradeableProxy proxyToken = new ERC20UpgradeableProxy(avaxTokenImplementation, avaxTokenProxyAdmin, "");
        IProxyInitialize token = IProxyInitialize(address(proxyToken));
        token.initialize(name, symbol, decimals, 0, true, address(this));

        swapMappingBSC2AVAX[bscTokenAddr] = address(token);
        swapMappingAVAX2BSC[address(token)] = bscTokenAddr;

        emit SwapPairCreated(bscTxHash, address(token), bscTokenAddr, symbol, name, decimals);
        return address(token);
    }

    function fillBSC2AVAXSwap(bytes32 bscTxHash, address bscTokenAddr, address toAddress, uint256 amount) external onlyOwner returns (bool) {
        require(!filledBSCTx[bscTxHash], "AVAXSwapAgentImpl: bsc tx filled already");
        address avaxTokenAddr = swapMappingBSC2AVAX[bscTokenAddr];
        require(avaxTokenAddr != address(0), "AVAXSwapAgentImpl: no swap pair for this token");
        filledBSCTx[bscTxHash] = true;
        IERC20Mintable(avaxTokenAddr).mintTo(amount, toAddress);
        emit SwapFilled(avaxTokenAddr, bscTxHash, toAddress, amount);

        return true;
    }

    function swapAVAX2BSC(address avaxTokenAddr, uint256 amount) external payable notContract returns (bool) {
        address bscTokenAddr = swapMappingAVAX2BSC[avaxTokenAddr];
        require(bscTokenAddr != address(0), "AVAXSwapAgentImpl: no swap pair for this token");
        require(msg.value == swapFee, "AVAXSwapAgentImpl: swap fee not equal");

        IERC20(avaxTokenAddr).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Mintable(avaxTokenAddr).burn(amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit SwapStarted(avaxTokenAddr, bscTokenAddr, msg.sender, amount, msg.value);
        return true;
    }
}