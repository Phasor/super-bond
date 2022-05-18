/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.0",
  networks: {
            kovan: {
                  url: `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
                  accounts: [process.env.PRIVATE_KEY]
                  }
  }
};
