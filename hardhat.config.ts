import { HardhatUserConfig } from 'hardhat/types'
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import '@primitivefi/hardhat-dodoc'
import 'hardhat-tracer'
import 'hardhat-gas-reporter'

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
  },
  solidity: {
    version: '0.8.13',
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 50,
    enabled: true,
  },
}

export default config
