pragma solidity ^0.4.25;

// Non-Confidential Multiparty Registered eDelivery
contract ConfidentialMultipartyRegisteredEDelivery {
    // Possible states
    enum State {notexists, cancelled, finished }

    struct ReceiverState{
        bytes32 receiverSignature;      // hB
        bytes32 keySignature;           // k'T
        State state;
    }

    struct Message{
        bool messageExists;
        // Parties involved in the message
        address sender;
        address[] receivers;
        mapping(address => ReceiverState) receiversState;
    }

    // Mapping of all messages
    mapping(uint => Message) messages;

    // Parties involved
    address public ttp;

    // Constructor funcion
    constructor () public {
        ttp = msg.sender;
    }

    // finish() lets TTP finish the delivery
    function finish(uint _id, address _sender, address _receiver, bytes32 _receiverSignature, bytes32 _keySignature) public {
        require (msg.sender==ttp, "Only TTP can finish");
        if (!messages[_id].messageExists) {
            // Message not exists
            createMessage(_id, _sender);
        }
        if (messages[_id].receiversState[_receiver].state==State.notexists) {
            // Receiver state is 'not exists'
            addReceiver(_id, _receiver, _receiverSignature, _keySignature, State.finished);
        }
    }

    // cancel() lets sender cancel the delivery
    function cancel (uint _id, address[] _cancelledReceivers) public {
        if (!messages[_id].messageExists) {
            // Message not exists
            createMessage(_id, _sender);
        }
        require (msg.sender==messages[_id].sender, "Only sender of the message can cancel");
        for (uint i = 0; i<cancelledReceivers.length;i++){
            address receiverToCancel = _cancelledReceivers[i];
            if (messages[_id].receiversState[_receiver].state==State.notexists) {
                // Receiver state is 'not exists'
                addReceiver(_id, receiverToCancel, 0, 0, State.cancelled);
            }
        }
    }

    // Creates a new message
    function createMessage(uint _id, address _sender) private {
        messages[_id].sender = _sender;
        messages[_id].messageExists = true;
    }

    // Adds a new receiver to that message
    function addReceiver(uint _id, address _receiver, bytes32 _receiverSignature, bytes32 _keySignature, State _state) private {
        messages[_id].receivers.push(_receiver);
        messages[_id].receiversState[_receiver].receiverSignature = _receiverSignature;
        messages[_id].receiversState[_receiver].keySignature = _keySignature;
        messages[_id].receiversState[_receiver].state = _state;
    }

    // getState() returns the state of a receiver in an string format
    function getState(uint _id, address _receiver) public view returns (string) {
        if (messages[_id].receiversState[_receiver].state==State.notexists) {
            return "not exists";
        } else if (messages[_id].receiversState[_receiver].state==State.cancelled) {
            return "cancelled";
        } else if (messages[_id].receiversState[_receiver].state==State.finished) {
            return "finished";
        } 
    }

    // getReceiverSignature() returns the signature of a receiver
    function getReceiverSignature(uint _id, address _receiver) public view returns (bytes32) {
        return messages[_id].receiversState[_receiver].receiverSignature;
    }

    // getKeySignature() returns the key for a receiver
    function getKeySignature(uint _id, address _receiver) public view returns (bytes32) {
        return messages[_id].receiversState[_receiver].keySignature;
    }
}