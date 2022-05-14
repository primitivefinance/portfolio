import hre from 'hardhat'
import expect from '../shared/expect'
import { utils } from 'ethers'

let testDecoder

describe('testDecoder', () => {
  beforeEach(async () => {
    const TestDecoder = await hre.ethers.getContractFactory('TestDecoder')
    testDecoder = await TestDecoder.deploy()
  })

  it('separates the nibbles of a byte into two bytes', async () => {
    const res = await testDecoder.separate('0x12')
    expect(res.upper).to.eq('0x01')
    expect(res.lower).to.eq('0x02')
  })

  it('converts an array of bytes into a byte32', async () => {
    expect(await testDecoder.toBytes32('0x1234')).to.eq(
      '0x0000000000000000000000000000000000000000000000000000000000001234'
    )
  })

  it('converts a formatted amount into an uint256', async () => {
    const amount = '0x1201'
    expect(await testDecoder.toAmount(amount)).to.eq(utils.parseEther('1'))
  })
})
