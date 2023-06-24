# data.R
#
# Script to read data and prepare it for visualization and modeling.

# --- Libraries ---

library(dplyr)
library(readr)

# --- Main ---

read_data <- function() {
  data <- read_csv("./data/indicadores-2012.csv") %>%
    filter(ano_referencia <= ano_integralizacao) %>%
    group_by(cod_curso) %>%
    mutate(qt_desistencias = sum(qt_desistencias)) %>%
    ungroup() %>%
    filter(ano_integralizacao == ano_referencia) %>%
    mutate(
      administracao = as.factor(administracao),
      tipo_administracao = as.factor(case_when(
        administracao %in% c(1, 2, 3) ~ "Pública",
        administracao %in% c(4, 5) ~ "Privada",
        administracao == 7 ~ "Especial",
        TRUE ~ "Outro"
      )),
      cod_uf = as.factor(cod_uf),
      org_academica = as.factor(case_when(
        org_academica == 1 ~ "Universidade",
        org_academica == 2 ~ "Centro Universitário",
        org_academica == 3 ~ "Faculdade",
        org_academica == 4 ~ "Instituto Federal",
        org_academica == 5 ~ "CEFET",
      )),
      cod_curso = as.factor(cod_curso),
      cod_regiao = as.factor(cod_regiao),
      nome_regiao = as.factor(case_when(
        cod_regiao == 1 ~ "Norte",
        cod_regiao == 2 ~ "Nordeste",
        cod_regiao == 3 ~ "Sudeste",
        cod_regiao == 4 ~ "Sul",
        cod_regiao == 5 ~ "Centro-Oeste",
        TRUE ~ "Não se aplica"
      )),
      cod_area = as.factor(cod_area),
      nome_area = as.factor(nome_area),
      modalidade_ensino = as.factor(case_when(
        modalidade_ensino == 1 ~ "Presencial",
        modalidade_ensino == 2 ~ "A distância",
        TRUE ~ "Outro"
      )),
      grau_academico = as.factor(case_when(
          grau_academico == 1 ~ "Bacharelado",
          grau_academico == 2 ~ "Licenciatura",
          grau_academico == 3 ~ "Tecnológico",
        )),
      evasao = qt_desistencias / qt_ingressantes,
    )

  return(data)
}
