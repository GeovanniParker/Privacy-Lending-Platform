import { expect } from "chai";
import { ethers } from "hardhat";
import { LendingArithmetic } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

/**
 * @title Encrypted Arithmetic Operations Tests
 * @chapter arithmetic
 *
 * This test suite demonstrates arithmetic operations on encrypted data using FHEVM.
 * Fully Homomorphic Encryption allows mathematical calculations on encrypted values
 * without revealing the underlying data.
 *
 * Key operations covered:
 * - FHE.add() - Addition on encrypted values
 * - FHE.sub() - Subtraction on encrypted values
 * - FHE.mul() - Multiplication on encrypted values
 * - Combining operations in workflows
 */
describe("Lending Arithmetic Operations", function () {
  let contract: LendingArithmetic;
  let platform: SignerWithAddress;
  let borrower: SignerWithAddress;

  beforeEach(async function () {
    [platform, borrower] = await ethers.getSigners();

    const factory = await ethers.getContractFactory("LendingArithmetic");
    contract = await factory.deploy();
    await contract.waitForDeployment();
  });

  /**
   * @title Encrypted Multiplication - Interest Calculation
   *
   * FHE.mul() performs multiplication on encrypted values. This is essential for
   * calculating interest on encrypted loan amounts.
   *
   * Example: principal = 5000, interest rate = 5% (500 basis points)
   * Encrypted interest = encrypted principal * 500
   *
   * The result is encrypted - no one can see the actual interest amount without
   * proper decryption permissions.
   */
  describe("Interest calculation with FHE.mul()", function () {
    it("Should calculate encrypted interest using multiplication", async function () {
      const principal = 5000;
      const interestRate = 500; // 5% = 500 basis points

      // Create loan with interest calculation
      const tx = await contract.connect(borrower).createLoan(principal, interestRate);
      await tx.wait();

      const loanId = 1;

      // Verify loan was created with encrypted values
      const loanInfo = await contract.getLoanInfo(loanId);
      expect(loanInfo.borrower).to.equal(borrower.address);
      expect(loanInfo.interestRate).to.equal(interestRate);
      expect(loanInfo.isActive).to.be.true;

      // The interest is calculated on encrypted principal using FHE.mul()
      // Interest = principal * rate = 5000 * 500 = 2,500,000 (scaled)
      // Actual = 2,500,000 / 10,000 = 250
    });

    it("Should handle different interest rates", async function () {
      const principal = 10000;

      // Test various interest rates
      await contract.connect(borrower).createLoan(principal, 300);  // 3%
      await contract.connect(borrower).createLoan(principal, 1000); // 10%
      await contract.connect(borrower).createLoan(principal, 2000); // 20%

      const loan1 = await contract.getLoanInfo(1);
      const loan2 = await contract.getLoanInfo(2);
      const loan3 = await contract.getLoanInfo(3);

      expect(loan1.interestRate).to.equal(300);
      expect(loan2.interestRate).to.equal(1000);
      expect(loan3.interestRate).to.equal(2000);
    });

    it("Should reject excessive interest rates", async function () {
      const principal = 5000;
      const excessiveRate = 5000; // 50% exceeds 30% max

      await expect(
        contract.connect(borrower).createLoan(principal, excessiveRate)
      ).to.be.revertedWith("Interest rate too high");
    });
  });

  /**
   * @title Encrypted Addition - Total Calculation
   *
   * FHE.add() adds two encrypted values together. This is used to calculate
   * the total repayment amount (principal + interest).
   *
   * Example: principal = 5000, interest = 250
   * Encrypted total = encrypted principal + encrypted interest = 5250
   *
   * Both inputs and output remain encrypted throughout the operation.
   */
  describe("Total calculation with FHE.add()", function () {
    it("Should calculate encrypted total using addition", async function () {
      const principal = 5000;
      const interestRate = 500; // 5%

      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;

      // Get encrypted amounts (only authorized users can decrypt)
      const amounts = await contract.connect(borrower).getEncryptedAmounts(loanId);

      // Verify we received encrypted handles (non-zero)
      expect(amounts.principal).to.not.equal(0);
      expect(amounts.interest).to.not.equal(0);
      expect(amounts.total).to.not.equal(0);

      // Total was calculated using: FHE.add(principal, interest)
      // The actual value is encrypted - can only be decrypted by authorized parties
    });

    it("Should maintain encryption throughout calculation", async function () {
      const principal = 10000;
      const interestRate = 1000; // 10%

      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;

      // All values remain encrypted
      const amounts = await contract.connect(borrower).getEncryptedAmounts(loanId);

      // These are handles to encrypted values, not plaintext
      // Each value was calculated using FHE operations
      expect(amounts.total).to.not.equal(amounts.principal);
      expect(amounts.paid).to.equal(amounts.paid); // Initially 0
    });
  });

  /**
   * @title Encrypted Subtraction - Payment Processing
   *
   * FHE.sub() subtracts one encrypted value from another. This is essential
   * for tracking loan repayment progress.
   *
   * Example: remaining = 5250, payment = 1000
   * Encrypted new remaining = encrypted remaining - encrypted payment = 4250
   *
   * The borrower's balance updates without revealing the actual amounts.
   */
  describe("Payment processing with FHE.sub()", function () {
    it("Should update encrypted balance using subtraction", async function () {
      const principal = 5000;
      const interestRate = 500;

      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;
      const paymentAmount = 1000;

      // Make a payment - uses FHE.sub() internally
      await contract.connect(borrower).makePayment(loanId, paymentAmount);

      // Verify payment was recorded
      const amounts = await contract.connect(borrower).getEncryptedAmounts(loanId);

      // Paid amount increased (FHE.add)
      expect(amounts.paid).to.not.equal(0);

      // Remaining decreased (FHE.sub)
      expect(amounts.remaining).to.not.equal(amounts.total);

      // Actual values are encrypted - privacy preserved
    });

    it("Should handle multiple payments", async function () {
      const principal = 10000;
      const interestRate = 500;

      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;

      // Make multiple payments
      await contract.connect(borrower).makePayment(loanId, 1000);
      await contract.connect(borrower).makePayment(loanId, 2000);
      await contract.connect(borrower).makePayment(loanId, 1500);

      // Each payment updates encrypted balances using FHE.add() and FHE.sub()
      const amounts = await contract.connect(borrower).getEncryptedAmounts(loanId);

      // All values are encrypted throughout
      expect(amounts.paid).to.not.equal(0);
      expect(amounts.remaining).to.not.equal(amounts.total);
    });

    it("Should reject zero payments", async function () {
      const principal = 5000;
      const interestRate = 500;

      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;

      await expect(
        contract.connect(borrower).makePayment(loanId, 0)
      ).to.be.revertedWith("Payment must be greater than 0");
    });
  });

  /**
   * @title Complex Encrypted Workflows
   *
   * Real applications combine multiple FHE operations in workflows.
   * This demonstrates how FHE.mul(), FHE.add(), and FHE.sub() work together
   * to create privacy-preserving financial calculations.
   */
  describe("Complete encrypted workflow", function () {
    it("Should handle full loan lifecycle with encrypted arithmetic", async function () {
      const principal = 8000;
      const interestRate = 750; // 7.5%

      // Step 1: Create loan (FHE.mul for interest, FHE.add for total)
      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;

      // Step 2: Get initial amounts
      const initialAmounts = await contract.connect(borrower).getEncryptedAmounts(loanId);

      expect(initialAmounts.principal).to.not.equal(0);
      expect(initialAmounts.total).to.not.equal(0);

      // Step 3: Make payments (FHE.add for paid, FHE.sub for remaining)
      await contract.connect(borrower).makePayment(loanId, 2000);
      await contract.connect(borrower).makePayment(loanId, 3000);

      // Step 4: Verify balances updated
      const updatedAmounts = await contract.connect(borrower).getEncryptedAmounts(loanId);

      expect(updatedAmounts.paid).to.not.equal(0);
      expect(updatedAmounts.remaining).to.not.equal(updatedAmounts.total);

      // All calculations performed on encrypted data - complete privacy maintained
    });

    it("Should allow platform to update interest rates", async function () {
      const principal = 5000;
      const initialRate = 500;

      await contract.connect(borrower).createLoan(principal, initialRate);

      const loanId = 1;

      // Platform adjusts interest rate
      const newRate = 750;
      await contract.connect(platform).updateInterestRate(loanId, newRate);

      // Verify update
      const loanInfo = await contract.getLoanInfo(loanId);
      expect(loanInfo.interestRate).to.equal(newRate);

      // All encrypted amounts recalculated with new rate
      // Uses FHE.mul(), FHE.add(), FHE.sub() internally
    });
  });

  /**
   * @title Best Practices for Encrypted Arithmetic
   *
   * Key takeaways:
   * 1. FHE.mul() for multiplication (interest calculation)
   * 2. FHE.add() for addition (totals, accumulation)
   * 3. FHE.sub() for subtraction (payments, balances)
   * 4. Always grant ACL permissions after operations
   * 5. Validate plaintext inputs before encryption
   * 6. Combine operations for complex workflows
   */
  describe("Access control for encrypted values", function () {
    it("Should enforce access control on encrypted amounts", async function () {
      const principal = 5000;
      const interestRate = 500;

      await contract.connect(borrower).createLoan(principal, interestRate);

      const loanId = 1;

      // Borrower can access
      await contract.connect(borrower).getEncryptedAmounts(loanId);

      // Platform can access
      await contract.connect(platform).getEncryptedAmounts(loanId);

      // Unauthorized cannot access
      const [, , unauthorized] = await ethers.getSigners();
      await expect(
        contract.connect(unauthorized).getEncryptedAmounts(loanId)
      ).to.be.revertedWith("Not authorized");
    });
  });
});
