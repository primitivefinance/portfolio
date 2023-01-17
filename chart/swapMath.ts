import gaussian from 'gaussian'

export const years = (days) => days / 365
const between = (x, min, max) => x >= min && x <= max

const snorm = () => gaussian(0, 1)
const cdf = (x) => snorm().cdf(x)
const ppf = (x) => snorm().ppf(x)
const pdf = (x) => snorm().pdf(x)
const d_ppf = (x) => 1 / pdf(ppf(x))

export type Parameters = {
  price: number
  strike: number
  vol: number
  tau: number
  fee?: number
  swapAssetIn?: number
  swapQuoteIn?: number
}

/**
 * @param price A value in $
 * @param strike A value in $
 * @param vol A percentage
 * @param tau Seconds of time remaining
 * @returns R_x Asset reserves.
 */
export function getXWithPrice(price, strike, vol, tau): number {
  let input = Math.log(price / strike) + (Math.pow(vol, 2) / 2) * tau
  return 1 - cdf(input / (vol * Math.sqrt(tau)))
}

/**
 * @param x Amount of Asset reserves. 1 > x > 0.
 * @param strike A value in $
 * @param vol A percentage
 * @param tau Seconds of time remaining
 * @returns R_y Quote reserves.
 */
export function getYWithX(x, strike, vol, tau, inv): number {
  return strike * cdf(ppf(1 - x) - vol * Math.sqrt(tau)) + inv
}

/** price(R_x) = Ke^(Φ^-1(1 - R_x)σ√τ - 1/2σ^2τ) */
export function getPriceWithX(x, strike, vol, tau): number {
  let input = ppf(1 - x) * vol * Math.sqrt(tau) - (Math.pow(vol, 2) / 2) * tau
  return strike * Math.exp(input)
}

export function computeMarginalPriceQuoteIn(d_y, R_y, strike, vol, tau, fee, inv): number {
  let gamma = 1 - fee
  let part0 = R_y + d_y * gamma - inv
  let part1 = part0 / strike
  let part2 = ppf(part1)
  let part3 = part2 + vol * Math.sqrt(tau)
  let part4 = strike / gamma
  let part5 = part4 * pdf(part3)
  let part6 = d_ppf(part1)
  let d_x = part5 * part6
  console.log({ d_x, part0, part1, part2, part3, part4, part5, part6 })
  return d_x
}

export function computeMarginalPriceAssetIn(d_x, R_x, strike, vol, tau, fee, inv): number {
  let gamma = 1 - fee
  let part0 = 1 - R_x - d_x * gamma
  let part1 = ppf(part0)
  let part2 = part1 - vol * Math.sqrt(tau)
  let part3 = strike * gamma
  let part4 = pdf(part2)
  let part5 = part3 * part4
  let part6 = d_ppf(part0)
  let d_y = part5 * part6
  console.log({ d_y })
  return d_y
}

export function getAmounts(parameters: Parameters): [number, number] {
  let _t = years(parameters.tau)
  let R_x = getXWithPrice(parameters.price, parameters.strike, parameters.vol, _t)
  let R_y = getYWithX(R_x, parameters.strike, parameters.vol, _t, 0)
  return [R_x, R_y]
}
