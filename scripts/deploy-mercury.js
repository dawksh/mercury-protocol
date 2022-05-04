const hre = require("hardhat");

async function main() {

  const Mercury = await hre.ethers.getContractFactory("Mercury");
  const mercury = await Mercury.deploy(...args);

  await mercury.deployed();

  console.log("Mercury deployed to:", mercury.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
