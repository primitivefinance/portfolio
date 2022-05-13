import hre from 'hardhat'
import { expect } from 'chai'
import { Compiler } from '../../typechain-types/Compiler.sol'
import { Context, contextFixture, Contracts, fixture } from '../shared/fixture'
import { encodeCreateCurve, encodeCreatePair } from '../../lib'
import { mintAndApprove } from '../contextHelpers'
import { Values } from '../constants'

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

  describe.only('CreateCurve', function () {
    it('creates a curve and emits the CreateCurve event', async function () {
      const strike = 50
      const sigma = 1e4
      const maturity = 200
      const fee = 100
      const gamma = 1e4 - fee
      const nonce = await contracts.main.curveNonce()
      const payload = encodeCreateCurve(strike, sigma, maturity, fee)
      console.log(payload.bytes, payload.hex)
      await expect(contracts.main.testCreateCurve(payload.hex))
        .to.emit(contracts.main, 'CreateCurve')
        .withArgs(parseInt(nonce.add(1).toString()), strike, sigma, maturity, gamma)
    })
  })
})
