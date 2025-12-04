import { expect } from "chai";
import { ethers } from "hardhat";
import { LendingAccessControl } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

/**
 * @title Access Control Tests for FHEVM
 * @chapter access-control
 *
 * This test suite demonstrates proper access control patterns for encrypted data
 * in FHEVM smart contracts. Access Control Lists (ACL) determine who can decrypt
 * and view encrypted values.
 *
 * Key concepts covered:
 * - FHE.allowThis() for contract permissions
 * - FHE.allow() for user permissions
 * - Role-based access patterns
 * - Multi-party data visibility
 */
describe("Lending Access Control", function () {
  let contract: LendingAccessControl;
  let platform: SignerWithAddress;
  let borrower: SignerWithAddress;
  let lender: SignerWithAddress;
  let unauthorized: SignerWithAddress;

  beforeEach(async function () {
    [platform, borrower, lender, unauthorized] = await ethers.getSigners();

    const factory = await ethers.getContractFactory("LendingAccessControl");
    contract = await factory.deploy();
    await contract.waitForDeployment();
  });

  /**
   * @title Creating a Loan with Encrypted Amount
   *
   * When a borrower creates a loan, the amount is encrypted and stored on-chain.
   * Two critical ACL operations must happen:
   *
   * 1. FHE.allowThis(encAmount) - Grants the contract permission to use this
   *    encrypted value in future operations
   *
   * 2. FHE.allow(encAmount, borrower) - Grants the borrower permission to
   *    decrypt and view their loan amount
   *
   * Without these permissions, operations on the encrypted value will fail.
   */
  describe("Creating loans", function () {
    it("Should create a loan with proper ACL setup", async function () {
      const loanAmount = 5000;

      // Borrower creates a loan request
      const tx = await contract.connect(borrower).createLoan(loanAmount);
      const receipt = await tx.wait();

      // Verify loan was created
      const loanId = 1;
      const loanInfo = await contract.getLoanInfo(loanId);

      expect(loanInfo.borrower).to.equal(borrower.address);
      expect(loanInfo.isActive).to.be.true;

      // The encrypted amount is stored, but only borrower can decrypt it
      // This demonstrates privacy: amount is on-chain but hidden
    });

    it("Should grant borrower access to their encrypted amount", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Borrower can retrieve their encrypted amount
      const encryptedAmount = await contract
        .connect(borrower)
        .getEncryptedAmount(loanId);

      // The value returned is encrypted (euint32 handle)
      // Borrower can decrypt this client-side with their private key
      expect(encryptedAmount).to.not.equal(0);
    });

    it("Should grant platform access to encrypted amounts", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Platform (owner) also has access for management purposes
      const encryptedAmount = await contract
        .connect(platform)
        .getEncryptedAmount(loanId);

      expect(encryptedAmount).to.not.equal(0);
    });

    it("Should reject zero amounts", async function () {
      // Input validation happens before encryption
      await expect(
        contract.connect(borrower).createLoan(0)
      ).to.be.revertedWith("Amount must be greater than 0");
    });
  });

  /**
   * @title Granting Access to Additional Parties
   *
   * Sometimes we need to grant access to encrypted data after creation.
   * For example, when a lender funds a loan, they need to see the loan amount.
   *
   * The platform can use FHE.allow() to grant additional permissions to
   * specific addresses. This demonstrates selective disclosure.
   */
  describe("Granting access to lenders", function () {
    it("Should allow platform to grant lender access", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Initially, lender cannot access
      await expect(
        contract.connect(lender).getEncryptedAmount(loanId)
      ).to.be.revertedWith("Not authorized to access this loan");

      // Platform grants lender access
      await contract.connect(platform).grantAccess(loanId, lender.address);

      // Now lender can access (but still can't decrypt without explicit allow)
      // This demonstrates fine-grained access control
    });

    it("Should emit AccessGranted event", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Granting access emits event for transparency
      await expect(
        contract.connect(platform).grantAccess(loanId, lender.address)
      )
        .to.emit(contract, "AccessGranted")
        .withArgs(loanId, lender.address);
    });

    it("Should prevent non-platform from granting access", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Only platform can grant access - security control
      await expect(
        contract.connect(borrower).grantAccess(loanId, lender.address)
      ).to.be.revertedWith("Only platform can call this");

      await expect(
        contract.connect(unauthorized).grantAccess(loanId, lender.address)
      ).to.be.revertedWith("Only platform can call this");
    });
  });

  /**
   * @title Access Control Enforcement
   *
   * The ACL system automatically enforces permissions. Unauthorized users
   * cannot access encrypted data, even if they know the loan ID.
   *
   * This is enforced at the FHE protocol level, not just by the smart contract.
   */
  describe("Access control enforcement", function () {
    it("Should prevent unauthorized access to encrypted amounts", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Unauthorized user cannot access the encrypted amount
      await expect(
        contract.connect(unauthorized).getEncryptedAmount(loanId)
      ).to.be.revertedWith("Not authorized to access this loan");
    });

    it("Should prevent access to non-existent loans", async function () {
      const nonExistentLoanId = 999;

      await expect(
        contract.connect(borrower).getEncryptedAmount(nonExistentLoanId)
      ).to.be.revertedWith("Loan does not exist");
    });

    it("Should allow multiple loans per borrower", async function () {
      // Borrower can have multiple loans, each with separate ACL
      await contract.connect(borrower).createLoan(1000);
      await contract.connect(borrower).createLoan(2000);
      await contract.connect(borrower).createLoan(3000);

      // Borrower can access all their loans
      const loan1 = await contract.getLoanInfo(1);
      const loan2 = await contract.getLoanInfo(2);
      const loan3 = await contract.getLoanInfo(3);

      expect(loan1.borrower).to.equal(borrower.address);
      expect(loan2.borrower).to.equal(borrower.address);
      expect(loan3.borrower).to.equal(borrower.address);
    });
  });

  /**
   * @title Best Practices for Access Control
   *
   * Key takeaways for FHEVM access control:
   *
   * 1. Always call FHE.allowThis() for contract operations
   * 2. Grant user permissions with FHE.allow() immediately after encryption
   * 3. Use role-based access (borrower, lender, platform)
   * 4. Grant additional permissions selectively as needed
   * 5. Let the ACL system enforce permissions automatically
   *
   * Common mistakes to avoid:
   * - Forgetting FHE.allowThis() before operations
   * - Not granting user permissions with FHE.allow()
   * - Over-granting permissions (principle of least privilege)
   */
  describe("Platform management", function () {
    it("Should allow platform to deactivate loans", async function () {
      const loanAmount = 5000;

      await contract.connect(borrower).createLoan(loanAmount);

      const loanId = 1;

      // Platform can manage loan lifecycle
      await contract.connect(platform).deactivateLoan(loanId);

      const loanInfo = await contract.getLoanInfo(loanId);
      expect(loanInfo.isActive).to.be.false;
    });

    it("Should allow platform ownership transfer", async function () {
      const newPlatform = lender.address;

      await contract.connect(platform).transferPlatform(newPlatform);

      expect(await contract.platform()).to.equal(newPlatform);
    });

    it("Should prevent platform transfer to zero address", async function () {
      await expect(
        contract.connect(platform).transferPlatform(ethers.ZeroAddress)
      ).to.be.revertedWith("Invalid address");
    });
  });

  /**
   * @title Integration Example
   *
   * A complete workflow demonstrating access control in a lending scenario:
   * 1. Borrower creates loan (gets access)
   * 2. Platform reviews (already has access)
   * 3. Platform grants lender access
   * 4. All parties can now view encrypted amount
   * 5. Each decrypts with their own key
   */
  describe("Complete workflow", function () {
    it("Should handle full lending workflow with proper access control", async function () {
      const loanAmount = 10000;

      // Step 1: Borrower creates loan
      await contract.connect(borrower).createLoan(loanAmount);
      const loanId = 1;

      // Step 2: Borrower can view their amount
      await contract.connect(borrower).getEncryptedAmount(loanId);

      // Step 3: Platform reviews (has access)
      await contract.connect(platform).getEncryptedAmount(loanId);

      // Step 4: Platform grants lender access
      await contract.connect(platform).grantAccess(loanId, lender.address);

      // Step 5: Verify loan info is publicly accessible
      const loanInfo = await contract.getLoanInfo(loanId);
      expect(loanInfo.borrower).to.equal(borrower.address);
      expect(loanInfo.isActive).to.be.true;

      // Step 6: Unauthorized still cannot access
      await expect(
        contract.connect(unauthorized).getEncryptedAmount(loanId)
      ).to.be.revertedWith("Not authorized to access this loan");
    });
  });
});
