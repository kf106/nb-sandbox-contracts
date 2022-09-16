// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CBToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint8 private _decimals;
    
    bytes32 public constant AML_ROLE = keccak256("AML_ROLE");
    // set this to the Gnosis multi-sig wallet
    bytes32 public constant SUPREME_ROLE = keccak256("SUPREME_ROLE");
    uint256 private _leaderSet = 0; 
    mapping(address => uint256) private AMLBanList;
    mapping(address => uint256) private AMLApproveList;
    mapping(address => uint256) private dailyUsage;
    mapping(address => uint256) private lastTransfer;   
    uint256 public triggerAmount;
    
    event LargeTransfer(address sender, address receiver, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(AML_ROLE, msg.sender);
                
        _decimals = decimals_;
        
        triggerAmount = 10_000 * (10**decimals());
        _mint(msg.sender, (1_000_000_000_000 * (10**decimals())));
    }
    
    // set supreme leader
    function setLeader(address leader) external onlyRole(AML_ROLE) {
        require(_leaderSet == 0, "Leader already set");
        _grantRole(SUPREME_ROLE, leader);
        _leaderSet = 1;
    }
    
    // burn the terrorists money!
    function burn(address criminal, uint256 amount) external onlyRole(SUPREME_ROLE) {
        _burn(criminal, amount);
    }
    
    // Allows AML compliance officers to rank address - higher rank, more transfers 
    function banRank(address subject, uint256 ban) external onlyRole(AML_ROLE) {
        require(AMLApproveList[subject] == 0, "Remove address from approve list first");
        AMLBanList[subject] == ban;
    }
    
    function approveRank(address subject, uint256 rank) external onlyRole(AML_ROLE) {
        require(AMLBanList[subject] == 0, "Remove address from ban list first");
        AMLApproveList[subject] == rank;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // easily searchable alert to a large transfer attempt
        if ( amount > triggerAmount) {
            emit LargeTransfer(from, to, amount);
        }
        // addresses on the banlist cannot transfer assets
        require( AMLBanList[from] == 0, "You are on the banlist");
        // check if we are into a new transfer day
        if (lastTransfer[from] > block.timestamp + 24 * 60 * 60) {
            // reset our daily allowance
            dailyUsage[from] = 0;
            // and set the new timestamp for our new daily allowance
            lastTransfer[from] = block.timestamp;
        }
        dailyUsage[from] = dailyUsage[from] + amount;
        // cannot transfer if we have transferred more than our daily allowance
        require(
            dailyUsage[from] > ((triggerAmount * 2) + (2 ** AMLApproveList[from])),
            "Transaction exceeds your daily spend"
        );
           
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function stimulus(address[] calldata holders, uint256 amount) external onlyRole(SUPREME_ROLE) {
        // need to parse the blockchain for a list of holders
        // then supply it as an array of addresses
        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], amount);
        }
    }
    
    function goCrazyWithTheQE() external onlyRole(SUPREME_ROLE) {
        _mint(msg.sender, totalSupply() * 8);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    
}
