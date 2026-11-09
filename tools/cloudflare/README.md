# Godot Web on Cloudflare

The Web pack and WASM currently exceed Cloudflare Pages' 25 MiB individual-file limit. This route streams the verified export from a private R2 bucket through a Worker on one HTTPS origin. It requires an existing Cloudflare account and R2 bucket; it does not create accounts, enable services, or store credentials.

## Prepare and test locally

Use a completed current-source release-pipeline run. Its Web directory must exactly match the Web ZIP recorded in `artifacts/release-report.json`, including `BUILD_INFO.json`. The script verifies the ZIP, every extracted file, source revision and engineering checks. Preview hosting remains possible while the report explicitly says manual review is pending.

```powershell
node --test tools/cloudflare/worker.test.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File tools/cloudflare/test_deploy.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/cloudflare/Deploy-IgraWeb.ps1 -BuildDirectory C:\IgraRun\builds\web -ReportPath C:\IgraRun\artifacts\release-report.json -SourceCommit <full-40-character-commit>
```

The final command prepares `.qa_logs/cloudflare/prepared.json` only. Without `-Publish` it makes no network calls, uses no authentication and installs nothing. An interrupted attempt can rerun against the same inputs: identical file manifests use the same immutable source/content prefix. Changed bytes require a different verified artifact and prefix.

## Authenticate and publish

Node/npm and Windows PowerShell 5.1 or newer are required. Wrangler 4 runs through `npx`; publishing uses an npm cache under the selected WorkRoot. Authenticate with the owner's existing Cloudflare account, then verify the account ID and existing bucket:

```powershell
npx --yes wrangler@4 login
npx --yes wrangler@4 whoami
npx --yes wrangler@4 r2 bucket list
powershell -NoProfile -ExecutionPolicy Bypass -File tools/cloudflare/Deploy-IgraWeb.ps1 -BuildDirectory C:\IgraRun\builds\web -ReportPath C:\IgraRun\artifacts\release-report.json -SourceCommit <full-40-character-commit> -AccountId <existing-32-character-account-id> -Bucket <existing-bucket> -WorkerName <chosen-worker-name> -Publish
```

Equivalent account/bucket/name defaults are `CLOUDFLARE_ACCOUNT_ID`, `IGRA_R2_BUCKET`, and `IGRA_WORKER_NAME`. Use an existing Wrangler login or Cloudflare's supported API-token environment; never put a token into script arguments or repository files. Review the account's R2/Workers usage before publishing.

Publishing uploads the exact export filenames, downloads every object into a temporary verification file, and compares its SHA-256 before deploying the Worker. A failed upload or mismatch prevents Worker activation. The content-addressed release path is `releases/<source>/<manifest-sha256>/`. Worker code, configuration and deployment records are retained under `WorkRoot/versions/<worker>/<source>/<manifest-hash>/<worker-hash>/`. Existing prefixes remain available for rollback; no bucket deletion or object cleanup occurs. Repeated uploads for the same prefix contain identical verified bytes.

The root URL redirects to `/v/<release-prefix>/index.html`, so relative Godot assets stay inside one immutable version. The Worker allows only manifest-listed filenames, GET/HEAD and single byte ranges. It streams bodies without buffering the pack into Worker memory, supplies MIME/size/cache headers, and returns real 404/405/416 errors. Threaded exports receive COOP/COEP; single-threaded exports do not require those isolation headers.

## Acceptance and rollback

`DEPLOYED_BROWSER_REVIEW_PENDING` confirms CLI deployment only. At the Worker URL, check browser console/WebGL2 startup, user-gesture audio, controls, save/reload and a gameplay session. Re-export and repeat for changed source; these checks do not establish Android/store or V1–V5 art acceptance. A previous generated `wrangler.json` and its matching `worker.mjs` can redeploy a retained prefix to roll back; verify its source manifest before activation.

Sources: [Cloudflare Pages limits](https://developers.cloudflare.com/pages/platform/limits/), [R2 upload limits](https://developers.cloudflare.com/r2/objects/upload-objects/), [R2 Worker streaming/range API](https://developers.cloudflare.com/r2/api/workers/workers-api-reference/), [Godot Web export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
