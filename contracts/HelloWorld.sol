// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract HelloWorld {

string public message ;

constructor(){
    message = "hello world";
}

function setMessage(string memory _message) public{
    message = _message;
}

function getMessage() public view returns (string memory) {
    return message;

}

}