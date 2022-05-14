import { expect } from 'chai'
import { BigNumber, Signer } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import hre, { ethers } from 'hardhat'
import { toBn } from 'evm-bn'
import { TestPrototypeHyper } from '../../typechain-types'
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
} from '../helpers'
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

  describe('Decoder', function () {
    testAmountCases.forEach(({ raw, full }) => {
      it('Decodes amount information', async function () {
        const data = await contract.testDecodeAmount(full)
        expect(data.toString()).to.deep.equal(parseEther(raw).toString())
      })
      it('Decodes all information', async function () {
        const data = await contract.testDecodeInfo(full)
        const hex = hexToBytes(full.substring(2))
        expect(data.max).to.be.deep.equal(hexlify(hex[0] >> 4))
        expect(data.ord).to.be.deep.equal(hexlify(hex[0] & 0x0f))
        expect(data.len).to.be.deep.equal(hex[1] >> 4 <= 1 ? hexlify(0x0) : hexlify(hex[1] >> 4))
        expect(data.dec).to.be.deep.equal(hexlify(hex[1] >> 4 <= 1 ? hex[1] : hex[1] & 0x0f))
        expect(data.end).to.be.deep.equal(hexlify(hex[hex.length - 1]))
        expect(data.amt.toString()).to.deep.equal(parseEther(raw).toString())
      })
    })
  })

  describe('Encoder', function () {
    testAmountCases.forEach(({ raw, full }) => {
      it('Encodes all info then checks it individually', async function () {
        const wei = parseEther(raw).toString()
        const { firstByte, secondByte, middleBytes, lastByte } = deconstructCalldata(full)
        const { max, ord } = decodeFirstByte(firstByte)
        const { inf, dec } = decodeSecondByte(secondByte)
        const { amt } = decodeMiddleBytes(middleBytes)
        const { end } = decodeLastByte(lastByte)
        const bytesArray = [firstByte, secondByte, ...middleBytes, lastByte].map((byteNumber) => hexlify(byteNumber))
        const hexArray = bytesToHex(bytesArray)
        const encodedFirstByte = encodeFirstByte(max, ord)
        const encodedSecondByte = encodeSecondByte(inf, dec)
        const encodedMiddleBytes = encodeMiddleBytes(wei).bytes //hexToBytes(encodeAmount(parseEther(raw)).amount._hex)
        const encodedLastByte = end
        const decodedAmount = runLengthDecode(amt.toString(), dec)
        expect(hexArray).to.be.deep.equal(full)
        expect(+decodedAmount._hex).to.deep.equal(+wei)
        expect(firstByte).to.be.equal(encodedFirstByte)
        expect(secondByte).to.be.equal(encodedSecondByte)
        expect(middleBytes.map((byte) => !isNaN(byte)))
        expect(encodedMiddleBytes.map((val, i) => encodedMiddleBytes[i] === middleBytes[i])).to.be.deep.eq(
          encodedMiddleBytes.map((val, i) => true)
        )
        expect(lastByte).to.be.deep.equal(encodedLastByte)
      })

      it('Encodes all information and compares against original calldata', async function () {
        const data = await contract.testDecodeInfo(full)
        const { firstByte, secondByte, middleBytes, lastByte } = deconstructCalldata(full)
        const { max, ord } = decodeFirstByte(firstByte)
        const { inf, dec } = decodeSecondByte(secondByte)
        const { amt } = decodeMiddleBytes(middleBytes)
        const { end } = decodeLastByte(lastByte)
        expect(data.max).to.be.deep.equal(hexlify(max ? 1 : 0))
        expect(data.ord).to.be.deep.equal(hexlify(ord))
        expect(data.len).to.be.deep.equal(hexlify(inf))
        expect(data.dec).to.be.deep.equal(hexlify(dec))
        expect(data.end).to.be.deep.equal(hexlify(end))
        expect(+data.amt._hex).to.deep.equal(+runLengthDecode(amt.toString(), dec)._hex)
        expect(+data.amt._hex).to.deep.equal(+parseEther(raw)._hex)
        expect(bytesToHex([firstByte, secondByte, ...middleBytes, lastByte])).to.be.deep.equal(hexlify(full))
      })
    })
  })
})
