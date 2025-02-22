const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("Supreme Bank Token", function () {
  const NAME = "Supreme Bank Digital Currency";
  const SYMBOL = "SBDC";
  const DECIMALS = 6;
  const TOTAL_SUPPLY_DECIMAL = "0".repeat(DECIMALS);
  const INITIAL_TOTAL_SUPPLY = "1000000000000".concat(TOTAL_SUPPLY_DECIMAL);

  const MINTED_TOKENS = "5".concat(TOTAL_SUPPLY_DECIMAL);
  const TOKENS_AFTER_MINT = "1000000000005".concat(TOTAL_SUPPLY_DECIMAL);

  const DEFAULT_ADMIN_ROLE =
    "0x0000000000000000000000000000000000000000000000000000000000000000";
  const SUPREME_ROLE = ethers.utils.id("SUPREME_ROLE");
  const BURNER_ROLE = ethers.utils.id("BURNER_ROLE");
  const MINTER_ROLE = ethers.utils.id("MINTER_ROLE");
  const AML_ROLE = ethers.utils.id("AML_ROLE");
  const ROLE = ethers.utils.id("ROLE");

  let token, admin, leader, accountOne;

  before(async () => {
    [admin, leader, accountOne] = await ethers.getSigners();

    const CBToken = await ethers.getContractFactory("CBToken");
    token = await CBToken.deploy(NAME, SYMBOL, DECIMALS);
    // Set the supreme leader
    await token.setLeader(leader.address);
    expect(await token.hasRole(SUPREME_ROLE, leader.address)).to.equal(true);

    await token.deployed();
  });

  describe("Deployment", async () => {
    it("Should set the correct admin", async () => {
      expect(await token.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.equal(
        true
      );
      expect(
        await token.hasRole(DEFAULT_ADMIN_ROLE, accountOne.address)
      ).to.equal(false);
    });

    it("Should return the correct number of decimals", async () => {
      expect(await token.decimals()).to.equal(DECIMALS);
    });

    it("Should return the correct total supply", async () => {
      expect(await token.totalSupply()).to.equal(INITIAL_TOTAL_SUPPLY);
    });
  });

  describe("Minting", async () => {
    it("Should allow accounts with the minter role to mint tokens", async () => {
      expect(await token.totalSupply()).to.equal(INITIAL_TOTAL_SUPPLY);
      expect(await token.balanceOf(admin.address)).to.equal(
        INITIAL_TOTAL_SUPPLY
      );
      expect(await token.balanceOf(accountOne.address)).to.equal(0);

      expect(await token.hasRole(MINTER_ROLE, admin.address)).to.equal(true);

      await token.mint(accountOne.address, MINTED_TOKENS);

      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);
      expect(await token.balanceOf(admin.address)).to.equal(
        INITIAL_TOTAL_SUPPLY
      );
      expect(await token.balanceOf(accountOne.address)).to.equal(MINTED_TOKENS);
    });

    it("Should not allow other addresses to mint more tokens", async () => {
      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);

      expect(await token.hasRole(MINTER_ROLE, accountOne.address)).to.equal(
        false
      );

      await expect(
        token.connect(accountOne).mint(accountOne.address, MINTED_TOKENS)
      ).to.be.revertedWith(
        `AccessControl: account ${accountOne.address.toLowerCase()} is missing role ${MINTER_ROLE}`
      );

      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);
    });
  });

  describe("Burning", async () => {
    it("Should allow accounts with the burner role to burn tokens", async () => {
      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);
      expect(await token.balanceOf(admin.address)).to.equal(
        INITIAL_TOTAL_SUPPLY
      );
      expect(await token.balanceOf(accountOne.address)).to.equal(MINTED_TOKENS);

      expect(await token.hasRole(BURNER_ROLE, admin.address)).to.equal(true);

      await token.connect(admin).burn(accountOne.address, MINTED_TOKENS);

      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);
      expect(await token.balanceOf(admin.address)).to.equal(
        INITIAL_TOTAL_SUPPLY
      );
      // Burned tokens are spawned to the supreme leader address!
      expect(await token.balanceOf(leader.address)).to.equal(MINTED_TOKENS);
      expect(await token.balanceOf(accountOne.address)).to.equal(0);
    });

    it("Should not allow others to burn tokens", async () => {
      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);

      expect(await token.hasRole(BURNER_ROLE, accountOne.address)).to.equal(
        false
      );

      await expect(
        token.connect(accountOne).burn(admin.address, MINTED_TOKENS)
      ).to.be.revertedWith(
        `AccessControl: account ${accountOne.address.toLowerCase()} is missing role ${BURNER_ROLE}`
      );
      await expect(
        token.connect(accountOne).burn(accountOne.address, MINTED_TOKENS)
      ).to.be.revertedWith(
        `AccessControl: account ${accountOne.address.toLowerCase()} is missing role ${BURNER_ROLE}`
      );

      expect(await token.totalSupply()).to.equal(TOKENS_AFTER_MINT);
    });
  });

  describe("Cheating", async () => {
    it("should return the correct total supply to leaders only", async () => {
      expect(await token.hasRole(SUPREME_ROLE, leader.address)).to.equal(true);
      const totalSupplyLeader = await token.totalSupply();
      const totalSupplyAdmin = await token.connect(admin).totalSupply();
      const totalSupplyUser = await token.connect(accountOne).totalSupply();
      expect(totalSupplyLeader).to.equal(totalSupplyAdmin);
      expect(totalSupplyLeader).to.be.greaterThan(totalSupplyUser);
    });
  });

  describe("RBAC", async () => {
    afterEach(async () => {
      await token.connect(admin).revokeRole(ROLE, admin.address);
      await token.connect(admin).revokeRole(ROLE, accountOne.address);
    });

    it("should give the deployer the default admin role", async () => {
      expect(await token.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.equal(
        true
      );
    });

    it("should allow admins to grant roles", async () => {
      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(false);
      await token.connect(admin).grantRole(ROLE, accountOne.address);
      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(true);
    });

    it("should not allow admins to update leader!", async () => {
      expect(await token.hasRole(AML_ROLE, admin.address)).to.equal(true);

      const currentLeader = await token.leaderAddress();

      await expect(
        token.connect(admin).setLeader(accountOne.address)
      ).to.be.revertedWith("Leader already set");
      const newLeader = await token.leaderAddress();
      expect(newLeader).to.equal(currentLeader);
    });

    it("should not allow non-admins to update leader!", async () => {
      const currentLeader = await token.leaderAddress();

      await expect(
        token.connect(accountOne).setLeader(accountOne.address)
      ).to.be.revertedWith(
        `AccessControl: account ${accountOne.address.toLowerCase()} is missing role ${AML_ROLE}`
      );

      const newLeader = await token.leaderAddress();
      expect(newLeader).to.equal(currentLeader);
    });

    it("should not allow non-admins to grant roles", async () => {
      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(false);
      await expect(
        token.connect(accountOne).grantRole(ROLE, accountOne.address)
      ).to.be.revertedWith(
        `AccessControl: account ${accountOne.address.toLowerCase()} is missing role ${DEFAULT_ADMIN_ROLE}`
      );
      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(false);
    });

    it("should allow admin to revoke roles", async () => {
      await token.connect(admin).grantRole(ROLE, accountOne.address);

      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(true);
      await token.connect(admin).revokeRole(ROLE, accountOne.address);
      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(false);
    });

    it("should not allow non-admins to revoke roles", async () => {
      await token.connect(admin).grantRole(ROLE, accountOne.address);

      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(true);
      await expect(
        token.connect(accountOne).revokeRole(ROLE, accountOne.address)
      ).to.be.revertedWith(
        `AccessControl: account ${accountOne.address.toLowerCase()} is missing role ${DEFAULT_ADMIN_ROLE}`
      );
      expect(await token.hasRole(ROLE, accountOne.address)).to.equal(true);
    });
  });
});
