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

describe('Prototype', function () {
  let signer: Signer, contract: TestPrototypeHyper

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    contract = await (await ethers.getContractFactory('TestPrototypeHyper')).deploy()
    await contract.deployed()
    await contract.a(parseEther('100'), parseEther('100'))
  })

  it('Order: Swaps ETH to Token with order type 0x01', async function () {
    const amount = ethers.utils.parseEther('10')
    let tx: Tx = { to: contract.address, value: '' }
    tx.data = encodeOrder(Orders.SWAP_EXACT_ETH_FOR_TOKENS) + amount._hex.substring(2) + '05'
    tx.value = BigNumber.from('1')._hex
    await signer.sendTransaction(tx)
  })
})
