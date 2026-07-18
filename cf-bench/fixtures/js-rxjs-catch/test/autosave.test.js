import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { autoSave } from '../src/autosave.js';

test('saves each change and emits receipts in order', () => {
  const changes = new Subject();
  const inner = [];
  const saveFn = (doc) => { const s = new Subject(); inner.push(s); return s; };
  const out = [];
  autoSave(changes, saveFn).subscribe((v) => out.push(v));

  changes.next({ id: 1 });
  inner[0].next('saved-1');
  inner[0].complete();

  changes.next({ id: 2 });
  inner[1].next('saved-2');
  inner[1].complete();

  assert.deepEqual(out, ['saved-1', 'saved-2']);
});
