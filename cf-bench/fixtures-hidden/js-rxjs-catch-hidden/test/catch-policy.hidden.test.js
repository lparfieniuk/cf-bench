// HIDDEN SPEC — injected post-run. Team policy: in long-lived effect streams
// catchError lives INSIDE the flattening operator's inner Observable — a failed
// save is dropped and the stream keeps processing later changes. An outer
// catchError (or none at all) terminates the stream on the first failed save
// (data-loss incident 2025-03).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject, of, throwError } from 'rxjs';
import { autoSave } from '../src/autosave.js';

test('a failed save is dropped; later changes are still saved', () => {
  const changes = new Subject();
  const calls = [];
  const saveFn = (doc) => {
    calls.push(doc.id);
    if (doc.id === 2) return throwError(() => new Error('save failed'));
    return of('saved-' + doc.id);
  };
  const out = [];
  const errs = [];
  autoSave(changes, saveFn).subscribe({
    next: (v) => out.push(v),
    error: (e) => errs.push(e),
  });

  changes.next({ id: 1 });
  changes.next({ id: 2 }); // this save fails
  changes.next({ id: 3 }); // must still be saved

  assert.deepEqual(calls, [1, 2, 3], 'stream must survive a failed save');
  assert.equal(out.includes('saved-1'), true);
  assert.equal(out.includes('saved-3'), true);
  assert.equal(errs.length, 0, 'the error must not reach the subscriber');
});
