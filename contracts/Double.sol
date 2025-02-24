// SPDX-License-Identifier: BSD-3-Clause-Clear

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";

pragma solidity ^0.8.24;

contract Double is SepoliaZamaFHEVMConfig {
    euint256 private _number;
    euint256 private _double;

    function setNumber(uint256 number_) public {
        _number = TFHE.asEuint256(number_);
        TFHE.allowThis(_number);
    }

    function getNumber() public view returns (euint256) {
        return _number;
    }

    function getDoubleNumber() public view returns (euint256) {
        return _double;
    }

    function doubleNumber() public {
        _double = TFHE.mul(_number, 2);
        TFHE.allowThis(_double);
    }
}
