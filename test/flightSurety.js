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
  const airline7 = accounts[7];

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
    await config.flightSuretyApp.registerAirline(airline2, {
      from: config.owner,
    });

    const isRegistered1 =
      await config.flightSuretyApp.getAirlineRegistrationStatus(airline2);

    assert.equal(isRegistered1, true, "An airline should be registered");
  });

  it(`Airline that has not been funded should not have operational status`, async function () {
    await config.flightSuretyApp.registerAirline(airline3, {
      from: config.owner,
    });

    const isOperational =
      await config.flightSuretyApp.getAirlineOperationalStatus(airline3);

    assert.equal(
      isOperational,
      false,
      "An airline should not be oppearational if has not been funded"
    );
  });

  it(`An airline should be operational if has been funded`, async function () {
    await config.flightSuretyApp.registerAirline(airline4, {
      from: config.owner,
    });

    await config.flightSuretyApp.fund({ from: airline4, value: payment });

    const funding = await config.flightSuretyApp.getFunding(airline4);

    const isOperational =
      await config.flightSuretyApp.getAirlineOperationalStatus(airline4);

    assert.equal(
      funding.toString(),
      10000000000000000000,
      "Value should be 10 ethers"
    );

    assert.equal(
      isOperational,
      true,
      "An airline that has been funded should be operational"
    );
  });

  it(`An opeational airline can register a flight`, async function () {
    await config.flightSuretyApp.registerAirline(airline5, {
      from: config.owner,
    });

    await config.flightSuretyApp.fund({ from: airline5, value: payment });

    await config.flightSuretyApp.registerFlight(flightNumber, timestamps, {
      from: airline5,
    });

    const flightStatus = await config.flightSuretyApp.getFlightStatus(
      airline5,
      flightNumber,
      timestamps
    );

    assert.equal(
      flightStatus,
      true,
      "An airline that has been funded should be able to register a flight"
    );
  });

  it(`An already registered airline can vote a new entering airline`, async function () {
    await config.flightSuretyApp.registerAirline(airline6, {
      from: config.owner,
    });

    await config.flightSuretyApp.voteAirline(airline6, true, {
      from: airline4,
    });

    const votesQty = await config.flightSuretyApp.getVotesQty(airline6);

    assert.equal(
      votesQty,
      1,
      "Airline should have one vote after another one has voted"
    );
  });

  it(`An airline should be registered after getting the right amount of votes`, async function () {
    await config.flightSuretyApp.voteAirline(airline6, true, {
      from: airline2,
    });

    await config.flightSuretyApp.voteAirline(airline6, true, {
      from: airline3,
    });

    const isRegistered =
      await config.flightSuretyApp.getAirlineRegistrationStatus(airline6);

    assert.equal(isRegistered, true, "An airline should be registered");
  });

  it(`An airline can not vote twice the same airline`, async function () {
    await config.flightSuretyApp.registerAirline(airline7, {
      from: config.owner,
    });
    await config.flightSuretyApp.voteAirline(airline7, true, {
      from: airline2,
    });
    try {
      await config.flightSuretyApp.voteAirline(airline7, true, {
        from: airline2,
      });
    } catch (error) {
      const err = error.data.stack
        .toString()
        .match("Requester has already voted");

      assert.equal(
        err[0],
        "Requester has already voted",
        "An airline can not vote twice the same airline"
      );
    }
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
