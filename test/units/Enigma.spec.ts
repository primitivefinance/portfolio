import { expect } from 'chai'
import hre from 'hardhat'
import { TestEnigmaVirtualMachine } from 'typechain-types'
import { Context, Contracts, fixture, contextFixture, deployTestEnigma } from '../shared/fixture'

describe('EnigmaVirtualMachine.sol', function () {
  let contracts: Contracts, context: Context, enigma: TestEnigmaVirtualMachine
  this.beforeEach(async function () {
    context = await contextFixture(hre)
    contracts = await fixture(hre)
    enigma = await deployTestEnigma(hre)
  })

  describe('Enigma View', function () {
    it('testBalanceOf', async function () {
      await contracts.base.mint(enigma.address, '100')
      await expect(enigma.testBalanceOf(contracts.base.address)).to.not.emit(enigma, 'log').to.not.be.reverted
    })

    it('testUpdateLastTimestamp', async function () {
      await expect(enigma.testUpdateLastTimestamp()).to.not.emit(enigma, 'log').to.not.be.reverted
    })

    it('testBlockTimestamp', async function () {
      const number = await hre.ethers.provider.getBlockNumber()
      const block = await hre.ethers.provider.getBlock(number)
      const result = await enigma.testBlockTimestamp()
      expect(result).to.be.eq(block.timestamp)
    })

    it('tests all constants', async function () {
      await expect(enigma.testConstants()).to.not.emit(enigma, 'log').to.not.be.reverted
    })
  })
})
