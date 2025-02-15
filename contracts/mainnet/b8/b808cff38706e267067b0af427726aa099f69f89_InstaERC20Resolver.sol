/**
 *Submitted for verification at BscScan.com on 2022-12-21
*/

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

contract Resolver {
    struct TokenData {
        bool isToken;
        string name;
        string symbol;
        uint256 decimals;
    }

    function getTokenDetails(address[] memory tknAddress) public view returns (TokenData[] memory) {
        TokenData[] memory tokenDatas = new TokenData[](tknAddress.length);
        for (uint256 i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokenDatas[i] = TokenData(true, "ETHER", "ETH", 18);
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                bool isToken = true;

                try token.symbol() {} catch {
                    isToken = false;
                    continue;
                }

                try token.name() {} catch {
                    isToken = false;
                    continue;
                }

                try token.decimals() {} catch {
                    isToken = false;
                    continue;
                }

                tokenDatas[i] = TokenData(true, token.name(), token.symbol(), token.decimals());
            }
        }
        return tokenDatas;
    }

    struct BalanceData {
        address owner;
        address[] tokens;
    }

    struct BalanceReturnData {
        address owner;
        uint256[] balances;
    }

    function getBalancesOfOwnersWithTokens(BalanceData[] memory datas)
        public
        view
        returns (BalanceReturnData[] memory)
    {
        BalanceReturnData[] memory balanceReturnData = new BalanceReturnData[](datas.length);
        for (uint256 i = 0; i < datas.length; i++) {
            balanceReturnData[i].owner = datas[i].owner;
            balanceReturnData[i].balances = getBalances(datas[i].owner, datas[i].tokens);
        }
        return balanceReturnData;
    }

    function getBalancesOfOwners(address[] memory owners, address[] memory tokens)
        public
        view
        returns (BalanceReturnData[] memory)
    {
        BalanceReturnData[] memory balanceReturnData = new BalanceReturnData[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balanceReturnData[i].owner = owners[i];
            balanceReturnData[i].balances = getBalances(owners[i], tokens);
        }
        return balanceReturnData;
    }

    function getBalances(address owner, address[] memory tknAddress) public view returns (uint256[] memory) {
        uint256[] memory tokensBal = new uint256[](tknAddress.length);
        for (uint256 i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokensBal[i] = owner.balance;
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                tokensBal[i] = token.balanceOf(owner);
            }
        }
        return tokensBal;
    }

    function getAllowances(
        address owner,
        address spender,
        address[] memory tknAddress
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenAllowances = new uint256[](tknAddress.length);
        for (uint256 i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokenAllowances[i] = 0;
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                tokenAllowances[i] = token.allowance(owner, spender);
            }
        }
        return tokenAllowances;
    }
}

contract InstaERC20Resolver is Resolver {
    string public constant name = "ERC20-Resolver-v1.2";
}