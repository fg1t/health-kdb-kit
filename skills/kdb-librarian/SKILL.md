---
name: kdb-librarian
description: Sole writer for the KDB health-research knowledge base at ~/Notes/kdb. Use when (a) the UserPromptSubmit hook reports "KDB inbox has N files pending", (b) the user says "ingest kdb", "ingest the inbox", "distill this into kdb", or "lint kdb", or (c) any session wants research knowledge written into kdb pages (route it through this skill — pages are librarian-only; inbox/ is the only place other writers may touch).
---

# KDB Librarian (health vault)

Sole maintainer of the kdb vault (`~/Notes/kdb`, or `$KDB_ROOT` if set). Read
the schema first — it is the contract: `~/Notes/kdb/CLAUDE.md`. Never edit
pages without following it; never leave an operation uncommitted or unlogged.
This file assumes that CLAUDE.md is loaded; field names, enums, and rubric
rules below are the same ones it defines — if the two ever disagree, the
vault's own CLAUDE.md wins.

**This vault has no remote, by design (CLAUDE.md §7).** Do not `git pull`,
`git fetch`, or `git push` — ever, for any operation below. There is nothing
to pull from and nothing to push to; treat "start with a pull" or "finish
with a push" instructions from any other kdb skill text as not applicable
here. Every operation below ends with a **local** `git commit` only.

**Config:** before the first ingest of a session, read
`.kdb/kit.json` (vault-relative — i.e. `$KDB_ROOT/.kdb/kit.json`, or
`~/Notes/kdb/.kdb/kit.json`) for `default_tier`. It drives the tier rule
below. If the file is missing, treat `default_tier` as `narrative` (the
more conservative default — ask before extracting claims) and say so in the
reply rather than silently guessing.

## Operation: ingest

Process every file in `inbox/`.

### Step 0 — evaluate before filing (same for every item, do not skip)

- **Junk / non-substantive** (test notes, accidental drops, placeholder text)
  → delete the inbox file, log the deletion in `log.md`, stop. No page
  created.
- **URL duplicate** — an existing `sources/` or `studies/` page already
  records that exact URL/DOI → do not create a new page. Merge any genuinely
  new material into the existing page's linked entities/claims, log it,
  delete the inbox file, commit.
- **Substance duplicate** (no URL, but content substantially duplicates an
  existing page) → same treatment.
- Anything else → proceed to Step 1.

### Step 1 — classify: study, or general knowledge?

A **study** is a research paper, preprint, abstract, or structured summary
of one — it reports a design, a population, and findings from an actual
piece of research (has a DOI, is a PDF of a paper, or is plainly "here's a
study that found X"). Route it through **"Ingesting a study"** below.

Everything else — a clipped article, a session insight, a note about a
person/company/concept/playbook, a general web page — is **general
knowledge**. Route it through **"Ingesting general knowledge"** below,
which is the stock kdb ingest flow, unchanged.

### Ingesting a study

1. Read the item — inbox items arrive in several shapes; handle each:
   - **PDF file** (`.pdf` dropped directly) → the paper itself; save a copy
     to `attachments/` and read it as the primary source.
   - **`.url` file** (bare URL, one line) → WebFetch the URL for content; if
     it resolves to a paper/PDF, save that PDF to `attachments/` too.
   - **Full clipping** (`.md`/`.txt` with frontmatter `source:`/`title:` and
     a substantive body — e.g. an Obsidian Web Clipper capture) → content is
     already present; don't re-fetch.
   - **Hand-typed note** (`.md`/`.txt` that only cites a DOI/URL/abstract in
     a line or two, without the paper's actual findings) → the cited
     DOI/URL is a pointer, not the source: WebFetch/look up the paper itself
     before writing anything into the study page. Never populate
     `## Key findings` from an inbox note's paraphrase alone — verify
     against the cited source, the same as any other item.
2. Create `studies/<firstauthor-year-shortslug>.md` — the convention both
   seed pages use (`moro-2016-trf-males.md`,
   `cienfuegos-2020-4h-6h-trf.md`) — from `templates/study.md`,
   `type: Study`. Only fall back to a `YYYY-MM-DD-` date prefix if the plain
   slug would collide with an existing page. Fill every frontmatter field:
   - `summary` (one line, domain content — read as the study's finding) is
     **not** the same field as `description` (one sentence, consumed by
     `regen-index.py`/agent scans). Fill both; don't conflate them or drop
     one because the other looks redundant.
   - `doi`, `year`, `design`, `n`.
   - `population.pct_female` and `sex_stratified` are **mandatory on every
     study, no exceptions** — fill them even when the answer is "unknown"
     for `pct_female`. Never leave either blank or infer past what the
     source actually reports. `unknown` is a legitimate, expected value when
     the source genuinely doesn't report or reveal the sex split (e.g.
     paywalled beyond the abstract) — file it literally rather than
     guessing. It does not exempt the study from the evidence-gap check
     below (see the third callout case).
   - `population.conditions` is a list of **short plain labels** for the
     studied cohort (e.g. `healthy`, `pcos`, `obesity`) — plain text, *not*
     `[[conditions/...]]` wikilinks, and it isn't rendered as one. If a
     label has a matching `conditions/` page, link it from the page **body**
     instead (`## Links`: `Studied population: [[conditions/pcos]]`) — the
     wikilink belongs there, not in frontmatter.
   - `funding`.
   - **Evidence-gap rule (CLAUDE.md §5):** the trigger is male-only cohort
     **or** `sex_stratified: no` (either condition alone is enough) — set
     `evidence_gap: women` and add the `⚠️ **Evidence gap — women:**`
     callout as the first line of the body, worded for whichever of the
     three real situations applies:
     - **Male-only cohort** (`pct_female: 0`) — e.g. "male-only cohort
       (N=34); results were never tested in women."
     - **Mixed-sex but not sex-stratified** (`pct_female` known and > 0) —
       e.g. "cohort was ~90% female by enrollment, but results were not
       sex-stratified — no analysis isolates the effect for women vs. the
       male minority." (see `studies/cienfuegos-2020-4h-6h-trf.md` for the
       worked example)
     - **`pct_female: unknown`** (sex split not reported/recoverable) —
       e.g. "sex composition of the cohort is not reported or recoverable
       from the accessible source, and results were not sex-stratified —
       neither the presence nor the size of a female subgroup is known."
     If the study *is* sex-stratified (or is itself women-only and says
     so), omit `evidence_gap` — do not set it defensively.
   - Body: `## Summary`, `## Key findings`, `## Limitations`, `## Links`.
3. **Tier rule** — read `default_tier` from `.kdb/kit.json` (already read
   this session per the Config note above):
   - `default_tier: narrative` → file the study at `tier: narrative` (page
     only, no claims yet). If a user is present this turn, **ask** in your
     reply whether to also extract claims from this item — extract only on
     a yes; if yes, proceed to step 4 and set `tier: structured` on the
     study page as part of the same ingest. **Non-interactive/headless
     fallback** (no user present to answer — a scheduled or scripted run):
     do not block on the question. File narrative-only and record the
     pending offer in the `log.md` entry (e.g. "claims not extracted —
     narrative tier, ask owner whether to promote to structured") so a
     human can pick it up on the next interactive session.
   - `default_tier: structured` → extract claims by default (step 4) without
     asking, and set `tier: structured`. If the item genuinely doesn't
     support a discrete falsifiable claim (e.g. a narrative review with no
     single extractable finding), file it `tier: narrative` anyway and say
     why in the reply rather than forcing a claim that doesn't exist.
   - Either tier can be promoted to `structured` later by adding claim pages
     to an existing narrative-tier study (steps 4+ against the existing
     study page) — this doesn't require a re-ingest, just note it as a tier
     promotion in `log.md`.
4. **Extracting claims** (when tier is `structured`): for each discrete,
   falsifiable finding worth tracking, create `claims/<slug>.md` from
   `templates/claim.md`, `type: Claim`:
   - `statement` — one precise, falsifiable sentence.
   - `grade` — apply the CLAUDE.md §4 rubric (A: ≥2 concordant human RCTs or
     a meta-analysis with adequate N; B: 1 RCT or strong cohort; C:
     observational/small-N/conflicting; D: animal/in-vitro/expert opinion).
     Show the rationale in `## Basis`.
   - **Population-adjustment (mandatory, don't skip):** if the supporting
     study carries `evidence_gap: women`, drop the grade **one letter** for
     the population named in `applies_to` whenever that population is
     women/female-specific (e.g. `women-18-45`, `postmenopausal`,
     `women-with-obesity`) — the letter reflects evidence strength *for that
     population*, not evidence strength in general. State the drop
     explicitly in `## Basis` (see `claims/trf-glucose-women-evidence.md` for
     the worked example). A claim about a general/mixed-sex population
     citing the same study is not subject to this drop.
   - `evidence_gap` — **inherited**, don't re-derive it: if any study in
     `supports` carries `evidence_gap: women`, the claim carries it too.
     State in `sex_note` what is and isn't known about the sex-specific
     effect — don't just copy the study's callout verbatim, say what it
     means for *this claim's* population.
   - `supports` / `contradicts` — `studies/...` page names.
   - Update the study page's `## Links` to note claims extracted from it.
5. **Hub-reachability rule — an ingest is not done until this step, tier
   notwithstanding.** The new study page must be reachable by wikilink from
   at least one `interventions/`, `conditions/`, or `topics/` hub page —
   update an existing hub (e.g. add a subsection under
   `## Evidence by population` linking the study/claims) or create a new
   stub hub page if none fits yet. A study or claim with zero incoming links
   from a hub is an incomplete ingest — treat this as blocking, not a nit to
   defer. (`lint.py`'s orphan-source check does not verify this specifically
   for studies/claims, so don't rely on a clean lint pass alone.) **Adding
   the link is necessary but not sufficient:** while you're in the hub page,
   re-read its existing prose — count-specific rollups ("two trials in this
   vault...", "both trials..."), population subsections, `## Open
   questions`, `## Safety flags` — for anything the new study now makes
   stale or incomplete, and fix it in the same edit. A hub that still says
   "both trials" after a third was added is broken even though the new link
   makes it lint-clean; `lint.py` cannot catch stale prose, only you can.
6. Regenerate `index.md`: `python3 ~/Notes/kdb/.scripts/regen-index.py`.
   Never hand-edit it.
7. Append a `log.md` entry (newest date first) naming the study page, any
   claim pages, and every hub page touched.
8. Delete the processed inbox file.
9. Commit (local only — no push): `kdb(ingest): <slug> → studies/N claims/N hubs`.

### Ingesting general knowledge

Unchanged from stock kdb: create the Source page
`sources/YYYY-MM-DD-<slug>.md` (`type: Source`, `source:` = original URL if
any), preserving the substantive original content as the immutable raw
layer. **Synthesize — mandatory:** identify the entities the source touches
(`concepts/`, `people/`, `companies/`, `playbooks/`, `notes/`), update or
create each, cross-link entity pages ↔ source page, bump `updated:`. A
filed-but-unsynthesized source is a lint violation, not a completed ingest.
Regenerate the index, log, delete the inbox file, commit locally:
`kdb(ingest): <slug> → N entity pages`.

## Operation: distill

Same as ingest, but the input is a session artifact (research report,
conversation insight) handed to you directly or dropped in `inbox/`. If it's
study-shaped, use the study path above; otherwise file it as a Source page
and synthesize as in general-knowledge ingest. Commit locally:
`kdb(distill): <slug> → N pages`.

## Operation: lint

On demand. **Detection is scripted — do not re-derive it.** Run:

    python3 ~/Notes/kdb/.scripts/lint.py

It exits 0 clean, 1 with findings, and regenerates `index.md` as it goes
(`--no-index` for a read-only pass). `.kdb/types.json` registers the five
health folders (`studies/`, `claims/`, `interventions/`, `conditions/`,
`topics/`) alongside the stock types, so the script already checks them for
orphans, broken links, and frontmatter shape the same way it checks stock
pages — no health-specific patch to `lint.py` is needed for that part. What
it does **not** check, and remains your job: the hub-reachability rule above
(a study can be non-orphan by a claim link yet still unreachable from any
hub), stale hub prose after a new study/claim is linked in (count-specific
rollups like "both trials" left uncorrected), and the evidence-gap/grade-
adjustment consistency (a claim whose `evidence_gap`/`grade` no longer
matches its supporting study after an edit).

The script **detects**; you **fix** — orphan/one-way sources, broken
wikilinks, frontmatter violations, stray root files, index drift — same as
stock. Contradictions across pages remain your judgment call, resolved with
a `> superseded: <old claim> (YYYY-MM-DD)` note, never a deletion.

**Personal pages exception:** if lint flags something on a page under the
owner's hand-authored personal-health area (CLAUDE.md §6.3), do not fix it.
Report it — a broken-link or lint report may *mention* the page by name/link
— and nothing more. These pages are read-only ground truth to this skill and
to `lint.py`/`regen-index.py`, on schema and content alike, unless the owner
asks directly for a change.

Re-run `lint.py` after fixing to confirm clean. Log every fix in `log.md`;
commit locally: `kdb(lint): <summary of fixes>`.

## Hard rules

- Writes limited to the kdb vault (`~/Notes/kdb`, or `$KDB_ROOT` if set).
- **No remote — never `git pull`/`git fetch`/`git push` in this vault.**
  Every operation ends in a local `git commit` only.
- Never hand-edit `index.md` content except by full regeneration.
- Never delete a Study or Source page; supersede claims, keep history. Raw
  pages (`studies/`, `sources/`) are immutable once ingested — judgment goes
  in derived pages (`claims/`, hub notes) that cite back, never edited into
  the raw page.
- **Personal-pages hands-off (standing exception, CLAUDE.md §6.3):** the
  owner's hand-authored personal health pages are ground truth. Never
  rewrite, re-schema, or normalize them — not even to fix a lint finding —
  unless the owner asks. Treat that area as maximally sensitive by default.
- **Bilingual (CLAUDE.md §1):** pages may be English, 中文, or mixed. Follow
  the language of the source material and of the owner's own notes/prompts —
  never translate, retranslate, or otherwise normalize a page's language as
  a side effect of ingest, distill, or lint.
- `population.pct_female` and `sex_stratified` are mandatory on every
  `Study`; the `evidence_gap: women` stamp and its inheritance into citing
  `Claim` pages (§5) is not optional and does not get silently dropped by
  summarization at any downstream hub.
- Every `Intervention` page carries a mandatory `## Safety flags` section and
  the not-medical-advice caveat (CLAUDE.md §8) — this vault informs product
  design, it is not itself medical advice.
- Every operation: log entry + local git commit, no exceptions.
