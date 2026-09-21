# Seed preparation, live-criteria audit, and pilot rules

Run this before the freeze checklist. It answers two questions: *is the seed clean?* and *can the
seed actually fail the criteria we intend to score?*

---

## 0. Which repository is the seed?

Two candidates. The decision is not close, but the loser has a real job.

### `orthoMTL` at `C0` — the seed

It is the only candidate with the three things the design rests on:

| Requirement | `orthoMTL` @ `C0` | `orthopen` |
|-------------|-------------------|------------|
| Accepted version for baseline subtraction (§4.2) | yes | **none — never submitted** |
| Frozen held-out test suite (§5 deletion guard) | yes | **no `tests/` directory at all** |
| Rejection letters as judge calibration ground truth (§5.1.2) | yes | belongs to a different package |
| "What would have happened" is literally true | yes | counterfactual about a package that never went |

**The missing test suite is decisive.** Without a behavioural oracle, an arm can delete
functionality to get a clean check and score perfectly. That loophole is the one §5 exists to close,
and no substitute is available: writing tests for `orthopen` now means writing them against
behaviour you would also be scoring, which is circular.

### The subtler objection: wrong kind of broken

A nine-year-old package needs modernisation — roxygen, `Authors@R`, a `tests/` directory, a
`.Rbuildignore` for that stray `.Rproj`, dependency declarations. That work is real, but **it is not
CRAN-specific**, and it is what a general R-packaging skill addresses rather than a CRAN skill.

Every arm would spend most of its budget on the same modernisation, and the CRAN-compliance signal —
the thing the study measures — would be a thin layer on top of a thick layer of shared refactoring.
The effect you care about gets swamped by work that no arm's skill differentiates.

`orthoMTL` @ `C0` is already a package; the remaining distance is exactly CRAN compliance. That is
the right task shape.

### On the resubmission worry

Not a reason to switch seeds. Egress to CRAN submission endpoints is blocked at the container level
and every run greps its transcript for attempts (`run_arm.sh`). Arms also produce states that differ
from the accepted version, so nothing any arm builds *is* the published package.

### What `orthopen` is genuinely good for

**The deliberately-broken tree for rule validation.** §4.3 requires the finding parser and every
static rule to be validated against "the baseline plus one deliberately broken tree" before any arm
runs. `orthopen` is that tree, naturally — no fabrication, no fitting.

From the repository page alone it visibly carries: `"Orthopen in R"` (C01, the "in R" rule), a 2014
reference as a bare publisher URL rather than `doi:` form (C08/L13), `orthopen.Rproj` at top level
with no `.Rbuildignore` (L38-adjacent), `install_github()` instructions in the README, and a
malformed markdown link. A rule set that fires on all of those is a rule set that works.

Use it this week. It needs no run budget and it validates the scoring pipeline before Phase 1.

**Reconsider only on data.** Run the §3 seed audit on `orthoMTL` @ `C0` first. If both the violation
set and the regression surface come out thin, revisit — but then the honest move is a second study on
a held-out package with its own oracles, not swapping a seed that lacks them.

---

## 1. Extracting the seed

**`git clone` at a commit is not acceptable.** A clone carries the whole object database — every
later branch, every fix, every CRAN-preparation commit. `git log C0..HEAD`, `git show`, or a glance
at `.git/packed-refs` hands the agent the answers. Export a tree instead.

```bash
# Identify C0 — the commit where the CRAN packaging conversation began.
git log --reverse --oneline --date=short --pretty='%h %ad %s' | head -40

# Confirm what that tree contains before exporting.
git ls-tree -r --name-only C0

# Export. No .git, no branches, no reflog, no history of any kind.
mkdir -p arms/A0/pkg
git archive C0 | tar -x -C arms/A0/pkg
```

### Identifying `C0` in this repository

**DECIDED: `C0` = the first commit of `Novartis/orthoMTL`.**

`https://github.com/Novartis/orthoMTL/tree/main/R` is **HEAD** — the accepted state. That is the
baseline for subtraction (§4.2) and the source of the frozen test suite (§5). It is not the seed.

The accepted package's own NEWS describes the release as a major refactor and scope expansion of
`orthopen`, adding survival/censoring support, an `alpha` mixing parameter, cross-validation,
bootstrap and plotting helpers, and renaming `orthopen()` to `orthoMTL()`. `Novartis/orthoMTL` is
therefore the CRAN-targeted successor repository, and its first commit is where the CRAN effort
begins.

Chosen because it needs no judgement call. "The first commit of the repository" is one sentence on a
slide and cannot be accused of having been picked after seeing results.

#### The one hazard: a scaffold-only initial commit

Corporate repositories frequently open with a template — LICENSE, CODE_OF_CONDUCT, `.github/`
templates, a README stub, and **no package at all**. If that is what the first commit holds, the arms
would be asked to write a package from scratch rather than to prepare one for CRAN. That is a
different experiment, and a far worse one: the CRAN signal would be buried under authorship work no
skill differentiates.

**Pre-registered rule, stated now so the fallback is not a post-hoc choice:**

> `C0` is the first commit of `Novartis/orthoMTL` that contains an installable package — a
> `DESCRIPTION` and an `R/` directory with at least one function. If the initial commit satisfies
> this, `C0` is the initial commit.

Verify before freezing:

```bash
git clone https://github.com/Novartis/orthoMTL.git && cd orthoMTL

FIRST=$(git rev-list --max-parents=0 HEAD)
echo "first commit: $FIRST"
git show --stat "$FIRST" | head -30
git ls-tree -r --name-only "$FIRST"

# Does the first commit hold a package?
git ls-tree -r --name-only "$FIRST" | grep -E '^DESCRIPTION$|^R/.*\.[Rr]$'

# If not, find the first commit that does.
git log --reverse --diff-filter=A --pretty='%h %ad %s' --date=short -- DESCRIPTION | head -5
```

#### Leak checks at `C0`

1. **CRAN intent already stated.** Public Novartis repo — the README or DESCRIPTION may already
   announce CRAN as the target, or name the required structure. Grep, strip, log the strip.
2. **Imported-from-later-state scaffolding.** If the first commit imported `orthopen` alongside work
   already done toward submission, it may carry a `.Rbuildignore`, a `cran-comments.md` stub, or a CI
   workflow running `--as-cran`. All of those are answers, not starting conditions.
3. **`orthopen` lineage.** If the first commit is a wholesale import, expect `orthopen`'s own
   violations to come with it — the "in R" title, the bare publisher URL for the 2014 reference.
   Those are legitimate seed violations and should be left in place. They are exactly the LIVE
   criteria the study needs.

Record the resolved SHA in the pre-registration and in `provenance.txt` for every run.

**A note on the seed argument, for the mutation set only.** The accepted `orthoMTL()` exposes `seed`
as a user-supplied argument defaulting to `NULL`, documented as leaving the ambient RNG state
untouched. That is what the fix for ledger item R01 looks like in this package. Use it to build
`MUT-R01` and to sanity-check the C25 static rule — **not** as a scoring target. Scoring an arm on
whether it converged to this exact signature would reinstate the similarity endpoint rejected in §7.

### Notes on `git archive`

- It writes the tree at that commit and nothing else. Branches created later are unreachable because
  there is no object database in the output at all.
- It honours `export-ignore` in `.gitattributes`. Check whether `C0` had any — an `export-ignore`
  added later does not apply, but one present at `C0` silently drops files.
- Submodules are **not** included. If `C0` had any, decide explicitly whether the arms need them.

## 2. Stripping and verifying

Remove anything at `C0` that discusses CRAN plans or later fixes:

```bash
cd arms/A0/pkg
rm -f cran-comments.md NEWS.md NEWS TODO NOTES.md
# plus any planning docs, reviewer correspondence, CI configs encoding later check flags
```

Then verify — do not assume:

```bash
# 1. No history leaked.
[ -d .git ] && echo "FATAL: .git present"

# 2. No ledger keyword appears anywhere in the tree.
#    Build this list from rejection-ledger.md; every hit must be investigated.
grep -rniE 'set\.seed|file LICENSE|cran|resubmi|title case|dontrun|\\value' . \
  | tee ../../../seed-leak-audit.txt

# 3. Diff the seed against C0 as exported, to prove the strip removed only what was intended.
diff -rq <(git archive C0 | tar -tv) .
```

Log the audit output. It is the evidence that `A0` started blind, and it belongs on a backup slide.

Copy the verified tree to every arm, then add each arm's skill file:

```bash
for ARM in A1 A2 A3 A4 A5; do
  mkdir -p arms/$ARM && cp -r arms/A0/pkg arms/$ARM/pkg
done
```

---

## 3. Seed audit — establishing the before-state

**Every criterion is scoreable — but in different directions.** A criterion the seed satisfies is not
dead: an arm can *break* it. Given a prompt that explicitly says nothing is settled, an agent that
rewrites a compliant Title may well produce one that fails.

Run every static rule and the frozen check suite against the **seed**, before any arm runs:

```bash
Rscript scoring/audit_seed.R arms/A0/pkg
```

| Seed state | Arm outcome | Name | Contributes |
|------------|-------------|------|-------------|
| violates | fixed | **REPAIR** | credit |
| violates | still violates | unrepaired | burden |
| satisfies | broken | **REGRESSION** | burden |
| satisfies | still satisfies | held | — |
| n/a at seed | new surface violates | **NOVEL** | burden |

`NOVEL` covers what an arm creates: a new exported function with no `\value`, an added URL that
redirects, a new example writing outside `tempdir()`. The surface did not exist at the seed, so
neither repair nor regression applies.

**Residual review burden (co-primary 1) = unrepaired + regressions + novel.** Everything a human
would still have to catch. Report `REPAIR` separately as credit; never net them into one number
without showing both, because an arm that fixes five things and breaks four is not equivalent to one
that fixes one and breaks nothing.

### Scoring requires a before/after diff, not an end-state scan

Regression is invisible to a scan of the final tree alone — a failing Title looks the same whether it
was always wrong or was broken by the arm. The pipeline must evaluate each criterion against the seed
*and* the output tree and compare. The seed audit above is what makes that possible, which is why it
runs first.

### Why this is the better answer to a compliant seed

If the seed already satisfies most criteria, resolution comes from **regression and novel violations**
rather than repair. That needs no deliberate defect seeding, and it keeps the study honest: it is
still "what would have happened," not a constructed benchmark.

It also inverts the claim in a way worth stating out loud:

> A skill file's value may lie less in fixing what is broken than in stopping an agent from breaking
> what already works.

**Pre-registered prediction.** Freedom to rewrite is granted identically to every arm, so regression
risk is uniform by construction. Expect the highest regression counts in `A0` (freedom, no guidance)
and `A5` (freedom, undistilled context inviting broad rewriting), and the lowest in `A2`, whose
adversarial self-review step should catch its own regressions before terminating. If that ordering
holds, it is direct mechanism evidence, and it was predicted in advance.

### If both LIVE and regression surfaces come out thin

Then the seed is close to CRAN-ready and the study has little headroom in either direction. Report
that plainly — it is a real finding about the starting point. Deliberate defect seeding remains
available, but it converts the study into a seeded-defect benchmark and must be relabelled
throughout. Decide before the pilot, never after seeing a flat result.

---

## 4. Pilot rules

The pilot is a harness test. It confers no advantage on any arm because each run starts from a fresh
tree with a fresh `CLAUDE_CONFIG_DIR` and auto memory disabled — nothing carries between runs.

The leakage risk is **you**, not the agents.

### What the pilot may change

Only harness defects — things that prevent the experiment from measuring anything:

- the prompt suppressing a whole finding class (no arm touched DESCRIPTION; §FROZEN_PROMPT diagnostic)
- an arm hanging on a user prompt that will never be answered
- the finding parser or a static rule failing to run
- `FAIL_ENVIRONMENT` check outcomes, meaning the §4.2 gate leaked
- budget so tight that every arm terminates `BUDGET_EXHAUSTED`

### What the pilot may never change

- prompt wording adjusted because an arm **performed poorly**
- budget raised because a favoured arm ran out of turns
- criteria added, removed or reweighted after seeing which arms violated what
- static rules loosened because an arm tripped one in a way that "isn't really the point"

The test for any proposed change: *would I make this edit if the arms had performed in the opposite
order?* If not, it is fitting, not fixing.

**Any change at all voids the pilot block** (§6.1). Delete `runs/` and `blinded/` and start block 2
from scratch. Budget the pilot as spent regardless.

### Record before running block 2

- pilot termination reasons per arm
- whether the DESCRIPTION diagnostic passed
- the seed audit's before-state per criterion (§3), and the counts of criteria the seed violates
  versus satisfies
- what changed, if anything, and therefore whether the pilot was pooled or discarded
