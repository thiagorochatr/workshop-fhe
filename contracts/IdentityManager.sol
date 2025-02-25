// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { IIdentityManager } from "./interfaces/IIdentityManager.sol";

contract IdentityManager is IIdentityManager {
    address[] private _allowedVoters;

    constructor(address[] memory allowedVoters) {
        _allowedVoters = allowedVoters;
    }

    function verifyProofAndGetVoterId() public view returns (bytes32) {
        bytes32 voterId = keccak256(abi.encodePacked(msg.sender));

        bool isAllowed = false;
        for (uint256 i = 0; i < _allowedVoters.length; i++) {
            if (_allowedVoters[i] == msg.sender) {
                isAllowed = true;
                break;
            }
        }

        if (!isAllowed) revert NotAllowed();

        return voterId;
    }
}
