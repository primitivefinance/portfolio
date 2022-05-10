import { expect } from 'chai'
import { BigNumber, Signer } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import hre, { ethers } from 'hardhat'
import { TestPrototypeHyper } from '../typechain-types'
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

describe('Prototype', function () {
  let signer: Signer, contract: TestPrototypeHyper

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    contract = await (await ethers.getContractFactory('TestPrototypeHyper')).deploy()
    await contract.deployed()
    await contract.a(parseEther('100'), parseEther('100'))
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
