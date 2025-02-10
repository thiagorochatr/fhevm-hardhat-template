// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";
// import "fhevm-contracts/contracts/token/ERC20/extensions/ConfidentialERC20Mintable.sol";

/// @notice This contract implements an encrypted ERC20-like token with confidential balances using Zama's FHE library.
/// @dev It supports typical ERC20 functionality such as transferring tokens, minting, and setting allowances,
/// @dev but uses encrypted data types.
contract MyConfidentialERC20 is SepoliaZamaFHEVMConfig {
    euint64 _number;

    constructor(uint64 number_) {
        _number = TFHE.asEuint64(number_);
    }

    function number() public view returns (euint64) {
        return _number;
    }
}
