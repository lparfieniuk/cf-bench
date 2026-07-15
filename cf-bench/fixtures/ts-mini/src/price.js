// Pricing helpers for the mini storefront.

export function applyDiscount(price, percent) {
  return price * (1 - percent);
}

export function formatPrice(value) {
  return `$${value.toFixed(2)}`;
}
