import hre from 'hardhat'
import { expect } from 'chai'
import { Compiler } from '../../typechain-types/Compiler.sol'
import { Context, contextFixture, Contracts, fixture } from '../shared/fixture'
import { encodeCreatePair } from '../../lib'
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
      await expect(contracts.main.testCreatePair(payload.hex))
        .to.emit(contracts.main, 'CreatePair')
        .withArgs(base, quote)
    })
  })
})
