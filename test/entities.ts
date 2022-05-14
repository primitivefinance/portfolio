// --- Abstract representations of the solidity data structures. --- //

import { BigNumber } from 'ethers'
import { Values } from './constants'

export enum Kinds {
  UNKNOWN,
  ADD_LIQUIDITY,
  ADD_LIQUIDITY_ETH,
  REMOVE_LIQUIDITY,
  REMOVE_LIQUIDITY_ETH,
  SWAP_EXACT_TOKENS_FOR_TOKENS,
  SWAP_TOKENS_FOR_EXACT_TOKENS,
  SWAP_EXACT_ETH_FOR_TOKENS,
  SWAP_TOKENS_FOR_EXACT_ETH,
  SWAP_EXACT_TOKENS_FOR_ETH,
  SWAP_ETH_FOR_EXACT_TOKENS,
  CREATE_POOL,
}

export enum PoolIds {
  ETH_USDC,
}

export interface BlockTimestamp {
  blockTimestamp: number
}

export interface HyperPoolStruct extends BlockTimestamp {
  internalBase: BigNumber
  internalQuote: BigNumber
  internalLiquidity: BigNumber
}

export interface HyperPoolPositionStruct extends BlockTimestamp {
  liquidity: BigNumber
}

export interface HyperPoolTokensStruct {
  tokenBase: string
  tokenQuote: string
}

export class HyperPool {
  globalReserves: any = {}
  pools: any = {}

  constructor() {}

  initPool(id: number) {
    this.pools[id] = {
      internalBase: Values.ZERO_BN,
      internalQuote: Values.ZERO_BN,
      internalLiquidity: Values.ZERO_BN,
      blockTimestamp: 1,
    }
  }

  addLiquidity(id: number, base: BigNumber, quote: BigNumber, liquidity: BigNumber, blockTimestamp: number) {
    this.pools[id] = {
      internalBase: base.add(this.pools[id].internalBase),
      internalQuote: quote.add(this.pools[id].internalQuote),
      internalLiquidity: liquidity.add(this.pools[id].internalLiquidity),
      blockTimestamp: blockTimestamp,
    }
  }

  removeLiquidity(id: number, base: BigNumber, quote: BigNumber, liquidity: BigNumber, blockTimestamp: number) {
    this.pools[id] = {
      internalBase: this.pools[id].internalBase.sub(base),
      internalQuote: this.pools[id].internalQuote.sub(quote),
      internalLiquidity: this.pools[id].internalLiquidity.sub(liquidity),
      blockTimestamp: blockTimestamp,
    }
  }
}
