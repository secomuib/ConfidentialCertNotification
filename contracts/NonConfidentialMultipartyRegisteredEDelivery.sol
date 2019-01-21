pragma solidity ^0.4.25;

// Factory contract for Confidential Multiparty Registered eDelivery
contract ConfidentialMultipartyRegisteredEDeliveryFactory {
    mapping(address => address[]) public senderDeliveries;
    mapping(address => address[]) public receiverDeliveries;
    address[] public deliveries;

    function createDelivery(address[] _receivers, bytes32 _messageHash, uint _term1, uint _term2) public payable {
        address newDelivery = (new NonConfidentialMultipartyRegisteredEDelivery)
            .value(msg.value)(msg.sender, _receivers, _messageHash, _term1, _term2);
        deliveries.push(newDelivery);
        senderDeliveries[msg.sender].push(newDelivery);
        for (uint i = 0; i<_receivers.length; i++) {
            receiverDeliveries[_receivers[i]].push(newDelivery);
        }
    }

    function getSenderDeliveries(address _sender) public view returns (address[]) {
        return senderDeliveries[_sender];
    }

    function getSenderDeliveriesCount(address _sender) public view returns (uint) {
        return senderDeliveries[_sender].length;
    }

    function getReceiverDeliveries(address _receiver) public view returns (address[]) {
        return receiverDeliveries[_receiver];
    }

    function getReceiverDeliveriesCount(address _receiver) public view returns (uint) {
        return receiverDeliveries[_receiver].length;
    }

    function getDeliveries() public view returns (address[]) {
        return deliveries;
    }

    function getDeliveriesCount() public view returns (uint) {
        return deliveries.length;
    }
}

contract ConfidentialMultipartyRegisteredEDeliveryFactory {
    //Variables
    enum State {cancelled, finished}
    address ttp;
    struct Receiver{
        address receiver;
        string hB;
        string keyB;
        State state;
        bool isValue;
    }
    struct Message{
        uint id;
        address sender;
        mapping(address => Receiver) receivers; //All receivers
        bool isValue;
    }
    mapping(address => mapping(uint => Message)) messages;   

    //Constructor
    constructor() public {
        ttp = msg.sender;
    }

    //Events
    event cancelEvent(
        address cancelledUser,
        string cancelResponse
    );

    event finishEvent(
        string resolveResponse
    );

    //Main functions    
    function cancel (uint id,address[] cancelledReceivers) public {
        if (messages[msg.sender][id].isValue){
            for (uint i = 0; i<cancelledReceivers.length;i++){
                address receiverToCancel = cancelledReceivers[i];
                
                if ((messages[msg.sender][id].receivers[receiverToCancel].
                        isValue)&&(messages[msg.sender][id].receivers
                        [receiverToCancel].state==State.finished)){
                    cancelEvent(receiverToCancel,messages[msg.sender]
                        [id].receivers[receiverToCancel].hB);
                } else if (!messages[msg.sender][id].receivers
                        [receiverToCancel].isValue){

                    addReceiver(id,msg.sender,receiverToCancel,
                        "","",State.cancelled);
                    cancelEvent(receiverToCancel,stateToString(messages
                        [msg.sender][id].receivers[receiverToCancel].
                        state));
                } else {
                    cancelEvent(receiverToCancel,stateToString(messages
                        [msg.sender][id].receivers[receiverToCancel].state));
                }
            }
        } else {
            createMessage(id,msg.sender);
            for(uint j= 0; j<cancelledReceivers.length;j++){
                address receiverToAdd = cancelledReceivers[j];
                addReceiver(id,msg.sender,receiverToAdd,"","",
                    State.cancelled);
                cancelEvent(receiverToAdd,stateToString(messages[msg.sender]
                    [id].receivers[receiverToAdd].state));
            }
        }
    }

    function finish(uint id,address sender,address receiver,string _hB,
        string _keyB) public {

        if (msg.sender==ttp){
            if (messages[sender][id].isValue){
                if((messages[sender][id].receivers[receiver].isValue)
                    &&(messages[sender][id].receivers[receiver].
                    state==State.cancelled)){

                    finishEvent(stateToString(messages[sender][id].
                        receivers[receiver].state));

                } else if(!messages[sender][id].receivers[receiver].isValue){
                    
                    addReceiver(id,sender,receiver,_hB,_keyB,State.finished);

                    finishEvent(stateToString(messages[sender][id].
                        receivers[receiver].state));
                } else {
                    finishEvent(stateToString(messages[sender]
                    [id].receivers[receiver].state));
                }
            }else{
                createMessage(id,sender);
                addReceiver(id,sender,receiver,_hB,_keyB,State.finished);

                finishEvent(stateToString(messages[sender][id].
                    receivers[receiver].state));
            }
        }
    }

    function createMessage(uint id, address sender) private {     
        messages[sender][id].id=id;
        messages[sender][id].sender=sender;
        messages[sender][id].isValue=true;
    }

    function addReceiver(uint id, address sender, address receiver,
        string _hB, string _keyB, State _state) private{

        messages[sender][id].receivers[receiver].receiver=receiver;
        messages[sender][id].receivers[receiver].hB=_hB;
        messages[sender][id].receivers[receiver].keyB=_keyB;
        messages[sender][id].receivers[receiver].state=_state;
        messages[sender][id].receivers[receiver].isValue=true;
    }

    function getAddress(uint id,address sender,address receiver) 
        public view returns (address){

        return messages[sender][id].receivers[receiver].receiver;
    }

    function gethB(uint id,address sender,address receiver) 
        public view returns (string){

        return messages[sender][id].receivers[receiver].hB;
    }

    function getState(uint id,address sender, address receiver) 
        public view returns (State){

        return messages[sender][id].receivers[receiver].state;
    }

    function stateToString(State state) view private returns 
        (string){

        if (state==State.cancelled) return "Cancelled";
        if (state==State.finished) return "Finished";
    }
}

// Non-Confidential Multiparty Registered eDelivery
contract NonConfidentialMultipartyRegisteredEDelivery {
    // Possible states
    enum State {notexists, created, cancelled, accepted, finished }
    
    // Parties involved
    address public sender;
    address[] public receivers;
    mapping (address => State) public receiversState;
    uint acceptedReceivers;

    // Message
    bytes32 public messageHash;
    string public message;
    // Time limit (in seconds)
    // See units: http://solidity.readthedocs.io/en/develop/units-and-global-variables.html?highlight=timestamp#time-units
    uint public term1; 
    uint public term2; 
    // Start time
    uint public start; 

    // Constructor funcion to create the delivery
    constructor (address _sender, address[] _receivers, bytes32 _messageHash, uint _term1, uint _term2) public payable {
        // Requires that the sender send a deposit of minimum 1 wei (>0 wei)
        require(msg.value>0, "Sender has to send a deposit of minimun 1 wei"); 
        require(_term1 < _term2, "Timeout term2 must be greater than _term1");
        sender = _sender;
        receivers = _receivers;
        // We set the state of every receiver to 'created'
        for (uint i = 0; i<receivers.length; i++) {
            receiversState[receivers[i]] = State.created;
        }
        acceptedReceivers = 0;
        messageHash = _messageHash;
        start = now; // now = block.timestamp
        term1 = _term1; // timeout term1, in seconds
        term2 = _term2; // timeout term2, in seconds
    }

    // accept() let receivers accept the delivery
    function accept() public {
        require(now < start+term1, "The timeout term1 has been reached");
        require(receiversState[msg.sender]==State.created, "Only receivers with 'created' state can accept");

        acceptedReceivers = acceptedReceivers+1;
        receiversState[msg.sender] = State.accepted;        
    }

    // finish() let sender finish the delivery sending the message
    function finish(string _message) public {
        require((now >= start+term1) || (acceptedReceivers>=receivers.length), 
            "The timeout term1 has not been reached and not all receivers have been accepted the delivery");
        require (msg.sender==sender, "Only sender of the delivery can finish");
        require (messageHash==keccak256(_message), "Message not valid (different hash)");
        
        message = _message;
        sender.transfer(this.balance); // Sender receives the refund of the deposit
        // We set the state of every receiver with 'accepted' state to 'finished'
        for (uint i = 0; i<receivers.length; i++) {
            if (receiversState[receivers[i]] == State.accepted) {
                receiversState[receivers[i]] = State.finished;    
            }
        }
    }

    // cancel() let receivers cancel the delivery
    function cancel() public {
        require(now >= start+term2, "The timeout term2 has not been reached");
        require(receiversState[msg.sender]==State.accepted, "Only receivers with 'accepted' state can cancel");

        receiversState[msg.sender] = State.cancelled;
    }

    // getState(address) returns the state of a receiver in an string format
    function getState(address _receiver) public view returns (string) {
        if (receiversState[_receiver]==State.notexists) {
            return "not exists";
        } else if (receiversState[_receiver]==State.created) {
            return "created";
        } else if (receiversState[_receiver]==State.cancelled) {
            return "cancelled";
        } else if (receiversState[_receiver]==State.accepted) {
            return "accepted";
        } else if (receiversState[_receiver]==State.finished) {
            return "finished";
        } 
    }
}