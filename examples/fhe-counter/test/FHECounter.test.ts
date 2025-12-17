import { expect } from "chai";
import { ethers } from "hardhat";
import { FHECounter } from "../typechain-types";
import { createInstances } from "../test/instance";
import { getSigners, initSigners } from "../test/signers";

/**
 * @title FHE Counter Test Suite
 * @notice Comprehensive tests for encrypted counter operations
 * @dev Demonstrates basic FHEVM patterns and best practices
 *
 * @chapter basic
 * @difficulty beginner
 *
 * This test suite covers:
 * - ✅ Encrypted counter initialization
 * - ✅ Encrypted increment operations
 * - ✅ Encrypted decrement operations
 * - ✅ Access control for encrypted data
 * - ✅ Permission management patterns
 */
describe("FHE Counter", function () {
  let counter: FHECounter;
  let owner: any;
  let user1: any;
  let user2: any;

  before(async function () {
    await initSigners();
    const signers = await getSigners();
    owner = signers.alice;
    user1 = signers.bob;
    user2 = signers.carol;
  });

  beforeEach(async function () {
    const CounterFactory = await ethers.getContractFactory("FHECounter");
    counter = await CounterFactory.connect(owner).deploy();
    await counter.waitForDeployment();
  });

  /**
   * @test Counter Initialization
   * @description Verify counter starts at encrypted zero
   */
  describe("Initialization", function () {
    it("Should initialize counter to encrypted zero", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);
      const encryptedCount = await counter.connect(owner).getCount();

      // Owner should be able to decrypt initial value
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(0);
    });

    it("Should set deployer as owner", async function () {
      expect(await counter.owner()).to.equal(owner.address);
    });
  });

  /**
   * @test Encrypted Increment
   * @description Test adding encrypted values to counter
   *
   * Key Concepts:
   * - Creating encrypted inputs with proofs
   * - Using FHE.add() for encrypted addition
   * - Proper permission management with FHE.allow()
   */
  describe("Increment Operations", function () {
    it("✅ Should increment by encrypted value", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // Create encrypted input: encrypt value 5
      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(5);
      const encryptedInput = await input.encrypt();

      // Increment counter by encrypted 5
      await counter.connect(owner).increment(
        encryptedInput.handles[0],
        encryptedInput.inputProof
      );

      // Verify encrypted counter value
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(5);
    });

    it("✅ Should increment multiple times", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // First increment: +3
      let input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(3);
      let encrypted = await input.encrypt();
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Second increment: +7
      input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(7);
      encrypted = await input.encrypt();
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Total should be 3 + 7 = 10
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(10);
    });

    it("✅ Should increment by one (plaintext)", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // Increment by plaintext 1
      await counter.connect(owner).incrementByOne();

      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(1);
    });

    it("Should emit CounterIncremented event", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(1);
      const encrypted = await input.encrypt();

      await expect(
        counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof)
      ).to.emit(counter, "CounterIncremented").withArgs(owner.address);
    });
  });

  /**
   * @test Encrypted Decrement
   * @description Test subtracting encrypted values from counter
   *
   * Key Concepts:
   * - Using FHE.sub() for encrypted subtraction
   * - Handling underflow scenarios with encrypted values
   */
  describe("Decrement Operations", function () {
    it("✅ Should decrement by encrypted value", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // First, increment to 10
      let input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(10);
      let encrypted = await input.encrypt();
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Then decrement by 3
      input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(3);
      encrypted = await input.encrypt();
      await counter.connect(owner).decrement(encrypted.handles[0], encrypted.inputProof);

      // Should be 10 - 3 = 7
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(7);
    });

    it("Should emit CounterDecremented event", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(1);
      const encrypted = await input.encrypt();

      await expect(
        counter.connect(owner).decrement(encrypted.handles[0], encrypted.inputProof)
      ).to.emit(counter, "CounterDecremented").withArgs(owner.address);
    });
  });

  /**
   * @test Access Control
   * @description Verify permission management for encrypted data
   *
   * Key Concepts:
   * - FHE.allow() grants decryption permission
   * - Only authorized users can decrypt
   * - Owner can grant access to other users
   */
  describe("Access Control", function () {
    it("✅ Should allow owner to decrypt counter", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // Increment counter
      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(42);
      const encrypted = await input.encrypt();
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Owner should decrypt successfully
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(42);
    });

    it("✅ Should grant access to other users", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner, user1);

      // Increment counter
      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(100);
      const encrypted = await input.encrypt();
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Grant access to user1
      await counter.connect(owner).grantAccess(user1.address);

      // User1 should now be able to decrypt
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.bob.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(100);
    });

    it("❌ Should prevent non-owner from granting access", async function () {
      await expect(
        counter.connect(user1).grantAccess(user2.address)
      ).to.be.revertedWith("Only owner can grant access");
    });
  });

  /**
   * @test Reset Functionality
   * @description Test counter reset to zero
   */
  describe("Reset Operations", function () {
    it("✅ Should reset counter to zero", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // Increment counter
      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(99);
      const encrypted = await input.encrypt();
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Reset
      await counter.connect(owner).reset();

      // Should be back to 0
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(0);
    });

    it("❌ Should prevent non-owner from resetting", async function () {
      await expect(
        counter.connect(user1).reset()
      ).to.be.revertedWith("Only owner can reset");
    });

    it("Should emit CounterReset event", async function () {
      await expect(
        counter.connect(owner).reset()
      ).to.emit(counter, "CounterReset").withArgs(owner.address);
    });
  });

  /**
   * @test Common Patterns
   * @description Demonstrates best practices for FHEVM development
   */
  describe("FHEVM Best Practices", function () {
    it("✅ Pattern: Always call FHE.allowThis() after operations", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      // This pattern is demonstrated in all counter operations
      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(1);
      const encrypted = await input.encrypt();

      // increment() internally calls FHE.allowThis()
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // Counter remains accessible
      const encryptedCount = await counter.getCount();
      expect(encryptedCount).to.not.be.undefined;
    });

    it("✅ Pattern: Grant user permissions with FHE.allow()", async function () {
      const instances = await createInstances(await counter.getAddress(), ethers, owner);

      const input = instances.alice.createEncryptedInput(
        await counter.getAddress(),
        owner.address
      );
      input.add32(5);
      const encrypted = await input.encrypt();

      // increment() internally calls FHE.allow(count, msg.sender)
      await counter.connect(owner).increment(encrypted.handles[0], encrypted.inputProof);

      // User can decrypt their own transaction result
      const encryptedCount = await counter.getCount();
      const decryptedCount = instances.alice.decrypt(await counter.getAddress(), encryptedCount);
      expect(decryptedCount).to.equal(5);
    });
  });
});
