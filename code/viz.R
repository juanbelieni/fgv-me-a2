# viz.R
#
# Script to generate visualizations for the article.


# --- Libraries ---

library(ggplot2)
library(stringr) # string manipulation
library(ggpubr) # stat_cor
source("./code/data.R")

# --- Config ---

theme_set(theme_bw(
  base_size = 14,
))

# --- Data ---

data <- read_data()

# --- Functions ---

save_plot <- function(filename, width = 12, height = 4) {
  path <- "article/images/"
  filename <- paste0(path, filename, ".png")

  ggsave(
    filename,
    width = width,
    height = height,
    dpi = 300,
  )
}

# --- Visualizations ---

# Plot: quantidade de desistências por quantidade de ingressantes

data %>%
  ggplot(aes(x = qt_ingressantes, y = qt_desistencias)) +
  geom_point(alpha = 0.25) +
  geom_smooth(
    method = "glm",
    formula = y ~ x,
    color = "red",
    fill = "red",
  ) +
  stat_cor() +
  labs(
    x = "Quantidade de ingressantes",
    y = "Quantidade de desistências"
  )

save_plot("desistencias-por-ingressantes")

# Plot: quantidade de desistências por prazo de integralização

data %>%
  ggplot(aes(x = as.factor(prazo_integralizacao), y = qt_desistencias)) +
  geom_jitter(alpha = 0.25) +
  scale_y_log10() +
  labs(
    x = "Prazo de integralização (anos)",
    y = "Quantidade de desistências"
  )

save_plot("desistencias-por-prazo-integralizacao", width = 6, height = 4)

# Plot: evasão por ano de integralização

data %>%
  ggplot(aes(x = as.factor(prazo_integralizacao), y = evasao)) +
  geom_boxplot(outlier.alpha = 0.25) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x = "Prazo de integralização (anos)",
    y = "Evasão"
  )

save_plot("evasao-por-prazo-integralizacao", width = 6, height = 4)

# Plot: quantidade de desistências por região

data %>%
  ggplot(aes(x = reorder(nome_regiao, qt_desistencias), y = qt_desistencias)) +
  geom_jitter(alpha = 0.1) +
  geom_boxplot(
    outlier.alpha = 0,
    color = "red",
    fill = "red",
    alpha = 0.5,
  ) +
  scale_y_log10() +
  labs(
    x = "Região",
    y = "Quantidade de desistências"
  )

save_plot("desistencias-por-regiao")
