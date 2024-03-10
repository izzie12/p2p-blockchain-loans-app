// SPDX-License-Identifier:MIT
pragma solidity 0.8.0;

contract P2PLoanify{

    uint256 contractBalance;

    constructor() payable{
        contractBalance=0;
    }

    //INITIALIZE CUSTOMER STATES
    address borrowerAddress;
    mapping(address => uint256) public borrowerCredit;
    mapping(address => uint256) public borrowerIncomePY;
    mapping(address => uint256) public borrowerBalance;

    // STRUCT TO HOLD CUSTOMER DATA
    struct borrowerSchema {
        address borrowerAddress;
        uint256 borrowerCredit;
        uint256 borrowerBalance;
        uint256 borrowerIncomePY;
    }

    //INITIALIZE OFFER STATES
    uint256 offerID;
    mapping(uint256 => address payable ) public lender;
    mapping(uint256 => uint256) public offerAmount;
    mapping(uint256 => uint256) public offerDuration;
    mapping(uint256 => uint256) public offerRate;
    mapping(uint256 => address) public owner;
    mapping(uint256 => bool) public isAvailable;
    mapping(uint256 => bool) public isMine;
    mapping(uint256 => bool) public isDeleted;
    mapping(uint256 => bool) public isDue;

    // STRUCT TO HOLD OFFER DATA
    struct offerSchema {
        address payable lender;
        uint256 offerID;
        uint256 offer_amount;
        uint256 lend_rate;
        address owner;
        uint256 lend_duration;
        uint256 lend_repayment;
        bool isAvailable;
        bool isCancelled;
        bool isDue;
    }

    //INITIALIZE OFFERS ARRAY TO HOLD ALL OFFERS
    offerSchema[] public offersArray;

    // CREATE AN INSTANCE OF THE OFFER SCHEMA TO HOLD THE CURRENT LOANS A USER HAS.
    offerSchema[] public myLoans;

    //FUNCTION TO RETURN ALL OFFERS
    function get_offers() public view returns (offerSchema[] memory){
        return offersArray;
    }

     //FUNCTION TO RETURN ALL TAKEN OFFERS
    function get_myLoans() public view returns (offerSchema[] memory){
        return myLoans;     
    }

    //FUNCTION TO CREATE AN OFFER
    function create_offer(uint256 _offerAmount, uint256 _loanDuration, uint256 _loanRate) external payable returns(string memory){
        
        require(_offerAmount > 0 && _loanDuration > 0 && _loanRate > 0, "Fill in the required fields" );

        //ASSIGN OFFER STATES TO PARAMETERS
        offerID++;
        lender[offerID] = payable (msg.sender);
        offerAmount[offerID] = _offerAmount;
        offerDuration[offerID] = _loanDuration;
        offerRate[offerID] = _loanRate;
        
        //PLACE PARAMETERS IN THE STRUCT
        offerSchema memory newOffer = offerSchema({
            lender: payable (msg.sender),
            offerID: offerID,
            offer_amount: _offerAmount,
            lend_rate:_loanRate,
            owner:msg.sender,
            lend_duration: _loanDuration,
            lend_repayment: _offerAmount + (_offerAmount * (_loanRate / 100) * _loanDuration),
            isAvailable:true,
            isCancelled:false,
            isDue:false
        });

        //CHECK THE OFFER ARRAY LENGTH AND STORE IT
        uint256 newOfferIndex = offersArray.length;

        //PUSH THE NEWLY CREATED OFFER
        offersArray.push(newOffer);

        //COMPARE THE LENGTH TO THE LENGTH + 1 TO ENSURE THERE WAS A PUSH. IF NOT, RETURN AN ERROR.
        require(offersArray.length == newOfferIndex + 1, "Error creating an offer, try again");

        return "Offer Created";
    }

    //FUNCTION TO DELETE OFFER
    function delete_offer(uint256 offerId, uint256 amount, address payable giver) external payable returns(string memory) {
        
        amount = offersArray[offerId].offer_amount;
        uint256 lastOfferIndex = offersArray.length - 1;
        require(lastOfferIndex >= 0, "No offers exist to delete");
        require(offerId <= lastOfferIndex, "Offer does not exist in array");
        if (offerId < lastOfferIndex) {
            offersArray[offerId] = offersArray[lastOfferIndex];
        }
        offersArray.pop();

        bool success = giver.send(amount*1e18);
        if (success) {
            //RETURN A SUCCESS MESSAGE IF EVERYTHING WORKS.
            return "Your offer has been refunded";
        } else {
            //RETURN AN ERROR MESSAGE IF TRANSFER FAILS
            return "Failed to transfer funds.";
        }

    }

    //REMOVE OFFER FROM ALL OFFERS
    function remove_offer(uint256 offerId) public payable{  
        uint256 lastOfferIndex = offersArray.length - 1;
        require(lastOfferIndex >= 0, "No offers exist to delete");
        require(offerId <= lastOfferIndex, "Offer does not exist in array");
        if (offerId < lastOfferIndex) {
            offersArray[offerId] = offersArray[lastOfferIndex];
        }
        offersArray.pop();    
    }

    function remove_my_loan(uint256 offerId) public payable{  
        uint256 lastOfferIndex = myLoans.length - 1;
        require(lastOfferIndex >= 0, "No offers exist to delete");
        require(offerId <= lastOfferIndex, "Offer does not exist in array");
        if (offerId < lastOfferIndex) {
            myLoans[offerId] = myLoans[lastOfferIndex];
        }
        myLoans.pop();   
    }

    //CREATE A SCHEMA TO HOLD ALL CUSTOMERS
    borrowerSchema[] public customerArray;

    // Function to add a new customer's credit score to the mapping and array
    function add_customer(address _customer, uint256 _creditScore, uint256 _netIncome, uint _customer_balance) public {

        // Add the customer's credit score to the mapping
        borrowerCredit[_customer] = _creditScore;
        borrowerIncomePY[_customer] = _netIncome;
        borrowerBalance[_customer] = _customer_balance;
        
        // Add the customer to the array of Customer structs
        borrowerSchema memory newCustomer = borrowerSchema({
            borrowerAddress: _customer,
            borrowerCredit: _creditScore,
            borrowerBalance: _customer_balance,
            borrowerIncomePY: _netIncome
        });

        //PUSH THE CUSTOMER TO THE NEW CUSTOMER ARRAY.
        customerArray.push(newCustomer);
    }

    //FUNCTION TO GET CREDIT SCORE OF THE PERSON APPLYING FOR LOAN
    function get_credit_score() public view returns (uint256) {

        //CHECK IF A VALUE IS RETURNED AND IF YES, RETURN THE CREDIT SCORE OF THE PERSON TRIGGERING THIS FUNCTION.
        require(borrowerCredit[msg.sender] != 0,"Error getting your credit score");
        return borrowerCredit[msg.sender];

    }

    //FUNCTION TO GET NET INCOME OF THE PERSON APPLYING FOR LOAN
    function get_net_income() public view returns (uint256) {

        //CHECK IF A VALUE IS RETURNED AND IF YES, RETURN THE NET INC0ME OF THE PERSON TRIGGERING THIS FUNCTION.
        require(borrowerIncomePY[msg.sender] != 0,"Error getting your net income");
        return borrowerIncomePY[msg.sender];

    }


    function apply_for_loan(uint256 offerId, address payable borrower) public payable returns (string memory){
        
        uint256 amount = offersArray[offerId].offer_amount;

        //CHECK THE PERSON TRYING TO APPLY AND RETURN ERROR IF THE CREATOR IS TRYING TO APPLY...
        require(msg.sender != offersArray[offerId].lender, "You cannot apply for your own loan.");

        //CALL FUNCTION TO CHECK CREDIT SCORE AND NET INCOME OF THE PERSON APPLYING
        uint256 myCredit = get_credit_score();
        uint256 myIncome = get_net_income();

        //CHECK IF CREDIT SCORE IS ABOVE 350 AND RETURN AN ERROR IF NOT
        require(myCredit >= 300,"Your credit score is too low.");
        
        //CHECK IF THE PERSON'S INCOME IS MORE OR EQUAL TO 5 TIMES THE REPAYMENT.
        require(myIncome >= 5 * offersArray[offerId].lend_repayment, "Your income level is too low for this loan.");
        
        //MAKE THE OFFER UNAVAILABLE AS IT WILL BE ASSINGED TO THIS PERSON
        offersArray[offerId].isAvailable = false;

        //SET THE OWNER TO THE CURRENT BORROWER
        offersArray[offerId].owner = msg.sender;

        //ADD THE OFFER TO AN ARRAY TO HOLD ONLY LOANS THE PERSON HAS TAKEN
        myLoans.push(offersArray[offerId]);

        //REMOVE OFFER FROM ALL OFFERS ARRAY
        remove_offer(offerId);

        bool success = borrower.send(amount*1e18);
        if (success) {
            //RETURN A SUCCESS MESSAGE IF EVERYTHING WORKS.
            return "Loan Approved. Funds can now be accessed in your wallet.";
        } else {
            //RETURN AN ERROR MESSAGE IF TRANSFER FAILS
            return "Error: Failed to transfer funds.";
        }

    }

    //SEND REPAYMENT TO THE LENDER
    function repay_loan(uint256 offerId) public payable returns(bool){
          
        //CHECK IF THE SENDER HAS ENOUGH ETHEREUM
        require(msg.sender.balance >= msg.value, "Insufficient balance");

        //CHECK IF THE CONTRACT HAS RECEIVED THE REPAYMENT AMOUNT
        require(address(this).balance >= msg.value, "Insufficient funds in contract");

        //TRANSFER THE REPAYMENT FROM THE CONTRACT TO THE LENDER
        payable(myLoans[offerId].lender).transfer(msg.value);

        //REMOVE LOAN FROM MY LOANS AFTER REPAYING
        remove_my_loan(offerId);

        return true;
       
    }

}