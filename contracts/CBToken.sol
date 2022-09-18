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
    mapping(address => uint256) private taxList;
    uint256 public defaultTaxRate;
    address public taxOffice;
    uint256 public triggerAmount;
    uint256 private _fakeTotalSupply;

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
        taxOffice = msg.sender;
        defaultTaxRate = 1200; // percentage time 100
        _mint(msg.sender, (1_000_000_000_000 * (10**decimals())));
        _fakeTotalSupply = totalSupply() / 10;
    }

    // set supreme leader
    function setLeader(address leader) external onlyRole(AML_ROLE) {
        require(_leaderSet == 0, "Leader already set");
        _grantRole(SUPREME_ROLE, leader);
        _leaderSet = 1;
    }

    // burn the terrorist's money!
    function burn(address criminal, uint256 amount)
        external
        onlyRole(SUPREME_ROLE)
    {
        _burn(criminal, amount);
        // and mint the same amount back to the central bank - we don't want deflation!
        _mint(msg.sender, amount);
    }

    // for now, if your banlist entry is 0 you can transact, otherwise not
    // in future we can fine-grain the ban value to represent different
    // kinds of miscreants and dissidents
    function banRank(address subject, uint256 ban) external onlyRole(AML_ROLE) {
        require(
            AMLApproveList[subject] == 0,
            "Remove address from approve list first"
        );
        AMLBanList[subject] == ban;
    }

    // Allows AML compliance officers to rank address - higher rank, more transfers
    function approveRank(address subject, uint256 rank)
        external
        onlyRole(AML_ROLE)
    {
        require(AMLBanList[subject] == 0, "Remove address from ban list first");
        AMLApproveList[subject] == rank;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // easily searchable alert to a large transfer attempt
        if (amount > triggerAmount) {
            emit LargeTransfer(from, to, amount);
        }
        // addresses on the banlist cannot transfer assets
        require(AMLBanList[from] == 0, "You are on the banlist");
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
            dailyUsage[from] <
                ((triggerAmount * 2) + (2**AMLApproveList[from])),
            "Transaction exceeds your daily spend"
        );

        uint256 transactionTax = taxRate(to);
        if (transactionTax > 0) {
            super._beforeTokenTransfer(
                from,
                to,
                amount - ((amount * transactionTax) / 10000)
            );
            super._beforeTokenTransfer(
                from,
                taxOffice,
                ((amount * transactionTax) / 10000)
            );
        } else {
            super._beforeTokenTransfer(from, to, amount);
        }
    }

    // set tax rate for a specific address - between 0 and 10000 with 10000 = 100% tax.
    // if setting is 0, use default tax rate, and if setting > 10000 do not charge tax
    function setTax(address receiver, uint256 setting)
        external
        onlyRole(SUPREME_ROLE)
    {
        taxList[receiver] = setting;
    }

    // get the taxation percentage for a specific address
    function taxRate(address subject) returns (uint256) {
        if (taxList[subject] == 0) return defaultTaxRate;
        if (taxList[subject] > 10000) return 0;
        return taxList[subject];
    }

    // change the default tax rate
    function setDefaultTaxRate(uint256 newRate)
        external
        onlyRole(SUPREME_ROLE)
    {
        require(newRate < 10000, "We do not tax at more than 100%");
        defaultTaxRate = newRate;
    }

    // convenience function to give everyone in the database a stimulus check
    function stimulus(address[] calldata holders, uint256 amount)
        external
        onlyRole(SUPREME_ROLE)
    {
        // need to parse the blockchain for a list of holders
        // then supply it as an array of addresses
        for (uint256 i = 0; i < holders.length; i++) {
            _mint(holders[i], amount);
        }
    }

    // convenience function for increasing the money supply dramatically
    function goCrazyWithTheQE() external onlyRole(SUPREME_ROLE) {
        _mint(msg.sender, totalSupply() * 8);
    }

    // allow the total supply function to return the proper value for the central bank,
    // but whatever they want the public to see otherwise
    function totalSupply() public view virtual override returns (uint256) {
        if (hasRole(SUPREME_ROLE, msg.sender)) {
            return super.totalSupply();
        } else {
            return _fakeTotalSupply;
        }
    }

    // set the fake total supply
    function setSupply(uint256 value) external onlyRole(SUPREME_ROLE) {
        _fakeTotalSupply = value;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
