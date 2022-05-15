import { expect } from 'chai'
import { parseEther } from 'ethers/lib/utils'
import hre from 'hardhat'
import { TestHyperSwap } from 'typechain-types'
import { Context, Contracts, fixture, contextFixture, deployTestHyperSwap } from '../shared/fixture'

describe('HyperSwap.sol', function () {
  let contracts: Contracts, context: Context, hyperSwap: TestHyperSwap
  this.beforeAll(async function () {
    context = await contextFixture(hre)
    contracts = await fixture(hre)
  })

  this.beforeEach(async function () {
    hyperSwap = await deployTestHyperSwap(hre)
    await hyperSwap.helperSetTokens(contracts.base.address, contracts.quote.address)
  })

  describe('HyperSwap View', function () {
    it('testCheckSwapMaturityCondition', async function () {
      const number = await hre.ethers.provider.getBlockNumber()
      const block = await hre.ethers.provider.getBlock(number)
      const timestamp = block.timestamp
      await hre.ethers.provider.send('evm_mine', [timestamp + 1000])
      await expect(hyperSwap.testCheckSwapMaturityCondition(timestamp)).to.not.emit(hyperSwap, 'log').to.not.be.reverted
    })
    it('testGetPhysicalReserves', async function () {
      const liquidity = parseEther('1')
      await expect(hyperSwap.testGetPhysicalReserves(liquidity)).to.not.emit(hyperSwap, 'log').to.not.be.reverted
    })
    it('testGetInvariant', async function () {
      await expect(hyperSwap.testGetInvariant()).to.not.emit(hyperSwap, 'log').to.not.be.reverted
    })
  })

  describe('HyperSwap Internal', function () {
    it('testUpdateLastTimestamp', async function () {
      await expect(hyperSwap.testUpdateLastTimestamp())
        .to.emit(hyperSwap, 'UpdateLastTimestamp')
        .to.not.emit(hyperSwap, 'log').and.to.not.be.reverted
    })
    it('testSwap', async function () {
      await expect(hyperSwap.testSwap(0)).to.emit(hyperSwap, 'Swap').and.to.not.be.reverted
      await expect(hyperSwap.testSwap(1)).to.emit(hyperSwap, 'Swap').and.to.not.be.reverted
    })
    it('testSwap', async function () {
      await expect(hyperSwap.testSwap(0)).to.not.emit(hyperSwap, 'log').and.to.not.be.reverted
      await expect(hyperSwap.testSwap(1)).to.not.emit(hyperSwap, 'log').and.to.not.be.reverted
    })
  })
})
