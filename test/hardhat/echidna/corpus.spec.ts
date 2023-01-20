import { ethers } from 'hardhat'
import { expect } from 'chai'

// `yarn prepare:echidna`
// `npx hardhat test ./test/hardhat/echidna/corpus.spec.ts --network etheno`
describe(`constructor of pool`, function () {
  let signer, other
  let risky_18, stable_18, risky_6, stable_6
  let weth
  let hyper
  let forwarder_helper

  before(async function () {
    ;[signer, other] = await (ethers as any).getSigners()
  })

  beforeEach(async function () {
    const Hyper = await ethers.getContractFactory('TestHyperTime')
    const tokenFactory = await ethers.getContractFactory('TestERC20')

    const HyperForwarderHelper = await ethers.getContractFactory('HyperForwarderHelper')
    const WETH = await ethers.getContractFactory('WETH')

    risky_18 = await tokenFactory.deploy('Test Risky 18', 'RISKY18', 18)
    stable_18 = await tokenFactory.deploy('Test Stable 18', 'STABLE18', 18)
    risky_6 = await tokenFactory.deploy('Test Risky 6', 'RISKY6', 6)
    stable_6 = await tokenFactory.deploy('Test Stable 6', 'STABLE6', 6)

    weth = await WETH.deploy()
    hyper = await Hyper.deploy(weth.address)
    forwarder_helper = await HyperForwarderHelper.deploy()

    console.log(`mockRisky18 ${risky_18.address} mockStable18 ${stable_18.address}`)
    console.log(`mockRisky18 ${risky_6.address} mockStable6 ${stable_6.address}`)
    console.log(`forwarder_helper ${forwarder_helper.address}`)
    console.log(`hyper ${hyper.address}`)
    console.log(`weth ${weth.address}`)
  })

  describe('when the contract is deployed', function () {
    it('__account__.settled', async function () {
      const res = await hyper.__account__()
      expect(res.settled).to.equal(true)
    })
  })
})
