function toHex(input) {
  return input.toString(16).length % 2 == 0 ? input.toString(16) : `0${input.toString(16)}`;
}

function fromAmount(amount) {
  let power = 0;

  while (amount % 10n == 0) {
    amount /= 10n;
    ++power;
  }

  console.log(amount, power);

  return `${toHex(power)}${toHex(amount)}`;
}

function encodeClaim(poolId, fee0, fee1) {
  let data = '';

  let encodedPoolId = toHex(poolId);
  let encodedFee0 = fromAmount(fee0);
  let encodedFee1 = fromAmount(fee1);

  data += toHex(16);
  data += toHex((data.length + encodedPoolId.length) / 2 + 1);
  data += encodedPoolId;
  data += toHex((data.length + encodedFee0.length) / 2 + 1);
  data += encodedFee0;
  data += encodedFee1;

  return data;
}

function encodeSwap(
  useMax,
  sellAsset,
  poolId,
  amount0,
  amount1,
) {
  let data = '';

  let encodedPoolId = toHex(poolId);
  let encodedAmount0 = fromAmount(amount0);
  let encodedAmount1 = fromAmount(amount1);

  data += useMax ? '1' : '0';
  data += '5';
  data += sellAsset ? '01' : '00';
  data += toHex((data.length + encodedPoolId.length) / 2 + 1);
  data += encodedPoolId;
  data += toHex((data.length + encodedAmount0.length) / 2 + 1);
  data += encodedAmount0;
  data += encodedAmount1;

  return data;
}
