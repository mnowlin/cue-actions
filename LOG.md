# Session Log — cue-actions Project

Paper title: **"Partisan vs Climate Cues and Public Opinion about Trump's Actions on Energy"**

This log records what has been done in each working session. Update it at the end of each session.

---

## Project Overview

An academic article examining how partisan (Trump) and climate change cues
shape US public opinion about President Trump's actions on energy during his
second term.

**Key files:**
- `cue-actions.qmd` — main manuscript (renders to HTML, PDF, DOCX)
- `scripts/manuscript-prep.R` — survey design, five `svyglm` models (H1-H4), regression table, and predicted-value figures sourced by the manuscript
- `scripts/export-cited-refs.R` — pre-render step that trims the master `.bib` to cited keys
- `data/cueActionsDataWeighted.csv` — weighted survey data (N = 3,113)
- `README.md` — project structure and reproduction instructions

---

## Session History

### Session 9 — 2026-09-15 (Proofreading pass, citation-key fix, CLAUDE.md update)

- User made a manual proofreading/wordsmithing pass over `cue-actions.qmd`
  (Introduction, Polarization on Energy Issues, Cues and Cue-Taking,
  Hypotheses, and Data/Results sections): tightened phrasing throughout,
  dropped the now-outdated "prepared for submission to APSA" line from the
  abstract block, added `@benegalCostSensitivityPartisan2024` and
  `@cohenPartyPolicyDominating2003` as supporting citations, and clarified
  how the political-beliefs measure was constructed (from a 7-point ideology
  scale plus party identification).
- Fixed a citation-key mismatch flagged as a follow-up in Session 8: the two
  papers added to Zotero since then resolved to slightly different
  Better-BibTeX keys than what was hand-typed in the qmd
  (`houstonEngagementHighProfile2026` → `houstonHowEngagementHighProfile2026`;
  `vranceanuCrossPressuresAffect2022` → `vranceanuHowCrosspressuresAffect2022`).
  Updated both in-text citations to match the master bib; re-rendered and
  confirmed no citeproc warnings remain.
- Re-rendered HTML, PDF, and DOCX outputs to reflect the prose changes;
  `_freeze/` cache updated accordingly.
- Added a pointer to `/paperpush-plugin:paperpush-prepare-submission` in
  `CLAUDE.md` for use when this manuscript is ready to submit.

### Session 8 — 2026-09-14 (Education/partisan-cue literature search, theory + Discussion additions, abstract update)

- Used Consensus to search for research on education and partisan cue-taking,
  specifically to contextualize the paper's null H3/H4 finding (education did
  not moderate the Trump cue's effect) and the unexpected two-way education x
  political-beliefs interaction. Surfaced Ehret, Sparks, and Sherman (2017,
  *Environmental Politics*) on the ideological-consistency model, Vrânceanu
  (2022, *West European Politics*) on education moderating responses to
  incongruent vs. congruent cues, and Houston and Barone (2026, *Education
  Finance and Policy*) on partisan-official cues chiefly polarizing rather
  than persuading.
- Integrated these into `cue-actions.qmd`:
  - **Cues and Cue-Taking** theory section: added the ideological-consistency
    and congruent/incongruent-cue nuance to the paragraph on education and
    cue receptivity.
  - **Discussion**, H3/H4 paragraph: added the congruent-cue explanation
    (Vrânceanu) and the polarize-not-persuade pattern (Houston and Barone) as
    candidate explanations for the null education-moderation result.
  - **Discussion**, education x political-beliefs paragraph: added a new
    paragraph noting the finding fits the ideological-consistency model for
    Democrats but runs opposite to it for Republicans, tying to the paper's
    broader partisan-asymmetry theme.
- Bibliography: `ehretSupportEnvironmentalProtection2017` already existed in
  the master bib (`01-RESEARCH/Manuscript-Files/refs.bib`). Added
  `houstonEngagementHighProfile2026` and `vranceanuCrossPressuresAffect2022`
  to the master bib manually (full metadata, DOIs verified via web search),
  flagged with a comment that they are not yet real Zotero items. **Follow-up
  for the user**: add these two papers to Zotero via "Add Item(s) by
  Identifier" (DOIs `10.1162/edfp_a_00449` and
  `10.1080/01402382.2021.1975447`) so Better BibTeX's auto-export doesn't
  drop them on its next full re-export; Zotero's local connector HTTP server
  was not reachable (port 23119 refused), so this could not be done
  programmatically.
- Rendered HTML, PDF, and DOCX to confirm both new citations resolve cleanly
  with no citeproc warnings.
- Updated the abstract to state the findings (Trump cue increased support
  among conservative Republicans; climate cue's only effect was reducing
  Republican support for eliminating renewable tax credits; Democrats
  unresponsive; education did not moderate either cue), rather than only
  describing the design.
- Staged `presentation/NowlinAPSA26.qmd` (modified) and
  `presentation/NowlinAPSA2026.pdf` (new) per user request.
- Restored `.gitignore`, `CLAUDE.md`, `LOG.md`, `README.md`, `_quarto.yaml`,
  and `custom-reference-doc.docx` from spurious `755` file-mode changes
  (likely a OneDrive sync artifact) back to `644` so they wouldn't show as
  modified in git with no real content change.

### Session 7 — 2026-09-01 (APSA 2026 conference presentation)

- Built `presentation/NowlinAPSA26.qmd`, a Quarto reveal.js slide deck for
  the APSA 2026 talk, modeled on a prior conference presentation (a
  property-buyout paper) the user placed in the file as a template. Reuses
  that deck's theme assets: `presentation/pp.scss` (UTA blue `#0064B1`,
  Abhaya Libre / Jost fonts, `.section-background` dividers) and
  `presentation/UTAPoliticalScience.png` logo.
- Deck flow mirrors the manuscript: Motivation -> Trump's five energy actions
  -> uneven baseline polarization -> cues/cue-taking + the education channel
  -> H1-H4 -> Data and Analysis (survey, experimental design, question
  wording, measures, model) -> Results (`fig_identity`, `fig_college`, plus
  interpretation slides) -> Discussion -> Appendix (`desc_table`,
  `means_table`, split regression table) -> References.
- Tables and figures are pulled live from `scripts/manuscript-prep.R`, which
  the setup chunk sources after setting `knitr::opts_knit$root.dir` to the
  project root (same pattern as the template deck). Slides call the existing
  objects (`desc_table`, `means_table`, `fig_identity`, `fig_college`) and
  inline values (`n_total`, `n_trump`, `n_climate`, `n_control`, `wtd_mean()`).
- Split the wide five-model `results_table` into two Appendix slides — "Main
  Effects" (cue / identity / college + intercept, `style_tt(fontsize = 0.7)`)
  and "Interactions" (the nine interaction terms, `fontsize = 0.55`) — each
  rebuilt via `modelsummary(models, coef_map = coef_map[...])` so they stay
  consistent with the manuscript table.
- Title-slide tweaks per user requests: removed the logo from the title
  slide only (CSS `.reveal:has(#title-slide.present) .slide-logo`, kept on
  content slides); added the venue as an italic white `subtitle`
  ("American Political Science Association Conference, September 2026") —
  used `subtitle` rather than `date`, since Quarto date-parses the `date`
  field and collapsed the string to an ISO date; added "Associate Professor"
  above the department in the affiliation block.
- Renders cleanly to `presentation/NowlinAPSA26.html`; user also exported a
  PDF of the slides.

### Session 6 — 2026-08-28 (Difference-of-means table, education x beliefs interaction in Discussion, full proofreading pass, conference PDF)

- Moved `tbl-results` (the main regression table) back out of the Appendix
  and into the Results section, right after the paragraph that first cites
  it. The Appendix now holds only `tbl-results-explore`.
- Added a difference-of-means table (`means_table` in `manuscript-prep.R`,
  new section 3b; `tbl-means` in the qmd): survey-weighted mean support for
  each of the five actions by cue condition (control / Trump / climate), plus
  the Trump- and climate-cue mean differences from control with design-based
  tests. Estimated per DV via `svyglm(dv ~ trump.cue + climate.cue)` — the
  intercept is the weighted control mean and the two slopes are the weighted
  mean differences. Only the Trump cue's -0.18 drop on nuclear licensing is
  significant (*p* < .05); every other condition difference is null.
- Fact-checked the user's new Results paragraph on the education x political-
  beliefs two-way interaction against the fitted models. The substantive
  claims hold (college-educated conRep less supportive of cancel wind and
  nuclear; college-educated libDem less supportive of tax credits, cancel
  wind, and nuclear — all negative and significant), but flagged that the
  cross-reference pointed at the wrong table (`@tbl-means` should be
  `@tbl-results`; the user's interim `@tbl-tbl-results` typo was also fixed)
  and that "(at *p*<0.10)" understates the conRep x college cancel-wind term,
  which is *p* = .04. Left those two items for the user to adjust in prose.
- Drafted a new Discussion paragraph (after the H3/H4 paragraph) on that
  unanticipated interaction: a college degree is associated with *lower*
  support for several actions among committed partisans on both sides but
  *higher* support among moderates/others; framed as exploratory (not
  preregistered, 3 of 5 actions). Added a matching sentence to the closing
  future-research paragraph.
- Corrected "ceiling effect" -> "floor effect" in the H2 Discussion
  paragraph: the DV is *support*, and liberal Democrats' support sits near
  the bottom of the 1-5 scale (1.4-1.7 in the control condition), so there is
  little room for a cue to push it lower.
- Ran a full typo / spelling / grammar pass over the manuscript at the user's
  request (all fixes except the line-168 cross-reference and p-value items
  above, which are the user's prose to adjust): ~20 fixes, including a broken
  word ("example.eEarly"), a duplicated phrase, several subject-verb
  disagreements ("@tbl-results show", "the main effect ... were", "views ...
  has grown"), two comma splices / run-ons (the Bergquist sentence and the
  floor-effect sentence), a stray period before a citation, "than those
  without a degree" -> "with a degree", hyphenation ("working-class",
  "college-educated"), "Republican party" -> "Party", "pre-registered" ->
  "preregistered", and shifting the abstract's stale pre-registration future
  tense ("I will survey", "will be asked") to past. Left "in the U.S."
  untouched inside the verbatim survey question wording.
- Re-rendered HTML, PDF, and DOCX; all three build cleanly.
- Staged `_output/nowlinAPSA2026.pdf`, a copy of the rendered PDF the user is
  circulating for APSA 2026, to be tracked alongside the standard outputs.

### Session 5 — 2026-08-27 (Literature integration from cue-energy, hypotheses intro, Discussion/Conclusion, citation fixes)

- Pulled the "Under Review/cue-energy" manuscript's literature review (a
  related project on the same survey/cues design) and integrated relevant
  material into "Polarization on Energy Issues" and "Cues and Cue-Taking":
  fixed a broken/unfinished paragraph and added source-specific polarization
  content (fossil fuels vs. renewables vs. nuclear) and an elite-cues/
  "Trump effect" paragraph. Per user request, reworded all borrowed passages
  so phrasing doesn't closely track the cue-energy source text, while
  keeping the same citations and claims.
- Discovered that `export-cited-refs.R`'s pre-render step silently drops any
  cited key not present in the master bib (`Manuscript-Files/refs.bib`),
  which briefly broke 12 pre-existing citations (6 academic + 6 news items)
  that were only in the local `references.bib`. Recovered full bibliographic
  details for all 12 from the previously rendered `_output/cue-actions.html`
  and reported them to the user to add to Zotero; user has since added all
  12 to the master bib (final 2 — Carnes & Lupu, Zingher — landed under
  different auto-generated keys, `carnesWhiteWorkingClass2021` and
  `zingherTRENDSDiplomaDivide2022`; updated all in-text citations to match).
  `export-cited-refs.R` now reports 48/48 cited keys resolved.
- User hand-added a paragraph to the Introduction citing the general
  cue-taking/heuristics literature and Trump's support among non-college
  voters; filled in the three empty citation brackets using sources already
  cited elsewhere in the paper for the same claims (Kam 2005; Schaffner &
  Streb 2002; Mérola & Hitt 2016; Morgan & Lee 2018; Zingher 2022).
- Drafted a hypotheses-introduction paragraph (before `## Hypotheses`)
  synthesizing the partisan cue-taking and education/class-inflected-Trump-
  support channels into the logic behind H1-H4.
- Drafted the full "Discussion and Conclusion" section (previously empty):
  walks through H1-H4 findings action-by-action, including the climate cue's
  counterintuitive negative effect on Republican support for eliminating
  wind/solar tax credits, ties the results back to the source-specific
  polarization argument, notes limitations, and closes with a future-research
  paragraph per the author's usual structure.
- Filled in the Introduction's "Overall, I find that..." summary paragraph
  to match the Results/Discussion findings.
- Re-rendered HTML, PDF, and DOCX; all three build cleanly with 0 warnings.

### Session 4 — 2026-08-25 (Robustness check, descriptive stats, exploratory model, media-grounded intro)

- Compared the primary H1-H4 model with and without demographic controls
  (`age`, `male`, `white`, `inc`) as a diagnostic (scratch script, not saved).
  Estimates barely moved; only one term crossed a significance threshold
  (Cancel Wind's `trump.cue:conRep`, n.s. → marginal). Per user decision,
  made the no-controls specification the permanent primary model: removed
  the four control terms from `rhs` in `scripts/manuscript-prep.R`, updated
  `table_notes`, simplified `predict_grid()`/removed the now-unused
  `controls_at_mean` block, and updated the H1-H4 bullet text and summary
  paragraph in `cue-actions.qmd` with the refit estimates/p-values.
- Added a descriptive statistics table (`desc_table` in `manuscript-prep.R`,
  section 1b): survey-weighted mean/SD (`svymean`/`svyvar`) and unweighted
  range for the five DV items and the three focal IVs (conRep, libDem,
  college). Placed as `tbl-descriptives` in "Data and Measures," right after
  the IV description paragraph.
- Added inline R code reporting the Cancel Wind and Nuclear weighted means
  (`wtd_mean()`) in the "Data and Measures" prose, replacing placeholder text.
- Moved `tbl-results` (the main regression table) from the Results section
  into the Appendix; Results now leads with the two prediction figures and
  the hypothesis bullets.
- User asked whether the climate cue's effect is also moderated by education
  (`fig-college` only ever tested this for the Trump cue, per H3/H4). Fit an
  exploratory model with `climate.cue:college` and its `conRep`/`libDem`
  interactions — no term reached significance in any of the five DVs (all
  *p* > .20). Initially added these terms directly to the shared primary
  model, which measurably weakened two preregistered H1/H2 results (Tax
  Credits climate x conRep: ** → †); at the user's choice, reverted the
  primary model to its original H1-H4 spec and instead fit the exploratory
  terms as a separate model (`models_explore`/`results_table_explore` in
  `manuscript-prep.R`, section 6). Added `tbl-results-explore` to the
  Appendix and a paragraph in Results describing the null exploratory
  finding.
- Searched the `cue-actions` Undermind workspace for literature on Trump
  support among non-college voters (the "diploma divide" / education
  realignment literature). Drafted two new paragraphs in "Cues and
  Cue-Taking" (after the existing working-class-cue sentence, before
  Hypotheses) grounding that sentence in the realignment literature and then
  complicating it with a contested-evidence caveat that motivates testing
  H3/H4 empirically. Added 6 new entries to the master bib
  (`Manuscript-Files/refs.bib`, tagged `project/cue-actions`): Kitschelt &
  Rehm 2019, Zingher 2022, Sances 2019, Morgan & Lee 2018, Abramowitz &
  McCoy 2019, Carnes & Lupu 2020.
- Web-searched for media coverage of the real Trump administration actions
  behind each of the five DVs (all occurred 2025-2026) and used them to
  finish the incomplete opening paragraph of the Introduction: EO 14156
  national energy emergency (Jan 2025), Treasury/IRS tax-credit rule
  tightening (Aug 2025), DOE emergency orders forcing coal-plant retention
  (MI/WA/IN/CO), Interior's 13.1M-acre coal leasing opening (Sept 2025),
  the East Coast offshore wind construction halt (Dec 2025), and the NRC
  licensing-speedup executive orders (May 2025). Added 6 more `@online`
  entries to the master bib for these sources (DOI, DOE, NPR, CPR,
  Washington Post, Columbia Sabin Center), also tagged `project/cue-actions`.
- `export-cited-refs.R` confirms all cited keys resolve (30/30 by end of
  session); both HTML and PDF render cleanly throughout.

### Session 3 — 2026-08-17 (Literature search + Cues and Cue-Taking section)

- Connected the Undermind MCP (account `matthew.nowlin@uta.edu`) and used the
  existing `cue-actions` Undermind workspace (created empty at project setup).
- Launched a deep search — "Education and partisan cue-taking" — asking
  whether lower-education respondents are more responsive to partisan cues.
  Result (52 papers): the literature rejects a simple "low education = more
  cue-taking" model; cue receptivity is conditional (numeracy, expressive
  utility, issue type) rather than uniformly higher among the less educated.
  Added the top 23 papers to a new `/literature/` folder in the workspace
  (Undermind-side, not the git-ignored local `literature/` folder).
- Drafted the "Cues and Cue-Taking" theory section in `cue-actions.qmd`
  (per `nowlin-style-profile.md`), grounded in that search: partisan cues as
  heuristic/motivated reasoning, climate-specific cue backlash effects, and
  the more conditional education/numeracy findings that motivate H3/H4.
  Matched 9 new citation keys (Kam05, Schaffner02, Slothuus10, Leeper14,
  Taber06, Petersen13, Druckman13, Feldman18, Merkley21, McConnell22,
  Merola16, Tappin21/26, Kahan13, Bakker19, Hamilton11) against the master
  bib (`Manuscript-Files/refs.bib`) by title/author before citing — all
  matched; `export-cited-refs.R` confirms 15/15 cited keys resolve, and the
  HTML render shows no unresolved-citation markers.
- User hand-added one sentence noting the Trump cue may work differently
  from a generic partisan cue given Trump's claimed strength among white
  working-class voters — motivated an ad hoc subgroup check (see below).
- Ran two exploratory subgroup analyses at the user's request, **not saved
  to any script** (diagnostic only, results reported in chat):
  1. H1/H2 terms among white, non-college respondents only (N = 906;
     college is constant in this subsample so H3/H4 are untestable there).
  2. Full H1-H4 model (including college interactions) restricted to white
     respondents only (N = 2,107), so H3/H4 could be tested within race.
     No H3/H4 term reached significance; the only significant cue term
     was climate cue x conRep on tax credits, in the direction opposite H1.
- Added `nowlin-style-profile.md` to `.gitignore` (project-setup step this
  project had missed — the style profile is shared across projects via
  `01-RESEARCH/project-files/`, not meant to be tracked per-project).

### Session 1 — 2026-07-21 (Project setup)

- Set up the project structure from the standard project-files template:
  copied `_quarto.yaml`, `custom-reference-doc.docx`, `LOG.md`, `README.md`,
  `template.qmd`, and `scripts/export-cited-refs.R`.
- Renamed `template.qmd` → `cue-actions.qmd` and set the manuscript title to
  "Partisan vs Climate Cues and Public Opinion about Trump's Actions on
  Energy" in the YAML header.
- Updated `_quarto.yaml`'s render list and `scripts/export-cited-refs.R`'s
  source-file list to reference `cue-actions.qmd`.
- Added `literature/` and `data/` to `.gitignore`.
- Created `scripts/manuscript-prep.R` as the analysis code file to be sourced
  by the manuscript (currently a stub — data loading and models to be added).
- Rewrote `README.md` and this log for the cue-actions project, adapted from
  the cue-WTP project template.
- Git repo already existed locally with `origin` pointing to
  `https://github.com/mnowlin/cue-actions`, but had no commits yet.

### Session 2 — 2026-07-21 (H1-H4 analysis, regression table, predicted-value figures)

- User added `data/cueActionsDataWeighted.csv` (N = 3,113) and wrote the four
  preregistered hypotheses (H1-H4) and the "Data and Measures" prose directly
  into `cue-actions.qmd`.
- Built out `scripts/manuscript-prep.R`: `svydesign(ids = ~1, weights = ~weight)`
  and five `svyglm` models (one per DV: tax credits, keep coal open, coal
  leasing, cancel wind, nuclear licensing) sharing one RHS with cue x identity
  interactions (H1/H2) and cue x identity x college three-way interactions
  (H3/H4). Reference categories: control condition, moderate/other identity,
  no college degree.
- Fixed two pre-existing template bugs while getting the first render to work
  (also patched in `../project-files/` so future project setups don't hit
  them): `export-cited-refs.R` crashed via `writeLines(NULL, ...)` when no
  citations exist yet; `_quarto.yaml` was missing `execute: echo: false` /
  `warning: false`, so R source was echoing into the rendered manuscript
  instead of the table/figure output.
- Built `results_table` (`@tbl-results`): a `modelsummary` regression table
  covering all 5 models. Iterated through several rendering problems before
  landing on the current approach — duplicate captions (dropped `title=` from
  `modelsummary()`, relying on the chunk's `tbl-cap`), a table too wide/tall
  for the PDF page (shortened coefficient/column labels, moved demographic
  controls to a footnote instead of printed rows), and `modelsummary`'s
  default backend now being the `tinytable` package rather than `kableExtra`
  (an old `kable_styling()` post-processing approach errored; switched to
  `tinytable::style_tt(fontsize = 0.7)`, which works uniformly across HTML,
  PDF, and DOCX).
- Added `†` (*p* < .10) to the significance-star map alongside the usual
  `*`/`**`/`***`, confirmed the glyph renders correctly in all three formats.
- Per user request, removed `trump.approval` as a control from all five
  models. Coefficients on `conRep`/`libDem` grew substantially (expected,
  since approval and partisanship are collinear), but the H1-H4 conclusions
  were materially unchanged; updated the in-text bullet numbers accordingly.
  Also corrected a bullet-text error from the first pass (H3's three-way term
  is negative in *all five* models, not four of five).
- Added two `marginaleffects::predictions()` figures, with demographic
  controls held at survey-weighted means: `fig-identity` (predicted support
  by cue condition x political identity, all 5 DVs, tests H1/H2) and
  `fig-college` (predicted support by Trump cue x college degree, ConRep vs.
  LibDem only, tests H3/H4).
- Re-rendered HTML, PDF, and DOCX repeatedly after each change (table
  iterations, dagger addition, trump.approval removal, figures) to confirm
  all three formats build cleanly; visually inspected rendered PDF pages and
  extracted DOCX/HTML text each time rather than trusting a clean exit code.

---

## Analysis Architecture

All analysis lives in `scripts/manuscript-prep.R`, sourced at the top of
`cue-actions.qmd`:

- Survey design: `svydesign(ids = ~1, weights = ~weight)`, simple weighted
  design (no clustering/strata).
- Five `svyglm` models (one per DV), same RHS: cue main effects, identity
  main effects, college main effect, cue x identity interactions, cue x
  college and college x identity interactions, and the cue x identity x
  college three-way interactions that test H3/H4, plus controls (age, male,
  white, inc).
- `results_table`: `modelsummary()` (backend: `tinytable`) with a `coef_map`
  restricted to the cue/identity/college terms (controls omitted from the
  printed table, noted in a footnote), `stars_map` including `†` for
  *p* < .10, styled via `tinytable::style_tt(fontsize = 0.7)`.
- `get_term()` / `hyp_terms` / `hyp_results`: helpers for pulling a specific
  hypothesis-relevant coefficient out of a model's tidy output.
- `predict_grid()`: builds a prediction grid (cue/identity/college combos,
  other controls at survey-weighted means) and calls
  `marginaleffects::predictions()` per model; feeds `fig_identity` and
  `fig_college`.

## Key Analytical Decisions

- **Survey weights**: simple weighted design (`svydesign(ids = ~1, weights = ~weight)`),
  no clustering/strata variables in the data.
- **Reference categories**: control condition (vs. Trump cue / climate cue),
  moderate/other identity (vs. conRep / libDem), and no college degree are
  the excluded referents throughout.
- **Controls**: age, male, white, inc, included additively in every model.
  `trump.approval` was tried and then dropped per user request (collinear
  with partisanship; dropping it didn't change the substantive conclusions).
- **Table readability across HTML/PDF/DOCX**: demographic controls are
  estimated but not printed in `tbl-results` (footnoted instead) to keep the
  table a manageable width; `tinytable::style_tt(fontsize = 0.7)` handles the
  rest.
- **Significance reporting**: `†`/`*`/`**`/`***` for *p* < .10/.05/.01/.001,
  per user request.

## Key Findings (as of Session 2, 2026-07-21)

- **H1** (conRep more supportive under either cue) — partially supported.
  The Trump cue significantly increased conservative Republican support for
  coal leasing (*b* = 0.45, *p* = .028) and nuclear licensing (*b* = 0.49,
  *p* = .030), marginally for keeping coal plants open (*b* = 0.33,
  *p* = .091), and was positive but not significant for the remaining two
  actions. The climate cue never significantly increased conRep support, and
  significantly *reduced* it for renewable tax credits (*b* = -0.45,
  *p* = .008).
- **H2** (libDem less supportive under either cue) — not supported at
  conventional significance. Both cues moved libDem support in the
  hypothesized negative direction for four of five actions, but no
  coefficient reached *p* < .05; the climate cue's effect on tax-credit
  support was marginal (*b* = -0.25, *p* = .066).
- **H3** (Trump-cue effect on conRep concentrated among non-college
  respondents) — not supported. The three-way term was negative in all five
  models (directionally consistent with H3) but never significant.
- **H4** (Trump-cue effect on libDem concentrated among non-college
  respondents) — not supported. The three-way term was small and
  inconsistent in sign across models.
- Overall: the Trump cue (not the climate cue) is the more reliable driver of
  conservative Republican support, concentrated in 2-3 of the 5 actions
  (coal leasing, nuclear licensing, and marginally coal-plant retention).
  There's no reliable evidence of cue-driven suppression among liberal
  Democrats, or that education moderates the Trump cue's effect on either
  group. These conclusions are robust to dropping the Trump-approval
  control.
