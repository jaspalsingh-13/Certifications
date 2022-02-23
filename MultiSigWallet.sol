//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract MultiSigWallet{

    uint constant private MIN_SIGN = 2;
    address private _owner;
    mapping(address=>uint) private _owners;

    event SignTransaction(uint txid, uint sigCount, uint amt, string status);
    //event PreSignTransaction(uint txid, uint sigCount, uint amt);

    constructor(){
      _owner = msg.sender;
 }
    struct Transaction {
        address from;
        address to;
        uint amount;
        uint signatureCount;
        mapping(address=>uint) signatures;
    }

    mapping(uint=>Transaction) private transactions;

    uint private transactionIndex;

    uint[] private pendingTransactions;

    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    modifier validOwner() {

        require(msg.sender == _owner || _owners[msg.sender]==1);
        _;
    }

    // 
    //function walletOwner() public {
      //  _owner = msg.sender;
    //}
    // @jaspal - to check whether the address is already in the list of owners or not 

    function addOwner(address newOwner) public onlyOwner {
        _owners[newOwner]=1;

    }

    function deleteOwner(address owner) public onlyOwner {
        _owners[owner] = 0;
    }

    function transferTo(address _to, uint _amount) validOwner payable public {
        require(address(this).balance >= _amount, " insufficient contract balance");

        transactionIndex = transactionIndex + 1;

        Transaction storage transaction = transactions[transactionIndex];

        transaction.to = _to;
        transaction.from = msg.sender;
        transaction.amount = _amount;
        transaction.signatureCount =0;
        emit SignTransaction(transactionIndex, transaction.signatureCount,transaction.amount,"after the transfer ");

        pendingTransactions.push(transactionIndex);

    }

    function signTransaction(uint transactionID) validOwner payable public {
        Transaction storage transactionHappened = transactions[transactionID];

        //require(address(0x0) != transactionHappened.from, "from address already exist");
        require(msg.sender != transactionHappened.from,"sender is the from ");
        require(transactionHappened.signatures[msg.sender]!=1, " this is already sign");
        transactionHappened.signatures[msg.sender] = 1; 
        transactionHappened.signatureCount++;

        emit SignTransaction(transactionID,transactionHappened.signatureCount,transactionHappened.amount,"clear the require stage");

        if(transactionHappened.signatureCount >= MIN_SIGN)
        {
            emit SignTransaction(transactionID,transactionHappened.signatureCount,transactionHappened.amount,"before balance check");

            require(address(this).balance>= transactionHappened.amount," contract does not have the sufficient balance");
            
            emit SignTransaction(transactionID,transactionHappened.signatureCount,transactionHappened.amount,"after the balance check ");

            payable (transactionHappened.to).transfer(transactionHappened.amount);

            emit SignTransaction(transactionID,transactionHappened.signatureCount,transactionHappened.amount,"after the transfer ");
            
            deleteTransaction(transactionID);
        }
    }

    function deleteTransaction(uint256 transactionInd) validOwner public {

        for(uint i=0; i<pendingTransactions.length-1;i++){
            if(transactionInd == pendingTransactions[i]){
                pendingTransactions[i]=pendingTransactions[i+1];
                delete pendingTransactions[pendingTransactions.length-1];
                //pendingTransactions.length -1;
                delete transactions[transactionInd];

            }
        }
        

    }

    

    receive() external payable {


    }

}
