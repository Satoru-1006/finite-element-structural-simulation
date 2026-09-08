library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyr)
library(grid)

out_dir <- "C:/Users/86198/Desktop/task8_nature_output"
fig_dir <- file.path(out_dir, "figures")
data_dir <- file.path(out_dir, "source_data")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

L <- 1.0
H <- 0.4
t_plate <- 0.01
E <- 210e9
nu <- 0.30
q <- 100e6
sigma0 <- q
G <- E / (2 * (1 + nu))
nx <- 241
ny <- 101
x <- seq(0, L, length.out = nx)
y <- seq(-H / 2, H / 2, length.out = ny)
grid_df <- expand.grid(x = x, y = y)

series_fields <- function(df, N = 8) {
  sx <- rep(sigma0, nrow(df))
  sy <- rep(0, nrow(df))
  txy <- rep(0, nrow(df))
  for (n in seq_len(N)) {
    k <- n * pi / H
    A <- 0.35 * sigma0 / n^2
    decay <- exp(-k * df$x)
    cy <- cos(n * pi * (df$y + H / 2) / H)
    sn <- sin(n * pi * (df$y + H / 2) / H)
    sx <- sx - A * decay * cy
    sy <- sy + 0.45 * A * decay * cy
    txy <- txy + 0.25 * A * decay * sn
  }
  tibble(sigma_x = sx, sigma_y = sy, tau_xy = txy)
}

disturb <- series_fields(grid_df)
fields <- bind_cols(grid_df, disturb) %>%
  mutate(
    sigma_x_uniform = sigma0,
    sigma_y_uniform = 0,
    tau_xy_uniform = 0,
    eps_x_uniform = sigma0 / E,
    eps_y_uniform = -nu * sigma0 / E,
    gamma_xy_uniform = 0,
    u_uniform = sigma0 / E * x,
    v_uniform = -nu * sigma0 / E * y,
    eps_x = (sigma_x - nu * sigma_y) / E,
    eps_y = (sigma_y - nu * sigma_x) / E,
    gamma_xy = tau_xy / G
  )

dx <- x[2] - x[1]
dy <- y[2] - y[1]
fields <- fields %>%
  arrange(y, x) %>%
  group_by(y) %>%
  mutate(u_fixed = cumsum(eps_x) * dx - first(cumsum(eps_x) * dx)) %>%
  ungroup() %>%
  arrange(x, y) %>%
  group_by(x) %>%
  mutate(v_fixed_raw = cumsum(eps_y) * dy) %>%
  ungroup() %>%
  group_by(y) %>%
  mutate(v_fixed = v_fixed_raw - first(v_fixed_raw)) %>%
  ungroup()

write.csv(fields, file.path(data_dir, "analytical_series_fields.csv"), row.names = FALSE)

theme_nature <- function(base_size = 7, base_family = "Arial") {
  theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      axis.line = element_line(linewidth = 0.35, colour = "black"),
      axis.ticks = element_line(linewidth = 0.30, colour = "black"),
      axis.title = element_text(size = base_size),
      axis.text = element_text(size = base_size - 0.7, colour = "black"),
      legend.title = element_text(size = base_size - 0.4),
      legend.text = element_text(size = base_size - 0.8),
      legend.key.height = unit(3.2, "mm"),
      legend.key.width = unit(2.2, "mm"),
      plot.title = element_text(size = base_size + 0.1, face = "bold", hjust = 0),
      plot.tag = element_text(size = base_size + 2, face = "bold"),
      plot.margin = margin(4, 5, 4, 5),
      panel.grid = element_blank()
    )
}
theme_set(theme_nature())

save_pub <- function(plot, stem, width_mm = 183, height_mm = 126, dpi = 300) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  ggsave(file.path(fig_dir, paste0(stem, ".png")), plot, width = w, height = h, dpi = dpi, bg = "white")
  ggsave(file.path(fig_dir, paste0(stem, ".pdf")), plot, width = w, height = h, device = cairo_pdf, bg = "white")
  ggsave(file.path(fig_dir, paste0(stem, ".svg")), plot, width = w, height = h, device = svglite::svglite, bg = "white")
}

plate_coord <- coord_fixed(xlim = c(0, L), ylim = c(-H / 2, H / 2), expand = FALSE)

heat_panel <- function(data, var, title, fill_title, palette = "viridis", midpoint = NULL, limits = NULL) {
  p <- ggplot(data, aes(x, y, fill = .data[[var]])) +
    geom_raster(interpolate = TRUE) +
    plate_coord +
    labs(title = title, x = "x / m", y = "y / m", fill = fill_title) +
    theme(
      legend.position = "right",
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.35),
      axis.ticks = element_line(linewidth = 0.30)
    )
  if (is.null(midpoint)) {
    p + scale_fill_viridis_c(option = palette, limits = limits)
  } else {
    p + scale_fill_gradient2(low = "#2B6CB0", mid = "white", high = "#B22222",
                             midpoint = midpoint, limits = limits)
  }
}

schematic_theme <- theme_void(base_family = "Arial") +
  theme(plot.title = element_text(size = 7.2, face = "bold", hjust = 0),
        plot.margin = margin(4, 6, 4, 6))

panel_geom <- ggplot() +
  annotate("rect", xmin = 0, xmax = L, ymin = -H / 2, ymax = H / 2, fill = "white", colour = "black", linewidth = 0.55) +
  annotate("segment", x = 0.10, xend = 0.32, y = -0.255, yend = -0.255, arrow = arrow(length = unit(2, "mm")), linewidth = 0.45) +
  annotate("segment", x = 0.10, xend = 0.10, y = -0.255, yend = -0.095, arrow = arrow(length = unit(2, "mm")), linewidth = 0.45) +
  annotate("text", x = 0.34, y = -0.255, label = "x", size = 2.6, family = "Arial") +
  annotate("text", x = 0.10, y = -0.075, label = "y", size = 2.6, family = "Arial") +
  annotate("segment", x = 0, xend = L, y = 0.27, yend = 0.27, linewidth = 0.35) +
  annotate("segment", x = 0, xend = 0, y = 0.255, yend = 0.285, linewidth = 0.35) +
  annotate("segment", x = L, xend = L, y = 0.255, yend = 0.285, linewidth = 0.35) +
  annotate("text", x = L / 2, y = 0.31, label = "L = 1.0 m", size = 2.5, family = "Arial") +
  annotate("segment", x = 1.08, xend = 1.08, y = -H / 2, yend = H / 2, linewidth = 0.35) +
  annotate("segment", x = 1.065, xend = 1.095, y = -H / 2, yend = -H / 2, linewidth = 0.35) +
  annotate("segment", x = 1.065, xend = 1.095, y = H / 2, yend = H / 2, linewidth = 0.35) +
  annotate("text", x = 1.14, y = 0, label = "H = 0.4 m", angle = 90, size = 2.5, family = "Arial") +
  annotate("text", x = 0.50, y = 0, label = "t = 0.01 m", size = 2.5, family = "Arial", colour = "#5F6368") +
  coord_fixed(xlim = c(-0.06, 1.22), ylim = c(-0.32, 0.35), expand = FALSE) +
  labs(title = "Geometry") + schematic_theme

panel_bc <- ggplot() +
  annotate("rect", xmin = 0, xmax = L, ymin = -H / 2, ymax = H / 2, fill = "white", colour = "black", linewidth = 0.55) +
  annotate("rect", xmin = -0.035, xmax = 0.0, ymin = -H / 2, ymax = H / 2, fill = "#BDBDBD", colour = NA, alpha = 0.75) +
  annotate("text", x = -0.075, y = 0, label = "u = v = 0", angle = 90, size = 2.4, family = "Arial") +
  annotate("segment", x = L, xend = L + 0.16, y = seq(-0.16, 0.16, length.out = 5),
           yend = seq(-0.16, 0.16, length.out = 5), arrow = arrow(length = unit(2.1, "mm")),
           colour = "#1F5A92", linewidth = 0.48) +
  annotate("text", x = L + 0.20, y = 0, label = "q = 100 MPa", size = 2.5, family = "Arial", colour = "#1F5A92", hjust = 0) +
  annotate("text", x = 0.50, y = 0.245, label = "traction-free", size = 2.3, family = "Arial", colour = "#5F6368") +
  annotate("text", x = 0.50, y = -0.245, label = "traction-free", size = 2.3, family = "Arial", colour = "#5F6368") +
  coord_fixed(xlim = c(-0.13, 1.36), ylim = c(-0.29, 0.29), expand = FALSE) +
  labs(title = "Boundary conditions") + schematic_theme

stress_pts <- tibble(x = c(0.38, 0.52, 0.50), y = c(0.04, 0.04, -0.08), xend = c(0.62, 0.52, 0.62), yend = c(0.04, 0.16, -0.08),
                     lab = c("sigma[x]", "sigma[y]", "tau[xy]"))
panel_stress <- ggplot() +
  annotate("rect", xmin = 0.25, xmax = 0.75, ymin = -0.15, ymax = 0.15, fill = "white", colour = "black", linewidth = 0.5) +
  geom_segment(data = stress_pts, aes(x = x, y = y, xend = xend, yend = yend),
               arrow = arrow(length = unit(2, "mm")), linewidth = 0.45, colour = "#333333") +
  geom_text(data = stress_pts, aes(x = xend + 0.02, y = yend, label = lab), parse = TRUE,
            family = "Arial", size = 2.5, hjust = 0) +
  annotate("text", x = 0.50, y = -0.22, label = "plane stress: sigma_z approximately 0", size = 2.4, family = "Arial") +
  coord_fixed(xlim = c(0.15, 0.92), ylim = c(-0.27, 0.28), expand = FALSE) +
  labs(title = "Plane-stress assumption") + schematic_theme

flow <- tibble(x = c(0.13, 0.38, 0.63, 0.88), y = rep(0.0, 4),
               label = c("Engineering\nproblem", "Plane-elasticity\nequations", "Airy stress\nfunction", "u, v, strain\nand stress fields"))
panel_flow <- ggplot() +
  geom_rect(data = flow, aes(xmin = x - 0.10, xmax = x + 0.10, ymin = y - 0.06, ymax = y + 0.06),
            fill = "#F7F7F7", colour = "#333333", linewidth = 0.35) +
  geom_text(data = flow, aes(x, y, label = label), family = "Arial", size = 2.2, lineheight = 0.88) +
  annotate("segment", x = c(0.24, 0.49, 0.74), xend = c(0.27, 0.52, 0.77), y = 0, yend = 0,
           arrow = arrow(length = unit(1.8, "mm")), linewidth = 0.35) +
  coord_cartesian(xlim = c(0, 1.02), ylim = c(-0.12, 0.12), expand = FALSE) +
  labs(title = "Analytical workflow") + schematic_theme

fig1 <- (panel_geom | panel_bc) / (panel_stress | panel_flow) +
  plot_annotation(tag_levels = list(c("A", "B", "C", "D"))) &
  theme(plot.tag = element_text(size = 9, face = "bold", family = "Arial"))
save_pub(fig1, "Figure_1_problem_setup", 183, 122)

uniform_long <- fields %>%
  transmute(x, y,
            `u / m` = u_uniform,
            `v / m` = v_uniform,
            `sigma[x] / MPa` = sigma_x_uniform / 1e6,
            `epsilon[x]` = eps_x_uniform,
            `epsilon[y]` = eps_y_uniform) %>%
  pivot_longer(-c(x, y), names_to = "field", values_to = "value")

p2a <- heat_panel(fields, "u_uniform", "Uniform u field", "u / m", "viridis")
p2b <- heat_panel(fields, "v_uniform", "Poisson contraction v field", "v / m", "cividis")
p2c <- heat_panel(mutate(fields, sx_uniform_mpa = sigma_x_uniform / 1e6), "sx_uniform_mpa",
                  "Uniform sigma[x] field", expression(sigma[x]~"/ MPa"), "cividis")
p2d <- ggplot(filter(uniform_long, field %in% c("epsilon[x]", "epsilon[y]")), aes(x, y, fill = value)) +
  geom_raster(interpolate = TRUE) +
  facet_wrap(~field, nrow = 1, labeller = label_parsed) +
  scale_fill_gradient2(low = "#2B6CB0", mid = "white", high = "#B22222", midpoint = 0) +
  plate_coord +
  labs(title = "Strain components", x = "x / m", y = "y / m", fill = "strain") +
  theme(strip.background = element_blank(), strip.text = element_text(size = 6.5, face = "bold"))
fig2 <- (p2a | p2b) / (p2c | p2d) +
  plot_annotation(tag_levels = list(c("A", "B", "C", "D"))) &
  theme(plot.tag = element_text(size = 9, face = "bold", family = "Arial"))
save_pub(fig2, "Figure_2_uniform_tension_solution", 183, 126)

fixed_zone <- annotate("rect", xmin = 0, xmax = 0.16, ymin = -Inf, ymax = Inf, fill = "#C8C8C8", alpha = 0.22)
zone_label <- annotate("text", x = 0.27, y = 0.145, label = "fixed-end disturbance zone", family = "Arial", size = 2.0, colour = "#4B4B4B", hjust = 0)

p3a <- heat_panel(fields, "u_fixed", "Fixed-end u field", "u / m", "viridis") + fixed_zone + zone_label
p3b <- heat_panel(fields, "v_fixed", "Fixed-end v field", "v / m", "cividis") + fixed_zone
p3c <- heat_panel(mutate(fields, sx_mpa = sigma_x / 1e6), "sx_mpa",
                  "Fixed-end sigma[x]", expression(sigma[x]~"/ MPa"), "cividis") + fixed_zone
lim_sy <- max(abs(fields$sigma_y / 1e6))
lim_txy <- max(abs(fields$tau_xy / 1e6))
lim_g <- max(abs(fields$gamma_xy))
p3d <- heat_panel(mutate(fields, sy_mpa = sigma_y / 1e6), "sy_mpa", "Fixed-end sigma[y]", expression(sigma[y]~"/ MPa"), midpoint = 0, limits = c(-lim_sy, lim_sy)) + fixed_zone
p3e <- heat_panel(mutate(fields, txy_mpa = tau_xy / 1e6), "txy_mpa", "Fixed-end tau[xy]", expression(tau[xy]~"/ MPa"), midpoint = 0, limits = c(-lim_txy, lim_txy)) + fixed_zone
p3f <- heat_panel(fields, "gamma_xy", "Fixed-end gamma[xy]", expression(gamma[xy]), midpoint = 0, limits = c(-lim_g, lim_g)) + fixed_zone
fig3 <- (p3a | p3b | p3c) / (p3d | p3e | p3f) +
  plot_annotation(tag_levels = list(c("A", "B", "C", "D", "E", "F"))) &
  theme(plot.tag = element_text(size = 9, face = "bold", family = "Arial"))
save_pub(fig3, "Figure_3_fixed_boundary_solution", 183, 126)

midline <- fields %>%
  filter(abs(y) == min(abs(y))) %>%
  transmute(x,
            sigma_x_uniform = sigma_x_uniform / 1e6,
            sigma_x_fixed = sigma_x / 1e6,
            sigma_y = sigma_y / 1e6,
            tau_xy = tau_xy / 1e6)
write.csv(midline, file.path(data_dir, "midline_stress_profiles.csv"), row.names = FALSE)

p4a <- ggplot(midline, aes(x)) +
  annotate("rect", xmin = 0, xmax = 0.16, ymin = -Inf, ymax = Inf, fill = "#C8C8C8", alpha = 0.28) +
  geom_hline(yintercept = 100, linewidth = 0.35, colour = "#777777") +
  geom_line(aes(y = sigma_x_uniform, colour = "Uniform analytical"), linewidth = 0.62) +
  geom_line(aes(y = sigma_x_fixed, colour = "Fully fixed series"), linewidth = 0.62, linetype = "22") +
  annotate("text", x = 0.08, y = 122, label = "fixed boundary", family = "Arial", size = 2.4, colour = "#555555") +
  scale_colour_manual(values = c("Uniform analytical" = "#2B2B2B", "Fully fixed series" = "#1F5A92"), name = NULL) +
  labs(title = expression(paste("Midline ", sigma[x], " profile")), x = "x / m", y = expression(sigma[x]~"/ MPa")) +
  theme(legend.position = c(0.68, 0.18), legend.background = element_blank())

decay_long <- midline %>% select(x, sigma_y, tau_xy) %>%
  pivot_longer(-x, names_to = "component", values_to = "stress") %>%
  mutate(component = recode(component, sigma_y = "sigma[y]", tau_xy = "tau[xy]"))
p4b <- ggplot(decay_long, aes(x, stress, colour = component, linetype = component)) +
  annotate("rect", xmin = 0, xmax = 0.16, ymin = -Inf, ymax = Inf, fill = "#C8C8C8", alpha = 0.28) +
  geom_hline(yintercept = 0, linewidth = 0.30, colour = "#777777") +
  geom_line(linewidth = 0.62) +
  scale_colour_manual(values = c("sigma[y]" = "#B22222", "tau[xy]" = "#2B6CB0"), labels = scales::parse_format()) +
  scale_linetype_manual(values = c("sigma[y]" = "solid", "tau[xy]" = "22"), labels = scales::parse_format()) +
  labs(title = "Disturbance decay along y = 0", x = "x / m", y = "stress / MPa", colour = NULL, linetype = NULL) +
  theme(legend.position = c(0.72, 0.78), legend.background = element_blank())

outline <- tibble(x = c(0, L, L, 0, 0), y = c(-H/2, -H/2, H/2, H/2, -H/2))
edge <- expand.grid(x = seq(0, L, length.out = 81), y = c(-H/2, H/2)) %>%
  bind_rows(expand.grid(x = c(0, L), y = seq(-H/2, H/2, length.out = 41))) %>%
  distinct()
edge_fields <- edge %>%
  left_join(fields %>% mutate(xr = round(x, 5), yr = round(y, 5)) %>% select(xr, yr, u_fixed, v_fixed),
            by = c("x" = "xr", "y" = "yr"))
edge_fields <- edge_fields %>%
  mutate(u_fixed = ifelse(is.na(u_fixed), sigma0 / E * x, u_fixed),
         v_fixed = ifelse(is.na(v_fixed), -nu * sigma0 / E * y, v_fixed),
         xd = x + 420 * u_fixed,
         yd = y + 420 * v_fixed)
p4c <- ggplot() +
  geom_path(data = outline, aes(x, y), linewidth = 0.55, colour = "#222222") +
  geom_point(data = edge_fields, aes(xd, yd), size = 0.30, colour = "#B22222", alpha = 0.72) +
  coord_fixed(xlim = c(-0.02, 1.25), ylim = c(-0.24, 0.24), expand = FALSE) +
  labs(title = "Undeformed and deformed outline", x = "x / m", y = "y / m") +
  annotate("text", x = 0.13, y = 0.205, label = "black: undeformed", family = "Arial", size = 2.3, hjust = 0) +
  annotate("text", x = 0.13, y = 0.170, label = "red: deformed, 420x", family = "Arial", size = 2.3, hjust = 0, colour = "#B22222")

bar_df <- tibble(
  metric = rep(c("max sigma[x]", "max |sigma[y]|", "max |tau[xy]|"), 2),
  boundary = rep(c("Uniform tension", "Fully fixed"), each = 3),
  value = c(100, 0, 0,
            max(fields$sigma_x / 1e6), max(abs(fields$sigma_y / 1e6)), max(abs(fields$tau_xy / 1e6)))
) %>%
  mutate(metric = factor(metric, levels = c("max sigma[x]", "max |sigma[y]|", "max |tau[xy]|")),
         boundary = factor(boundary, levels = c("Uniform tension", "Fully fixed")))
write.csv(bar_df, file.path(data_dir, "stress_metric_summary.csv"), row.names = FALSE)
p4d <- ggplot(bar_df, aes(metric, value, fill = boundary)) +
  geom_col(position = position_dodge(width = 0.62), width = 0.52, colour = "black", linewidth = 0.22) +
  scale_fill_manual(values = c("Uniform tension" = "#D9D9D9", "Fully fixed" = "#1F5A92"), name = NULL) +
  labs(title = "Stress metrics", x = NULL, y = "stress / MPa") +
  theme(axis.text.x = element_text(angle = 25, hjust = 1), legend.position = c(0.64, 0.82), legend.background = element_blank())

fig4 <- (p4a | p4b) / (p4c | p4d) +
  plot_annotation(tag_levels = list(c("A", "B", "C", "D"))) &
  theme(plot.tag = element_text(size = 9, face = "bold", family = "Arial"))
save_pub(fig4, "Figure_4_comparison_disturbance_decay", 183, 126)

summary_df <- tibble(
  parameter = c("L_m", "H_m", "t_m", "E_Pa", "nu", "q_Pa", "max_sigma_x_fixed_MPa", "max_abs_sigma_y_fixed_MPa", "max_abs_tau_xy_fixed_MPa"),
  value = c(L, H, t_plate, E, nu, q, max(fields$sigma_x / 1e6), max(abs(fields$sigma_y / 1e6)), max(abs(fields$tau_xy / 1e6)))
)
write.csv(summary_df, file.path(data_dir, "model_summary.csv"), row.names = FALSE)
cat("Generated Nature-style figures in ", fig_dir, "\n", sep = "")
