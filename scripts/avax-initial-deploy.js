const AVAXSwapAgentImpl = artifacts.require("AVAXSwapAgentImpl");
const AVAXSwapAgentUpgradeableProxy = artifacts.require("AVAXSwapAgentUpgradeableProxy");
const ERC20TokenImplementation = artifacts.require("ERC20TokenImplementation");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
const DUMMY_ADDRESS = "0x0000000000000000000000000000000000000001"

async function main() {
  const avaxBridgeFee = process.env["AVAX_BRIDGE_FEE"];
  const avaxBridgeOwner = process.env["AVAX_BRIDGE_OWNER"];
  const avaxTokenProxyAdmin = process.env["AVAX_TOKEN_PROXY_ADMIN"];
  const avaxBridgeProxyAdmin = process.env["AVAX_BRIDGE_PROXY_ADMIN"];

  const tokenImpl = await ERC20TokenImplementation.new();
  ERC20TokenImplementation.setAsDeployed(tokenImpl);
  const tokenImplInitTx = await tokenImpl.initialize("ERC20 Implementation", "", 0, 0, false, DUMMY_ADDRESS);

  const bridgeImpl = await AVAXSwapAgentImpl.new();
  AVAXSwapAgentImpl.setAsDeployed(bridgeImpl);
  const bridgeImplInitTx = await bridgeImpl.initialize(ZERO_ADDRESS, 0, ZERO_ADDRESS, ZERO_ADDRESS);

  const selector = web3.eth.abi.encodeFunctionSignature("initialize(address,uint256,address,address)");
  const data = selector + (web3.eth.abi.encodeParameters(
    ['address','uint256','address','address'],
    [tokenImpl.address, avaxBridgeFee, avaxBridgeOwner, avaxTokenProxyAdmin]
  )).substr(2);

  const proxy = await AVAXSwapAgentUpgradeableProxy.new(
    bridgeImpl.address,
    avaxBridgeProxyAdmin,
    data
  );
  AVAXSwapAgentUpgradeableProxy.setAsDeployed(proxy);

  console.log("token implementation deployed: ", tokenImpl.address);
  console.log("token implementation inited: ", tokenImplInitTx.tx);
  console.log("bridge implementation deployed: ", bridgeImpl.address);
  console.log("bridge implementation inited: ", bridgeImplInitTx.tx);
  console.log("proxy deployed: ", proxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });