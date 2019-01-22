pragma solidity ^0.4.25;

// Factory contract for Confidential Multiparty Registered eDelivery
contract ConfidentialMultipartyRegisteredEDeliveryFactoryTTP {
    mapping(address => address[]) public senderDeliveries;
    mapping(address => address[]) public receiverDeliveries;
    address[] public deliveries;

    address public ttp;

    // Constructor funcion to create the factory/TTP
    constructor () public payable {
        ttp = msg.sender;
    }

    function createDelivery(address[] _receivers, uint _term) public {
        address newDelivery = new ConfidentialMultipartyRegisteredEDelivery
            (msg.sender, ttp, _receivers, _term);
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

// Non-Confidential Multiparty Registered eDelivery
contract ConfidentialMultipartyRegisteredEDelivery {
    // Possible states
    enum State {notexists, created, cancelled, accepted, finished }
    
    struct ReceiverState{
        bytes32 receiverSignature;      // hB
        bytes32 keySignature;           // k'T
        State state;
    }

    // Parties involved
    address public sender;
    address public ttp;
    address[] public receivers;
    mapping (address => ReceiverState) public receiversState;
    uint acceptedReceivers;

    // Time limit (in seconds)
    // See units: http://solidity.readthedocs.io/en/develop/units-and-global-variables.html?highlight=timestamp#time-units
    uint public term;
    // Start time
    uint public start; 

    // Constructor funcion to create the delivery
    constructor (address _sender, address _ttp, address[] _receivers, uint _term) public {
        sender = _sender;
        ttp = _ttp;
        receivers = _receivers;
        // We set the state of every receiver to 'created'
        for (uint i = 0; i<receivers.length; i++) {
            receiversState[receivers[i]].state = State.created;
        }
        acceptedReceivers = 0;
        start = now; // now = block.timestamp
        term = _term; // timeout term, in seconds
    }

    // accept() let receivers accept the delivery
    function accept(bytes32 _receiverSignature) public {
        require(now < start+term, "The timeout 'term' has been reached");
        require(receiversState[msg.sender].state==State.created, "Only receivers with 'created' state can accept");

        acceptedReceivers = acceptedReceivers+1;
        receiversState[msg.sender].receiverSignature = _receiverSignature;
        receiversState[msg.sender].state = State.accepted;        
    }

    // finish() let sender finish the delivery sending the message
    function finish(string _message) public {
        
        // PENDENT: comprovar que finaliza el TTP

        require((now >= start+term) || (acceptedReceivers>=receivers.length), 
            "The timeout 'term' has not been reached and not all receivers have been accepted the delivery");
        require (msg.sender==sender, "Only sender of the delivery can finish");
        //require (messageHash==keccak256(_message), "Message not valid (different hash)");
        
        //message = _message;
        // We set the state of every receiver with 'accepted' state to 'finished'
        for (uint i = 0; i<receivers.length; i++) {
            if (receiversState[receivers[i]].state == State.accepted) {
                receiversState[receivers[i]].state = State.finished;    
            }
        }
    }

    // cancel() let receivers cancel the delivery
    function cancel() public {
        require(receiversState[msg.sender].state==State.accepted, "Only receivers with 'accepted' state can cancel");

        // PENDENT: Segons 9.4.2, el sender també pot cancelar

        receiversState[msg.sender].state = State.cancelled;
    }

    // getState(address) returns the state of a receiver in an string format
    function getState(address _receiver) public view returns (string) {
        if (receiversState[_receiver].state==State.notexists) {
            return "not exists";
        } else if (receiversState[_receiver].state==State.created) {
            return "created";
        } else if (receiversState[_receiver].state==State.cancelled) {
            return "cancelled";
        } else if (receiversState[_receiver].state==State.accepted) {
            return "accepted";
        } else if (receiversState[_receiver].state==State.finished) {
            return "finished";
        } 
    }

    // getReceiverSignature(address) returns the signature of a receiver
    function getReceiverSignature(address _receiver) public view returns (bytes32) {
        return receiversState[_receiver].receiverSignature;
    }

    // getKeySignature(address) returns the key for a receiver
    function getKeySignature(address _receiver) public view returns (bytes32) {
        return receiversState[_receiver].keySignature;
    }
}