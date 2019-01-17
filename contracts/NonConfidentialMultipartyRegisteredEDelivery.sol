pragma solidity ^0.4.25;

// Notificació multipart certificada no confidencial, d'un sol ús
contract NonConfidentialMultipartyRegisteredEDelivery {
    // Possible states
    enum State {notexists, created, cancelled, accepted, finished }
    
    // Parties involved
    address public sender;
    address[] public receivers;
    mapping (address => State) public receiversState;

    // Message
    bytes32 public messageHash;
    string public message;
    // Time limit (in seconds)
    // See units: http://solidity.readthedocs.io/en/develop/units-and-global-variables.html?highlight=timestamp#time-units
    uint public term1; 
    uint public term2; 
    // Start time
    uint public start; 

    constructor (address[] _receivers, bytes32 _messageHash, uint _term1, uint _term2) public payable {
        // Requires that the sender send a deposit of minimum 1 wei (>0 wei)
        require(msg.value>0, "Sender has to send a deposit of minimun 1 wei"); 
        sender = msg.sender;
        receivers = _receivers;
        // We set the state of every receiver to 'created'
        for (uint i = 0; i<receivers.length; i++) {
            receiversState[receivers[i]] = State.created;
        }
        messageHash = _messageHash;
        start = now; // now = block.timestamp
        term1 = _term1;
        term2 = _term2;
    }

    function accept() public {
        require(now < start+term1, "The timeout term1 has been reached");
        require(receiversState[msg.sender]==State.created, "Only receivers with 'created' state can accept");

        receiversState[msg.sender] = State.accepted;
    }

    function finish(string _message) public {
        require(now >= start+term1, "The timeout term1 has not been reached");
        require (msg.sender==sender, "Only sender of the notification can finish");
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

    function cancel() public {
        require(now >= start+term2, "The timeout term2 has not been reached");
        require(receiversState[msg.sender]==State.accepted, "Only receivers with 'accepted' state can cancel");

        receiversState[msg.sender] = State.cancelled;
    }

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