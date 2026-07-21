# Partisan vs Climate Cues and Public Opinion about Trump's Actions on Energy

Manuscript and reproducible analysis examining how partisan (Trump) and
climate change cues shape US public opinion about President Trump's actions
on energy during his second term.

## Layout

```
cue-actions.qmd                      Manuscript source (renders to HTML, PDF, DOCX)
_quarto.yaml                         Quarto project config
_output/                             Rendered HTML/PDF/DOCX (tracked in git)
custom-reference-doc.docx            Word reference template used for the DOCX output
LOG.md                               Running session log (newest entry first)
scripts/
  manuscript-prep.R                  Sourced by the qmd: loads data and prepares the
                                       analysis objects, tables, and figures
  export-cited-refs.R                Pre-render step: trims the master .bib to cited keys
data/                                Survey/analysis data (NOT in git -- see below)
  cueActionsDataWeighted.csv         Survey data with post-stratification weights
literature/                          Background literature (NOT in git -- local only)
```

## Reproducing the analysis

Requires R with: `survey`, `dplyr`, `broom`, `modelsummary`, `tinytable`, `marginaleffects`, `ggplot2`.

- **Manuscript:** `quarto render` → outputs to `_output/` (HTML, PDF, and DOCX;
  the DOCX uses `custom-reference-doc.docx`)
- **Models only:** `Rscript scripts/manuscript-prep.R` builds the analysis
  objects without rendering the manuscript.

## Data

The `data/` folder is **not tracked in git**. Restore it before rendering:

- `data/cueActionsDataWeighted.csv` — survey responses (N = 3,113), weighted
  (`weight`) to match US Census demographics. Includes the cue-condition
  assignment (`trump.cue`, `climate.cue`, `control`); outcome variables on
  support for five of Trump's federal energy actions (`fed.action.tax.credits`,
  `fed.action.coal.keep.open`, `fed.action.coal.leasing`,
  `fed.action.cancel.wind`, `fed.action.nuclear.licensing`); partisanship and
  attitude variables (`democrat`, `republican`, `libDem`, `conRep`,
  `trump.approval`); and controls (`age`, `male`, `white`, `edu`, `college`,
  `inc`).

## Notes

- `references.bib` and the local `.csl` are generated at render time by the
  pre-render step (`export-cited-refs.R`) from the master bibliography, so
  they are git-ignored.
- `_output/` **is tracked in git** (unlike most build artifacts) so the
  rendered manuscript is available without re-running R/Quarto. Re-render
  (`quarto render`) after any change to `cue-actions.qmd` or
  `scripts/manuscript-prep.R` and commit the updated files in `_output/`
  alongside the source change.
- Quarto's freeze cache (`_freeze/`) is enabled (`execute: freeze: auto` in
  `_quarto.yaml`), so code chunks are only re-executed when the qmd or its
  upstream R sources change.
- `literature/` is git-ignored (kept local only).
- `LOG.md` records what changed and why for each work session; add a new
  entry at the top rather than editing manuscript prose notes into commit
  messages.
