// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { SepoliaZamaFHEVMConfig } from "fhevm/config/ZamaFHEVMConfig.sol";
import { GatewayCaller, Gateway } from "fhevm/gateway/GatewayCaller.sol";
import { SepoliaZamaGatewayConfig } from "fhevm/config/ZamaGatewayConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVotingSystem } from "./interfaces/IVotingSystem.sol";
import { IdentityManager } from "./IdentityManager.sol";

contract VotingSystem is
    IVotingSystem,
    IdentityManager,
    SepoliaZamaFHEVMConfig,
    SepoliaZamaGatewayConfig,
    GatewayCaller,
    Ownable
{
    euint64 private _number;
    euint64 private _sum;
    uint64 public _numberDecrypted;
    constructor(uint64 number_, address[] memory allowedVoters) IdentityManager(allowedVoters) Ownable(msg.sender) {
        _number = TFHE.asEuint64(number_);
        TFHE.allowThis(_number); // Permite o contrato acessar o valor criptografado
    }

    function number() public view returns (euint64) {
        return _number;
    }

    function getDoubleNumber() public view returns (euint64) {
        return _sum;
    }

    function doubleNumber() public {
        _sum = TFHE.add(_number, _number);
        TFHE.allowThis(_sum); // Permite acesso ao resultado da soma
        bytes32 voterId = verifyProofAndGetVoterId();
        emit VoteCasted(voterId);
    }

    function requestUint64(uint64 input1) public {
        // @note input1 é como se fosse um index, por exemplo _votes[input1], pega o vote do index input1
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(_sum);
        uint256 requestID = Gateway.requestDecryption(
            cts,
            this.callbackUint64.selector,
            0,
            block.timestamp + 100,
            false
        );
        addParamsUint256(requestID, input1);
    }

    function callbackUint64(uint256 requestID, uint64 decryptedInput) public onlyGateway returns (uint64) {
        uint256[] memory params = getParamsUint256(requestID);
        unchecked {
            uint64 result = decryptedInput;
            _numberDecrypted = result;
            return result;
        }
    }
}
