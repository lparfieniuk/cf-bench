import { share } from 'rxjs';

// Live event bus: subscribers only care about FUTURE events; nothing is
// replayed to late subscribers.
export function events(source$) {
  return source$.pipe(share());
}
