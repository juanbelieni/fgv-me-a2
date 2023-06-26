# models.R
#
# Script to fit models from the article.

# --- Libraries ---

library(ggplot2)
library(MASS) # negative binomial models
library(AER) # dispersion tests
library(countreg) # RQR
library(nortest) # normality tests
source("./code/data.R")

# --- Data ---

data <- read_data()

# --- Functions ---

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

model_poisson <- glm(
  qt_desistencias ~ 1
    + modalidade_ensino
    + tipo_administracao
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
  family = poisson,
)

resids_poisson <- qresiduals(model_poisson)

summary(model_poisson)
metrics(model_poisson)
dispersiontest(model_poisson)
summary(resids_poisson)

# Negative Binomial

model_nb <- glm.nb(
  qt_desistencias ~ 1
    + modalidade_ensino
    + tipo_administracao
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
)

resids_nb <- qresiduals(model_nb)

summary(model_nb)
metrics(model_nb)
summary(resids_nb)
ad.test(resids_nb)
