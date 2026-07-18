import { combineLatest, map } from 'rxjs';

// Live order summary: recompute totals whenever ANY input changes.
export function orderSummary(cart$, shipping$) {
  return combineLatest([cart$, shipping$]).pipe(
    map(([cart, shipping]) => ({ items: cart.length, shipping })),
  );
}
