// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IReferralStorage.sol";

contract ReferralReader {
    function getCodeOwners(IReferralStorage _referralStorage, bytes32[] memory _codes) public view returns (address[] memory) {
        address[] memory owners = new address[](_codes.length);

        for (uint256 i = 0; i < _codes.length; i++) {
            bytes32 code = _codes[i];
            owners[i] = _referralStorage.codeOwners(code);
        }

        return owners;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);

    function getTraderReferralInfo(address _account)
        external
        view
        returns (bytes32, address);

    function setTraderReferralCode(address _account, bytes32 _code) external;

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external;

    function setReferrerTier(address _referrer, uint256 _tierId) external;

    function govSetCodeOwner(bytes32 _code, address _newAccount) external;

    function setMinReward(uint256 _min) external;

    function setMarginFee(uint256 _fee) external;

    function setTokenReward(address _token) external;

    function withdrawnToken(address _token, address _to, uint256 _amount) external;

    function removeRebate(address _user) external;

    function addReward(address _account, uint256 _sizeDelta) external;

    function getTokenReward() external view returns (address);

    function depositPending() external view returns (uint256);

    function deposit(uint256 _amount) external;
}