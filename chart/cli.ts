import { plotFromParameters } from './plot'
import type { Parameters } from './swapMath'

// yarn plot --price 10 --strike 10 --vol 1 --tau 365 --swapQuoteIn 0.061707 --fee 0.0015
async function main() {
  let parameters: Parameters = {
    price: 0,
    strike: 0,
    vol: 0,
    tau: 0,
    fee: 0,
  }

  process.argv.forEach((val, index, array) => {
    if (index < 2) return // [binary, path-to-script, ...]
    // grab the key value pairs, starting at index 2. This means all "odd" indexes are values.
    let isKey = index % 2 === 0
    if (!isKey) return // already handled when we hit the key

    // we got a key! grab the next item in the array as its value
    if (!val.startsWith('--')) throw new Error('invalid key, are you missing `--`?')

    let key = val.split('--').reverse()[0] // grab the key after the --
    let value = Number(array[index + 1])
    if (value === 0) throw new Error(`Value for ${key} cannot be zero.`)

    // populate
    parameters[key as keyof Parameters] = value
  })

  plotFromParameters(parameters)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
