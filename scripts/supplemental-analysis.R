# supplemental-analysis.R
# Sourced by cue-actions-supplemental.qmd, after scripts/analysis.R. Builds the
# robustness-check and diagnostic objects (unweighted models, demographic
# controls, covariate balance, weighted-vs-unweighted sample comparison) shown
# in the supplemental materials. Reuses `d`, `design`, `rhs`, `dvs`,
# `dv_labels`, `coef_map`, `gof_omit_pattern`, and `stars_map` from analysis.R.

# --- 1. Survey sample: unweighted vs. weighted ------------------------------
# Compares the raw sample to the raking-weighted sample on the demographic
# and partisanship variables used as raking targets (see Data and Measures).

sample_vars <- c("age", "male", "white", "college", "democrat", "republican")

sample_labels <- c(
  age        = "Age (years)",
  male       = "Male",
  white      = "White (non-Hispanic)",
  college    = "College graduate",
  democrat   = "Democrat",
  republican = "Republican"
)

sample_row <- function(v) {
  x <- d[[v]]
  data.frame(
    Variable   = sample_labels[[v]],
    Unweighted = round(mean(x, na.rm = TRUE), 3),
    Weighted   = round(as.numeric(svymean(as.formula(paste0("~", v)), design = design, na.rm = TRUE)), 3)
  )
}

sample_comparison_table <- lapply(sample_vars, sample_row) |>
  bind_rows() |>
  mutate(Difference = round(Weighted - Unweighted, 3)) |>
  tt(notes = "Weights computed via iterative raking (survey/anesrake) to US Census 2023 ACS demographic targets and Pew NPORS 2025 party-affiliation targets. See Data and Measures.") |>
  style_tt(fontsize = 0.7)

# --- 2. Robustness: results without survey weights --------------------------
# Re-estimates the preregistered H1-H4 specification (tbl-results) via
# unweighted OLS to confirm the main results are not an artifact of the
# raking weights.

fit_model_unweighted <- function(dv) {
  f <- as.formula(paste(dv, "~", rhs))
  lm(f, data = d)
}

models_unweighted <- lapply(dvs, fit_model_unweighted)
names(models_unweighted) <- dv_labels[dvs]

results_table_unweighted <- modelsummary(
  models_unweighted,
  coef_map = coef_map,
  gof_omit = gof_omit_pattern,
  stars = stars_map,
  notes = "Unweighted OLS (lm), same specification as the weighted models in the manuscript's main results table. Reference categories: control condition, moderate/other political identity, no college degree."
) |>
  style_tt(fontsize = 0.7)

# --- 3. Covariate balance across experimental conditions --------------------
# Respondents were randomly assigned to the Trump, climate, or control
# conditions. This checks that assignment produced comparable groups on
# demographics and the pre-treatment political-belief moderators.

d <- d |>
  mutate(condition = case_when(
    trump.cue   == 1 ~ "Trump",
    climate.cue == 1 ~ "Climate",
    control     == 1 ~ "Control"
  ) |> factor(levels = c("Control", "Climate", "Trump")))

balance_vars <- c("age", "male", "white", "college", "inc", "conRep", "libDem")
balance_type <- c(
  age = "cont", male = "bin", white = "bin", college = "bin",
  inc = "cont", conRep = "bin", libDem = "bin"
)
balance_labels <- c(
  age     = "Age (years)",
  male    = "Male",
  white   = "White (non-Hispanic)",
  college = "College graduate",
  inc     = "Income (1-11)",
  conRep  = "Conservative Republican",
  libDem  = "Liberal Democrat"
)

balance_row <- function(v) {
  x    <- d[[v]]
  type <- balance_type[[v]]
  mu   <- tapply(x, d$condition, mean, na.rm = TRUE)
  p    <- if (type == "bin") {
    suppressWarnings(chisq.test(table(d$condition, x))$p.value)
  } else {
    anova(lm(x ~ d$condition))$`Pr(>F)`[1]
  }
  fmt <- function(v) if (type == "bin") sprintf("%.1f%%", 100 * v) else sprintf("%.2f", v)
  data.frame(
    Variable = balance_labels[[v]],
    Control  = fmt(mu[["Control"]]),
    Climate  = fmt(mu[["Climate"]]),
    Trump    = fmt(mu[["Trump"]]),
    `p-value` = sprintf("%.3f", p),
    check.names = FALSE
  )
}

balance_table <- lapply(balance_vars, balance_row) |>
  bind_rows() |>
  tt(notes = paste(
    "Cell entries are unweighted condition means: percentages for binary",
    "indicators and means for continuous measures. The p-value tests for",
    "differences across the three conditions (chi-square for indicators,",
    "one-way ANOVA for continuous measures); non-significant values indicate",
    "the covariate is balanced across conditions, as expected under random",
    "assignment."
  )) |>
  style_tt(fontsize = 0.7)

# --- 4. Robustness: controlling for demographic covariates -------------------
# Adds age, male, white, and income as additive controls to the preregistered
# H1-H4 specification to confirm the cue and interaction effects are not
# driven by demographic imbalances across conditions.

rhs_controls <- paste(rhs, "age + male + white + inc", sep = " + ")

fit_model_controls <- function(dv) {
  f <- as.formula(paste(dv, "~", rhs_controls))
  svyglm(f, design = design)
}

models_controls <- lapply(dvs, fit_model_controls)
names(models_controls) <- dv_labels[dvs]

results_table_controls <- modelsummary(
  models_controls,
  coef_map = coef_map,
  gof_omit = gof_omit_pattern,
  stars = stars_map,
  notes = "Survey-weighted OLS (svyglm), adding age, male, white, and income as additive controls to the specification in the manuscript's main results table. Control coefficients omitted from display; reference categories as in the manuscript's main results table."
) |>
  style_tt(fontsize = 0.7)

# Note: the Trump-approval corroborating analysis (cue x continuous Trump
# approval) moved to the main manuscript; see scripts/analysis.R section 7
# and cue-actions.qmd. `models_approval` and `fig_approval` are built there
# and are available here too since cue-actions-supplemental.qmd sources
# analysis.R before this file.
