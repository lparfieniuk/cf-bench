import { switchMap } from 'rxjs';

// House pattern for user-input streams: map each input to at most one
// in-flight request.
export function searchResults(query$, fetchFn) {
  return query$.pipe(switchMap(fetchFn));
}
