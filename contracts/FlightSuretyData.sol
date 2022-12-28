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
        bool isRegistered;
        bool isOperational;
    }

    struct AirlineRegistrationRequest {
        string name;
        address airlineAddress;
    }

    mapping(address => uint256) private authorizedCaller;

    mapping(address => Airline) airlines;


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
            isRegistered: true,
            isOperational: false
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
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address _airlineAddress,
                                string memory _name   
                            )
                            external
                            returns(bool success)
    {
      
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    // function buy
    //                         (                             
    //                         )
    //                         external
    //                         payable
    // {

    // }


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
    // fallback() 
    //                         external 
    //                         payable 
    // {
    //     fund();
    // }
}