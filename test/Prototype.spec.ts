import { expect } from 'chai'
import { BigNumber, BigNumberish, Signer } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import hre, { ethers } from 'hardhat'
import { TestPrototypeHyper } from '../typechain-types'
import { TestERC20 } from '../typechain-types/test/TestERC20'
import { TestHyperLiquidity } from '../typechain-types/test/TestHyperLiquidity'
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

const testAmountCases = [
  { raw: '15.000000000000555', full: '0x0bc3354a6ba7a1822b05' },
  { raw: '14.0000415', full: '0x0b6b08583c9f05' },
  { raw: '14.00415', full: '0x0b4d155e5f05' },
  { raw: '2.2', full: '0x0b111605' },
]

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

async function setupPool(
  contract: TestHyperLiquidity,
  poolId: number,
  tokenBase: string,
  tokenQuote: string,
  internalBase: BigNumberish,
  internalQuote: BigNumberish,
  internalLiquidity: BigNumberish
) {
  await contract.setTokens(poolId, tokenBase, tokenQuote)
  await contract.setLiquidity(poolId, internalBase, internalQuote, internalLiquidity)
}

describe('Prototype', function () {
  let signer: Signer, contract: TestPrototypeHyper, hyperLiquidity: TestHyperLiquidity
  let tokenBase: TestERC20,
    tokenQuote: TestERC20,
    user: string,
    poolId = 1,
    initialBase = 100,
    initialQuote = 500,
    initialLiquidity = 1000

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    user = await signer.getAddress()
    const wad = parseEther('1')
    contract = await (await ethers.getContractFactory('TestPrototypeHyper')).deploy()
    hyperLiquidity = await (await ethers.getContractFactory('TestHyperLiquidity')).deploy()
    tokenBase = await (await ethers.getContractFactory('TestERC20')).deploy('base', 'base', 18)
    tokenQuote = await (await ethers.getContractFactory('TestERC20')).deploy('quote', 'quote', 18)
    await tokenBase.mint(user, wad)
    await tokenQuote.mint(user, wad)
    await tokenBase.approve(hyperLiquidity.address, ethers.constants.MaxUint256)
    await tokenQuote.approve(hyperLiquidity.address, ethers.constants.MaxUint256)
    await contract.deployed()
    await contract.a(parseEther('100'), parseEther('100'))
    await setupPool(
      hyperLiquidity,
      poolId,
      tokenBase.address,
      tokenQuote.address,
      initialBase,
      initialQuote,
      initialLiquidity
    )
  })

  describe('Add + Remove Half Liquidity', function () {
    let ratio = 500 / 100
    let ratioLiq = 1000 / 100
    let dB = 10
    let dQ = dB * ratio
    let netLiquidityFactor = 0.5
    let dL = dB * ratioLiq * netLiquidityFactor // remove half the liquidity
    let addLiq = 0
    let removeLiq = 1

    it('Add Liquidity: Debts both tokens and emits a debit', async function () {
      await expect(hyperLiquidity.multiOrder([poolId, poolId], [addLiq, removeLiq], dB, dQ, dL))
        .to.emit(hyperLiquidity, 'Debit')
        .withArgs(tokenBase.address, dB * netLiquidityFactor)
        .to.emit(hyperLiquidity, 'Debit')
        .withArgs(tokenQuote.address, dQ * netLiquidityFactor)
    })

    it('Add Liquidity: Debts both tokens and pays tokens', async function () {
      await expect(() =>
        hyperLiquidity.multiOrder([poolId, poolId], [addLiq, removeLiq], dB, dQ, dL)
      ).to.changeTokenBalances(tokenBase, [hyperLiquidity, signer], [dB * netLiquidityFactor, -dB * netLiquidityFactor])
    })
  })

  it('Order: Swaps ETH to Token with order type 0x01', async function () {
    let tx: Tx = { to: contract.address, value: '' }
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
    await expect(signer.sendTransaction(tx))
      .to.emit(contract, 'Swap')
      .withArgs(args.ord, args.pair, args.output, args.amt._hex)
  })
})
