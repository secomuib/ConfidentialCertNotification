pragma solidity ^0.4.11;

contract ExampleContract {
    string public message;

    constructor(string _message) public {
        message = _message;
    }
}
