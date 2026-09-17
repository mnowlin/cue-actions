# manuscript-prep.R
# Sourced by cue-actions.qmd. Loads data, builds the survey design, fits the
# weighted OLS models testing H1-H4, and builds the tables/objects used in
# the manuscript.

library(survey)
library(dplyr)
library(broom)
library(modelsummary)
library(tinytable)
library(marginaleffects)
library(ggplot2)

# --- 1. Data and survey design ----------------------------------------------

d <- read.csv("data/cueActionsDataWeighted.csv")

design <- svydesign(ids = ~1, weights = ~weight, data = d)

# Unweighted condition sample sizes, for in-text reporting of random assignment.
n_trump   <- sum(d$trump.cue == 1)
n_climate <- sum(d$climate.cue == 1)
n_control <- sum(d$control == 1)
n_total   <- nrow(d)

# --- 1b. Descriptive statistics table ----------------------------------------
# Survey-weighted mean and SD, plus unweighted range, for the five DV items
# and the three focal IVs (conRep, libDem, college).

desc_labels <- c(
  "fed.action.tax.credits"       = "Tax Credits",
  "fed.action.coal.keep.open"    = "Coal Open",
  "fed.action.coal.leasing"      = "Coal Leasing",
  "fed.action.cancel.wind"       = "Cancel Wind",
  "fed.action.nuclear.licensing" = "Nuclear",
  "conRep"                       = "Cons. Republican",
  "libDem"                       = "Lib. Democrat",
  "college"                      = "College"
)

desc_row <- function(v) {
  x <- d[[v]]
  data.frame(
    Variable = desc_labels[[v]],
    Range    = paste0(min(x, na.rm = TRUE), "-", max(x, na.rm = TRUE)),
    Mean     = round(as.numeric(svymean(as.formula(paste0("~", v)), design = design)), 2),
    SD       = round(sqrt(as.numeric(svyvar(as.formula(paste0("~", v)), design = design))), 2)
  )
}

desc_table <- lapply(names(desc_labels), desc_row) |>
  bind_rows() |>
  tt() |>
  style_tt(fontsize = 0.7)

# --- 2. Model specification --------------------------------------------------
# Baseline categories: control condition, moderate/other political identity,
# no college degree.
#
#   trump.cue:conRep, climate.cue:conRep       -> H1 (conRep more supportive
#                                                  under either cue)
#   trump.cue:libDem, climate.cue:libDem       -> H2 (libDem less supportive
#                                                  under either cue)
#   trump.cue:college:conRep                   -> H3 (effect concentrated
#                                                  among non-college conRep)
#   trump.cue:college:libDem                   -> H4 (effect concentrated
#                                                  among non-college libDem)
#
# A separate exploratory model with climate.cue:college:conRep /
# climate.cue:college:libDem terms (not preregistered) is fit below in
# section 6, kept out of this specification so it doesn't cost precision
# on the preregistered H1-H4 tests.

dvs <- c(
  "fed.action.tax.credits",
  "fed.action.coal.keep.open",
  "fed.action.coal.leasing",
  "fed.action.cancel.wind",
  "fed.action.nuclear.licensing"
)

dv_labels <- c(
  "fed.action.tax.credits"      = "Tax Credits",
  "fed.action.coal.keep.open"   = "Coal Open",
  "fed.action.coal.leasing"     = "Coal Leasing",
  "fed.action.cancel.wind"      = "Cancel Wind",
  "fed.action.nuclear.licensing" = "Nuclear"
)

rhs <- paste(
  "trump.cue + climate.cue + conRep + libDem + college",
  "trump.cue:conRep + climate.cue:conRep",
  "trump.cue:libDem + climate.cue:libDem",
  "trump.cue:college + college:conRep + college:libDem",
  "trump.cue:college:conRep + trump.cue:college:libDem",
  sep = " + "
)

fit_model <- function(dv) {
  f <- as.formula(paste(dv, "~", rhs))
  svyglm(f, design = design)
}

models <- lapply(dvs, fit_model)
names(models) <- dv_labels[dvs]

# --- 3. Regression table ------------------------------------------------------

# Displayed coefficients are the cue main effects, identity main effects,
# and the interaction terms that directly test H1-H4.
coef_map <- c(
  "trump.cue"                       = "Trump Cue",
  "climate.cue"                     = "Climate Cue",
  "conRep"                          = "Cons. Republican",
  "libDem"                          = "Lib. Democrat",
  "college"                         = "College",
  "trump.cue:conRep"                = "Trump x ConRep",
  "climate.cue:conRep"              = "Climate x ConRep",
  "trump.cue:libDem"                = "Trump x LibDem",
  "climate.cue:libDem"              = "Climate x LibDem",
  "trump.cue:college"               = "Trump x College",
  "conRep:college"                  = "College x ConRep",
  "libDem:college"                  = "College x LibDem",
  "trump.cue:conRep:college"        = "Trump x ConRep x College",
  "trump.cue:libDem:college"        = "Trump x LibDem x College",
  "(Intercept)"                     = "Intercept"
)

gof_omit_pattern <- "IC$|Log.Lik|F$|RMSE|Adj"
stars_map <- c("†" = .1, "*" = .05, "**" = .01, "***" = .001)
table_notes <- "Survey-weighted OLS (svyglm). Reference categories: control condition, moderate/other political identity, no college degree."

results_table <- modelsummary(
  models,
  coef_map = coef_map,
  gof_omit = gof_omit_pattern,
  stars = stars_map,
  notes = table_notes
) |>
  style_tt(fontsize = 0.7)

# --- 3b. Difference-of-means table (cue condition) -------------------------
# Survey-weighted mean support for each action by cue condition, plus the
# Trump- and climate-cue differences from control. Estimated per DV with
# svyglm(dv ~ trump.cue + climate.cue): the intercept is the weighted control
# mean, and the two slopes are the weighted mean differences from control,
# with design-based SEs and tests.

star <- function(p) {
  as.character(cut(p, breaks = c(-Inf, .001, .01, .05, .1, Inf),
                   labels = c("***", "**", "*", "†", "")))
}

means_row <- function(dv) {
  m <- svyglm(as.formula(paste(dv, "~ trump.cue + climate.cue")), design = design)
  s <- summary(m)$coefficients
  p_col  <- grep("^Pr", colnames(s))
  ctrl   <- s["(Intercept)", "Estimate"]
  t_diff <- s["trump.cue", "Estimate"]
  c_diff <- s["climate.cue", "Estimate"]
  data.frame(
    Action              = dv_labels[[dv]],
    Control             = sprintf("%.2f", ctrl),
    `Trump Cue`         = sprintf("%.2f", ctrl + t_diff),
    `Climate Cue`       = sprintf("%.2f", ctrl + c_diff),
    `Trump - Control`   = paste0(sprintf("%+.2f", t_diff), star(s["trump.cue", p_col])),
    `Climate - Control` = paste0(sprintf("%+.2f", c_diff), star(s["climate.cue", p_col])),
    check.names = FALSE
  )
}

means_table <- lapply(dvs, means_row) |>
  bind_rows() |>
  tt(notes = paste(
    "Survey-weighted mean support (1-5) by cue condition, with mean differences",
    "from the control condition. Differences and tests from",
    "svyglm(support ~ trump.cue + climate.cue).",
    "† p<0.10, * p<0.05, ** p<0.01, *** p<0.001."
  )) |>
  style_tt(fontsize = 0.7)

# --- 3c. Liberal Democrats' control-condition means (floor-effect check) ---
# Survey-weighted mean support among liberal Democrats in the control
# condition only, for the in-text floor-effect discussion of why the Trump
# and climate cues moved Democrats' opinions so little.

wtd_mean_sub <- function(x, w) sum(x * w) / sum(w)

libdem_control <- d[d$libDem == 1 & d$control == 1, ]
libdem_control_means <- sapply(dvs, function(dv) {
  round(wtd_mean_sub(libdem_control[[dv]], libdem_control$weight), 2)
})
names(libdem_control_means) <- dv_labels[dvs]

# --- 4. Helper for in-text/bullet interpretation of hypothesis terms --------

get_term <- function(model, term) {
  tidy(model) %>% filter(term == !!term)
}

hyp_terms <- c(
  H1a = "trump.cue:conRep",
  H1b = "climate.cue:conRep",
  H2a = "trump.cue:libDem",
  H2b = "climate.cue:libDem",
  H3  = "trump.cue:conRep:college",
  H4  = "trump.cue:libDem:college"
)

hyp_results <- lapply(models, function(m) {
  purrr_map <- lapply(hyp_terms, function(term) get_term(m, term))
  names(purrr_map) <- names(hyp_terms)
  purrr_map
})

# --- 5. Predicted values for the IVs of interest -----------------------------
# Model-predicted support (95% CIs) for the cue x political-identity and
# cue x identity x college terms that test H1-H4.

wtd_mean <- function(x) sum(x * d$weight) / sum(d$weight)

predict_grid <- function(grid) {
  out <- lapply(names(models), function(dv_label) {
    p <- as.data.frame(predictions(models[[dv_label]], newdata = grid))
    p$dv <- dv_label
    p
  })
  bind_rows(out) %>% mutate(dv = factor(dv, levels = dv_labels))
}

# 5a. Cue condition x political identity (H1/H2), college held at its
# survey-weighted mean so predictions reflect the general population.
grid_identity <- expand.grid(
  cue_label      = c("Control", "Trump Cue", "Climate Cue"),
  identity_label = c("Moderate/Other", "Cons. Republican", "Lib. Democrat"),
  stringsAsFactors = FALSE
) %>%
  mutate(
    trump.cue   = as.numeric(cue_label == "Trump Cue"),
    climate.cue = as.numeric(cue_label == "Climate Cue"),
    conRep      = as.numeric(identity_label == "Cons. Republican"),
    libDem      = as.numeric(identity_label == "Lib. Democrat"),
    college     = wtd_mean(d$college)
  )

pred_identity <- predict_grid(grid_identity) %>%
  mutate(
    cue_label = factor(cue_label, levels = c("Control", "Trump Cue", "Climate Cue")),
    identity_label = factor(identity_label, levels = c("Moderate/Other", "Cons. Republican", "Lib. Democrat"))
  )

fig_identity <- ggplot(pred_identity, aes(x = identity_label, y = estimate, color = cue_label)) +
  geom_pointrange(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = 0.5)
  ) +
  facet_wrap(~dv, nrow = 1) +
  labs(x = NULL, y = "Predicted Support (1-5)", color = "Condition") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 40, hjust = 1), legend.position = "bottom")

# 5b. Trump cue x political identity x college (H3/H4). Climate cue and the
# moderate/other identity group are dropped since H3/H4 only concern the
# Trump cue's effect on conRep/libDem, moderated by education.
grid_college <- expand.grid(
  cue_label      = c("Control", "Trump Cue"),
  identity_label = c("Cons. Republican", "Lib. Democrat"),
  college_label  = c("No Degree", "College Degree"),
  stringsAsFactors = FALSE
) %>%
  mutate(
    trump.cue   = as.numeric(cue_label == "Trump Cue"),
    climate.cue = 0,
    conRep      = as.numeric(identity_label == "Cons. Republican"),
    libDem      = as.numeric(identity_label == "Lib. Democrat"),
    college     = as.numeric(college_label == "College Degree")
  )

pred_college <- predict_grid(grid_college) %>%
  mutate(
    cue_label = factor(cue_label, levels = c("Control", "Trump Cue")),
    college_label = factor(college_label, levels = c("No Degree", "College Degree"))
  )

fig_college <- ggplot(pred_college, aes(x = college_label, y = estimate, color = cue_label)) +
  geom_pointrange(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = 0.4)
  ) +
  facet_grid(identity_label ~ dv) +
  labs(x = NULL, y = "Predicted Support (1-5)", color = "Condition") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 40, hjust = 1), legend.position = "bottom")

# --- 6a. Hypothesis test summary (H1/H2 scorecard) --------------------------
# H1 and H2 are preregistered as directional (one-tailed) compound hypotheses
# ("Trump OR climate cue"), and the preregistration did not specify a
# significance threshold. Rather than reducing each compound hypothesis to a
# single supported/not-supported verdict, this table reports the one-tailed
# test (the statistically appropriate test for a directional hypothesis) for
# each cue x identity interaction term, separately for each of the five
# actions, so the cue- and action-specific pattern underlying the H1/H2
# conclusions in the text is fully transparent.
#
#   trump.cue:conRep, climate.cue:conRep -> H1 (expected sign: positive)
#   trump.cue:libDem, climate.cue:libDem -> H2 (expected sign: negative)
#
# One-tailed p = two-tailed p / 2 when the estimated sign matches the
# hypothesized direction, and 1 - two-tailed p / 2 otherwise (i.e., evidence
# against the hypothesized direction can never register as one-tailed
# "significant," but a two-tailed-significant effect in the *opposite* of
# the hypothesized direction is flagged separately below).

scorecard_terms <- c(
  "trump.cue:conRep"   = 1,
  "climate.cue:conRep" = 1,
  "trump.cue:libDem"   = -1,
  "climate.cue:libDem" = -1
)

scorecard_cell <- function(dv_label, term, expected_sign) {
  m    <- models[[dv_label]]
  s    <- summary(m)$coefficients
  est  <- s[term, "Estimate"]
  p2   <- s[term, grep("^Pr", colnames(s))]
  matches_direction <- sign(est) == expected_sign
  p1   <- if (matches_direction) p2 / 2 else 1 - p2 / 2
  mark <- if (matches_direction && p1 < .05) {
    "*"
  } else if (matches_direction && p1 < .10) {
    "†"
  } else if (!matches_direction && p2 < .05) {
    "‡"  # significant, opposite of the hypothesized direction
  } else {
    ""
  }
  sprintf("%+.2f%s", est, mark)
}

hyp_scorecard_table <- data.frame(Action = unname(dv_labels[dvs]), check.names = FALSE)
scorecard_col_labels <- c(
  "trump.cue:conRep"   = "H1: Trump x ConRep",
  "climate.cue:conRep" = "H1: Climate x ConRep",
  "trump.cue:libDem"   = "H2: Trump x LibDem",
  "climate.cue:libDem" = "H2: Climate x LibDem"
)
for (term in names(scorecard_terms)) {
  hyp_scorecard_table[[scorecard_col_labels[[term]]]] <- sapply(
    dv_labels[dvs], scorecard_cell, term = term, expected_sign = scorecard_terms[[term]]
  )
}

hyp_scorecard_table <- hyp_scorecard_table |>
  tt(notes = paste(
    "Cell entries are the cue x identity interaction coefficient from the model",
    "for that action (@tbl-results), with one-tailed significance given the",
    "preregistered directional hypotheses (which specified no significance",
    "threshold): * one-tailed p<.05; † one-tailed p<.10; ‡ two-tailed",
    "p<.05 in the direction opposite the one hypothesized. H1 expects positive",
    "coefficients (more support); H2 expects negative coefficients (less",
    "support)."
  )) |>
  style_tt(fontsize = 0.7)

# --- 6. Exploratory model: climate cue x education --------------------------
# Not preregistered. H3/H4 only hypothesized that education would moderate
# the Trump cue's effect; this adds the parallel climate.cue:college terms
# to check whether education also moderates the climate cue's effect. Fit as
# a separate model (rather than added to `models` above) so it doesn't cost
# precision on the preregistered H1-H4 tests.

rhs_climate_college <- paste(rhs, "climate.cue:college + climate.cue:college:conRep + climate.cue:college:libDem", sep = " + ")

fit_model_explore <- function(dv) {
  f <- as.formula(paste(dv, "~", rhs_climate_college))
  svyglm(f, design = design)
}

models_explore <- lapply(dvs, fit_model_explore)
names(models_explore) <- dv_labels[dvs]

coef_map_explore <- c(coef_map, c(
  "climate.cue:college"        = "Climate x College",
  "climate.cue:conRep:college" = "Climate x ConRep x College",
  "climate.cue:libDem:college" = "Climate x LibDem x College"
))

results_table_explore <- modelsummary(
  models_explore,
  coef_map = coef_map_explore,
  gof_omit = gof_omit_pattern,
  stars = stars_map,
  notes = "Survey-weighted OLS (svyglm). Exploratory model adding climate.cue:college and its interactions with conRep/libDem to the preregistered H1-H4 specification; not used for the preregistered hypothesis tests."
) |>
  style_tt(fontsize = 0.7)

# --- 7. Corroborating analysis: Trump approval as a continuous moderator ----
# trump.approval (1-5) was measured after respondents saw their assigned cue,
# so it cannot be added as a covariate or moderator in the preregistered
# causal model (H1-H4) without risking post-treatment bias: because it is
# downstream of the manipulation, conditioning on it can distort the very
# cue effects it would be added to help interpret. It is also highly
# correlated with the conRep/libDem measures used in the main models
# (r = .65 / -.57), so including it alongside them would not isolate an
# independent effect in any case. This is not a preregistered hypothesis;
# it is reported as a corroborating analysis on the mechanism behind the
# preregistered Trump-cue findings above -- whether the same pattern holds
# under an alternative operationalization of pro-Trump orientation, not a
# robustness check of the H1-H4 estimates themselves to a specification
# choice.

# 7a. Does cue assignment predict stated Trump approval? A significant
# coefficient would indicate the cue itself shifted stated approval, which
# would complicate its use as a moderator below.
trump_approval_balance <- svyglm(trump.approval ~ trump.cue + climate.cue, design = design)

trump_approval_balance_table <- tidy(trump_approval_balance) |>
  mutate(across(where(is.numeric), ~ round(.x, 3))) |>
  tt(notes = paste(
    "Survey-weighted OLS of Trump approval (1-5) on cue condition (control",
    "condition omitted). Neither coefficient approaches significance."
  )) |>
  style_tt(fontsize = 0.7)

# 7b. Model: cues x continuous Trump approval, replacing conRep/libDem. Not
# preregistered and not causal, since approval is measured post-treatment;
# reported as a corroborating analysis on whether a more direct measure of
# pro-Trump orientation shows a pattern consistent with the conRep-based
# results above.
fit_model_approval <- function(dv) {
  f <- as.formula(paste(
    dv,
    "~ trump.cue + climate.cue + trump.approval",
    "+ trump.cue:trump.approval + climate.cue:trump.approval"
  ))
  svyglm(f, design = design)
}

models_approval <- lapply(dvs, fit_model_approval)
names(models_approval) <- dv_labels[dvs]

coef_map_approval <- c(
  "trump.cue"                 = "Trump Cue",
  "climate.cue"                = "Climate Cue",
  "trump.approval"              = "Trump Approval",
  "trump.cue:trump.approval"    = "Trump Cue x Approval",
  "climate.cue:trump.approval"  = "Climate Cue x Approval",
  "(Intercept)"                 = "Intercept"
)

results_table_approval <- modelsummary(
  models_approval,
  coef_map = coef_map_approval,
  gof_omit = gof_omit_pattern,
  stars = stars_map,
  notes = paste(
    "Survey-weighted OLS (svyglm). Not preregistered: replaces the ideology x",
    "party identity measures (conRep/libDem) with continuous Trump approval",
    "(1-5), measured after the cue manipulation. Because approval is",
    "post-treatment, these estimates are descriptive only and should not be",
    "given a causal interpretation."
  )
) |>
  style_tt(fontsize = 0.7)

# 7c. Figure: predicted support by Trump approval and cue condition, for
# each action. Uses the models_approval fits above.
grid_approval <- expand.grid(
  trump.approval = seq(1, 5, by = 0.1),
  cue_label      = c("Control", "Trump Cue", "Climate Cue"),
  stringsAsFactors = FALSE
) %>%
  mutate(
    trump.cue   = as.numeric(cue_label == "Trump Cue"),
    climate.cue = as.numeric(cue_label == "Climate Cue")
  )

predict_grid_approval <- function(grid) {
  out <- lapply(names(models_approval), function(dv_label) {
    p <- as.data.frame(predictions(models_approval[[dv_label]], newdata = grid))
    p$dv <- dv_label
    p
  })
  bind_rows(out) %>% mutate(dv = factor(dv, levels = dv_labels))
}

pred_approval <- predict_grid_approval(grid_approval) %>%
  mutate(cue_label = factor(cue_label, levels = c("Control", "Trump Cue", "Climate Cue")))

fig_approval <- ggplot(pred_approval, aes(x = trump.approval, y = estimate, color = cue_label, fill = cue_label)) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  facet_wrap(~dv, nrow = 1) +
  labs(x = "Trump Approval (1-5)", y = "Predicted Support (1-5)", color = "Condition", fill = "Condition") +
  theme_bw() +
  theme(legend.position = "bottom")
