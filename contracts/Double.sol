// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

contract Double {
    uint256 _number;
    uint256 _double;

    function setNumber(uint256 number_) public {
        _number = number_;
    }

    function getNumber() public view returns (uint256) {
        return _number;
    }

    function getDoubleNumber() public view returns (uint256) {
        return _double;
    }

    function doubleNumber() public {
        _double = _number * 2;
    }
}
