// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyApp {
    
    // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    using SafeMath for uint256; 

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // Account used to deploy contract
    address private contractOwner; 

    /* Number of airlines already registered until needed to vote for a new one */
    uint8 threshold = 5;
    
    FlightSuretyData flightSuretyData;

    uint256 public constant RegistrationFee = 10 ether;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");  

        // All modifiers require an "_" which indicates where the function body will be added
        _;
    }

    /**
    * @dev Modifier that requires that what is being paid is enough
    */
    modifier paidEnough(uint256 _value)
    {
        require(msg.value >= _value, 'Payment is insuficient');
        _;
    }

    /**
    * @dev Modifier that validates the payment, returning if there are remaining funds
    */
    modifier checkPayment(uint256 _value, address payable account)
    {
        uint256 spare = msg.value - _value;
        account.transfer(spare);
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract)
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational  
                            () 
                            public 
                            view 
                            returns(bool) 
    {
        return flightSuretyData.isOperational();
    }


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function getAirlineRegistrationStatus
                                        (
                                            address airline
                                        )
                                        public
                                        view
                                        returns(bool)
    {
        return flightSuretyData.getAirlineRegistrationStatus(airline);
    }

    function getAirlineOperationalStatus
                                        (
                                            address airline
                                        )
                                        public
                                        view
                                        returns(bool)
    {
        return flightSuretyData.getAirlineOperationalStatus(airline);
    }
    
    function getRegisteredAirlines
                                    ()
                                    public
                                    view
                                    returns(uint256)
    {
        return flightSuretyData.getRegisteredAirlines();
    }

   /**
    * @dev Get the addresses of all the registered airlines
    *
    */   
    function getRegisteredAirlinesAccounts
                                        ()
                                        public
                                        view
                                        requireIsOperational
    {
        flightSuretyData.getRegisteredAirlinesAccounts();
    }

   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (
                                address airline   
                            )
                            external
                            requireIsOperational
    {
        /* Validations */
        require(airline != address(0), "InvalidAccountAddress");
        // require(flightSuretyData.getAirlineOperationalStatus(msg.sender), "AirlineHasNotBeenFunded");
        require(!flightSuretyData.getAirlineOperationalStatus(msg.sender), "AirlineAddressAlreadyRegistered");

        uint registeredAccounts = flightSuretyData.getRegisteredAirlines();

        if(registeredAccounts < threshold)
        {
            flightSuretyData.registerAirline(airline, false);
        }
        else
        {
            emit VoteRequestEvent(airline);
        }
    }

   /**
    * @dev This method gives a vote to an applicant airline, when the total airlines registered 
    *      are more than 5. 
    */
    function voteAirline
                        ()
                        public
                        requireIsOperational
    {

    }

   /**
    * @dev When writing a smart contract, you need to ensure that money is being sent to the contract and out of the contract as well. Payable does this for you, any function in Solidity with the modifier Payable ensures that the function can send and receive Ether
    *
    */
    function fund
                ()
                public
                payable
                requireIsOperational
                paidEnough(RegistrationFee)
                checkPayment(RegistrationFee, payable(msg.sender))
    {

        /* Validate that the ariline is already registered */
        require(flightSuretyData.getAirlineRegistrationStatus(msg.sender), 'Airline is not registered');

        /* Validate that the airline has not been already paid the funding */
        require(!flightSuretyData.getAirlineOperationalStatus(msg.sender), 'Airline was already funded');

        flightSuretyData.fund{value:RegistrationFee}(msg.sender);
    }      

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    string memory flightNumber,
                                    uint256 timestamp
                                )
                                external
    {
        /* Validate airline operational status */
        require(flightSuretyData.getAirlineOperationalStatus(msg.sender));
        
        /* Validate that the flight has not been already registered */
        require(!flightSuretyData.getFlightStatus(
            msg.sender, flightNumber, timestamp), 
            "This flight has already been registered"
        );

        /* Register the new flight */
        flightSuretyData.registerFlight(msg.sender, flightNumber, timestamp);
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
    }

    // Oracle managment

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify                                                       
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    /* Event triggered when a new airlines registers and needs votation to be authorized to enter */
    event VoteRequestEvent(address airline);

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }
}

/**
    We add a reference to the Data Contract. For this we create an interface.
    We are telling the app contract how to interact with the data contract
 */
abstract contract FlightSuretyData {
    function isOperational() public view virtual returns(bool);

    function registerAirline(address airline, bool fundComplete) external virtual;
    function getAirlineOperationalStatus(address airlineAddress) external view virtual returns(bool);
    function getAirlineRegistrationStatus(address airlineAddress) external view virtual returns(bool);
    function getRegisteredAirlines() external view virtual returns(uint256);
    function getRegisteredAirlinesAccounts() external view virtual returns(address [] memory);
    function fund(address account) external virtual payable;

    function getFlightStatus(address airline, string memory flightNumber, uint256 timestamp) external virtual view returns(bool);
    function registerFlight(address airline, string memory flight, uint256 timestamp) external virtual;
}