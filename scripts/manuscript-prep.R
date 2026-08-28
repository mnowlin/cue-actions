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
