const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require("fs");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(FlightSuretyData);
  const data_contract = await FlightSuretyData.deployed();
  await deployer.deploy(FlightSuretyApp, data_contract.address);
  const app_contract = await FlightSuretyApp.deployed();
  let url = "http://localhost:7545";
  let config = {
    localhost: {
      url: url,
      dataAddress: data_contract.address,
      appAddress: app_contract.address,
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
};

// module.exports = function (deployer) {
//   let firstAirline = "0x8FE5849BE0fd6d877D60dA6aAa535fCC685884c2";
//   deployer.deploy(FlightSuretyData).then((c) => {
//     return deployer.deploy(FlightSuretyApp).then(() => {
//       let config = {
//         localhost: {
//           url: "http://localhost:8545",
//           dataAddress: FlightSuretyData.address,
//           appAddress: FlightSuretyApp.address,
//         },
//       };
//       fs.writeFileSync(
//         __dirname + "/../src/dapp/config.json",
//         JSON.stringify(config, null, "\t"),
//         "utf-8"
//       );
//       fs.writeFileSync(
//         __dirname + "/../src/server/config.json",
//         JSON.stringify(config, null, "\t"),
//         "utf-8"
//       );
//     });
//   });
// };
