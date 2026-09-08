#!/usr/bin/env Rscript

# Nature-style quantitative figures for FEM task 9.
# Core conclusion:
# The CST model captures the global uniaxial-tension response, while fixed-end
# constraint and low-order discretization create local transverse/shear stress
# perturbations near the left boundary.

required <- c("ggplot2", "patchwork", "svglite", "ragg", "dplyr", "tidyr", "scales", "jsonlite")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  stop(
    "Missing R packages: ", paste(missing, collapse = ", "),
    "\nInstall with: install.packages(c(",
    paste(sprintf('\"%s\"', missing), collapse = ", "),
    "))",
    call. = FALSE
  )
}

library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyr)
library(scales)
library(jsonlite)

root <- "C:/Users/86198/Desktop/task9"
out_dir <- file.path(root, "output", "nature_figures_R")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

node <- read.csv(file.path(root, "node_displacements.csv"), check.names = FALSE)
elem <- read.csv(file.path(root, "element_stresses.csv"), check.names = FALSE)
summary <- jsonlite::fromJSON(file.path(root, "results_summary.json"))

L <- summary$parameters$L_m
H <- summary$parameters$H_m
E <- summary$parameters$E_Pa
nu <- summary$parameters$nu
q <- summary$parameters$q_Pa

theme_set(
  theme_classic(base_size = 7, base_family = "Arial") +
    theme(
      axis.line = element_line(linewidth = 0.3, colour = "black"),
      axis.ticks = element_line(linewidth = 0.3, colour = "black"),
      axis.title = element_text(size = 7),
      axis.text = element_text(size = 6.2, colour = "black"),
      legend.title = element_text(size = 6.2),
      legend.text = element_text(size = 5.8),
      strip.text = element_text(size = 6.5, face = "bold"),
      plot.title = element_text(size = 7.2, face = "bold"),
      plot.tag = element_text(size = 8, face = "bold"),
      panel.grid.major.y = element_line(linewidth = 0.18, colour = "#E6E6E6"),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank()
    )
)

palette_main <- c(
  "FEM" = "#3B6EA8",
  "Theory" = "#202020",
  "S11" = "#3B6EA8",
  "S22" = "#D99A2B",
  "S12" = "#7A6BAF"
)

save_pub <- function(plot, name, width_mm = 180, height_mm = 115, dpi = 600) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  svglite::svglite(file.path(out_dir, paste0(name, ".svg")), width = w, height = h)
  print(plot)
  dev.off()
  grDevices::cairo_pdf(file.path(out_dir, paste0(name, ".pdf")), width = w, height = h, family = "Arial")
  print(plot)
  dev.off()
  ragg::agg_png(file.path(out_dir, paste0(name, ".png")), width = w, height = h, units = "in", res = dpi, background = "white")
  print(plot)
  dev.off()
  ragg::agg_tiff(file.path(out_dir, paste0(name, ".tiff")), width = w, height = h, units = "in", res = dpi, background = "white")
  print(plot)
  dev.off()
}

# Figure A: axial displacement validation along the plate length.
mid_nodes <- node %>%
  mutate(abs_y_mid = abs(y - H / 2)) %>%
  group_by(x) %>%
  slice_min(abs_y_mid, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(x) %>%
  mutate(
    U1_theory = q / E * x,
    residual_um = (U1 - U1_theory) * 1e6,
    U1_um = U1 * 1e6,
    U1_theory_um = U1_theory * 1e6
  )

p_u <- ggplot(mid_nodes, aes(x = x)) +
  geom_line(aes(y = U1_um, colour = "FEM"), linewidth = 0.45) +
  geom_point(aes(y = U1_um, colour = "FEM"), size = 0.9, stroke = 0) +
  geom_line(aes(y = U1_theory_um, colour = "Theory"), linewidth = 0.45, linetype = "22") +
  scale_colour_manual(values = palette_main[c("FEM", "Theory")], name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.02))) +
  labs(x = "x position (m)", y = expression(U[x]~"(µm)"), title = "Axial displacement follows the theoretical linear trend") +
  theme(legend.position = c(0.20, 0.82))

p_res <- ggplot(mid_nodes, aes(x = x, y = residual_um)) +
  geom_hline(yintercept = 0, linewidth = 0.3, linetype = "22", colour = "#202020") +
  geom_area(fill = "#DDE8F5", alpha = 0.9) +
  geom_line(colour = "#3B6EA8", linewidth = 0.45) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.02))) +
  labs(x = "x position (m)", y = expression(Delta*U[x]~"(µm)"), title = "Residual highlights the fixed-end stiffness effect")

fig_a <- p_u / p_res + plot_annotation(tag_levels = "A")
save_pub(fig_a, "figA_displacement_validation", width_mm = 180, height_mm = 118)

# Figure B: stress components along the plate length, binned by x location.
stress_profile <- elem %>%
  mutate(
    bin = cut(centroid_x, breaks = seq(0, L, length.out = 21), include.lowest = TRUE),
    S11_MPa = S11 / 1e6,
    S22_MPa = S22 / 1e6,
    S12_MPa = S12 / 1e6
  ) %>%
  group_by(bin) %>%
  summarise(
    x = mean(centroid_x),
    S11 = mean(S11_MPa),
    S22 = mean(S22_MPa),
    S12 = mean(S12_MPa),
    .groups = "drop"
  ) %>%
  pivot_longer(cols = c(S11, S22, S12), names_to = "component", values_to = "stress_MPa")

p_stress <- ggplot(stress_profile, aes(x = x, y = stress_MPa, colour = component)) +
  geom_hline(yintercept = q / 1e6, linewidth = 0.3, linetype = "22", colour = "#202020") +
  geom_hline(yintercept = 0, linewidth = 0.25, colour = "#777777") +
  geom_line(linewidth = 0.52) +
  geom_point(size = 0.9, stroke = 0) +
  scale_colour_manual(values = palette_main[c("S11", "S22", "S12")], name = NULL,
                      labels = c(S11 = expression(sigma[x]), S22 = expression(sigma[y]), S12 = expression(tau[xy]))) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.02))) +
  labs(x = "x position (m)", y = "Mean stress by x-bin (MPa)",
       title = expression(sigma[x]~"approaches 100 MPa; transverse and shear stresses decay away from the fixed end")) +
  theme(legend.position = c(0.84, 0.82))

save_pub(p_stress, "figB_stress_components", width_mm = 180, height_mm = 92)

# Figure C: compact evidence map for error sources and improvement routes.
error_map <- data.frame(
  source = factor(
    c("CST constant strain", "Coarse mesh", "Fully fixed left edge", "Nodal load equivalence"),
    levels = c("CST constant strain", "Coarse mesh", "Fully fixed left edge", "Nodal load equivalence")
  ),
  effect = c(3, 3, 4, 2),
  improvement = c("Higher-order element", "Global/local refinement", "More realistic constraint", "Finer boundary mesh")
)

p_err <- ggplot(error_map, aes(x = source, y = effect)) +
  geom_col(width = 0.62, fill = "#6C8EBF") +
  geom_text(aes(label = improvement), hjust = -0.02, size = 2.0, family = "Arial") +
  coord_flip(ylim = c(0, 5.0), clip = "off") +
  scale_y_continuous(breaks = 0:4, labels = c("0", "low", "moderate", "high", "dominant")) +
  labs(x = NULL, y = "Qualitative impact on local error", title = "Main error sources and targeted refinements") +
  theme(
    plot.margin = margin(5.5, 38, 5.5, 5.5),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(linewidth = 0.18, colour = "#E6E6E6")
  )

save_pub(p_err, "figC_error_sources", width_mm = 140, height_mm = 85)

writeLines(c(
  "Generated R figures:",
  file.path(out_dir, "figA_displacement_validation.svg"),
  file.path(out_dir, "figB_stress_components.svg"),
  file.path(out_dir, "figC_error_sources.svg")
), file.path(out_dir, "README.txt"))
