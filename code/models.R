# models.R
#
# Script to fit models from the article.

# --- Libraries ---

library(ggplot2)
library(MASS) # negative binomial models
library(AER) # dispersion tests
source("./code/data.R")

# --- Data ---

data <- read_data()

# --- Functions ---

qq_plot <- function(model, plot_title = "", type = "pearson") {
  residuals <- resid(model, type = type)
  qqnorm(residuals, main = plot_title)
  qqline(residuals)
}

metrics <- function(model) {
  predicted <- predict(model, data, type = "response")
  model_rmse <- sqrt(mean((data$qt_desistencias - predicted)^2))
  model_mae <- mean(abs(data$qt_desistencias - predicted))
  model_mape <- mean(abs((
    data$qt_desistencias - predicted) /
    ifelse(data$qt_desistencias == 0, 1, data$qt_desistencias)))
  model_aic <- AIC(model)
  model_bic <- BIC(model)

  cat(paste("RMSE:", model_rmse, "\n"))
  cat(paste("MAE:", model_mae, "\n"))
  cat(paste("MAPE:", model_mape, "\n"))
  cat(paste("AIC:", model_aic, "\n"))
  cat(paste("BIC:", model_bic, "\n"))
}

# --- Models ---

# Poisson

f_model_poisson <- glm(
  qt_desistencias ~ 1
    + grau_academico
    + modalidade_ensino
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
  family = poisson,
)

summary(f_model_poisson)
summary(resid(f_model_poisson, type = "response"))
metrics(f_model_poisson)

qq_plot(
  f_model_poisson,
  plot_title = "Poisson GLM - QQ Plot",
  type = "pearson"
)

resid(f_model_poisson, type = "pearson") %>%
  as.data.frame() %>%
  ggplot(aes(x = .)) +
  geom_histogram(bins = 100) +
  labs(
    title = "Histogram of Poisson GLM residuals",
    x = "Residuals",
    y = "Frequency"
  )

# Negative Binomial

f_model_nb <- glm.nb(
  qt_desistencias ~ 1
    + grau_academico
    + modalidade_ensino
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
)

summary(f_model_nb)
summary(resid(f_model_nb, type = "pearson"))
metrics(f_model_nb)

qq_plot(
  f_model_nb,
  plot_title = "Negative Binomial GLM - QQ Plot",
  type = "pearson"
)

resid(f_model_nb, type = "pearson") %>%
  as.data.frame() %>%
  ggplot(aes(x = .)) +
  geom_histogram(bins = 100) +
  labs(
    title = "Histogram of Poisson GLM residuals",
    x = "Residuals",
    y = "Frequency"
  )
