import { expect } from 'chai'
import { BigNumber, BigNumberish, Signer } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import hre, { ethers } from 'hardhat'
import { TestPrototypeHyper } from '../typechain-types'
import { TestERC20 } from '../typechain-types/test/TestERC20'
import { TestHyperLiquidity } from '../typechain-types/test/TestHyperLiquidity'
import { Values } from './constants'
import { contextFixture, Contracts, fixture, Context, setupPool, mintAndApprove } from './contextHelpers'
import { Kinds, PoolIds } from './entities'
import {
  bytesToHex,
  decodeEnd,
  decodeFirstByte,
  decodeLastByte,
  decodeMiddleBytes,
  decodeOrder,
  decodeSecondByte,
  deconstructCalldata,
  encodeAmount,
  encodeFirstByte,
  encodeInfoFlag,
  encodeIsMaxFlag,
  encodeMiddleBytes,
  encodeOrder,
  encodeParameters,
  encodeSecondByte,
  encodeTransaction,
  hexToBytes,
  Orders,
  reverseRunLengthEncode,
  runLengthDecode,
  runLengthEncode,
} from './helpers'
const { hexlify } = ethers.utils

interface Tx {
  to: string
  value: string
  data?: string
}

interface Parameters {
  max: boolean
  ord: Orders
  pair: number
  amt: BigNumber
  output: string
}

function encodeCalldata(args: Parameters): string {
  return bytesToHex(encodeTransaction(args.max, args.ord, args.amt, hexlify(args.pair)))
}

interface MultiOrder {
  ids: number[]
  kinds: number[]
  amountsBase: number[]
  amountsQuote: number[]
  amountsLiquidity: number[]
}

describe('Prototype', function () {
  let contracts: Contracts, context: Context
  let initialBase = Values.HUNDRED,
    initialQuote = Values.HUNDRED * 5,
    initialLiquidity = Values.THOUSAND

  beforeEach(async function () {
    context = await contextFixture(hre)
    contracts = await fixture(hre)

    await mintAndApprove(contracts.base, context.user, contracts.pool.address, Values.ETHER)
    await mintAndApprove(contracts.quote, context.user, contracts.pool.address, Values.ETHER)

    await setupPool(
      contracts.pool,
      PoolIds.ETH_USDC,
      contracts.base.address,
      contracts.quote.address,
      initialBase,
      initialQuote,
      initialLiquidity
    )
  })

  describe('HyperLiquidity', function () {
    const quoteRatio = initialQuote / initialBase // multiply against the base numeraire
    const liquidityRatio = initialLiquidity / initialBase // multiply against the base numeraire
    const half = 0.5 // for removing half of liquidity allocated

    /* const orders: MultiOrder[] = [
      {
        ids: [PoolIds.ETH_USDC, PoolIds.ETH_USDC],
        kinds: [Kinds.ADD_LIQUIDITY, Kinds.REMOVE_LIQUIDITY],
        amountsBase: [dB, -dB * 0.5],
        amountsQuote: [dQ, -dQ * 0.5],
        amountsLiquidity: [dL, -dL * 0.5],
      },
    ] */

    it('Add Liquidity: Debits both tokens and emits two debit events', async function () {
      await expect(contracts.pool.multiOrder([PoolIds.ETH_USDC], [Kinds.ADD_LIQUIDITY], 10, 10 * quoteRatio, 0))
        .to.emit(contracts.pool, 'Debit')
        .withArgs(contracts.base.address, 10)
        .to.emit(contracts.pool, 'Debit')
        .withArgs(contracts.quote.address, 10 * quoteRatio)
    })

    it('Add Liquidity: Debits both tokens and transfers both tokens from user', async function () {
      await expect(() =>
        contracts.pool.multiOrder(
          [PoolIds.ETH_USDC, PoolIds.ETH_USDC],
          [Kinds.ADD_LIQUIDITY, Kinds.REMOVE_LIQUIDITY],
          10,
          10 * quoteRatio,
          10 * liquidityRatio * half
        )
      ).to.changeTokenBalances(contracts.base, [contracts.pool, context.signer], [10 * half, -10 * half])
    })

    it('Add Liquidity: Debits both tokens and debits both from users internal balance', async function () {
      await contracts.pool.fund(contracts.base.address, 5)
      await contracts.pool.fund(contracts.quote.address, 5)
      // call add liquidity with funded internal balance
      await contracts.pool.multiOrder([PoolIds.ETH_USDC], [Kinds.ADD_LIQUIDITY], 5, 5, 0)
    })

    it('Remove Liquidity: Credits both tokens and emits a credit', async function () {
      await contracts.pool.multiOrder([PoolIds.ETH_USDC], [Kinds.ADD_LIQUIDITY], 10, 10 * quoteRatio, 0)
      await expect(
        contracts.pool.multiOrder([PoolIds.ETH_USDC], [Kinds.REMOVE_LIQUIDITY], 0, 0, 10 * liquidityRatio * half)
      )
        .to.emit(contracts.pool, 'Credit')
        .withArgs(contracts.base.address, 10 * half)
        .to.emit(contracts.pool, 'Credit')
        .withArgs(contracts.quote.address, 10 * quoteRatio * half)
    })
    it('Remove Liquidity: Credits both tokens and credits the users internal balance', async function () {
      await contracts.pool.multiOrder([PoolIds.ETH_USDC], [Kinds.ADD_LIQUIDITY], 10, 10 * quoteRatio, 0)

      const internalBase = await contracts.pool.balances(context.user, contracts.base.address)
      const internalQuote = await contracts.pool.balances(context.user, contracts.base.address)

      await expect(
        contracts.pool.multiOrder([PoolIds.ETH_USDC], [Kinds.REMOVE_LIQUIDITY], 0, 0, 10 * liquidityRatio * half)
      )

      const internalBaseAfter = await contracts.pool.balances(context.user, contracts.base.address)
      const internalQuoteAfter = await contracts.pool.balances(context.user, contracts.base.address)

      expect(internalBaseAfter.sub(internalBase).gt(0)).to.be.true
      expect(internalQuoteAfter.sub(internalQuote).gt(0)).to.be.true
    })

    it('Add Liquidity then Remove Half Liquidity: Emits two debit events', async function () {
      await expect(
        contracts.pool.multiOrder(
          [PoolIds.ETH_USDC, PoolIds.ETH_USDC],
          [Kinds.ADD_LIQUIDITY, Kinds.REMOVE_LIQUIDITY],
          10,
          10 * quoteRatio,
          10 * liquidityRatio * half
        )
      )
        .to.emit(contracts.pool, 'Debit')
        .withArgs(contracts.base.address, 10 * half)
        .to.emit(contracts.pool, 'Debit')
        .withArgs(contracts.quote.address, 10 * quoteRatio * half)
    })
  })

  describe('Villager', function () {
    beforeEach(async function () {})

    it('does something cool', async function () {})
    it('does something cool', async function () {})
  })

  describe('PrototypeHyper', function () {
    beforeEach(async function () {
      await contracts.main.a(Values.HUNDRED_ETHER, Values.HUNDRED_ETHER)
    })

    it('Order: Swaps ETH to Token with order type 0x01', async function () {
      let tx: Tx = { to: contracts.main.address, value: '' }
      tx.value = BigNumber.from('1')._hex
      const amount = ethers.utils.parseEther('10')
      const args: Parameters = {
        max: false,
        ord: Orders.SWAP_EXACT_ETH_FOR_TOKENS,
        pair: 1,
        amt: amount,
        output: tx.value,
      }
      tx.data = encodeCalldata(args)
      await expect(context.signer.sendTransaction(tx))
        .to.emit(contracts.main, 'Swap')
        .withArgs(args.ord, args.pair, args.output, args.amt._hex)
    })
  })
})
