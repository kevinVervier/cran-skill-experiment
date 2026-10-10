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

# Trial-style flow diagram for the design slide: starting package -> block-randomised
# arms -> blinded scoring, with the rules shared by every run along the top. Drawn on a
# fixed 16 x 9 canvas so the layout does not depend on the data; only n comes from runs.
# `step` builds it up for fragments on one canvas, so the layers align when stacked:
# 1 = rules + starting package, 2 = + randomisation and arms, 3 = + blinded scoring.
design_fig <- function(step = 3) {
  PANEL <- "#F2F2F2"; ARM <- "#4A4A4A"
  box <- function(x0, x1, y0, y1, fill, colour = NA)
    annotate("rect", xmin = x0, xmax = x1, ymin = y0, ymax = y1, fill = fill, colour = colour)
  arr <- function(x0, y0, x1, y1)
    annotate("segment", x = x0, y = y0, xend = x1, yend = y1, colour = MUTED, linewidth = .8,
             arrow = arrow(length = unit(.11, "in"), type = "closed"))
  ln <- function(x0, y0, x1, y1)
    annotate("segment", x = x0, y = y0, xend = x1, yend = y1, colour = MUTED, linewidth = .8)

  n <- as.integer(table(runs$arm)[names(arm_labels)])
  arms <- tibble::tibble(
    lab  = unname(arm_labels),
    desc = c("no skill file", "cran-extrachecks", "cran-submit",
             "r-package-development", "raw CRAN docs in context"),
    n    = paste0("n = ", n, ifelse(names(arm_labels) == "A0", "*", "")),
    y    = c(7.0, 5.7, 4.4, 3.1, 1.8),
    fill = ifelse(names(arm_labels) == "A0", ACCENT, ARM)
  )
  rules <- c("Pre-registered", "One agent", "Frozen prompt", "Fresh copy each run",
             "CRAN docs in every arm")
  rx <- 3.3 + 2.76 * (seq_along(rules) - 1)

  p <- ggplot() + coord_cartesian(xlim = c(0, 16), ylim = c(0, 9), expand = FALSE) +
    theme_void(base_size = 18)

  # Rules shared by every run.
  p <- p + annotate("text", x = .2, y = 8.55, label = "Every run:", hjust = 0,
                    fontface = "bold", size = 4.6, colour = INK)
  for (i in seq_along(rules)) p <- p + box(rx[i] - 1.3, rx[i] + 1.3, 8.25, 8.85, "white", MUTED)
  p <- p + annotate("text", x = rx, y = 8.55, label = rules, size = 3.9, colour = INK)

  # Starting package.
  p <- p + box(.2, 3.1, 3.3, 5.5, PANEL) +
    annotate("text", x = 1.65, y = 5.0, label = "Starting package", fontface = "bold",
             size = 5, colour = INK) +
    annotate("text", x = 1.65, y = 4.05, size = 4.1, colour = INK, lineheight = .95,
             label = "orthoMTL, re-broken:\n4 planted defects\n+ original set.seed()")
  if (step < 2) return(p)

  # Block randomisation fan-out.
  p <- p + arr(3.1, 4.4, 4.5, 4.4) +
    annotate("text", x = 4.55, y = 8.0, label = "block-randomised\n10 blocks", size = 3.8,
             colour = MUTED, lineheight = .9, vjust = 1) +
    ln(4.55, min(arms$y), 4.55, max(arms$y))
  for (y in arms$y) p <- p + arr(4.55, y, 5.25, y)

  # Arms.
  for (i in seq_len(nrow(arms))) p <- p + box(5.3, 9.8, arms$y[i] - .5, arms$y[i] + .5, arms$fill[i])
  p <- p +
    annotate("text", x = 5.5, y = arms$y + .17, label = arms$lab, hjust = 0,
             fontface = "bold", size = 5, colour = "white") +
    annotate("text", x = 5.5, y = arms$y - .2, label = arms$desc, hjust = 0,
             size = 3.7, colour = "white", family = "mono") +
    annotate("text", x = 9.6, y = arms$y, label = arms$n, hjust = 1,
             fontface = "bold", size = 4.6, colour = "white")

  p <- p + annotate("text", x = .2, y = .55, hjust = 0, size = 3.6, colour = MUTED,
                    label = paste0("60 runs planned, 3 lost to API rate limits, ", nrow(runs),
                                   " analysed.   * includes 10 runs whose skill file never arrived."))
  if (step < 3) return(p)

  # Collector -> blinded scoring.
  for (y in arms$y) p <- p + ln(9.8, y, 10.3, y)
  p <- p + ln(10.3, min(arms$y), 10.3, max(arms$y)) +
    arr(10.3, 5.95, 10.85, 5.95) + arr(10.3, 2.85, 10.85, 2.85) +
    annotate("text", x = 13.35, y = 7.75, label = "Scored blind to arm", fontface = "bold",
             size = 4.6, colour = INK) +
    box(10.9, 15.8, 4.9, 7.0, PANEL, INK) +
    annotate("text", x = 13.35, y = 6.45, label = "Primary: AI judge", fontface = "bold",
             size = 5, colour = INK) +
    annotate("text", x = 13.35, y = 5.55, size = 4.1, colour = INK, lineheight = .95,
             label = "a second model scores\n12 CRAN-reviewer criteria") +
    box(10.9, 15.8, 1.8, 3.9, PANEL) +
    annotate("text", x = 13.35, y = 3.35, label = "Machine check", fontface = "bold",
             size = 5, colour = INK) +
    annotate("text", x = 13.35, y = 2.45, size = 4.1, colour = INK, lineheight = .95,
             label = "R CMD check + scripts:\nplanted defects repaired?")
  p
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
