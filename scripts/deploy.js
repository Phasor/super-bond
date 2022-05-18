const { web3tx, toWad, wad4human } = require("@decentral.ee/web3-helpers");
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // We get the contract to deploy
  const Bond = await hre.ethers.getContractFactory("Bond");
  
  // const bondContract = await Bond.deploy(
    // ISuperfluid host,
    // IConstantFlowAgreementV1 cfa,
    // ISuperToken acceptedToken,
    // int96 fundingTarget, //in wei
    // int96 fundingRate, //basis points
    // int96 loanTerm //length of loan, days
  // );
  
  const bondContract = await Bond.deploy(
    "0xF0d7d1D47109bA426B9D8A3Cde1941327af1eea3", //host contract address
    "0xECa8056809e7e8db04A8fF6e4E82cD889a46FE2F", //cfa contract address
    "0xDD5462a7dB7856C9128Bc77Bd65c2919Ee23C6E1", //Kovan Ethx super token
    1000000000000000000,                          // funding target in wei 
    1000,                                         // interest rate in basis points
    365);                                         // loan term, days

  
  await bondContract.deployed();

  console.log("Super Bond deployed to:", bondContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// npx hardhat run scripts/deploy.js --network kovan
// fake UWL: 0xbDfb61f061250a1f6A9e184B7B0EE8d7d4f83cfC
// second latest DEPLOYED_CONTRACT_ADDRESS: 0x38E975A42e3DfEEa6cAA9672a6Fbb3C4bdbb97a3 
// latest: 0x603c02f90299A49c009411419c392FE49a6B6096
// npx hardhat verify --network rinkeby --constructor-args arguments.js 0x4358407B34ba88f6cEf4648Ff59690Ba5bE662d3
// npx hardhat verify --network goerli --constructor-args arguments.js 0x60EF4c93CE8c6e0182BC1c83A7CE47053c5af6c6
// https://hardhat.org/tutorial/deploying-to-a-live-network.html

// Testing Steps
