import { HardhatUserConfig } from 'hardhat/types'
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import '@primitivefi/hardhat-dodoc'

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 400,
      },
    },
  },
}

export default config
