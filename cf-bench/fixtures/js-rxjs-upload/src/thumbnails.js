import { mergeMap } from 'rxjs';

// Thumbnail generation: images are independent, generate in parallel
// for throughput.
export function thumbnails(images$, generateFn) {
  return images$.pipe(mergeMap(generateFn));
}
