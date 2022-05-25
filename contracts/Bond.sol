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
    address public acceptedTokenAddress;
    //variables for bond logic
    int96 public _fundingTarget; //the amount in wei the borrower wants to raise from the bond
    int96 public _amountRaised; // wei actually raised at the end of the campaign
    int96 public _fundingRate; //interest per year in basis points
    int96 public _loanTerm; //length of loan, days
    address public borrower;
    address private _admin = 0x870ac8121ba4a31dE8E5D91675edf3f937B8D7e9;
    int96 _initialBorrowerFlowRate;
    mapping (address => int96) private lenderContributions; //wei, keeps track of how much each investor put in
    mapping (address => bool) private lenderExists;
    address[] private lenderAddresses;
    mapping (address => int96) private lenderFlowRate; //wei
    int96 public constant secondsPerYear = 31536000;
    bool private borrowerHasLoan;
    bool private initialSetup;
    bool public openToDeposits;
    int96 private _totalRepaid;

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
        require(loanTerm > 0, "Can not have a loan term less than 1 day");
        require(fundingRate > 0, "Can not have a negative interest rate");
        require(fundingTarget > 0, "Can not have a negative funding target");

        _host = host;
        _cfa = IConstantFlowAgreementV1(
            address(host.getAgreementClass(keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1"))
            )
        );
        _acceptedToken = acceptedToken;
        acceptedTokenAddress = address(_acceptedToken);
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

//Events
    event depositEvent(address depositor, int96 amount);
    event InitialSetup(address borrower, int96 borrowerFlowRate, address acceptedToken);
    event TransferAllToBorrower(int96 _amountRaised, address to, address from);
    event cfaTerminated(address from, address to);
    

/// @dev deposit wrapped ERC20's for lending to the borrower
    function deposit(int96 amount, address tokenAddress ) external {
        require(tokenAddress == acceptedTokenAddress, "Can not deposit this token");
        require(openToDeposits,"closed to deposits");
        require(_fundingTarget - int96(int(ISuperToken(tokenAddress).balanceOf(address(this))))  > amount,"Not enough loan capacity for deposit this big");

        //Transer tokens into conract for lending
        //Lender needs to have called approve() already on front
        int256 transferAmount = int256(amount);
        ISuperToken(tokenAddress).transferFrom(msg.sender, address(this), uint(transferAmount));

        //Store the lender deposit. Check for overflow
        int96 tmpContribution = lenderContributions[msg.sender];
        lenderContributions[msg.sender] = lenderContributions[msg.sender] + amount;
        require(lenderContributions[msg.sender] > tmpContribution, "over flow");

        //add investor to the register of lenders if not already there
        if (!lenderExists[msg.sender]) {
            lenderAddresses.push(msg.sender);
            lenderExists[msg.sender] = true;
        }

        emit depositEvent(msg.sender, amount);
    }

/// @dev helper to calc each investors flow rate, wei/second
    function _calcInvestorFlowRate(address investorAddress) view private returns (int96 flowRate) {

    int96 totalInterestPerYear = (_amountRaised * _fundingRate) / 10000;  
    int96 totalPrincipalPerYear = (_amountRaised * 365) / _loanTerm; 
    int96 totalRepaymentPerYear = totalInterestPerYear + totalPrincipalPerYear;
    
    int96 totalInvestorCFPerYear = (lenderContributions[investorAddress] * totalRepaymentPerYear) / _amountRaised;
    int96 totalInvestorCFPerSecond = totalInvestorCFPerYear / secondsPerYear; 
    flowRate = totalInvestorCFPerSecond;
    }

/// @dev transfers the investors funds raised from this contract to the borrower
    function _transferAllFundsToBorrower() private {
        require(ISuperToken(_acceptedToken).balanceOf(address(this)) > 0, "contract does not own any of the accepted token");
        require(openToDeposits = true,"closed to deposits");
        _amountRaised = int96(int(ISuperToken(_acceptedToken).balanceOf(address(this))));
        
        //close fund raising period
        openToDeposits = false;
        borrowerHasLoan = true;
        
        //transfer all funds raised from contract to borrower
        int256 amountRaisedForCall = int256(_amountRaised); //convert to 256 for .transfer below
        ISuperToken(_acceptedToken).transfer(borrower, uint256(amountRaisedForCall));

        (, int96  initialBorrowerFlowRate, , ) = _cfa.getFlow(_acceptedToken, address(this), borrower);
         _initialBorrowerFlowRate = initialBorrowerFlowRate;
         emit TransferAllToBorrower(_amountRaised, borrower, address(this));
    }

/// @dev sets the flow rate for each investor for easy creation of CFA agreement
    function _setAllInvestorFlowRates() private {
        uint256 numOfInvestors = lenderAddresses.length;
        //loop through the investors and set the flow rate for each
        for (uint i = 1; i <= numOfInvestors; i++) {
            address currentInvestor = lenderAddresses[i-1];
            lenderFlowRate[currentInvestor] = _calcInvestorFlowRate(currentInvestor);
        }
    }

/// @dev create the CFAs from contract to each investor
    function _updateInvestorFlows(bytes calldata ctx)
        private
        returns (bytes memory newCtx)
    {
        //get the latest borrower flow rate to the loan contract
        (, int96 newBorrowerFlowRate, , ) = _cfa.getFlow(_acceptedToken,address(this),borrower);
        
        newCtx = ctx;
        uint256 numOfInvestors = lenderAddresses.length;
        
        if (initialSetup == true) { 
            int96 outFlowRate;

            //create a new CFA flow from this contract to all investors 
            for (uint256 i = 1; i <= numOfInvestors; i++) {
                //create a new CFA  - THIS NEEDS TO BE A BATCH CALL *************
                outFlowRate = lenderFlowRate[lenderAddresses[i-1]];
                newCtx = cfaV1.createFlowWithCtx(
                    newCtx,
                    lenderAddresses[i-1],
                    _acceptedToken,
                    outFlowRate
                );
            }
            initialSetup = false; //stop the initial CFAs to investors being setup again
            emit InitialSetup(borrower,newBorrowerFlowRate, address(_acceptedToken));
        
        } else if (newBorrowerFlowRate == int(0)) { //borrower has deleted the repayment flow to the contract
            //delete all CFAs to all investors
            for (uint256 i = 1; i <= numOfInvestors; i++) {
                newCtx = cfaV1.deleteFlowWithCtx(
                    newCtx,
                    address(this),
                    lenderAddresses[i-1],
                    _acceptedToken
                );
            }
            emit cfaTerminated(borrower,address(this));

        } else { // CFA inflows to this contract have been updated

            if (newBorrowerFlowRate != _initialBorrowerFlowRate ) { //borrower CFA has been updated

            // SHOULD I BE UPDATING THE FLOW RATES OUT TO INVESTORS AT ALL HERE IF THE BORROWER CHANGES THEIR INFLOW?
            //PROBABLY NOT SINCE THE INTEREST IS SET BY HOW MUCH WAS RAISED, NOT HOW MUCH WAS FLOWING IN

                // //update all investor flow rates
                // _setAllInvestorFlowRates();

                // //update all CFAs to all investors
                // for (uint256 i = 1; i <= numOfInvestors; i++) {
                //     newCtx = cfaV1.updateFlowWithCtx(
                //                 newCtx,
                //                 lenderAddresses[i-1],
                //                 _acceptedToken,
                //                 lenderFlowRate[lenderAddresses[i-1]]
                //             );
                // }
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
