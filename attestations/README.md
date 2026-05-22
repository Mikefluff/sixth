# Pre-registration attestation ledger

This directory implements METHODOLOGY.md Rule 9 — external
attestation of pre-registration files.

## Why

Git history is verifiable to anyone who clones, but a malicious
maintainer can `git push --force` to rewrite history and pretend
predictions matched data post-hoc.  External attestation makes
this rewrite detectable: an externally-anchored hash of
`ledger.txt` proves what predictions existed at a given time.

## How to attest a new PREDICTIONS-N.md

```bash
scripts/attest_prediction.sh examples/PREDICTIONS-N.md
```

This:
1. SHA-256 the predictions file
2. Append `(timestamp, sha, path, git-head)` row to `ledger.txt`
3. Print the cumulative ledger hash for external anchoring

Then commit `ledger.txt` alongside `PREDICTIONS-N.md` in the
same commit.

## How to anchor externally

Pick at least one (more is better):

### OpenTimestamps (free, cryptographic, automated)

```bash
# Install once:
pip install opentimestamps-client

# After each ledger update:
ots stamp attestations/ledger.txt
git add attestations/ledger.txt.ots
git commit -m "anchor ledger to bitcoin via opentimestamps"
```

OpenTimestamps anchors to Bitcoin within ~24 hours.  The `.ots`
file proves the ledger existed at the calendar-server's time.

### Public social-media post (cheap, soft)

Tweet/toot the cumulative ledger SHA-256.  Record the URL of
the post in `anchors.md` (one row per anchor).  Public posts
have inherent timestamps from the platform.

### GitHub release tag

```bash
# Tag the commit that includes the ledger update:
git tag -a attest-NNNN -m "ledger sha: <sha>"
git push origin attest-NNNN
```

GitHub records tag-creation timestamps in the release page.

## Ledger format

`ledger.txt` is append-only.  Each row:

```
<iso-timestamp>  <sha256-of-predictions-file>  <repo-path>  <git-head-at-time-of-attestation>
```

The order rows appear in the file is significant — a row's
predecessors prove the temporal precedence of its predictions.

**Never edit existing rows.**  If a prediction file changes,
attest the new version (new row); the old row remains as
evidence of the prior commitment.

## Anchors index

External anchors of `ledger.txt` cumulative SHA-256:

| date | ledger sha-256 (partial) | anchor type | url / id |
|------|-------------------------|-------------|----------|
| 2026-05-22 | `77e0a79c…ab116` | git annotated tag (pushed to GitHub) | tag `attest-2026-05-22-cycle11` |

This table is updated by hand when anchors are filed.

### Verifying an anchor

For git-tag anchors:
```bash
git show attest-2026-05-22-cycle11           # see message + tag SHA
gh api repos/Mikefluff/sixth/git/refs/tags/attest-2026-05-22-cycle11
                                              # see GitHub-recorded creation
shasum -a 256 attestations/ledger.txt        # recompute ledger SHA
# Compare to SHA in tag message.  Match = ledger un-tampered.
```

For future OpenTimestamps anchors, use `ots verify <file>.ots`.

## Limits of this scheme

- A determined adversary with control of the repo AND the
  external anchor (cloud account, Twitter, OTS calendar server)
  can still rewrite history.  Use ≥2 different external anchors
  for meaningful adversarial resistance.
- Anchor latency: OpenTimestamps requires ~24 hours to
  finalise on Bitcoin.  Until then the OTS file is a
  pre-image; not yet anchored.
- This scheme does not verify the *content* of predictions
  (e.g., that they cite real literature).  That's METHODOLOGY.md
  Rule 2.

## Retroactive attestation of cycles 8 / 9 / 10A

The first three pre-registrations (PREDICTIONS-124.md = b0fcccd,
PREDICTIONS-125.md = 99f33f0, PREDICTIONS-126.md = f31ba43) were
filed before this attestation infrastructure existed.  They are
retroactively attested in the initial ledger but the *git-commit*
column for each is the original commit that introduced the file
— anyone can verify by `git log -p attestations/ledger.txt` that
the ledger entries were added in a later commit than the
predictions themselves.

The retroactive entries are honest about being retroactive: the
attestation timestamp is when the ledger was created, not when
the predictions were filed.  The git-commit column anchors the
ACTUAL chronology of the predictions.
