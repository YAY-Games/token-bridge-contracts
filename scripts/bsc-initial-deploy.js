const BSCSwapAgentImpl = artifacts.require("BSCSwapAgentImpl");
const BSCSwapAgentUpgradeableProxy = artifacts.require("BSCSwapAgentUpgradeableProxy");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

async function main() {
  const bscBridgeFee = process.env["BSC_BRIDGE_FEE"];
  const bscBridgeOwner = process.env["BSC_BRIDGE_OWNER"];
  const bscBridgeProxyAdmin = process.env["BSC_BRIDGE_PROXY_ADMIN"];

  const impl = await BSCSwapAgentImpl.new();
  BSCSwapAgentImpl.setAsDeployed(impl);
  const tx = await impl.initialize(0, ZERO_ADDRESS);

  const selector = web3.eth.abi.encodeFunctionSignature("initialize(uint256,address)");
  const data = selector + (web3.eth.abi.encodeParameters(['uint256','address'], [bscBridgeFee, bscBridgeOwner])).substr(2);

  const proxy = await BSCSwapAgentUpgradeableProxy.new(
    impl.address,
    bscBridgeProxyAdmin,
    data
  );
  BSCSwapAgentUpgradeableProxy.setAsDeployed(proxy);

  console.log("implementation deployed: ", impl.address);
  console.log("implementation inited: ", tx.tx);
  console.log("proxy deployed: ", proxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });