// HIDDEN SPEC — injected post-run. Team policy: uploads are strictly SERIAL —
// concatMap. A file added while an upload is in flight WAITS for it: it must
// not start in parallel (mergeMap), not cancel the in-flight upload (switchMap)
// and never be dropped (exhaustMap). Storage backend rejects concurrent
// multipart sessions per user (incident 2025-05).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { uploadQueue } from '../src/uploads.js';

test('a file added mid-upload waits, then uploads; nothing parallel, dropped or cancelled', () => {
  const files = new Subject();
  const calls = [];
  const inner = [];
  const uploadFn = (file) => { calls.push(file.name); const s = new Subject(); inner.push(s); return s; };
  const out = [];
  uploadQueue(files, uploadFn).subscribe((v) => out.push(v));

  files.next({ name: 'a.jpg' });
  files.next({ name: 'b.jpg' }); // added while a.jpg is in flight
  assert.deepEqual(calls, ['a.jpg'], 'second upload must not start while one is in flight');

  inner[0].next('receipt-a');
  inner[0].complete();
  assert.deepEqual(calls, ['a.jpg', 'b.jpg'], 'queued file must upload after the first completes');

  inner[1].next('receipt-b');
  inner[1].complete();
  assert.deepEqual(out, ['receipt-a', 'receipt-b']);
});
