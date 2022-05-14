import { expect } from 'chai'
import { parseEther } from 'ethers/lib/utils'
import hre from 'hardhat'
import { TestHyperLiquidity } from '../../typechain-types/test/HyperLiquidity.t.sol/TestHyperLiquidity'
import { Context, Contracts, fixture, contextFixture, deployTestHyperLiquidity } from '../shared/fixture'
import { TestExternalLiquidity } from '../../typechain-types/test/HyperLiquidity.t.sol/TestExternalLiquidity'
import { BasicRealPool } from '../shared/utils'

describe('HyperLiquidity.sol', function () {
  let contracts: Contracts, context: Context, hyperLiquidity: TestHyperLiquidity, caller: TestExternalLiquidity
  this.beforeAll(async function () {
    context = await contextFixture(hre)
    contracts = await fixture(hre)
  })

  this.beforeEach(async function () {
    hyperLiquidity = await deployTestHyperLiquidity(hre)
    caller = (await (
      await hre.ethers.getContractFactory('TestExternalLiquidity')
    ).deploy(hyperLiquidity.address)) as TestExternalLiquidity
    await hyperLiquidity.helperSetTokens(contracts.base.address, contracts.quote.address)
  })

  describe('HyperLiquidity View', function () {})

  describe('HyperLiquidity Internal', function () {})

  describe('HyperLiquidity External', function () {
    it('testAddLiquidity', async function () {
      await expect(caller.testAddLiquidity())
        .to.emit(hyperLiquidity, 'IncreaseGlobal')
        .to.emit(hyperLiquidity, 'AddLiquidity')
        .to.emit(hyperLiquidity, 'IncreasePosition')
        .and.to.not.emit(hyperLiquidity, 'log')
    })

    it('testRemoveLiquidity', async function () {
      const [preGlobal0, preGlobal1] = await Promise.all([
        hyperLiquidity.globalReserves(await hyperLiquidity.base()),
        hyperLiquidity.globalReserves(await hyperLiquidity.quote()),
      ])

      await expect(caller.testRemoveLiquidity())
        .to.emit(hyperLiquidity, 'DecreaseGlobal')
        .to.emit(hyperLiquidity, 'RemoveLiquidity')
        .to.emit(hyperLiquidity, 'DecreasePosition')
        .and.to.not.emit(hyperLiquidity, 'log') // thats an error event

      // A standard pool was created. Then exact amount of liquidity was added and removed.
      // Therefore, the net change to global was only the amount of tokens added to the standard pool.
      const pool = await hyperLiquidity.pools('0x0100000001')

      const [postGlobal0, postGlobal1] = await Promise.all([
        hyperLiquidity.globalReserves(await hyperLiquidity.base()),
        hyperLiquidity.globalReserves(await hyperLiquidity.quote()),
      ])

      // Adds and then immediately removes amounts
      expect(postGlobal0).to.be.eq(pool.internalBase)
      expect(postGlobal1).to.be.eq(pool.internalQuote)
    })

    it('testCreatePair', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      await expect(caller.testCreatePair(base, quote))
        .to.emit(hyperLiquidity, 'CreatePair')
        .and.to.not.emit(hyperLiquidity, 'log')
    })

    it('testCreateCurve', async function () {
      await expect(caller.testCreateCurve(1e4, 500, 100, 75))
        .to.emit(hyperLiquidity, 'CreateCurve')
        .and.to.not.emit(hyperLiquidity, 'log')
    })
    it('testCreatePool', async function () {
      const { internalBase, internalQuote, internalLiquidity } = BasicRealPool
      const poolId = 4294967297 // 2 bytes pairId + 4 bytes curveId
      await expect(caller.testCreatePool(contracts.base.address, contracts.quote.address))
        .to.emit(hyperLiquidity, 'CreatePool')
        .withArgs(poolId, 1, 1, internalBase, internalQuote, internalLiquidity.div(1e3))
        .to.emit(hyperLiquidity, 'IncreaseGlobal')
        .to.emit(hyperLiquidity, 'AddLiquidity')
        .to.emit(hyperLiquidity, 'IncreasePosition')
        .and.to.not.emit(hyperLiquidity, 'log')
    })
  })
})
