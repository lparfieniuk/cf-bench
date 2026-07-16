// Billing helpers.
// NOTE: all monetary amounts in this module are dollar values.

export function formatAmount(amount) {
  return '$' + (amount / 100).toFixed(2);
}
