const asciichart = require('asciichart')
const stripAnsi = require('strip-ansi')
const assert = require('assert')

function plot(yArray, config = {}) {
  yArray = Array.isArray(yArray[0]) ? yArray : [yArray]
  yArray.forEach((a) => assert(a.length > 0, 'Cannot plot empty array'))

  const originalWidth = yArray[0].length
  if (config.width) {
    yArray = yArray.map((arr) => {
      const newArr = []
      for (let i = 0; i < config.width; i++) {
        newArr.push(arr[Math.floor((i * arr.length) / config.width)])
      }
      return newArr
    })
  }

  const plot = asciichart.plot(yArray, config)

  const xArray = config.xArray || (Array.isArray(yArray[0]) ? yArray[0] : yArray).map((v, i) => i)

  // determine the overall width of the plot (in characters)
  const plotFirstLine = stripAnsi(plot).split('\n')[0]
  const fullWidth = plotFirstLine.length
  // get the number of characters reserved for the y-axis legend
  const leftMargin = plotFirstLine.split(/┤|┼╮|┼/)[0].length + 1

  // the difference between the two is the actual width of the x axis
  const widthXaxis = fullWidth - leftMargin

  // get the number of characters of the longest x-axis label
  const longestXLabel = xArray.map((l) => l.toString().length).sort((a, b) => b - a)[0]
  const tickDistance = longestXLabel + 2

  let ticks = ' '.repeat(leftMargin - 1)
  for (let i = 0; i < widthXaxis; i++) {
    if ((i % tickDistance === 0 && i + tickDistance < widthXaxis) || i === widthXaxis - 1) {
      ticks += '┬'
    } else {
      ticks += '─'
    }
  }

  const lastTickValue = originalWidth - 1

  let tickLabels = ' '.repeat(leftMargin - 1)
  if (widthXaxis <= tickDistance) {
    // too short, just last tick
    tickLabels += lastTickValue.toFixed().padStart(widthXaxis - (tickLabels.length - leftMargin + 1))
  } else {
    for (let i = 0; i < widthXaxis; i++) {
      const tickValue = Math.round((i / widthXaxis) * originalWidth)
      if (i % tickDistance === 0 && i + tickDistance < widthXaxis) {
        tickLabels += tickValue.toFixed().padEnd(tickDistance)

        // final tick
        if (i >= widthXaxis - 2 * tickDistance) {
          if (widthXaxis % tickDistance === 0) {
            tickLabels += lastTickValue.toFixed().padStart(widthXaxis - (tickLabels.length - leftMargin + 1))
          } else {
            tickLabels += lastTickValue.toFixed().padStart(widthXaxis - (tickLabels.length - leftMargin + 1))
          }
        }
      }
    }
  }

  const title = config.title
    ? `${' '.repeat(leftMargin + (widthXaxis - config.title.length) / 2)}${config.title}\n`
    : ''

  let yLabel = ''
  if (config.yLabel || Array.isArray(config.lineLabels)) {
    if (config.yLabel) {
      yLabel += `${asciichart.darkgray}${config.yLabel.padStart(leftMargin + config.yLabel.length / 2)}${
        asciichart.reset
      }`
    }
    if (Array.isArray(config.lineLabels)) {
      let legend = ''
      for (let i = 0; i < Math.min(yArray.length, config.lineLabels.length); i++) {
        const color = Array.isArray(config.colors) ? config.colors[i] : asciichart.default
        legend += `    ${color}─── ${config.lineLabels[i]}${asciichart.reset}`
      }
      yLabel += ' '.repeat(fullWidth - 1 - stripAnsi(legend).length - stripAnsi(yLabel).length) + legend
    }
    yLabel += `\n${'╷'.padStart(leftMargin)}\n`
  }

  const xLabel = config.xLabel
    ? `\n${asciichart.darkgray}${config.xLabel.padStart(fullWidth - 1)}${asciichart.reset}`
    : ''
  return `\n${title}${yLabel}${plot}\n${ticks}\n${tickLabels}${xLabel}\n`
}

module.exports = { plot }
