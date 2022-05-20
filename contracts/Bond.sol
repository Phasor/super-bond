// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol"; 
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Bond is SuperAppBase {

    /**************************************************************************
     * Setup Super App
     *************************************************************************/

    using CFAv1Library for CFAv1Library.InitData;

    //initialize cfaV1 variable
    CFAv1Library.InitData public cfaV1;

    ISuperfluid private _host; // SF host contract
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // wrapped super token

    //variables for bond logic
    int96 private _fundingTarget; //the amount in wei the borrower wants to raise from the bond
    int96 private _amountRaised; // wei actually raised at the end of the campaign
    int96 private _fundingRate; //interest per year in basis points
    int96 private _loanTerm; //length of loan, days
    address public borrower;
    address private _admin = 0x870ac8121ba4a31dE8E5D91675edf3f937B8D7e9;
    int96 _initialBorrowerFlowRate;
    mapping (address => int96) private lenderContributions; //wei, keeps track of how much each investor put in
    mapping (address => bool) private lenderExists;
    address[] private lenderAddresses;
    mapping (address => int96) private lenderFlowRate; //wei
    int96 public constant secondsPerYear = 31536000;
    bool private investorFlowRatesSet; 
    bool private borrowerHasLoan;
    bool private initialSetup;
    bool public openToDeposits;
    address[] public whitelistedTokens;

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken,
        int96 fundingTarget, //in wei
        int96 fundingRate, //basis points
        int96 loanTerm //length of loan, days
    ) {
        require(address(host) != address(0), "host is zero address");
        require(address(cfa) != address(0), "cfa is zero address");
        require(address(acceptedToken) != address(0),"acceptedToken is zero address");

        _host = host;
        _cfa = IConstantFlowAgreementV1(
            address(host.getAgreementClass(keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1"))
            )
        );
        _acceptedToken = acceptedToken;
        _fundingTarget = fundingTarget;
        _fundingRate = fundingRate;
        _loanTerm = loanTerm;
        openToDeposits = true;
        borrowerHasLoan = false;
        borrower = msg.sender; //borrower will deploy the contract
        initialSetup = true;
        cfaV1 = CFAv1Library.InitData(_host, _cfa);

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);
    }

  /**************************************************************************
     * Bond logic
     *************************************************************************/

/// @dev whitelists the token so it can be deposited into this contract
    function whitelistToken(address tokenAddress) external onlyAdmin {
        whitelistedTokens.push(tokenAddress);
    }

/// @dev deposit wrapped ERC20's
    function deposit(int96 amount, address token ) external returns(bool) {
        //end user will call approve, then app will transferFrom there ERC2 to the SF upgrade function to wrap
        //then wrapped tokens will be deposited
    }

/// @dev helper to calc each investors flow rate, wei/second
    function _calcInvestorFlowRate(address investorAddress) view private returns (int96 flowRate) {
    
    ///// THIS IS NOT RIGHT< SHOULD BE ABLE TO DEAL WITH A SITUATION WHERE BORROWER UPDATES FLOW

    int96 totalInterestPerYearWei = (_amountRaised * _fundingRate) / 10000;  //wei
    int96 totalPrincipalPerYearWei = (_amountRaised * 365) / _loanTerm; //wei
    int96 totalRepaymentPerYearWei = totalInterestPerYearWei + totalPrincipalPerYearWei; //wei
    
    //does the contract still have eth in? ************************************?????!??
    int96 totalInvestorCFPerYearWei = (lenderContributions[investorAddress] * totalRepaymentPerYearWei) / _amountRaised;
    int96 totalInvestorCFPerSecondWei = totalInvestorCFPerYearWei / secondsPerYear; 
    flowRate = totalInvestorCFPerSecondWei;
    }

/// @dev transfers the investors funds raised from contract to the borrower
    function _transferAllFundsToBorrower() private {
        require(address(this).balance > 0, "contract is empty");
        require(openToDeposits = true,"closed to deposits");
        _amountRaised = int96(int(address(this).balance));
        
        //close fund raising period
        openToDeposits = false;
        borrowerHasLoan = true;
        
        //if non-empty transfer balance of funds raised
        (bool sent, ) = borrower.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether to Borrower");

        (, int96  initialBorrowerFlowRate, , ) = _cfa.getFlow(_acceptedToken, address(this), borrower);
         _initialBorrowerFlowRate = initialBorrowerFlowRate;
    }

/// @dev 
     fallback() external {
        require(openToDeposits,"closed to deposits");
        require(_fundingTarget - address(this).balance < msg.value,"Not enough loan capacity");
    }

    receive() external payable {
         require(openToDeposits,"closed to deposits");
         require(_fundingTarget - address(this).balance < msg.value,"Not enough loan capacity");
         //store the amount sent. Can handle situation where same user sends more than once 
        int96 memory tmpContribution = lenderContributions[msg.sender];
        lenderContributions[msg.sender] = lenderContributions[msg.sender] + int96(int(msg.value));
        require(lenderContributions[msg.sender] > tmpContribution, "over flow");
        //add investor to the register of lenders if not already there
        if (!lenderExists[msg.sender]) {
            lenderAddresses.push(msg.sender);
            lenderExists[msg.sender] = true;
        }
    }

/// @dev function sets the flow rate for each investor
    function _setAllInvestorFlowRates() private {
        uint256 memory numOfInvestors = lenderAddresses.length;
        //loop through the investors and set the flow rate for each
        for (uint i = 1; i <= numOfInvestors; i++) {
            lenderFlowRate[lenderAddresses[i-1]] = _calcInvestorFlowRate(lenderAddresses[i-1]);
        }
    }

/// @dev create the CFAs from contract to each investor
    function _updateInvestorFlows(bytes calldata ctx)
        private
        returns (bytes memory newCtx)
    {
        //int96 contractNetFlowRate = _cfa.getNetFlow(_acceptedToken,address(this)); 

        //get the latest borrower flow rate to the loan contract
        (, int96 newBorrowerFlowRate, , ) = _cfa.getFlow(_acceptedToken,address(this),borrower);
        
        newCtx = ctx;
        uint256 memory numOfInvestors = lenderAddresses.length;
        
        if (initialSetup == true) { 
            int96 memory outFlowRate;

            //loop through all investors and create a new CFA flow for each of them from contract to investor
            for (uint256 i = 1; i <= numOfInvestors; i++) {
                //create a new CFA  - THIS NEEDS TO BE A BATCH CALL *************
                outFlowRate = lenderFlowRate[lenderAddresses[i-1]];
                newCtx = cfaV1.createFlowWithCtx(
                    newCtx,
                    lenderAddresses[i-1],
                    _acceptedToken,
                    outFlowRate
                );
            initialSetup = false; //stop the initial CFAs to investors being setup again
            }
        } else if (newBorrowerFlowRate == 0) { //borrower has deleted the repayment flow to the contract
            //delete all CFAs to all investors
            for (uint256 i = 1; i <= numOfInvestors; i++) {
                newCtx = cfaV1.deleteFlowWithCtx(
                    newCtx,
                    address(this),
                    lenderAddresses[i-1],
                    _acceptedToken
                );
            }
        } else { // CFA inflows to this contract have been updated

            if (newBorrowerFlowRate != _initialBorrowerFlowRate ) { //borrower CFA has been updated

                //update all investor flow rates
                _setAllInvestorFlowRates();

                //update all CFAs to all investors
                for (uint256 i = 1; i <= numOfInvestors; i++) {
                    newCtx = cfaV1.updateFlowWithCtx(
                                newCtx,
                                lenderAddresses[i-1],
                                _acceptedToken,
                                lenderFlowRate[lenderAddresses[i-1]]
                            );
                }
            }
        }
    }



    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass, //address of CVA
        bytes32, // _agreementId -> hash of the sender and receiver's address of the flow that was created
        bytes calldata, /*_agreementData*/  //the address of the sender and receiver of the flow that was created, updated, or deleted - encoded using solidity's abi.encode() built in function
        bytes calldata, // _cbdata, // data that was returned by the beforeAgreement callback if it was run prior to the calling of afterAgreement callback
        bytes calldata _ctx // data about the call to the constant flow agreement contract itself
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        if (!borrowerHasLoan){
            _transferAllFundsToBorrower();
            _setAllInvestorFlowRates(); //sets the flow rates for internal accounting
        }
       
        return _updateInvestorFlows(_ctx);
    }


    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata, //agreementData,
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateInvestorFlows(_ctx);
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, //_cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        if (!_isSameToken(_superToken) || !_isCFAv1(_agreementClass))
            return _ctx;
        return _updateInvestorFlows(_ctx);
    }

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return
            ISuperAgreement(agreementClass).agreementType() ==
            keccak256(
                "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
            );
    }

    modifier onlyHost() {
        require(
            msg.sender == address(_host),
            "RedirectAll: support only one host"
        );
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "RedirectAll: not accepted token");
        require(_isCFAv1(agreementClass), "RedirectAll: only CFAv1 supported");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        _admin = newAdmin;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(admin() == msg.sender, "caller is not the admin");
        _;
    }



}
