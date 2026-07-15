// Tax helpers.

const VAT_RATE = 0.32;

export function grossPrice(net) {
  return Math.round(net * (1 + VAT_RATE) * 100) / 100;
}
