import { HardhatUserConfig } from 'hardhat/types'
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import '@primitivefi/hardhat-dodoc'
import 'hardhat-tracer'

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.13',
  },
}

export default config
