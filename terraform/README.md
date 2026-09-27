# Terraform

Two roots, each with its own provider, credentials and state:

| Folder | What it holds | Status |
| --- | --- | --- |
| `google/` | The Google Cloud project, its billing link, the APIs we call, their keys | Adopted from the live project (#108). `make tf` runs it. |
| `cloudflare_backup/` | The Cloudflare Tunnel and its DNS record | Reference only, never run from here. Its own README. |

They are separate on purpose: a Google plan never needs a Cloudflare token, and
the day Cloudflare joins it gets its own root, state and `make` target beside
this one rather than a second provider in `google/`.

## Google Cloud (`google/`)

Everything in it was created by hand in the console first, then **imported**,
not recreated: a new project id, OAuth client or API key would each have to be
chased through the app, `.env` and Google's console, and a deleted project id
can never be reused. So the project and both keys carry `prevent_destroy`, and
the project `deletion_policy = "PREVENT"` too.

### What Terraform owns

- **The project** `goalgetter-ai-tutor-1996` (number `330000594920`, name
  "GoalGetter AI Tutor", no organization) and its **billing link** to account
  `0118FD-436A50-6FFD59`.
- **The two APIs GoalGetter calls**: `generativelanguage.googleapis.com` (the
  Gemini API) and `youtube.googleapis.com` (YouTube Data API v3).
- **Both API keys and their restrictions**, each limited to its one API:
  `GoalGetter Gemini Key` → `generativelanguage.googleapis.com`, and
  `GoalGetter YouTube Key` → `youtube.googleapis.com`. Neither has an
  application restriction (referrer, IP), as in the console today; an IP one
  would tie the keys to this home connection's address.

**Which key the backend uses.** `.env` on the deploy machine holds the strings
(`GEMINI_API_KEY`, `YOUTUBE_API_KEY`); they are never written in a `.tf` file.
As of 2026-09-27 `YOUTUBE_API_KEY` is `GoalGetter YouTube Key`, but
`GEMINI_API_KEY` is a key from another of the user's projects, not
`GoalGetter Gemini Key` - #251.

**Why only two services are declared.** The project also has 23 other APIs
enabled that GoalGetter never calls - mostly the set Google switches on for every new
project (BigQuery and its family, Cloud Storage, Logging, Monitoring, Cloud
Trace, Datastore, Dataform, Dataplex, Analytics Hub, Cloud SQL, Service
Management/Usage, `cloudapis`, telemetry) plus `cloudaicompanion` ("Gemini for
Google Cloud", the console assistant - not the Gemini API the backend uses).
Declaring them would make each one read as a dependency of the app; turning them
off would be a live change nobody needs, and Terraform itself calls Service
Usage. `google_project_service` only touches what it declares, so they stay as
they are, unmanaged. The cost: a plan does not notice an API enabled by hand
later. `gcloud services list --enabled --project goalgetter-ai-tutor-1996` shows
the full list. Removing a declared API from `main.tf` stops managing it and never
disables it (`disable_on_destroy = false`).

### What Terraform cannot own: sign-in

The Google provider has no resource for the **OAuth consent screen** or a **web
OAuth client** (`google_iap_brand`/`google_iap_client` are for Identity-Aware
Proxy only). These stay manual, with or without Terraform. What exists, in
project `goalgetter-ai-tutor-1996`:

- **Web client id**
  `330000594920-iuok5ott835b3bb983e6dao0fanrrnmr.apps.googleusercontent.com`.
  The frontend carries it (`frontend/lib/core/config/app_config.dart`, the
  `GOOGLE_CLIENT_ID` define) and the backend checks every ID token's audience
  against `GOOGLE_CLIENT_ID` in `.env` - the same value.
- **Scopes** asked for: `openid`, `email`, `profile`
  (`frontend/lib/core/services/auth_service.dart`).
- **Authorized JavaScript origins** must include the public site,
  `https://goalsgetter.org` (`BASE_URL`). On the web the app signs in through
  Google's own rendered button, which checks the page's origin, so a new origin
  (another domain, the tailnet preview once it has HTTPS) needs adding here
  before sign-in works on it. The app uses no **redirect URI**.

Neither gcloud nor any API reads a web client's origins or the consent screen,
so the list above is what the code needs, not a copy of the console. To check or
change them: [Google Cloud console](https://console.cloud.google.com/auth/clients?project=goalgetter-ai-tutor-1996)
→ **Google Auth Platform** → **Clients** → the web client (origins, redirect
URIs); **Branding** (app name, support e-mail, authorized domains); **Audience**
(publishing status, test users); **Data access** (scopes).

### How to run it

Terraform is not installed on this machine; the root `Makefile` runs the pinned
official image (`TF_IMAGE`, matched by `required_version` in `google/main.tf`):

```bash
make tf                         # terraform plan (init runs first, every time)
make tf ARGS='plan -no-color'   # any subcommand: validate, fmt -check, output ...
make tf ARGS=apply              # interactive: shows the plan and asks
```

Credentials are the active gcloud login (`gcloud auth login` when it expires):
`make tf` exports `gcloud auth print-access-token` as
`GOOGLE_OAUTH_ACCESS_TOKEN` and forwards it to the container by name. No service
account key exists, and none is needed.

**On a machine with no state** the plan reads
`Plan: 5 to import, 0 to add, 0 to change, 0 to destroy.` - the import blocks in
`google/imports.tf` adopt the live resources, and **0 / 0 / 0 is the proof the
declaration matches the project**. `make tf ARGS=apply` then writes the local
state and changes nothing in Google. From there on, `make tf` reports
`No changes.` until someone edits the project in the console or a `.tf` file.
Anything other than import-only on a stateless plan - above all a *create* or a
*replace* - means stop and read it; do not apply.

### State and secrets

- **The state is local and never committed** (`terraform/google/terraform.tfstate`,
  gitignored): it holds both API key strings (`key_string`). Losing it loses
  nothing - the import blocks rebuild it.
- **Never save a plan to a file** (`-out`): a saved plan carries the key strings
  too. `*.tfplan` and `tfplan` are gitignored in case one is written anyway.
- A plan printed to the terminal shows `key_string = (sensitive value)`; the
  strings appear only where asked for in raw form (`terraform show -json`, the
  state file itself).
