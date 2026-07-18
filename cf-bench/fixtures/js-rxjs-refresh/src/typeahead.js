import { switchMap } from 'rxjs';

// House pattern for read streams: map each input to at most one in-flight
// request; a new input REPLACES the previous request.
export function typeahead(query$, searchFn) {
  return query$.pipe(switchMap(searchFn));
}
