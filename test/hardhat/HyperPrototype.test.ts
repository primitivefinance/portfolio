import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { assert, expect } from 'chai'
import hre, { ethers } from 'hardhat'
import { Contract } from 'ethers'
import { parseEther } from 'ethers/lib/utils'

import HyperSDK from '../../compiler/sdk'
import * as instructions from '../../compiler/instructions'

// Default parameters for testing.
const params = {
  strike: parseEther('10'),
  sigma: 1e4,
  maturity: 31556953,
  fee: 1e2,
  price: parseEther('10'),
  liquidity: parseEther('10'),
  tick: 23027, // ~$10, rounded up
}

/**
 * note: If tokens are not deployed, transactions will revert without returning data.
 *
 * @reverts With "NonExistentPool" error, if the `timestamp` public state variable of TestDecompiler is not set from zero.
 */
describe('HyperPrototype', function () {
  let sdk: HyperSDK
  let deployer: SignerWithAddress, signers: SignerWithAddress[]
  let tokens: [Contract, Contract]
  let weth: Contract

  // Setup
  before(async function () {
    signers = await ethers.getSigners()
    deployer = signers[0]
    sdk = new HyperSDK(
      deployer,
      async (signer) => await hre.ethers.getContractFactory('TestDecompilerPrototype', signer),
      async (signer) => await hre.ethers.getContractFactory('HyperForwarderHelper', signer)
    )
    weth = await (await hre.ethers.getContractFactory('WETH9', signers[0])).deploy()
  })

  // Global context for every test.
  beforeEach(async function () {
    this.hyper = await sdk.deploy(weth.address) // Deploys Hyper protocol.
    assert(typeof sdk.instance != 'undefined', 'Hyper contract not there, did it get deployed?')
    assert(typeof sdk.forwarder != 'undefined', 'Forwarder contract not there, did it get deployed?')

    this.caller = await sdk.forwarder.caller()

    // --- Prerequisites for testing --- //

    // - IMPORTANT FOR TESTING - //
    // This internally sets the timestamp for the contract's _blockTimestamp() function.
    await this.hyper.set(1)

    // Deploys tokens.
    const factory = await hre.ethers.getContractFactory('TestERC20')
    tokens = await Promise.all([factory.deploy('Asset', 'AST', 18), factory.deploy('Quote', 'QT', 18)])
    this.tokens = tokens

    // Mints tokens to the forwarder's caller contract.
    await Promise.all([
      this.tokens[0].mint(this.caller, parseEther('100')),
      this.tokens[1].mint(this.caller, parseEther('100')),
    ])

    // Forwarder calls the caller's function to approve the token for the target address to pull from it
    await Promise.all([
      sdk.forwarder.approve(this.tokens[0].address, sdk.instance?.address),
      sdk.forwarder.approve(this.tokens[1].address, sdk.instance?.address),
    ])
  })

  describe('Create', function () {
    it('Creates a pair in the createPool call', async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        params.strike,
        params.sigma,
        params.maturity,
        params.fee,
        params.price
      )

      await expect(call)
        .to.emit(sdk.forwarder, 'Success')
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(1, tokens[0].address, tokens[1].address)
    })

    it('Creates a curve in the createPool call', async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        params.strike,
        params.sigma,
        params.maturity,
        params.fee,
        params.price
      )

      await expect(call)
        .to.emit(sdk.forwarder, 'Success')
        .to.emit(sdk.instance, 'CreateCurve')
        .withArgs(1, params.strike, params.sigma, params.maturity, 1e4 - params.fee)
    })

    it('Creates a pool in the createPool call', async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        params.strike,
        params.sigma,
        params.maturity,
        params.fee,
        params.price
      )

      await expect(call)
        .to.emit(sdk.forwarder, 'Success')
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(0x01, tokens[0].address, tokens[1].address)
        .to.emit(sdk.instance, 'CreateCurve')
        .withArgs(0x0001, params.strike, params.sigma, params.maturity, 1e4 - params.fee)
        .to.emit(sdk.instance, 'CreatePool')
        .withArgs(0x0100000001, 1, 1, params.price)
    })

    it('Creates a pair directly', async function () {
      const { hex: data } = instructions.encodeCreatePair(tokens[0].address, tokens[1].address)

      await expect(deployer.sendTransaction({ to: sdk.instance?.address, data, value: BigInt(0) }))
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(1, tokens[0].address, tokens[1].address)
    })

    it('Creates a curve directly', async function () {
      const { hex: data } = instructions.encodeCreatePair(tokens[0].address, tokens[1].address)

      await expect(deployer.sendTransaction({ to: sdk.instance?.address, data, value: BigInt(0) }))
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(1, tokens[0].address, tokens[1].address)
    })
  })

  describe('Liquidity', function () {
    let poolId: number

    beforeEach(async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        params.strike,
        params.sigma,
        params.maturity,
        params.fee,
        params.price
      )

      await call

      poolId = await sdk.forwarder.getPoolId(1, 1)

      // mint tokens and approve hyper
    })

    it('adds liquidity', async function () {
      const hiTick = params.tick + 256
      const loTick = params.tick - 256
      const call = sdk.addLiquidity(poolId, loTick, hiTick, params.liquidity)
      await expect(call).to.emit(sdk.instance, 'AddLiquidity')
      expect(await this.tokens[0].balanceOf(sdk.instance?.address)).to.be.greaterThan(0)
      expect(await this.tokens[1].balanceOf(sdk.instance?.address)).to.be.greaterThan(0)
    })

    it('removes liquidity after adding it', async function () {
      const hiTick = params.tick + 256
      const loTick = params.tick - 256
      let call = sdk.addLiquidity(poolId, loTick, hiTick, params.liquidity)
      await call
      call = sdk.removeLiquidity(false, poolId, loTick, hiTick, params.liquidity)
      await expect(call).to.emit(sdk.instance, 'RemoveLiquidity')
    })
  })

  describe('Swap', function () {
    let poolId: number
    beforeEach(async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        params.strike,
        params.sigma,
        params.maturity,
        params.fee,
        params.price
      )

      await call

      poolId = await sdk.forwarder.getPoolId(1, 1)

      // mint tokens and approve hyper
    })

    it('swaps asset to quote', async function () {
      const hiTick = params.tick + 256
      const loTick = params.tick - 256
      let call = sdk.addLiquidity(poolId, loTick, hiTick, params.liquidity)
      await call

      call = sdk.swapAssetToQuote(false, poolId, parseEther('1'), ethers.constants.MaxUint256)
      await expect(call).to.emit(sdk.instance, 'Swap')
    })
  })
})
