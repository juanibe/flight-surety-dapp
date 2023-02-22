// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    address[] multiCalls = new address[](0);

    struct Airline {
        bool registered;
        bool operational;
    }

    struct AirlineRegistrationRequest {
        string name;
        address airlineAddress;
    }

    struct flightInfo{
        bool isRegistered; 
        uint256 totalPremium;
        uint256 statusCode;
    }

    struct InsureeInfo{
        uint256 insuranceAmount;
        uint256 payout;
    }

    struct Voter {
        address[] airlineVoters;
        mapping(address => bool) voteResults;
    }

    mapping(address => uint256) private authorizedCaller;
    
    mapping(address => bytes32 []) flightList; 
    mapping(address => mapping(bytes32 => flightInfo)) flights;
    mapping(address => Airline) airlines;
    mapping(address => uint256) funding;
    mapping(address => Voter) voters;
    mapping(address => mapping(bytes32 => address [])) insureeList;   //store the passenger addresses for each flight
    mapping(address => mapping(bytes32 => mapping(address => InsureeInfo))) insurees;    //For each flight, it keeps track of premium and payout for each insuree
    mapping(address => uint) voteCount;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AuthorizedContract(address authContract);
    event DeAuthorizedContract(address authContract);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (                                    
                                )  
    {
        contractOwner = msg.sender;
        
        airlines[msg.sender] = Airline({
            registered: true,
            operational: false
        }); 

        multiCalls.push(msg.sender);
    }

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
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier isCallerAuthorized()
    {
        require(authorizedCaller[msg.sender] == 1, "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller(address contractAddress) external
        requireContractOwner
    {
        authorizedCaller[contractAddress] = 1;
        emit AuthorizedContract(contractAddress);
    }


    function deauthorizeContract(address contractAddress) external
        requireContractOwner
    {
        delete authorizedCaller[contractAddress];
        emit DeAuthorizedContract(contractAddress);
    } 

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev 
    */
    function getRegisteredAirlines
                                ()
                                external
                                view
                                requireIsOperational
                                isCallerAuthorized
                                returns(uint256)
    {
        return multiCalls.length;
    }

    /**
    * @dev 
    *      
    *
    */
    function getRegisteredAirlinesAccounts
                                        ()
                                        external
                                        view
                                        requireIsOperational
                                        isCallerAuthorized
                                        returns(address[] memory)
    {
        return multiCalls;
    }


    /**
     * @dev Returns if the airline is registered or not by the address
     * @return bool 
     */
    function getAirlineRegistrationStatus
                                         (   
                                            address airlineAddress
                                         )
                                         external
                                         view
                                         requireIsOperational
                                         isCallerAuthorized
                                         returns(bool)
    {
        return airlines[airlineAddress].registered;
    }

    /**
     * @dev Returns if the airline is funded or not by the address
     * @return bool 
     */
     function getAirlineOperationalStatus
                                        (
                                            address airlineAddress
                                        )
                                        external
                                        view
                                        requireIsOperational
                                        isCallerAuthorized
                                        returns(bool)
    {
        return airlines[airlineAddress].operational;
    }

    /**
     * @dev Sets the operational status to the airline, either to true or false
     */
     function setAirlineOperationalStatus
                                        (
                                            address airlineAddress,
                                            bool status
                                        )
                                        private
                                        requireIsOperational
    {
        airlines[airlineAddress].operational = status;
    }

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address airlineAddress,
                                bool fundComplete   
                            )
                            external
    {
        airlines[airlineAddress] = Airline({
            registered: true,
            operational: fundComplete
        });

        multiCalls.push(airlineAddress);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */  
    function fund
                (
                    address account     
                )
                payable
                public
                requireIsOperational
                isCallerAuthorized
    {
        funding[account] = msg.value;
        setAirlineOperationalStatus(account, true);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    */  
    function getFunding
                (
                    address account     
                )
                public
                view
                requireIsOperational
                returns(uint256)
    {
        uint256 funds = funding[account];
        return funds;
    }

   /**
    * @dev Add a flight to the airline
    *      
    *
    */
    function registerFlight
                            (
                                address airlineAddress,
                                string memory flight,
                                uint256 timestamp
                            )
                            requireIsOperational
                            isCallerAuthorized
                            external
    {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        flightList[airlineAddress].push(key);
        flights[airlineAddress][key].isRegistered = true;
        flights[airlineAddress][key].totalPremium = 0;
        flights[airlineAddress][key].statusCode = 0;
    }

   /**
    * @dev Gets the state of a filight, either if it is 
    *      registered or not.
    *        
    *    
    */
    function getFlightStatus
                            (
                                address airline,
                                string memory flightNumber,
                                uint256 timestamp
                            )
                            external
                            view
                            requireIsOperational
                            isCallerAuthorized
                            returns(bool)
    {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, timestamp));
        bool result = flights[airline][key].isRegistered;
        return result;
    }

   /**
    * @dev 
    *        
    *    
    */
    function setFlightStatusCode
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint256 code
                                )
                                external
                                requireIsOperational
                                isCallerAuthorized
    {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        flights[airline][key].statusCode = code;
    }


   /**
    * @dev 
    *        
    *    
    */
    function getFlightStatusCode
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp
                                )
                                external
                                view
                                requireIsOperational
                                isCallerAuthorized
                                returns(uint256)
    {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        uint statusCode = flights[airline][key].statusCode;
        return statusCode;
    }

                            


   /**
    * @dev Buy insurance for a flight
    *      Increment premiums: Premiums are the amount you pay for your insurance every month
    *
    */   
    function buy
                            (
                                address airline,
                                string memory flight,
                                address insuree,
                                uint256 amount,
                                uint256 timestamp                             
                            )
                            external
                            payable
                            requireIsOperational
                            isCallerAuthorized
    {
        // Increment the total premium collected for a flight
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        flights[airline][key].totalPremium = flights[airline][key].totalPremium.add(amount);

        // Add the new insuree to the insuree list 
        insureeList[airline][key].push(insuree);
        
        insurees[airline][key][insuree] = InsureeInfo({ insuranceAmount: amount, payout: 0 }); 
    }

   /**
    * @dev 
    *      
    *
    */   
    function getFlightPremium
                            (
                                address airline,
                                string memory flight,
                                uint256 timestamp
                            )
                            external
                            view
                            requireIsOperational
                            isCallerAuthorized
                            returns(uint256)
    {
        bytes32 key = keccak256(abi.encodePacked(flight, timestamp));
        return flights[airline][key].totalPremium;
    }

    /**
     *  @dev Amount of voters
    */
    function getVoter
                    (
                        address account
                    )
                    external
                    view
                    requireIsOperational
                    isCallerAuthorized
                    returns(address[] memory)
    {
        return voters[account].airlineVoters;
    }

//   struct Voter {
//         address[] airlineVoters;
//         mapping(address => bool) voteResults;
//     }
//     mapping(address => Voter) voters;

    /**
     *  @dev Amount of voters
    */    
    function getVotersLength
                            (
                                address account
                            )
                            external
                            view
                            requireIsOperational
                            isCallerAuthorized
                            returns(uint256)
    {
        return voters[account].airlineVoters.length;
    }

    /**
     *  @dev Amount of votes that an airline has
    */    
    function getVotesQty
                            (
                                address account
                            )
                            external
                            view
                            requireIsOperational
                            isCallerAuthorized
                            returns(uint)
    {
        return voteCount[account];
    }

    /**
    *  @dev Adds information of the vote, like the voter, 
    *       the result and the airline being voted 
    */
    function addVoteInformation
                                (
                                    address enteringAirline,
                                    address registeredAirline,
                                    bool vote
                                )
                            external
                            requireIsOperational
                            isCallerAuthorized
    {
        voters[enteringAirline].airlineVoters.push(registeredAirline);
        voters[enteringAirline].voteResults[registeredAirline] = vote;
    }

    /**
     *  @dev Adds a new vote to the airline
    */
    function addVoteToAirline
                            (
                                address enteringAirline,
                                uint newVote
                            )
                            external
                            requireIsOperational
                            isCallerAuthorized
    {
        voteCount[enteringAirline] = voteCount[enteringAirline].add(newVote);
    }

    /**
     *  @dev Deletes the vote counter
    */
    function deleteVoteCounter
                            (
                                address airline
                            )
                            external
                            requireIsOperational
                            isCallerAuthorized
    {
        delete voteCount[airline];
    }


    /**
     *  @dev Credits payouts to insurees
    */
    // function creditInsurees
    //                             (
    //                             )
    //                             external
    //                             pure
    // {
    // }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    // function pay
    //                         (
    //                         )
    //                         external
    //                         pure
    // {
    // }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    // function fund
    //                         (   
    //                         )
    //                         public
    //                         payable
    // {
    // }

    // function getFlightKey
    //                     (
    //                         address airline,
    //                         string memory flight,
    //                         uint256 timestamp
    //                     )
    //                     pure
    //                     internal
    //                     returns(bytes32) 
    // {
    //     return keccak256(abi.encodePacked(airline, flight, timestamp));
    // }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() 
                            external 
                            payable 
    {
        fund(msg.sender);
    }
}