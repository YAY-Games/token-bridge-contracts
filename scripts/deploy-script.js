const _ = artifacts.require("_");

async function main() {
  const token = await BEP20YAY.new();
  _.setAsDeployed(_);

  console.log("contract deployed: ", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });