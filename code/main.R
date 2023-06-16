library(tidyverse)
library(MASS)
library(pscl)
library(brms)

data <- read_csv("./data/indicadores-2012.csv") %>%
  filter(modalidade_ensino == 1 & ano_referencia <= ano_integralizacao) %>%
  group_by(cod_curso) %>%
  mutate(qt_desistencias = sum(qt_desistencias)) %>%
  ungroup() %>%
  filter(ano_integralizacao == ano_referencia) %>%
  mutate(
    administracao = as.factor(administracao),
    tipo_administracao = as.factor(case_when(
      administracao %in% c(1, 2, 3) ~ "Pública",
      administracao %in% c(4, 5) ~ "Privada",
      administracao == 7 ~ "Especial"
    )),
    cod_uf = as.factor(cod_uf),
    org_academica = as.factor(org_academica),
    cod_curso = as.factor(cod_curso),
    cod_regiao = as.factor(cod_regiao),
    nome_regiao = as.factor(case_when(
      cod_regiao == 1 ~ "Norte",
      cod_regiao == 2 ~ "Nordeste",
      cod_regiao == 3 ~ "Sudeste",
      cod_regiao == 4 ~ "Sul",
      cod_regiao == 5 ~ "Centro-Oeste",
      TRUE ~ "Outro"
    )),
    cod_area = as.factor(cod_area),
    nome_area = as.factor(nome_area),
    modalidade_ensino = as.factor(modalidade_ensino),
    grau_academico = as.factor(grau_academico),
    razao_evasao = qt_desistencias / qt_ingressantes,
  )

qq_plot <- function(model, plot_title = "", type = "pearson") {
  residuals <- resid(model, type = type)
  qqnorm(residuals, main = plot_title)
  qqline(residuals)
}

metrics <- function(model) {
  predicted <- predict(model, data, type = "response")
  model_rmse <- sqrt(mean((data$qt_desistencias - predicted)^2))
  model_mae <- mean(abs(data$qt_desistencias - predicted))
  model_aic <- AIC(model)
  model_bic <- BIC(model)

  cat(paste("RMSE:", model_rmse, "\n"))
  cat(paste("MAE:", model_mae, "\n"))
  cat(paste("AIC:", model_aic, "\n"))
  cat(paste("BIC:", model_bic, "\n"))
}

# --- Plots ---

# Histogram of "qt_desistencias"

data %>%
  ggplot(aes(x = qt_desistencias, fill = nome_area)) +
  geom_histogram(bins = 100) +
  labs(
    title = "Histogram of \"qt_desistencias\"",
    x = "qt_desistencias",
    y = "Frequency"
  )

# Scatter plot of "qt_ingressantes" vs "qt_desistencias"

data %>%
  ggplot(aes(x = qt_ingressantes, y = qt_desistencias)) +
  geom_point(alpha = 0.5) +
  labs(
    title = "Scatter plot of \"qt_ingressantes\" vs \"qt_desistencias\"",
    x = "qt_ingressantes",
    y = "qt_desistencias"
  )

# --- Frequentist models ---

# Dumb

f_model_dumb <- lm(
  qt_desistencias ~ 1,
  data = data,
)

summary(f_model_dumb)
metrics(f_model_dumb)
qq_plot(f_model_dumb, plot_title = "Dumb Model - QQ Plot")

# Gaussian

f_model_gaussian <- glm(
  qt_desistencias ~ org_academica
    + nome_regiao
    + grau_academico
    + prazo_integralizacao
    + I(log(prazo_integralizacao))
    + I(log(qt_ingressantes)),
  data = data,
  family = gaussian()
)

summary(f_model_gaussian)
metrics(f_model_gaussian)

qq_plot(
  f_model_gaussian,
  plot_title = "Gaussian GLM - QQ Plot",
  type = "deviance"
)

# Poisson

f_model_poisson <- glm(
  qt_desistencias ~ org_academica
    + nome_regiao
    + grau_academico
    + cod_area
    + prazo_integralizacao
    + log(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
  family = poisson()
)

summary(f_model_poisson)
metrics(f_model_poisson)

qq_plot(
  f_model_poisson,
  plot_title = "Poisson GLM - QQ Plot",
  type = "deviance"
)

resid(f_model_poisson, type = "deviance") %>%
  as.data.frame() %>%
  ggplot(aes(x = .)) +
  geom_histogram(bins = 100) +
  labs(
    title = "Histogram of Poisson GLM residuals",
    x = "Residuals",
    y = "Frequency"
  )


# Negative Binomial

f_model_negbin <- glm.nb(
  qt_desistencias ~ org_academica
    + grau_academico
    + nome_regiao
    + cod_area
    + prazo_integralizacao
    + I(prazo_integralizacao^2)
    + qt_ingressantes
    + I(qt_ingressantes^2),
  data = data,
)

summary(f_model_negbin)
qq_plot(f_model_negbin, "Negative Binomial GLM - QQ Plot")
metrics(f_model_negbin)

# Zero Inflated Poisson

f_model_zip <- zeroinfl(
  qt_desistencias ~ org_academica + grau_academico
    + nome_regiao
    + cod_area
    + prazo_integralizacao
    + I(prazo_integralizacao^2)
    + qt_ingressantes,
  data = data,
  dist = "poisson"
)

summary(f_model_zip)
qq_plot(f_model_zip, "Zero Inflated Poisson GLM - QQ Plot")
metrics(f_model_zip)

# Zero Inflated Negative Binomial

f_model_zinb <- zeroinfl(
  qt_desistencias ~ org_academica + grau_academico
    + nome_regiao
    + cod_area
    + prazo_integralizacao
    + I(prazo_integralizacao^2)
    + qt_ingressantes
    + I(qt_ingressantes^2) | 1,
  data = data,
  dist = "negbin"
)

summary(f_model_zinb)
qq_plot(f_model_zinb, "Zero Inflated Negative Binomial GLM - QQ Plot")
metrics(f_model_zinb)

# --- Bayesian models ---

# Poisson

b_model_poisson <- brm(
  bf(
    qt_desistencias ~ org_academica
      + nome_regiao
      + grau_academico
      + cod_area
      + prazo_integralizacao
      + log(prazo_integralizacao)
      + log(qt_ingressantes)
  ),
  family = poisson(),
  data = data,
  iter = 1000,
  chains = 3,
  cores = 3,
)

summary(b_model_poisson)

resid(b_model_poisson, type = "pearson") %>%
  as_tibble() %>%
  ggplot(aes(x = Estimate)) +
  geom_histogram(bins = 100) +
  labs(
    title = "Histogram of Poisson GLM residuals",
    x = "Residuals",
    y = "Frequency"
  )

model3 <- brm(
  bf(qt_desistencias ~ tipo_administracao),
  family = zero_inflated_poisson(),
  data = data,
  iter = 2000,
  chains = 2,
  cores = 2,
)

residuals(model3) %>%
  as_tibble() %>%
  filter(Estimate < 200) %>%
  ggplot(aes(x = Estimate)) +
  geom_histogram(bins = 100) +
  geom_vline(xintercept = 0, color = "red") +
  labs(x = "Residuals", y = "Frequency")

model4 <- brm(
  bf(qt_desistencias ~ tipo_administracao + org_academica + cod_area),
  family = negbinomial(),
  data = data,
  iter = 1000,
  chains = 2,
  cores = 2,
)

residuals(model4) %>%
  as_tibble() %>%
  filter(Estimate < 200) %>%
  ggplot(aes(x = Estimate)) +
  geom_histogram(bins = 100) +
  geom_vline(xintercept = 0, color = "red") +
  labs(x = "Residuals", y = "Frequency")
