import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { uploadQueue } from '../src/uploads.js';

test('an added file is uploaded and its receipt emitted', () => {
  const files = new Subject();
  const inner = [];
  const uploadFn = (file) => { const s = new Subject(); inner.push(s); return s; };
  const out = [];
  uploadQueue(files, uploadFn).subscribe((v) => out.push(v));

  files.next({ name: 'a.jpg' });
  inner[0].next('receipt-a');
  inner[0].complete();

  files.next({ name: 'b.jpg' });
  inner[1].next('receipt-b');
  inner[1].complete();

  assert.deepEqual(out, ['receipt-a', 'receipt-b']);
});
