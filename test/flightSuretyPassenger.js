var Test = require("../config/testConfig.js");
// var BigNumber = require("bignumber.js");
contract("Flight Surety Tests", async (accounts) => {
  const payment = web3.utils.toWei("10", "ether");
  const timestamps = Math.floor(Date.now() / 1000);
  const flightNumber = "FR9876";
  // const airline1 = accounts[1];
  const airline2 = accounts[2];
  const airline3 = accounts[3];
  const airline4 = accounts[4];
  const airline5 = accounts[5];
  const airline6 = accounts[6];
  const passenger1 = accounts[7];

  const paymentHalfEther = web3.utils.toWei("0.5", "ether");

  var config;
  before("setup contract", async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(
      config.flightSuretyApp.address
    );
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`A passenger can buy an insurance for an existing flight`, async function () {
    await config.flightSuretyApp.registerAirline(airline2, {
      from: config.owner,
    });

    await config.flightSuretyApp.fund({ from: airline2, value: payment });

    await config.flightSuretyApp.registerFlight(flightNumber, timestamps, {
      from: airline2,
    });

    await config.flightSuretyApp.purchaseInsurance(
      airline2,
      flightNumber,
      timestamps,
      { from: passenger1, value: paymentHalfEther }
    );

    const flightStatus = await config.flightSuretyApp.getFlightStatus(
      airline2,
      flightNumber,
      timestamps
    );

    assert.equal(flightStatus, true, "Flight status should be true");
  });
});
