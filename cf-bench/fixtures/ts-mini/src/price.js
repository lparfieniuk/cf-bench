// Pricing helpers for the mini storefront.

// BUG (intentional, benchmark target): percent is treated as a fraction,
// so applyDiscount(200, 10) returns -1800 instead of 180.
export function applyDiscount(price, percent) {
  return price * (1 - percent);
}

export function formatPrice(value) {
  return `$${value.toFixed(2)}`;
}
