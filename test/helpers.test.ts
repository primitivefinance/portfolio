import { expect } from 'chai'
import { encodeOrder, Orders } from './helpers'

describe('Helpers', function () {
  it('Encodes a swap exact eth order', async function () {
    expect(encodeOrder(Orders.SWAP_EXACT_TOKENS_FOR_TOKENS)).to.be.hexEqual('0x05')
  })
})
