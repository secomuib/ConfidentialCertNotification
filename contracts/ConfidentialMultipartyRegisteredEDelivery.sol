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

    function createDelivery(address[] _receivers) public {
        address newDelivery = new ConfidentialMultipartyRegisteredEDelivery
            (msg.sender, ttp, _receivers);
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
    enum State {notexists, created, cancelled, finished }
    
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

    // Constructor funcion to create the delivery
    constructor (address _sender, address _ttp, address[] _receivers) public {
        sender = _sender;
        ttp = _ttp;
        receivers = _receivers;
        // We set the state of every receiver to 'created'
        for (uint i = 0; i<receivers.length; i++) {
            receiversState[receivers[i]].state = State.created;
        }
    }

    // cancel() let sender cancel the delivery
    function cancel() public {
        require (msg.sender==sender, "Only sender of the delivery can cancel");
        for (uint i = 0; i<receivers.length;i++) {
            if (receiversState[receivers[i]].state == State.created) {
                // Add Bi to B”−cancelled
                receiversState[receivers[i]].state = State.cancelled;
            }
        }
    }

    // finish() let TTP finish the delivery
    function finish(address _receiver, bytes32 _receiverSignature, bytes32 _keySignature) public {
        require (msg.sender==ttp, "Only TTP of the delivery can finish");
        if (receiversState[_receiver].state == State.created) {
            // Add Bi to B”−finished
            receiversState[_receiver].receiverSignature = _receiverSignature;
            receiversState[_receiver].keySignature = _keySignature;
            receiversState[_receiver].state = State.finished;
        }
    }

    // getState(address) returns the state of a receiver in an string format
    function getState(address _receiver) public view returns (string) {
        if (receiversState[_receiver].state==State.notexists) {
            return "not exists";
        } else if (receiversState[_receiver].state==State.created) {
            return "created";
        } else if (receiversState[_receiver].state==State.cancelled) {
            return "cancelled";
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