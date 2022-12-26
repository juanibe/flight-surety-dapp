const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require("fs");
console.log(__dirname + "/..");
module.exports = function (deployer) {
  let firstAirline = "0x8FE5849BE0fd6d877D60dA6aAa535fCC685884c2";
  deployer.deploy(FlightSuretyData, firstAirline).then(() => {
    return deployer.deploy(FlightSuretyApp).then(() => {
      let config = {
        localhost: {
          url: "http://localhost:8545",
          dataAddress: FlightSuretyData.address,
          appAddress: FlightSuretyApp.address,
        },
      };
      fs.writeFileSync(
        __dirname + "/../src/dapp/config.json",
        JSON.stringify(config, null, "\t"),
        "utf-8"
      );
      fs.writeFileSync(
        __dirname + "/../src/server/config.json",
        JSON.stringify(config, null, "\t"),
        "utf-8"
      );
    });
  });
};
