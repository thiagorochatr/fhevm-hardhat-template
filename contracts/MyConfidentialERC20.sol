// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";
// import "fhevm-contracts/contracts/token/ERC20/extensions/ConfidentialERC20Mintable.sol";

contract MyConfidentialERC20 is SepoliaZamaFHEVMConfig {
    euint64 private _number;
    euint64 private _sum;

    constructor(uint64 number_) {
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
    }
}
