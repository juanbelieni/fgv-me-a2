// Links úteis:

// sobre poisson (contém parágrafo sobre sobredispersão) https://sci-hub.ru/https://journals.healio.com/doi/abs/10.3928/01484834-20140325-04

// https://onlinelibrary.wiley.com/doi/epdf/10.1002/qre.2985 Efficient GLM-based control charts for Poisson processes

// https://scholarworks.umass.edu/cgi/viewcontent.cgi?article=1269&context=pare teste chi square

#import "template.typ": *

#show: project.with(
  title: "Modelagem da evasão\nno ensino superior no Brasil",
  authors: (
    (name: "Juan Belieni", email: "juanbelieni@gmail.com", affiliation: "FGV/EMAp"),
  ),
  date: datetime.today()
)

= Introdução

A evasão no ensino superior é um problema que afeta muitos cursos acadêmicos pelo país, e possui diversas naturezas ao nível do estudante, tais como vocacional, relativos ao desempenho ou até sociais~@ambiel-2021. A motivação de modelar esse fenômeno surge da necessidade de entender como fatores macro (localização, curso, etc.) influenciam a persistência dos estudantes.

= Dados <sec:dados>

Os dados desse trabalho foram coletados pelo Censo da Educação Superior, realizado anualmente pelo Inep~@inep, e disponibilizados no formato CSV no repositório do trabalho #footnote(link("https://github.com/juanbelieni/fgv-me-a2")).

Cada entrada do conjunto de dados possui informações ao nível de curso por instituição em um determinado ano de referência. A cada ano, a partir do ano de ingresso, é registrado a quantidade de alunos que concluíram e desistiram do curso, além do número de falecidos nesse determinado ano. Para esse trabalho, o ano de ingresso escolhido para a modelagem foi 2012.

Cada curso no conjunto conta com os seguintes dados:
- identificação (código e nome);
- local onde o curso é ofertado (região, UF e município);
- grau acadêmico conferido ao diplomado (bacharelado, licenciatura ou tecnólogo);
- modalidade de ensino (presencial ou a distância);
- classificação segundo a Cine Brasil.

Em relação à instituição onde o curso é ofertado, os seguintes dados são disponibilizados:
- identificação (código e nome);
- categoria administrativa:
  + pública federal;
  + pública estadual;
  + pública municipal;
  + privada com fins lucrativos;
  + privada sem fins lucrativos;
  + especial.
- organização acadêmica:
  + universidade;
  + centro universitário;
  + faculdade;
  + instituto federal de educação, ciência e tecnologia;
  + centro federal de educação tecnológica.

Na @sec:covariaveis será visto quais informações serão utilizadas para ajustar um modelo que atinga os propósitos desse trabalho.

= Modelagem

O foco dessa modelagem é entender a influência da região e do curso na quantidade de desistências. Mais especificamente, será modelado o número acumulado de desistências até o ano de integralização para um determinado curso $i$, que será denominado de $D_i$.

A escolha do ano de integralização como limite superior para o cálculo do número acumulado de desistências vem da necessidade de estipular uma base de comparação geral entre os diversos cursos, que possuem prazos de integralização diferentes.

== Modelos para contagem

=== Regressão de Poisson e suas limitações <sec:reg-poisson>

Para modelar um processo de contagem, natureza da variável de interesse desse trabalho, é conveniente utilizar um modelo linear generalizado (GLM) com a distribuição de Poisson~@gardner-1995, onde a função de ligação é do tipo $g(mu) = ln(mu)$. Dessa forma, um modelo desse tipo para a variável de interesse desse trabalho pode ser descrito da seguinte forma:

$
E[D_i | bold(X)_i] = mu_i = exp(beta_0 + bold(X)_i^T bold(beta')),
$

onde $bold(beta) = (beta_0, bold(beta)')$ é o vetor de parâmetros a ser estimado.

Essa técnica é conhecida como regressão de Poisson e a estimação dos parâmetros ocorre por meio de máxima verossimilhança. Por não possuir fórmula fechada, a estimação depende métodos numéricos (no _R_, é utilizado _Fisher's scoring_).

No entanto, diferente de outras distribuições como a Normal e a Binomial Negativa, não possui um parâmetro de dispersão. Por esse motivo, em uma regressão de Poisson, assume-se que os dados são equidispersos, i.e., que a média condicional seja igual à variância condicional~@coxe-2009. Caso isso não seja verdade e esse fato não for levado em conta, podemos acabar tendo valores incorretos para as estimativas de erro padrão, para os intervalos de confiança, etc.

É possível verificar um caso de sobredispersão ou subdispersão em um modelo já treinado por meio de um teste proposto por Cameron e Trivedi~@cameron-1990 de seguinte teor:

$
H_0 : & "Var"(y_i) = mu_i, \
H_1 : & "Var"(y_i) = mu_i + alpha dot g(mu_i),
$

onde $g(dot)$ é uma função positiva qualquer. No _R_, é possível realizar esse teste por meio do método `dispersiontest` disponibilizado na biblioteca _AER_~@r-aer.

Caso haja evidência para os casos citados, i.e., que os dados não sejam equidispersos, uma possível alternativa para contornar essa limitação do modelo é incluir um parâmetro de dispersão $phi.alt$. Com essa correção, o novo modelo, chamado de regressão Quasi-Poisson~@ver-2007, possui a seguinte descrição:

$
E[D_i | bold(X)_i]     = & mu_i, \
"Var"(D_i | bold(X)_i) = & phi.alt dot mu_i.
$

Outra alternativa é construir um GLM com a distribuição Binomial Negativa, que também possui um parâmetro de dispersão. Por possuir uma parametrização relativamente parecida com a regressão de Poisson, como será visto posteriormente, e não depender de métodos de quasi-verossimilhança, foi escolhida sua utilização.

=== Regressão Binomial Negativa <sec:reg-bin-neg>

A regressão Binomial Negativa começa com uma modelagem similar para média de $D_i$, mas introduz um novo parâmetro $kappa$ que descreve sua variância~@ver-2007. Para a modelagem que está sendo feito nesse trabalho, o modelo em questão seria descrito da seguinte forma:

$
E[D_i | bold(X)_i]     = & mu_i = exp(beta_0 + bold(X)_i^T bold(beta')), \
"Var"(D_i | bold(X)_i) = & mu_i + kappa mu_i^2.
$

Esta definição dá à regressão Binomial Negativa uma maior flexibilidade em modelar o comportamento envolvendo a variável de interesse e as covariáveis, se comparado com uma regressão de Poisson tradicional~@gardner-1995, sendo ainda possível utilizar máximo verossimilhança para estimar os parâmetros necessários.

No _R_, a biblioteca _MASS_ oferece uma implementação que permite ajustar modelos desse tipo~@r-mass, que pode ser feito utilizando o método `glm.nb`, uma modificação do método `glm` que estima um parâmetro $theta = 1/kappa$ por máxima verossimilhança, utilizado posteriormente para ajustar os parâmetros e outros valores associados ao modelo.

== Escolha das covariáveis <sec:covariaveis>

Já explorado na @sec:dados, a base de dados possui informações relativas ao curso e à instituição onde este é ofertado. No entanto, nem toda informação é útil, e a escolha de qual incluir para que o ajuste do modelo seja construído corretamente passou por uma investigação. A princípio, é esperado uma correlação substantiva entre a variável de interesse e a quantidade de ingressantes, como é possível ver na @img:desistencias-por-ingressantes.

#figure(
  image(
    "images/desistencias-por-ingressantes.png",
    width: 100%
  ),
  caption: [
   Gráfico de dispersão entre a quantidade de ingressantes e a quantidade de desistências, acompanhado por uma linha de regressão linear.
  ]
) <img:desistencias-por-ingressantes>

Porém, é importante notar que, diferente do que acontece em uma regressão linear tradicional, uma mudança unitária do valor de uma covariável qualquer $beta_j$ não resulta em uma mudança aditiva proporcional a $beta_j$, e sim acarreta uma mudança multiplicativa de fator $e^(beta_j)$~@coxe-2009. Dessa forma, devido à forte relação linear entre as variáveis, é interessante modelar a covariável relativa à quantidade de ingressantes como $log(dot)$.

Outra variável que deveria apresentar uma relevância considerável é o prazo de integralização. No entanto, não existe uma relação tão óbvia entre essa quantidade e a quantidade de desistências, como é possível ver na figura @img:desistencias-por-prazo-integralizacao. Além disso, apenas os cursos com prazo de integralização entre 3 e 6 anos apresentam uma quantidade considerável de dados.

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [#figure(
    image(
      "images/desistencias-por-prazo-integralizacao.png",
      width: 100%
    ),
    caption: [
      Gráfico da distribuição da quantidade de desistências em relação ao prazo de integralização.
    ]
  ) <img:desistencias-por-prazo-integralizacao>],
  [#figure(
    image(
      "images/evasao-por-prazo-integralizacao.png",
      width: 100%
    ),
    caption: [
      Gráfico da distribuição do percentual de evasão em relação ao prazo de integralização.
    ]
  ) <img:evasao-por-prazo-integralizacao>]
)

Se formos visualizar essa variável em relação ao percentual de evasão (@img:evasao-por-prazo-integralizacao), fica ainda menos óbvio qual seria sua forma funcional. Portanto, é perceptível que modelar essa variável como um valor não-categórico não seria o ideal.

Em relação às variáveis categóricas, algumas destas acabam tendo naturalmente muitas opções de valores possíveis, como a variável contendo a UF onde o curso é ofertado. Por esse motivo, essas variáveis foram preteridas em favor de outras mais gerais, como o da região, no caso citado. Para a última, nota-se uma ligeira diferença em relação ao percentual de evasão, como é possível observar na @img:desistencias-por-regiao.

#figure(
  image(
    "images/desistencias-por-regiao.png",
    width: 100%
  ),
  caption: [
    Gráfico da proporção da quantidade de desistências em relação à região.
  ]
) <img:desistencias-por-regiao>

A diferença que se destaca, nesse caso, é a maior representatividade na proporção da quantidade de desistências quando a classificação de região não se aplica. No conjunto de dados, essa classificação significa que o curso é ofertado a distância. Dessa maneira, conseguímos utilizar a variável que informa a modalidade de ensino para codificar essa discrepância.

Também é possível ver alterações significativas na proporção da quantidade de desistências quando analisamos esse valor em relação ao grau acadêmico:

#figure(
  image(
    "images/desistencias-por-grau-academico.png",
    width: 100%
  ),
  caption: [
    Gráfico da proporção da quantidade de desistências em relação à região.
  ]
) <img:desistencias-por-grau-academico>

Com essa investigação, as variáveis escolhidas serão transformadas para formar as covariáveis do modelo final, que será descrito a seguir e contará com 14 covariáveis.

== Modelo final <sec:modelo-final>

Por fim, o modelo escolhido foi uma regressão Binomial Negativa que leva em conta as influências das variáveis da quantidade de ingressantes, do prazo de integralização, da região e do grau acadêmico do curso. No _R_, tal modelo é construído da seguinte maneira:

```R
glm.nb(
  qt_desistencias ~ 1
    + grau_academico
    + modalidade_ensino
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
)
```

Antes de mostrar seus resultados, um modelo de regressão Poisson análogo ao apresentado para a regressão Binomial Negativa também será mostrado, no qual será aplicado o teste de dispersão apresentado na @sec:reg-poisson para verificar a necessidade o uso de um modelo que considere sobredisperão.

= Resultados

O modelo de regressãode  Poisson foi ajustado em _R_ utilizando a biblioteca padrão com o seguinte comando:

```R
glm(
  qt_desistencias ~ 1
    + grau_academico
    + modalidade_ensino
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
  family = poisson,
)
```

Por padrão, o _R_ considera que o parâmetro de dispersão é igual a 1~@r-base. Com esse valor e após 5 iterações de _Fisher's scoring_, foi produzido um modelo com AIC igual a 346.086, BIC igual a 346.200 e com as estimativas para os coeficientes que estão presente na @tab:modelo-poisson.

#show figure: set block(breakable: true)

#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr),
    inset: 0.75em,
    [*Covariável*]                      , [*Estimativa*] , [*Erro padrão*] , [*_z-value_*] ,
    [Intercepto]                        , [-2,8745820]   , [0,1093173]     , [-26,296]   ,
    [Grau acadêmico (licenciatura)]     , [-0,1031483]   , [0,0025556]     , [-40,362]   ,
    [Grau acadêmico (tecnológico)]      , [0,0279102]    , [0,0051524]     , [5,417]     ,
    [modalidade de ensino (presencial)] , [-0,0751300]   , [0,0034242]     , [-21,941]   ,
    [Prazo de integralização (2 anos)]  , [1,6789974]    , [0,1120510]     , [14,984]    ,
    [Prazo de integralização (3 anos)]  , [2,1489922]    , [0,1092246]     , [19,675]    ,
    [Prazo de integralização (4 anos)]  , [2,2735994]    , [0,1091543]     , [20,829]    ,
    [Prazo de integralização (5 anos)]  , [2,3266200]    , [0,1091148]     , [21,323]    ,
    [Prazo de integralização (6 anos)]  , [2,3211109]    , [0,1091185]     , [21,271]    ,
    [Prazo de integralização (7 anos)]  , [1,7429309]    , [0,1095723]     , [15,907]    ,
    [Prazo de integralização (8 anos)]  , [2,3309419]    , [0,1153985]     , [20,199]    ,
    [Prazo de integralização (9 anos)]  , [2,4016504]    , [0,1095908]     , [21,915]    ,
    [Prazo de integralização (10 anos)] , [2,3605742]    , [0,1103803]     , [21,386]    ,
    [Quantidade de ingressantes (log)]  , [0,9968214]    , [0,0007927]     , [1257,427]  ,
  ),
  caption: "Estimativa dos coeficientes do modelo de regressão de Poisson.",
) <tab:modelo-poisson>

Realizando o teste de dispersão apresentado na @sec:reg-poisson com o modelo acima, temos que seu p-valor é menor que 2,2e16, com o valor 7,121654 para $phi.alt$. Ou seja, temos bastante evidência para rejeitar a hipótese nula. Com isso, o modelo final especificado na @sec:modelo-final pode ser finalmente ajustado.

O método `glm.nb` começou estimando o valor de 5,7574 para o parâmetro $theta$. Depois disso, o modelo ajustado, com AIC igual a 216.300 e BIC igual a 216.423, apresentou como estimativa dos coeficientes os valores presentes na @tab:modelo-bin-neg.

#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr),
    inset: 0.75em,
    [*Covariável*]                      , [*Estimativa*] , [*Erro padrão*] , [*_z-value_*] ,
    [Intercepto]                        , [-2.963273]    , [0.170473]      , [-17.383]     ,
    [Grau acadêmico (licenciatura)]     , [-0,069959]    , [0,008000]      , [-8,745]      ,
    [Grau acadêmico (tecnológico)]      , [0,069413]     , [0,016140]      , [4,301]       ,
    [modalidade de ensino (presencial)] , [-0,148148]    , [0,017059]      , [-8,685]      ,
    [Prazo de integralização (2 anos)]  , [1,875490]     , [0,179533]      , [10,447]      ,
    [Prazo de integralização (3 anos)]  , [2,303471]     , [0,169455]      , [13,593]      ,
    [Prazo de integralização (4 anos)]  , [2,460757]     , [0,169083]      , [14,554]      ,
    [Prazo de integralização (5 anos)]  , [2,482171]     , [0,168821]      , [14,703]      ,
    [Prazo de integralização (6 anos)]  , [2,468621]     , [0,168874]      , [14,618]      ,
    [Prazo de integralização (7 anos)]  , [1,856029]     , [0,170813]      , [10,866]      ,
    [Prazo de integralização (8 anos)]  , [2,508925]     , [0,194096]      , [12,926]      ,
    [Prazo de integralização (9 anos)]  , [2,583033]     , [0,171510]      , [15,061]      ,
    [Prazo de integralização (10 anos)] , [2,577215]     , [0,176542]      , [14,598]      ,
    [Quantidade de ingressantes (log)]  , [0,991712]     , [0,003294]      , [301,089]     ,
  ),
  caption: "Estimativa dos coeficientes do modelo de regressão Binomial Negativa.",
) <tab:modelo-bin-neg>

É possível perceber que os dois métodos apresentaram valores muito próximos para os coeficientes, o que é o esperado dado que os dois métodos apresentam a mesma modelagem para a média. Outro comportamento esperado é o erro padrão menor para os coeficientes, pois, como visto na @sec:reg-poisson, modelos de regressão de Poisson com dados sobredispersos acabam atribuindo valores menos corretos para essa informação se comparados com modelos que consideram esse fenômeno.

Para diagnosticar o modelo, podemos utilizar um gráfico de quantis dos resíduos. Para o cálculo dos resíduos, será utilizado o _randomized quantile residual_ (RQR), proposto por Dunn e Smyth em 1996~@dunn-1996, que serve para trabalhar com modelos de contagem~@feng-2020. Visualização disponível na @img:qq-rqr, com os resíduos calculados utilizando o método `qresiduals` da biblioteca _countreg_~@r-countreg.

#figure(
  image(
    "images/qq-rqr.png",
    width: 100%
  ),
  caption: [
   Gráfico de quantis dos resíduos do tipo RQR.
  ]
) <img:qq-rqr>


É notável que o modelo não se ajustou bem aos dados, pois existe um grande desvio dos pontos da linha de identidade. Isso pode acontecer por vários fatores, sendo um deles a hipótese dos dados não seguirem realmente uma distribuição Binomial Negativa.

Essa hipótese pode ser avaliada ao testar se os resíduos realmente seguem uma distribuição normal. Utilizando o teste de Anderson–Darling~@anderson-2011 para essa finalidade, calculamos seu p-valor em _R_ utilizando o método `ad.test` da biblioteca @r-nortest, que considera que esse valor é menor que 2.2e-16. Ou seja, temos bastante evidência para rejeitar a normalidade dos resíduos.

É possível visualizar esse comportamento dos resíduos ao analisar sua densidade (@img:densidade-residuos). Mesmo tendo uma distribuição aparentemente gaussiana, a média tende para a direita e a cauda esquerda é mais pesada.

#figure(
  image(
    "images/densidade-residuos.png",
    width: 100%
  ),
  caption: [
   Gráfico de densidade dos resíduos.
  ]
) <img:densidade-residuos>

= Conclusão

