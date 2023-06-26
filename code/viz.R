# viz.R
#
# Script to generate visualizations for the article.


# --- Libraries ---

library(ggplot2)
library(stringr) # string manipulation
library(ggpubr) # stat_cor
library(MASS) # negative binomial models
library(countreg) # RQR

source("./code/data.R")

# --- Config ---

theme_set(theme_bw(
  base_size = 14,
))

theme_update(
  axis.text = element_text(color = "black"),
)

# --- Data ---

data <- read_data()

# --- Functions ---

save_plot <- function(filename, width = 12, height = 5) {
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
  geom_jitter(alpha = 0.02) +
  geom_violin(fill = "gray", alpha = 0.5) +
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
    y = "Percentual de evasão"
  )

save_plot("evasao-por-prazo-integralizacao", width = 6, height = 4)

# Plot: percentual de evasão por região

data %>%
  ggplot(aes(x = reorder(nome_regiao, evasao), y = evasao)) +
  geom_boxplot() +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x = "Região",
    y = "Percentual de evasão"
  )

save_plot("evasao-por-regiao")

# Plot: percentual de evasão por tipo de administração

data %>%
  ggplot(aes(evasao, fill = tipo_administracao)) +
  geom_density(
    position = "fill",
    alpha = 0.75,
  ) +
  scale_x_continuous(
    labels = scales::percent,
    expand = c(0, 0),
  ) +
  scale_y_continuous(
    labels = scales::percent,
    expand = c(0, 0),
  ) +
  labs(
    x = "Percentual de evasão",
    y = "Proporção",
    fill = "Grau acadêmico"
  )

save_plot("evasao-por-tipo-admnistracao")

# Plot: QQ plot dos resíduos de Pearson da regressão Binomial Negativa

model_nb <- glm.nb(
  qt_desistencias ~ 1
    + grau_academico
    + modalidade_ensino
    + tipo_administracao
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
)

resids <- qresiduals(model_nb) %>% as_tibble()

resids %>%
  ggplot(aes(sample = value)) +
  stat_qq(alpha = 0.25) +
  stat_qq_line() +
  labs(
    x = "Quantis teóricos",
    y = "Quantis amostrais",
  )

save_plot("qq-rqr")

# Plot: densidade dos resíduos

resids %>%
  ggplot(aes(value, fill = NULL)) +
  geom_density(
    fill = "black",
    color = "black",
    alpha = 0.5,
  ) +
  geom_histogram(
    aes(y = ..density..),
    fill = "white",
    color = "black",
    alpha = 0.25,
  ) +
  labs(
    x = "Resíduos",
    y = "Densidade",
  )

save_plot("densidade-residuos")
