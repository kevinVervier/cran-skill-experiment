# Figure helpers for talk.qmd. Reads the unblinded join (../unblinded_results.csv).
# Descriptive only (pre-reg section 8): per-run dots plus a median tick, no error bars.
suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(readr)})

INK    <- "#161616"   # single place to change when re-templating
ACCENT <- "#FF4E00"   # highlights the A0 control only
MUTED  <- "#939393"

runs_all <- read_csv("../unblinded_results.csv", show_col_types = FALSE) |>
  mutate(across(c(first_check_evt, wall_s, checks), \(x) suppressWarnings(as.numeric(x))))

# Three block-3 runs ended on API 429 (infrastructure), not agent behaviour.
runs <- filter(runs_all, term == "DECLARED_DONE")

arm_labels <- c(A0 = "A0 control", A1 = "A1 checklist", A2 = "A2 process",
                A3 = "A3 general R", A4 = "A4 oracle*", A5 = "A5 raw handbook")

dotplot <- function(var, xlab, d = runs, integer = FALSE) {
  d <- d |> filter(!is.na(.data[[var]])) |>
    mutate(arm = factor(arm, levels = rev(names(arm_labels)), labels = rev(arm_labels)),
           ctrl = arm == arm_labels[["A0"]])
  med <- d |> group_by(arm) |> summarise(m = median(.data[[var]]), .groups = "drop")
  ggplot(d, aes(.data[[var]], arm)) +
    geom_point(aes(colour = ctrl), shape = 16, size = 3, alpha = .75,
               position = position_jitter(height = .26, width = 0, seed = 1)) +
    geom_segment(data = med, aes(x = m, xend = m, y = as.numeric(arm) - .32,
                                 yend = as.numeric(arm) + .32),
                 colour = INK, linewidth = .9, inherit.aes = FALSE) +
    scale_x_continuous(breaks = if (integer) \(l) seq(ceiling(l[1]), floor(l[2])) else waiver()) +
    scale_colour_manual(values = c(`TRUE` = ACCENT, `FALSE` = MUTED), guide = "none") +
    labs(x = xlab, y = NULL, caption = "Dots = runs; bar = median. *A4 is an upper bound, not a competitor.") +
    theme_minimal(base_size = 18) +
    theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
          panel.grid.major.x = element_line(colour = "#E6E6E6"),
          plot.caption = element_text(colour = MUTED, size = 12), text = element_text(colour = INK))
}

# Seeded machine-detectable defects repaired with no regressions, completed runs only.
seed_cats <- c("missing_namespace", "license_template", "description_meta", "imports_unused")
seed_repaired <- vapply(runs$blind, function(b) {
  d <- jsonlite::read_json(file.path("..", "scoring", "results", b, "seed_audit.json"))
  all(seed_cats %in% unlist(d$repaired_categories)) && length(d$broke_or_new_categories) == 0
}, logical(1))
