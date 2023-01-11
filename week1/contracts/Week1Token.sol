// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Week1Token is ERC20 {

    address public god;
    uint256 public maxSupply = 1000000;
    
    mapping(address => uint256) public balances;
    mapping(address => bool) public blacklist;

    modifier isGod() {
        require(
            msg.sender == god,
            "You are not god"
        );
        _;
    }

    modifier validAddress(address rec) {
        require(
            rec != address(0),
            "Invalid address supplied"
        );
        _;
    }

    modifier notBlacklisted() {
        // stop blacklisted address even when using a contract
        require(
            blacklist[msg.sender] == false && blacklist[tx.origin] == false,
            "You are blacklisted" 
        );
        _;
    }

    constructor(address _godsAddress) ERC20("Week1Token", "WK1TOK") {
        god = _godsAddress;
    }

    // overrides for balances, so God can set balances
    function balanceOf(address _add) public view override returns (uint256) {
        return balances[_add];
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }

    // task 1 functions
    function mintTokensToAddress(address recipient, uint256 _amount) public isGod() validAddress(recipient) {
        _mint(recipient, _amount);
    }

    function changeBalanceAtAddress(address target, uint256 _newBalance) public isGod() validAddress(target) {
        balances[target] = _newBalance;
    }

    function authoritativeTransferFrom(address _from, address _to, uint256 _amount) public isGod() validAddress(_from) validAddress(_to) {
        _transfer(_from, _to, _amount);
    }


    // task 2 functions
    function sanctionAddress(address _add, bool _blacklsited) public isGod() validAddress(_add) {
        blacklist[_add] = _blacklsited;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override notBlacklisted() {
        super._beforeTokenTransfer(_from, _to, _amount);
    }


    // task 3 functions
    // decimals already set to 18 
    function mintThousand() public payable {
        require(
            msg.value == 1 ether,
            "1 ether required"
        );
        require(
            (totalSupply() + 1000) <= maxSupply,
            "Only 1 million tokens allowed" 
        );
        _mint(msg.sender, 1000);
    }

    // adding an override of the transfer function
    // as the _balances mapping is private and can't be updated
    // by the god user
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[from] = fromBalance - amount;
            balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function withdraw(address _to) public isGod() {
        // allows god to withdraw to any address
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(
            sent,
            "Unable to send refund"
        );
    }

    function sellBack(uint256 _amount) public {
        require (
            balances[msg.sender] >= _amount,
            "You don't have enough tokens"
        );
        require (
            _amount % 1000 == 0,
            "Not a multiple of 1000"
        );
        uint256 chunks = _amount/1000;
        uint256 amountToSend = chunks * 0.5 ether;
        require (
            address(this).balance >= amountToSend,
            "Not enough ether to send you"
        );

        // from what I can tell, we have to maintain our own balances mapping
        // as the _balances mapping provided by ERC20 is private, so the
        // god address couldn't update it

        // in this case, can't we just update the balances mapping
        // rather than using any transfer() function?

        balances[address(this)] += _amount;
        balances[msg.sender] -= _amount;

        (bool sent, ) = address(msg.sender).call{value: amountToSend}("");
        require(
            sent,
            "Unable to send refund"
        );
        
    }

    receive() external payable {}
}