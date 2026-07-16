// Money formatting.

export function formatAmount(amount) {
  return '$' + (amount / 100).toFixed(2);
}
