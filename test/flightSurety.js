var Test = require("../config/testConfig.js");
// var BigNumber = require("bignumber.js");
contract("Flight Surety Tests", async (accounts) => {
  const payment = web3.utils.toWei("10", "ether");
  const timestamps = Math.floor(Date.now() / 1000);
  const flightNumber = "FR9876";
  const airline1 = accounts[1];
  const airline2 = accounts[2];
  const airline3 = accounts[3];

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

  it(`Airline can be registered directly if there are less than 5 registered airlines`, async function () {
    await config.flightSuretyApp.registerAirline(airline1, {
      from: config.owner,
    });

    const isRegistered1 =
      await config.flightSuretyApp.getAirlineRegistrationStatus(airline1);

    assert.equal(isRegistered1, true, "An airline should be registered");
  });

  it(`Airline that has not been funded should not have operational status`, async function () {
    await config.flightSuretyApp.registerAirline(airline1, {
      from: config.owner,
    });

    const isOperational =
      await config.flightSuretyApp.getAirlineOperationalStatus(airline1);

    assert.equal(
      isOperational,
      false,
      "An airline should not be oppearational if has not been funded"
    );
  });

  it(`An airline should be operational if has been funded`, async function () {
    await config.flightSuretyApp.fund({ from: airline1, value: payment });

    const isOperational =
      await config.flightSuretyApp.getAirlineOperationalStatus(airline1);

    assert.equal(
      isOperational,
      true,
      "An airline that has been funded should be operational"
    );
  });

  it(`An opeational airline can register a flight`, async function () {
    await config.flightSuretyApp.registerAirline(airline2, {
      from: config.owner,
    });

    await config.flightSuretyApp.fund({ from: airline2, value: payment });

    await config.flightSuretyApp.registerFlight(flightNumber, timestamps, {
      from: airline2,
    });

    const flightStatus = await config.flightSuretyApp.getFlightStatus(
      airline2,
      flightNumber,
      timestamps
    );

    assert.equal(
      flightStatus,
      true,
      "An airline that has been funded should be able to register a flight"
    );
  });

  // it(`test`, async function () {
  //   // Get operating status
  //   assert.equal(1, 1);
  // });

  //   it(`(multiparty) has correct initial isOperational() value`, async function () {
  //     // Get operating status
  //     let status = await config.flightSuretyData.isOperational.call();
  //     assert.equal(status, true, "Incorrect initial operating status value");
  //   });

  //   it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {
  //     // Ensure that access is denied for non-Contract Owner account
  //     let accessDenied = false;
  //     try {
  //       await config.flightSuretyData.setOperatingStatus(false, {
  //         from: config.testAddresses[2],
  //       });
  //     } catch (e) {
  //       accessDenied = true;
  //     }
  //     assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
  //   });

  //   it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {
  //     // Ensure that access is allowed for Contract Owner account
  //     let accessDenied = false;
  //     try {
  //       await config.flightSuretyData.setOperatingStatus(false);
  //     } catch (e) {
  //       accessDenied = true;
  //     }
  //     assert.equal(
  //       accessDenied,
  //       false,
  //       "Access not restricted to Contract Owner"
  //     );
  //   });

  //   it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {
  //     await config.flightSuretyData.setOperatingStatus(false);

  //     let reverted = false;
  //     try {
  //       await config.flightSurety.setTestingMode(true);
  //     } catch (e) {
  //       reverted = true;
  //     }
  //     assert.equal(reverted, true, "Access not blocked for requireIsOperational");

  //     // Set it back for other tests to work
  //     await config.flightSuretyData.setOperatingStatus(true);
  //   });

  //   it("(airline) cannot register an Airline using registerAirline() if it is not funded", async () => {
  //     // ARRANGE
  //     let newAirline = accounts[2];

  //     // ACT
  //     try {
  //       await config.flightSuretyApp.registerAirline(newAirline, {
  //         from: config.firstAirline,
  //       });
  //     } catch (e) {}
  //     let result = await config.flightSuretyData.isAirline.call(newAirline);

  //     // ASSERT
  //     assert.equal(
  //       result,
  //       false,
  //       "Airline should not be able to register another airline if it hasn't provided funding"
  //     );
  //   });
});
