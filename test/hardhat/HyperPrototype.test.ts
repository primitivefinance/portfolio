import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import hre, { ethers } from 'hardhat'
import HyperSDK from '../../compiler/sdk'
import * as instructions from '../../compiler/instructions'
import { hexlify, hexValue, parseEther } from 'ethers/lib/utils'
import { Contract } from 'ethers'

const params = {
  strike: parseEther('10'),
  sigma: 1e4,
  maturity: 3157000,
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
  let deployer: SignerWithAddress, signers: SignerWithAddress[], sdk: HyperSDK, tokens: [Contract, Contract]
  before(async function () {
    signers = await ethers.getSigners()
    deployer = signers[0]
    sdk = new HyperSDK(
      deployer,
      async (signer) => await hre.ethers.getContractFactory('TestDecompilerPrototype', signer),
      async (signer) => await hre.ethers.getContractFactory('HyperForwarderHelper', signer)
    )

    const tokenFactory = await hre.ethers.getContractFactory('TestERC20')
    tokens = await Promise.all([tokenFactory.deploy('Asset', 'AST', 18), tokenFactory.deploy('Quote', 'QT', 18)])
    this.tokens = tokens
  })

  beforeEach(async function () {
    this.hyper = await sdk.deploy()
    await this.hyper.set(1)
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
      const caller = await sdk.forwarder.caller()
      // Mints tokens to the forwarder's caller contract.
      await Promise.all([
        this.tokens[0].mint(caller, parseEther('100')),
        this.tokens[1].mint(caller, parseEther('100')),
      ])

      // Forwarder calls the caller's function to approve the token for the target address to pull from it
      await Promise.all([
        sdk.forwarder.approve(this.tokens[0].address, sdk.instance?.address),
        sdk.forwarder.approve(this.tokens[1].address, sdk.instance?.address),
      ])

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
  })

  describe('Swap', function () {})
})
