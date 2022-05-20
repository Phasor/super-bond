const { web3tx, toWad, wad4human } = require("@decentral.ee/web3-helpers");
require("dotenv").config();
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

  // We get the contract to deploy
    const Bond = await hre.ethers.getContractFactory("Bond");
    const fundingTarget = ethers.BigNumber.from("10000000000000000"); // 0.01 eth

    const bondContract = await Bond.deploy(
    "0xF0d7d1D47109bA426B9D8A3Cde1941327af1eea3", //host contract address
    "0xECa8056809e7e8db04A8fF6e4E82cD889a46FE2F", //cfa contract address
    "0x2eb320e2100a043401e3b3b132d4134f235a6a04", //accpeted token, Kovan USDC super token, fUSDC
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


