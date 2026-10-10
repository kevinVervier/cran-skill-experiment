# Figure helpers for talk.qmd. Reads the unblinded join (../unblinded_results.csv).
# Descriptive only (pre-reg section 8): per-run dots plus a median tick, no error bars.
suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(readr)})

INK    <- "#161616"   # single place to change when re-templating
ACCENT <- "#FF4E00"   # highlights the A0 control only
MUTED  <- "#939393"

runs_all <- read_csv("../unblinded_results.csv", show_col_types = FALSE) |>
  mutate(across(c(first_check_evt, wall_s, checks), \(x) suppressWarnings(as.numeric(x))))

# Three block-3 runs ended on API 429 (infrastructure), not agent behaviour.
runs <- filter(runs_all, term == "DECLARED_DONE") |>
  # A4's hindsight file was never delivered (LESSONS_LEARNED.md section 0), so its runs are
  # identical in configuration to A0: pooled as A0 (n=20). The labels are re-mapped here only.
  mutate(arm = ifelse(arm == "A4", "A0", arm))

# Arms are named by content on slides; the A-codes stay as names for joins with the data.
arm_labels <- c(A0 = "Control", A1 = "Checklist", A2 = "Process",
                A3 = "General R", A5 = "Handbook")

# Outcome slide. judge_nc takes only 0/1/2 across all runs, so a jittered dot
# strip over-plots badly and implies a continuum that isn't there. A stacked
# count of runs per arm shows the whole distribution exactly, with no jitter
# seed to explain and nothing hidden behind another point.
stack_fig <- function(var = "judge_nc", d = runs) {
  d <- d |> filter(!is.na(.data[[var]])) |>
    count(arm, lev = factor(.data[[var]])) |>
    mutate(arm = factor(arm, levels = rev(names(arm_labels)), labels = rev(arm_labels)))
  ggplot(d, aes(n, arm, fill = lev)) +
    geom_col(width = .68, colour = "white", linewidth = 1.2,
             position = position_stack(reverse = TRUE)) +
    # White on the lightest fill is unreadable at projection distance.
    geom_text(aes(label = n, colour = lev), position = position_stack(vjust = .5, reverse = TRUE),
              fontface = "bold", size = 6.2, show.legend = FALSE) +
    # Ramp kept dark: light fills are the first thing video compression flattens.
    # All three clear 4.5:1 for white labels, with ~2:1 between adjacent levels.
    scale_fill_manual(values = c(`0` = "#161616", `1` = "#4A4A4A", `2` = "#757575"),
                      name = "Issues flagged") +
    scale_colour_manual(values = c(`0` = "white", `1` = "white", `2` = "white"), guide = "none") +
    scale_x_continuous(expand = expansion(mult = c(0, .02))) +
    labs(x = "Runs", y = NULL,
         caption = "Every run landed on 0-2 issues, in every arm.") +
    theme_minimal(base_size = 18) +
    theme(panel.grid = element_blank(), axis.text.x = element_blank(),
          legend.position = "top",
          plot.caption = element_text(colour = MUTED, size = 13),
          text = element_text(colour = INK))
}

dotplot <- function(var, xlab, d = runs, integer = FALSE) {
  d <- d |> filter(!is.na(.data[[var]])) |>
    mutate(arm = factor(arm, levels = rev(names(arm_labels)), labels = rev(arm_labels)),
           ctrl = arm == arm_labels[["A0"]])
  med <- d |> group_by(arm) |> summarise(m = median(.data[[var]]), .groups = "drop")
  ggplot(d, aes(.data[[var]], arm)) +
    geom_point(aes(colour = ctrl), shape = 16, size = 3.8, alpha = .75,
               position = position_jitter(height = .26, width = 0, seed = 1)) +
    geom_segment(data = med, aes(x = m, xend = m, y = as.numeric(arm) - .32,
                                 yend = as.numeric(arm) + .32),
                 colour = INK, linewidth = .9, inherit.aes = FALSE) +
    scale_x_continuous(breaks = if (integer) \(l) seq(ceiling(l[1]), floor(l[2])) else waiver()) +
    scale_colour_manual(values = c(`TRUE` = ACCENT, `FALSE` = MUTED), guide = "none") +
    labs(x = xlab, y = NULL, caption = "Dots = runs; bar = median.") +
    theme_minimal(base_size = 18) +
    theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
          panel.grid.major.x = element_line(colour = "#E6E6E6"),
          plot.caption = element_text(colour = MUTED, size = 13), text = element_text(colour = INK))
}

# Seeded machine-detectable defects repaired with no regressions, completed runs only.
seed_cats <- c("missing_namespace", "license_template", "description_meta", "imports_unused")
seed_repaired <- vapply(runs$blind, function(b) {
  d <- jsonlite::read_json(file.path("..", "scoring", "results", b, "seed_audit.json"))
  all(seed_cats %in% unlist(d$repaired_categories)) && length(d$broke_or_new_categories) == 0
}, logical(1))

# Experiment schematic for the design slide: five arms -> blinded scoring.
design_fig <- function() {
  d <- tibble::tibble(
    arm = factor(names(arm_labels), levels = rev(names(arm_labels))),
    lab = unname(arm_labels),
    n   = as.integer(table(runs$arm)[names(arm_labels)]),
    ctrl = names(arm_labels) == "A0"
  )
  ggplot(d, aes(x = 1, y = arm)) +
    geom_tile(aes(fill = ctrl), width = .9, height = .82, colour = "white", linewidth = 1.5) +
    geom_text(aes(label = paste0(lab, "   n = ", n)), colour = "white",
              fontface = "bold", size = 6.5, hjust = .5) +
    scale_fill_manual(values = c(`TRUE` = ACCENT, `FALSE` = "#5A5A5A"), guide = "none") +
    labs(x = NULL, y = NULL) +
    theme_void(base_size = 18)
}

# Anonymised schematic for the opening slide. No compound, gene, trial or
# variable names may appear in this talk, and the original study figures carry
# those labels in the image itself - so the effect is redrawn from scratch as an
# illustrative shape. Values are indicative, not estimates.
sign_flip_fig <- function() {
  d <- tibble::tibble(
    month = c(2, 4, 6, 10, 15, 18, 22),
    est   = c(-0.125, -0.105, -0.125, -0.105, -0.012, 0.012, 0.062),
    se    = c(0.012, 0.010, 0.011, 0.013, 0.014, 0.013, 0.015)
  )
  ggplot(d, aes(month, est)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = INK, linewidth = .6) +
    geom_ribbon(aes(ymin = est - 1.96 * se, ymax = est + 1.96 * se),
                fill = ACCENT, alpha = .18) +
    geom_line(colour = ACCENT, linewidth = 1.6) +
    geom_point(colour = ACCENT, size = 3.4) +
    annotate("text", x = 3.6, y = -0.052, label = "harmful", colour = INK,
             fontface = "bold", size = 6.4, hjust = .5) +
    annotate("text", x = 20, y = 0.028, label = "protective", colour = INK,
             fontface = "bold", size = 6.4, hjust = .5) +
    scale_x_continuous(breaks = d$month) +
    # State the sign: survival statisticians read a negative Cox coefficient as protective.
    labs(x = "Months of follow-up", y = "Effect on survival\n(below 0 = worse)",
         caption = "Schematic of one biomarker's effect. Shape is illustrative.") +
    theme_minimal(base_size = 19) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "#E6E6E6"),
          plot.caption = element_text(colour = MUTED, size = 13),
          text = element_text(colour = INK))
}

# Landmark schematic for the orthoMTL slide, replacing the MTLSA table image (unreadable
# when projected). Each landmark is one yes/no task: still event-free at that time?
# Patients are invented; 1 = event-free, 0 = event before the landmark, ? = censored.
landmark_fig <- function() {
  # y = 5 - id puts patient 1 at the top without a reversed scale.
  pts <- tibble::tibble(id = 1:4, time = c(20, 9, 15, 24), event = c(TRUE, TRUE, FALSE, FALSE))
  lms <- c(6, 12, 18)
  cells <- merge(pts, data.frame(lm = lms), by = NULL) |>
    mutate(lab = ifelse(lm < time, "1", ifelse(event, "0", "?")), y = 5 - id)
  pts <- mutate(pts, y = 5 - id)
  ggplot() +
    geom_vline(xintercept = lms, linetype = "dashed", colour = MUTED, linewidth = .6) +
    geom_segment(data = pts, aes(x = 0, xend = time, y = y, yend = y),
                 colour = INK, linewidth = 1.3) +
    geom_point(data = pts, aes(time, y, shape = event), size = 4.2, stroke = 1.4, colour = INK) +
    geom_label(data = cells, aes(lm, y, label = lab, colour = lab == "?"),
               fontface = "bold", size = 5.6, label.size = 0, fill = "white") +
    annotate("text", x = lms, y = 4.6, label = paste("Task", seq_along(lms)),
             fontface = "bold", size = 5.6, colour = INK) +
    scale_shape_manual(values = c(`TRUE` = 4, `FALSE` = 1), guide = "none") +
    scale_colour_manual(values = c(`TRUE` = ACCENT, `FALSE` = INK), guide = "none") +
    scale_x_continuous(breaks = lms, labels = paste(lms, "mo"), limits = c(0, 25)) +
    scale_y_continuous(breaks = 4:1, labels = paste("Patient", 1:4),
                       expand = expansion(add = c(.4, .4))) +
    labs(x = NULL, y = NULL,
         caption = "x event   o censored   1 event-free   0 event   ? left out of that task") +
    theme_minimal(base_size = 18) +
    theme(panel.grid = element_blank(),
          plot.caption = element_text(colour = MUTED, size = 12, hjust = .5),
          text = element_text(colour = INK))
}
