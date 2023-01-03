import * as dotenv from 'dotenv'
import fs from 'fs'
import { subtask } from 'hardhat/config'
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from 'hardhat/builtin-tasks/task-names'
import { HardhatUserConfig } from 'hardhat/types'
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomicfoundation/hardhat-chai-matchers'
import 'hardhat-preprocessor'
import 'hardhat-dependency-compiler'

dotenv.config()

const PRIMITIVE_RPC = process.env.PRIMTIIVE_RPC ?? ''

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(async (_, __, runSuper) => {
  const paths = await runSuper()

  return paths.filter((p) => !p.endsWith('PoC.sol'))
})

function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split('='))
}

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.13',
        settings: {
          viaIR: false,
          optimizer: {
            enabled: true,
            runs: 15000,
          },
        },
      },
      {
        version: '0.4.18',
      },
    ],
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      blockGasLimit: 30_000_000,
    },
    ganache: {
      url: 'http://localhost:8545',
      chainId: 1337,
    },
    primitive: {
      url: `http://${PRIMITIVE_RPC}:8545`,
      chainId: 1337,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  // Avoid foundry cache conflict.
  paths: { sources: './contracts', cache: 'hh-cache' },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace)
            }
          })
        }
        return line
      },
    }),
  },
  dependencyCompiler: {
    paths: ['solmate/tokens/WETH.sol'],
  },
}

export default config
