import hre from 'hardhat'
import { expect } from 'chai'
import { Context, contextFixture, Contracts, fixture, mintAndApprove } from '../shared/fixture'
import {
  bytesToHex,
  decodePoolId,
  encodeAddLiquidity,
  encodeCreateCurve,
  encodeCreatePair,
  encodeCreatePool,
  encodeJumpInstruction,
  encodeRemoveLiquidity,
  encodeSwapExactTokens,
  fixedX64ToFloat,
  INSTRUCTION_JUMP,
} from '../../lib'
import { parseEther } from 'ethers/lib/utils'
import { BigNumber } from 'ethers'
import { BasicRealPool, Values } from '../shared/utils'
import { TestCompiler, TestExternalCompiler } from 'typechain-types'

function getSwapTokensFromDir(
  dir: number,
  base: string,
  quote: string
): { inputAddress: string; outputAddress: string } {
  if (dir == 0) {
    return { inputAddress: base, outputAddress: quote }
  } else if (dir == 1) {
    return { inputAddress: quote, outputAddress: base }
  } else {
    throw new Error('Direction input not valid')
  }
}

// Note: if any of these tests randomly breaks... look at what _blockTimestamp() is pointing to in the contracts.
describe('Compiler', function () {
  let contracts: Contracts, context: Context

  beforeEach(async function () {
    context = await contextFixture(hre)
    contracts = await fixture(hre)

    await mintAndApprove(contracts.base, context.user, contracts.main.address, Values.ETHER)
    await mintAndApprove(contracts.quote, context.user, contracts.main.address, Values.ETHER)
  })

  describe('Instruction Single & Multi Processing', function () {
    let compiler: TestCompiler, caller: TestExternalCompiler
    this.beforeEach(async function () {
      compiler = (await (await hre.ethers.getContractFactory('TestCompiler')).deploy()) as TestCompiler
      caller = (await (
        await hre.ethers.getContractFactory('TestExternalCompiler')
      ).deploy(compiler.address)) as TestExternalCompiler
      await mintAndApprove(contracts.base, context.user, compiler.address, Values.ETHER)
      await mintAndApprove(contracts.quote, context.user, compiler.address, Values.ETHER)
    })

    it('testApplyCredit for events', async function () {
      await expect(compiler.testApplyCredit(contracts.base.address, 5))
        .to.emit(compiler, 'Credit')
        .withArgs(contracts.base.address, 5)
    })
    it('testApplyCredit for errors', async function () {
      await expect(compiler.testApplyCredit(contracts.base.address, 5)).and.to.not.emit(compiler, 'log')
    })
    it('testApplyDebit for events', async function () {
      const token = contracts.base.address
      const amount = 12
      await expect(compiler.testApplyDebit(token, amount)).to.emit(compiler, 'Debit').withArgs(token, amount)
    })
    it('testApplyDebit for errors', async function () {
      const token = contracts.base.address
      const amount = 12
      await expect(compiler.testApplyDebit(token, amount)).and.to.not.emit(compiler, 'log')
    })
    it('testSettleToken for events', async function () {
      const token = contracts.base.address
      await expect(compiler.testSettleToken(token))
        .to.emit(compiler, 'Debit')
        .withArgs(token, 10)
        .to.emit(compiler, 'Credit')
        .withArgs(token, 10)
    })
    it('testSettleToken for errors', async function () {
      const token = contracts.base.address
      await expect(compiler.testSettleToken(token)).to.not.emit(compiler, 'log')
    })
    it('testSettleBalances for events', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      await expect(compiler.testSettleBalances(base, quote))
        .to.emit(compiler, 'Debit')
        .withArgs(base, 10)
        .to.emit(compiler, 'Credit')
        .withArgs(quote, 10)
    })

    it('testSettleBalances for fails', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      await expect(compiler.testSettleBalances(base, quote)).to.not.emit(compiler, 'log')
    })

    it('testProcess for events', async function () {
      const { base, quote } = contracts
      await compiler.helperSetTokens(base.address, quote.address)
      await expect(caller.testProcess(base.address, quote.address)).to.emit(compiler, 'AddLiquidity')
    })

    it('testProcess for errors', async function () {
      const { base, quote } = contracts
      await compiler.helperSetTokens(base.address, quote.address)
      await expect(caller.testProcess(base.address, quote.address)).to.not.emit(compiler, 'log')
    })

    it('testJumpProcess for events', async function () {
      const { base, quote } = contracts
      await expect(caller.testJumpProcess(base.address, quote.address))
        .to.emit(compiler, 'CreatePair')
        .to.emit(compiler, 'CreateCurve')
    })

    it('testJumpProcess for errors', async function () {
      const { base, quote } = contracts
      await expect(caller.testJumpProcess(base.address, quote.address)).to.not.emit(compiler, 'log')
    })
  })

  /// note: temporarily removed from contracts, will be added later?
  /* it('testGetReportedPrice', async function () {
    const scaleFactorRisky = 1
    const scaleFactoryStable = 1
    const { strike, sigma, internalBase } = BasicRealPool
    const tau = 60 * 60 * 24 * 356 - 100
    const price = await contracts.main.testGetReportedPrice(
      scaleFactorRisky,
      scaleFactoryStable,
      internalBase,
      strike,
      sigma,
      tau
    )
    expect(fixedX64ToFloat(price)).to.be.eq(3.7647263806019016)
  }) */

  describe('Compiler Fallback', function () {
    it('testJumpProcess: creates a pair using the jump process', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      const data = encodeCreatePair(base, quote)
      const jumpInstruction = encodeJumpInstruction([data.bytes])
      await expect(contracts.main.testJumpProcess(jumpInstruction.hex))
        .to.emit(contracts.main, 'CreatePair')
        .withArgs(await contracts.main.pairNonce(), base, quote)
    })

    it('testJumpProcess: creates two pairs using the jump process', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      const data = encodeCreatePair(base, quote)
      const data2 = encodeCreatePair(quote, base)
      const jumpInstruction = encodeJumpInstruction([data.bytes, data2.bytes])
      const nonce = (await contracts.main.pairNonce()).add(1)
      await expect(contracts.main.testJumpProcess(jumpInstruction.hex))
        .to.emit(contracts.main, 'CreatePair')
        .to.emit(contracts.main, 'CreatePair')
      const pair1 = await contracts.main.pairs(nonce)
      expect(pair1.tokenBase).to.be.eq(base)
      expect(pair1.tokenQuote).to.be.eq(quote)
      const pair2 = await contracts.main.pairs(nonce.add(1))
      expect(pair2.tokenBase).to.be.eq(quote)
      expect(pair2.tokenQuote).to.be.eq(base)
    })

    it('testMain: public function for the fallback to create a Pair, Curve, and Pool', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      const strike = parseEther('10')
      const sigma = 1e4
      const maturity = 60 * 60 * 24 * 365 // note: the contracts _blockTimestamp is set to 100.
      const fee = 100
      const gamma = 1e4 - fee

      const basePerLiquidity = parseEther('0.69')
      const deltaLiquidity = parseEther('1')

      const deltaBase = basePerLiquidity
      const deltaQuote = BigNumber.from('669038505037077076')

      const pairId = ((await contracts.main.pairNonce()) as BigNumber).add(1)
      const curveId = ((await contracts.main.curveNonce()) as BigNumber).add(1)

      const data0 = encodeCreatePair(base, quote)
      const data1 = encodeCreateCurve(strike, sigma, maturity, fee)
      const data2 = encodeCreatePool(parseInt(pairId._hex), parseInt(curveId._hex), basePerLiquidity, deltaLiquidity)
      const jumpInstruction = encodeJumpInstruction([data0.bytes, data1.bytes, data2.bytes])
      await expect(contracts.main.testMain(jumpInstruction.hex))
        .to.emit(contracts.main, 'CreatePool')
        .to.emit(contracts.main, 'CreateCurve')
        .to.emit(contracts.main, 'CreatePool')
    })

    it('fallback#tests the fallback by sending data directly to contract', async function () {
      const [base, quote] = [contracts.base.address, contracts.quote.address]
      const data = encodeCreatePair(base, quote)
      const jumpInstruction = encodeJumpInstruction([data.bytes])
      await context.signer.sendTransaction({ to: contracts.main.address, data: jumpInstruction.hex, value: 0x0 })
    })
  })

  describe('HyperLiquidity', function () {
    it('getLiquidityMinted compared against getLiquidityMinted2', async function () {
      const poolId = 4
      const { internalBase, internalQuote, internalLiquidity } = BasicRealPool
      await contracts.main.setLiquidity(poolId, internalBase, internalQuote, internalLiquidity)
      const zero = await contracts.main.testGetLiquidityMinted(poolId, internalBase._hex, internalQuote._hex)
      const one = await contracts.main.getLiquidityMinted(poolId, internalBase._hex, internalQuote._hex)
      const two = await contracts.main.getLiquidityMinted2(poolId, internalBase._hex)
    })
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
      const poolId = decodePoolId(poolPayload.bytes.slice(1, 7))
      await expect(contracts.main.testCreatePool(poolPayload.hex))
        .to.emit(contracts.main, 'CreatePool')
        .withArgs(parseInt(poolId), pairId, curveId, deltaBase, deltaQuote, deltaLiquidity)
    })
  })

  describe('AddLiquidity', function () {
    it('adds liquidity and emits the AddLiquidity event', async function () {
      await contracts.main.setTimestamp(100)
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

      const rawPayload = poolPayload.bytes.slice(1)
      const poolId = decodePoolId(rawPayload.slice(0, 6))
      await contracts.main.testCreatePool(poolPayload.hex)

      const toRemove = deltaLiquidity.div(10)

      const allocatePayload = encodeAddLiquidity(
        false,
        parseInt(poolId),
        deltaBase.div(10),
        BigNumber.from('66904055621924321')
      )
      const computationRoundingHops = 2
      await expect(contracts.main.testAddLiquidity(allocatePayload.hex))
        .to.emit(contracts.main, 'AddLiquidity')
        .withArgs(
          parseInt(poolId),
          parseInt(pairId._hex),
          deltaBase.div(10),
          '66904055621924321',
          toRemove.sub(computationRoundingHops)
        )
    })
  })

  describe('SwapExactTokens', function () {
    it('swaps exact input amount of tokens and emits the Swap event', async function () {
      await contracts.main.setTimestamp(100)
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

      const rawPayload = poolPayload.bytes.slice(1)
      const poolId = decodePoolId(rawPayload.slice(0, 6))
      await contracts.main.testCreatePool(poolPayload.hex)

      const deltaIn = deltaBase.div(1000)

      const deltaOut = parseEther('0.000970860704930000')
      const dir = 0
      const swapPayload = encodeSwapExactTokens(false, parseInt(poolId), deltaIn, dir)
      const tokens = getSwapTokensFromDir(dir, contracts.base.address, contracts.quote.address)
      await expect(contracts.main.testSwapExactTokens(swapPayload.hex))
        .to.emit(contracts.main, 'Swap')
        .withArgs(parseInt(poolId), deltaIn, deltaOut, tokens.inputAddress, tokens.outputAddress)
    })
  })

  describe('RemoveLiquidity', function () {
    it('removes liquidity and emits the RemoveLiquidity event', async function () {
      await contracts.main.setTimestamp(100)
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

      const rawPayload = poolPayload.bytes.slice(1)
      const poolId = decodePoolId(rawPayload.slice(0, 6))
      await contracts.main.testCreatePool(poolPayload.hex)

      const toRemove = deltaLiquidity.div(10)

      const removePayload = encodeRemoveLiquidity(false, parseInt(poolId), toRemove)
      await expect(contracts.main.testRemoveLiquidity(removePayload.hex))
        .to.emit(contracts.main, 'RemoveLiquidity')
        .withArgs(parseInt(poolId), parseInt(pairId._hex), deltaBase.div(10), '66904055621924321', toRemove)
    })
  })
})
