// Auto-save effects.

// autoSave(changes$, saveFn) -> Observable of save receipts.
// changes$ emits document snapshots; saveFn(doc) returns an Observable
// of the save receipt. saveFn can error.
export function autoSave(changes$, saveFn) {
  throw new Error('not implemented');
}
