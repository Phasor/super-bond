
const fundingTarget = ethers.BigNumber.from("10000000000000000"); // 0.01 eth

module.exports = [
    "0xF0d7d1D47109bA426B9D8A3Cde1941327af1eea3", //host contract address
    "0xECa8056809e7e8db04A8fF6e4E82cD889a46FE2F", //cfa contract address
    "0xDD5462a7dB7856C9128Bc77Bd65c2919Ee23C6E1", //accpeted token, Kovan Ethx super token
    fundingTarget,                          // funding target in wei 
    1000,                                         // interest rate in basis points
    365
  ];