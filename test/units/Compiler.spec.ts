import hre from 'hardhat'
import { expect } from 'chai'
import { Compiler } from '../../typechain-types/Compiler.sol'
import { Context, contextFixture, Contracts, fixture } from '../shared/fixture'
import { decodePoolId, encodeCreateCurve, encodeCreatePair, encodeCreatePool } from '../../lib'
import { mintAndApprove } from '../contextHelpers'
import { Values } from '../constants'
import { TestERC20 } from '../../typechain-types/test/TestERC20'
import { parseEther } from 'ethers/lib/utils'
import { BigNumber } from 'ethers'

describe('Compiler', function () {
  let contracts: Contracts, context: Context

  beforeEach(async function () {
    context = await contextFixture(hre)
    contracts = await fixture(hre)

    await mintAndApprove(contracts.base, context.user, contracts.main.address, Values.ETHER)
    await mintAndApprove(contracts.quote, context.user, contracts.main.address, Values.ETHER)
  })

  describe('CreatePair', function () {
    it('creates a pair and emits the CreatePair event', async function () {
      const base = contracts.base.address
      const quote = contracts.quote.address
      const payload = encodeCreatePair(base, quote)
      const nonce = await contracts.main.pairNonce()
      await expect(contracts.main.testCreatePair(payload.hex))
        .to.emit(contracts.main, 'CreatePair')
        .withArgs(parseInt(nonce.add(1).toString()), base, quote)
    })
  })

  describe('CreateCurve', function () {
    it('creates a curve and emits the CreateCurve event', async function () {
      const strike = BigNumber.from(50)
      const sigma = 1e4
      const maturity = 200
      const fee = 100
      const gamma = 1e4 - fee

      const nonce = await contracts.main.curveNonce()
      const payload = encodeCreateCurve(strike, sigma, maturity, fee)
      await expect(contracts.main.testCreateCurve(payload.hex))
        .to.emit(contracts.main, 'CreateCurve')
        .withArgs(parseInt(nonce.add(1).toString()), strike, sigma, maturity, gamma)
    })
  })

  describe('CreatePool', function () {
    it('creates a pool and emits the CreatePool event', async function () {
      const base = contracts.base.address
      const quote = contracts.quote.address

      const strike = parseEther('10')
      const sigma = 1e4
      const maturity = 60 * 60 * 24 * 365 // note: the contracts _blockTimestamp is set to 100.
      const fee = 100
      const gamma = 1e4 - fee

      const basePerLiquidity = parseEther('0.69')
      const deltaLiquidity = parseEther('1')

      const deltaBase = basePerLiquidity
      const deltaQuote = BigNumber.from('669038505037077076')

      const payloadPair = encodeCreatePair(base, quote)
      await contracts.main.testCreatePair(payloadPair.hex)
      const pairId = (await contracts.main.pairNonce()) as BigNumber

      const payloadCurve = encodeCreateCurve(strike, sigma, maturity, fee)
      await contracts.main.testCreateCurve(payloadCurve.hex)
      const curveId = (await contracts.main.curveNonce()) as BigNumber

      const poolPayload = encodeCreatePool(
        parseInt(pairId._hex),
        parseInt(curveId._hex),
        basePerLiquidity,
        deltaLiquidity
      )
      const poolId = decodePoolId(poolPayload.bytes.slice(0, 6))
      await expect(contracts.main.testCreatePool(poolPayload.hex))
        .to.emit(contracts.main, 'CreatePool')
        .withArgs(parseInt(poolId), pairId, curveId, deltaBase, deltaQuote, deltaLiquidity)
    })
  })
})
