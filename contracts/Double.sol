// SPDX-License-Identifier: BSD-3-Clause-Clear

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";
import { GatewayCaller, Gateway } from "fhevm/gateway/GatewayCaller.sol";
import { SepoliaZamaGatewayConfig } from "fhevm/config/ZamaGatewayConfig.sol";

pragma solidity ^0.8.24;

contract Double is SepoliaZamaFHEVMConfig, SepoliaZamaGatewayConfig, GatewayCaller {
    euint256 private _number;
    euint256 private _double;
    uint256 public _numberDecrypted;

    function setNumber(einput encryptedSupport, bytes calldata supportProof) public {
        euint256 encryptedNumber = TFHE.asEuint256(encryptedSupport, supportProof);
        _number = encryptedNumber;
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

    function requestDecryptNumber() public {
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(_double);
        uint256 requestID = Gateway.requestDecryption( // não estamos usando o requestID por enquanto
                cts,
                this.callbackUint256.selector,
                0,
                block.timestamp + 100,
                false
            );
    }

    function callbackUint256(uint256 /*requestID*/, uint256 decryptedInput) public onlyGateway returns (uint256) {
        _numberDecrypted = decryptedInput;
        return _numberDecrypted;
    }
}
