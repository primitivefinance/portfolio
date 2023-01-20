import asciichart from 'asciichart'
import { plot, Plot } from 'nodeplotlib'
import { plot as asciiPlot } from './asciichart-extended'
import {
  years,
  getYWithX,
  getXWithPrice,
  getPriceWithX,
  computeMarginalPriceQuoteIn,
  getAmounts,
  computeMarginalPriceAssetIn,
  computePriceWithChangeInTau,
} from './swapMath'
import type { Parameters } from './swapMath'

export function plotReservesAndPricePoint(parameters: Parameters, names?: string[]): Plot[] {
  let _t = years(parameters.tau)
  let R_x = getXWithPrice(parameters.price, parameters.strike, parameters.vol, _t)
  let R_y = getYWithX(R_x, parameters.strike, parameters.vol, _t, 0)
  let P_0 = getPriceWithX(R_x, parameters.strike, parameters.vol, _t)
  return [
    {
      x: [R_x],
      y: [R_y],
      mode: 'text+markers',
      type: 'scatter',
      name: names?.[0] ?? 'Reserves',
      text: [`(${R_x.toFixed(4)},${R_y.toFixed(4)})`],
      textfont: {
        family: 'Times New Roman',
      },
      textposition: 'bottom center',
    },
    {
      x: [R_x],
      y: [P_0],
      mode: 'text+markers',
      type: 'scatter',
      name: names?.[1] ?? 'Reported Price',
      text: [`(${R_x.toFixed(4)},${P_0.toFixed(4)})`],
      textfont: {
        family: 'Times New Roman',
      },
      textposition: 'bottom center',
    },
  ]
}

export function plotMarginalPriceQuoteIn(parameters: Parameters): Plot {
  if (typeof parameters['swapQuoteIn'] === 'undefined')
    throw new Error('Trying to plot marginal price without a quote input!')
  let [R_x, R_y] = getAmounts(parameters)
  let _t = years(parameters.tau)
  let d_yPrime = computeMarginalPriceQuoteIn(
    parameters.swapQuoteIn,
    R_y,
    parameters.strike,
    parameters.vol,
    _t,
    parameters.fee,
    0
  )
  return {
    x: [R_x],
    y: [d_yPrime],
    mode: 'text+markers',
    type: 'scatter',
    name: 'Marginal price quote in',
    text: [`(${R_x.toFixed(4)},${d_yPrime.toFixed(4)})`],
    textfont: {
      family: 'Times New Roman',
    },
    textposition: 'bottom center',
  }
}

export function plotMarginalPriceAssetIn(parameters: Parameters): Plot {
  if (typeof parameters['swapAssetIn'] === 'undefined')
    throw new Error('Trying to plot marginal price without an asset input!')
  let [R_x] = getAmounts(parameters)
  let _t = years(parameters.tau)
  let d_xPrime = computeMarginalPriceAssetIn(
    parameters.swapAssetIn,
    R_x,
    parameters.strike,
    parameters.vol,
    _t,
    parameters.fee,
    0
  )
  return {
    x: [R_x],
    y: [d_xPrime],
    mode: 'text+markers',
    type: 'scatter',
    name: 'Marginal price asset in',
    text: [`(${R_x.toFixed(4)},${d_xPrime.toFixed(4)})`],
    textfont: {
      family: 'Times New Roman',
    },
    textposition: 'bottom center',
  }
}

function plotTauChangeInCurve(prevParams: Parameters, name: string): Plot[] {
  if (!prevParams.epsilon) return []
  let price = computePriceWithChangeInTau(
    prevParams.strike,
    prevParams.vol,
    prevParams.price,
    prevParams.tau,
    prevParams.epsilon
  )

  let _tau_initial = years(prevParams.tau)
  let R_x_initial = getXWithPrice(prevParams.price, prevParams.strike, prevParams.vol, _tau_initial)
  let R_y_initial = getYWithX(R_x_initial, prevParams.strike, prevParams.vol, _tau_initial, 0)
  let parameters = { ...prevParams, price, tau: prevParams.tau - prevParams.epsilon }

  let _tau_post = years(parameters.tau)
  let R_x_post = getXWithPrice(parameters.price, parameters.strike, parameters.vol, _tau_post)
  let R_y_post = getYWithX(R_x_post, parameters.strike, parameters.vol, _tau_post, 0)
  let invariant = R_y_initial - R_y_post
  console.log('invariant', invariant)

  let swapIn = {}
  if (parameters.swapAssetIn) {
    let R_x_trade = R_x_post + parameters.swapAssetIn
    let R_x_withFee = R_x_post + parameters.swapAssetIn * 0.8
    let R_y_trade = getYWithX(R_x_withFee, prevParams.strike, prevParams.vol, _tau_post, invariant)
    swapIn = {
      x: [R_x_trade],
      y: [R_y_trade],
      mode: 'text+markers',
      type: 'scatter',
      name: 'Res. swap in asset',
      text: [`(${R_x_trade.toFixed(4)},${R_y_trade.toFixed(4)})`],
      textfont: {
        family: 'Times New Roman',
      },
      textposition: 'bottom center',
    }
  }

  let xArray = new Array(101)
  let yArray = new Array(101)
  let priceArray = new Array(101)
  let _t = years(parameters.tau)
  for (let i = 0; i < yArray.length; i++) {
    let _x = i / (yArray.length - 1) // between 0 and 1, so we divide by each step!
    let _y = getYWithX(_x, parameters.strike, parameters.vol, _t, 0)
    xArray[i] = _x
    yArray[i] = _y
    priceArray[i] = getPriceWithX(_x, parameters.strike, parameters.vol, _t)
  }

  let plot: Plot[] = []
  plot.push({
    x: xArray,
    y: yArray,
    type: 'scatter',
    name,
  })
  plot.push(...plotReservesAndPricePoint(parameters, ['Res. epsilon', 'Rep. Price epsilon']))

  if ((swapIn as any)?.x) plot.push(swapIn)

  return plot
}

export function plotFromParameters(parameters: Parameters, LOG_ASCII = false) {
  // required parameters
  if (parameters['price'] === 0) throw new Error('missing --price argument')
  if (parameters['strike'] === 0) throw new Error('missing --strike argument')
  if (parameters['vol'] === 0) throw new Error('missing --vol argument')
  if (parameters['tau'] === 0) throw new Error('missing --tau argument')

  // with the parameters, we graph

  let xArray = new Array(101)
  let yArray = new Array(101)
  let priceArray = new Array(101)
  let _t = years(parameters.tau)
  for (let i = 0; i < yArray.length; i++) {
    let _x = i / (yArray.length - 1) // between 0 and 1, so we divide by each step!
    let _y = getYWithX(_x, parameters.strike, parameters.vol, _t, 0)
    xArray[i] = _x
    yArray[i] = _y
    priceArray[i] = getPriceWithX(_x, parameters.strike, parameters.vol, _t)
  }

  if (LOG_ASCII) {
    const config = {
      colors: [asciichart.magenta, asciichart.red],
      title: 'Primitive RMM Curve',
      height: 100,
      width: yArray.length,
      lineLabels: ['curve', 'spot price'],
      xLabel: 'asset reserves * 100',
      yLabel: 'quote reserves',
    }
    console.log(asciiPlot([yArray, priceArray], config as any))
  } else {
    const data: Plot[] = [
      {
        x: xArray,
        y: yArray,
        type: 'scatter',
        name: 'Curve',
      },
      {
        x: xArray,
        y: priceArray,
        type: 'scatter',
        name: 'Reported Price',
      },
      ...plotReservesAndPricePoint(parameters),
      ...plotTauChangeInCurve(parameters, 'epsilon'),
    ]

    if (parameters['swapAssetIn']) data.push(plotMarginalPriceAssetIn(parameters))
    if (parameters['swapQuoteIn']) data.push(plotMarginalPriceQuoteIn(parameters))

    const layout = {
      yaxis: { range: [0, parameters.strike * 1.5] },
      xaxis: { range: [0, 1] },
    }

    plot(data, layout, { displaylogo: false })
  }
}
