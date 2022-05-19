const { web3tx, toWad, wad4human } = require("@decentral.ee/web3-helpers");

require("dotenv").config();
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
  
    const fundingTarget = ethers.BigNumber.from("10000000000000000"); // 0.01 eth

    const bondContract = await Bond.deploy(
    "0xF0d7d1D47109bA426B9D8A3Cde1941327af1eea3", //host contract address
    "0xECa8056809e7e8db04A8fF6e4E82cD889a46FE2F", //cfa contract address
    "0xDD5462a7dB7856C9128Bc77Bd65c2919Ee23C6E1", //accpeted token, Kovan Ethx super token
    fundingTarget,                          // funding target in wei 
    1000,                                         // interest rate in basis points
    365);                                         // loan term, days

  
    await bondContract.deployed();
    console.log("Super Bond deployed to:", bondContract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


