import { expect } from 'chai'
import { BigNumber, Signer } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import hre, { ethers } from 'hardhat'
import { TestPrototypeHyper } from '../typechain-types'
import { decodeEnd, decodeOrder, encodeOrder, encodeParameters, Orders } from './helpers'
const { hexlify } = ethers.utils

interface Tx {
  to: string
  value: string
  data?: string
}

describe('Prototype', function () {
  let signer: Signer, contract: TestPrototypeHyper

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    contract = await (await ethers.getContractFactory('TestPrototypeHyper')).deploy()
    await contract.deployed()
    await contract.a(parseEther('100'), parseEther('100'))
  })

  it('Decodes amount info', async function () {
    const raw = '15.000000000000555000'
    const buf = Buffer.from([0x0b, 0xc3, 0x35, 0x4a, 0x6b, 0xa7, 0xa1, 0x82, 0x2b, 0x05])
    const value = Buffer.from([0x35, 0x4a, 0x6b, 0xa7, 0xa1, 0x82, 0x2b])
    const length = 0x0c
    const value2 = Buffer.from([0x08, 0x58, 0x3c, 0x9f])
    const length2 = 0x06
    const value3 = Buffer.from([0x15, 0x5e, 0x5f])
    const length3 = 0x04
    console.log(
      value.toString('hex'),
      value.toString('hex')[length - 0x01],
      value.toString('hex')[length],
      value.toString('hex')[length + 0x01]
    )

    console.log(
      value2.toString('hex'),
      value2.toString('hex')[length2 - 0x01],
      value2.toString('hex')[length2],
      value2.toString('hex')[length2 + 0x01]
    )

    console.log(
      value3.toString('hex'),
      value3.toString('hex')[length3 - 0x01],
      value3.toString('hex')[length3],
      value3.toString('hex')[length3 + 0x01]
    )

    console.log(hexlify(raw.substring(3, 0x0c).length))
    const amount = ethers.utils.parseEther('14.0000415')
    const params = encodeParameters(Orders.SWAP_EXACT_ETH_FOR_TOKENS, amount)
    console.log({ params })
    const decoded = await contract.testDecodeAmountInfo(params)
    let { ord, len, dec, end, amt } = decoded
    console.log(decoded)
    expect(ord).to.be.hexEqual(decodeOrder(params))
    expect(amt).to.be.hexEqual(amount._hex)
    expect(end).to.be.hexEqual(decodeEnd(params))
  })

  it('Order: Swaps ETH to Token with order type 0x01', async function () {
    const amount = ethers.utils.parseEther('10')
    let tx: Tx = { to: contract.address, value: '' }
    tx.data = encodeOrder(Orders.SWAP_EXACT_ETH_FOR_TOKENS) + amount._hex.substring(2) + '05'
    tx.value = BigNumber.from('1')._hex
    await signer.sendTransaction(tx)
  })

  describe.only('tests hardcoded cases', function () {
    it('Encodes and decodes amount', async function () {
      //const encoded = '0xc3354a6ba7a1822b'
      //const encoded2 = '0x354a6ba7a1822b'
      const raw = '15000000000000555000'
      const full = '0x0bc3354a6ba7a1822b05'
      const data = await contract.testDecodeAmount(full)
      expect(data.toString()).to.equal(raw)
    })
    it('Encodes and decodes amount', async function () {
      const raw = ethers.utils.parseEther('14.0000415').toString()
      const full = '0x0b6b08583c9f05'
      const data = await contract.testDecodeAmount(full)
      expect(data.toString()).to.equal(raw)
    })
    it('Encodes and decodes amount', async function () {
      const raw = ethers.utils.parseEther('14.00415').toString()
      const full = '0x0b4d155e5f05'
      const data = await contract.testDecodeAmount(full)
      expect(data.toString()).to.equal(raw)
    })
    it('Encodes and decodes amount', async function () {
      const raw = ethers.utils.parseEther('2.2').toString()
      const full = '0x0b111605'
      const data = await contract.testDecodeAmount(full)
      expect(data.toString()).to.equal(raw)
    })
  })
})
