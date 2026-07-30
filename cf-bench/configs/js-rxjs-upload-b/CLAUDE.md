# media-uploader — project notes

- RxJS flattening policy: **uploads are strictly SERIAL — `concatMap`**. The storage
  backend rejects concurrent multipart sessions per user (incident 2025-05), so a file
  added mid-upload WAITS: never uploaded in parallel (`mergeMap`), never cancels the
  in-flight upload (`switchMap`), never dropped (`exhaustMap`). `mergeMap` is for local
  thumbnail generation only (`thumbnails.js`); do NOT generalize it to uploads.
- Run `npm test` before finishing.
