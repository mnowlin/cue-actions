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
  "age + male + white + inc",
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
# and the interaction terms that directly test H1-H4. Demographic controls
# (age, male, white, inc) are estimated in every model but omitted from the
# printed table (noted below it) to keep the table a readable width across
# HTML, PDF, and DOCX.
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
table_notes <- "Survey-weighted OLS (svyglm). Reference categories: control condition, moderate/other political identity, no college degree. All models also control for age, gender, race, and income (omitted here for space)."

results_table <- modelsummary(
  models,
  coef_map = coef_map,
  gof_omit = gof_omit_pattern,
  stars = stars_map,
  notes = table_notes
) |>
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
# cue x identity x college terms that test H1-H4. Demographic controls are
# held at their survey-weighted means throughout.

wtd_mean <- function(x) sum(x * d$weight) / sum(d$weight)

controls_at_mean <- data.frame(
  age   = wtd_mean(d$age),
  male  = wtd_mean(d$male),
  white = wtd_mean(d$white),
  inc   = wtd_mean(d$inc)
)

predict_grid <- function(grid) {
  nd <- merge(grid, controls_at_mean)
  out <- lapply(names(models), function(dv_label) {
    p <- as.data.frame(predictions(models[[dv_label]], newdata = nd))
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
