e#import "template.typ": *

#show: project.with(
  title: "Modelagem da evasão\nno ensino superior no Brasil",
  authors: (
    (name: "Juan Belieni", email: "juanbelieni@gmail.com", affiliation: "FGV/EMAp"),
  ),
  date: datetime.today()
)

= Introdução

A evasão no ensino superior é um problema que afeta muitos cursos acadêmicos pelo país, e possui diversas naturezas ao nível do estudante, tais como vocacional, relativos ao desempenho ou até sociais~@ambiel-2021. No entanto, fatores macros também podem ajudar a entender efeitos globais do fenômeno de evasão, como a modalidade de ensino do curso.

A motivação de modelar esse fenômeno surge da necessidade de entender como fatores macro  influenciam a persistência dos estudantes.

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

Em relação às variáveis categóricas, algumas destas acabam tendo naturalmente muitas opções de valores possíveis, como a variável contendo a UF onde o curso é ofertado. Por esse motivo, essas variáveis foram preteridas em favor de outras mais gerais, como o da região, no caso citado. Para a última, nota-se uma ligeira diferença em relação ao percentual de evasão, como é possível observar na @img:evasao-por-regiao.

#figure(
  image(
    "images/evasao-por-regiao.png",
    width: 100%
  ),
  caption: [
    Gráfico da proporção da taxa de evasão em relação à região.
  ]
) <img:evasao-por-regiao>

A diferença que se destaca, nesse caso, é a maior representatividade na proporção do percentual de evasão quando a classificação de região não se aplica. No conjunto de dados, essa classificação significa que o curso é ofertado a distância. Dessa maneira, conseguímos utilizar a variável que informa a modalidade de ensino para codificar essa discrepância.

Também é possível ver alterações significativas na proporção do percentual de evasão quando analisamos esse valor em relação ao tipo de administração:

#figure(
  image(
    "images/evasao-por-tipo-administracao.png",
    width: 100%
  ),
  caption: [
    Gráfico da proporção da taxa de evasão em relação ao tipo de adminstração.
  ]
) <img:desistencias-por-grau-academico>

Com essa investigação, as variáveis escolhidas serão transformadas para formar as covariáveis do modelo final, que será descrito a seguir e contará com 14 covariáveis.

== Modelo final <sec:modelo-final>

Por fim, o modelo escolhido foi uma regressão Binomial Negativa que leva em conta as influências das variáveis da quantidade de ingressantes, do prazo de integralização, da região e do tipo de adiministração da universidade. No _R_, tal modelo é construído da seguinte maneira:

```R
glm.nb(
  qt_desistencias ~ 1
    + grau_academico
    + tipo_administracao
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
    + modalidade_ensino
    + tipo_administracao
    + as.factor(prazo_integralizacao)
    + log(qt_ingressantes),
  data = data,
  family = poisson,
)
```

Por padrão, o _R_ considera que o parâmetro de dispersão é igual a 1~@r-base. Com esse valor e após 5 iterações de _Fisher's scoring_, foi produzido um modelo com AIC igual a 339.177, BIC igual a 339.292 e com as estimativas para os coeficientes que estão presente na @tab:modelo-poisson.

#show figure: set block(breakable: true)

#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr),
    inset: 0.75em,
    [*Covariável*]                      , [*Estimativa*] , [*Erro padrão*] , [*_z-value_*] ,
    [Intercepto]                        , [-3.0975812] , [0.1103542] , [ -28.069] ,
    [Modalidade de ensino (presencial)] , [-0.0946402] , [0.0033707] , [ -28.077] ,
    [Tipo de administração (Privada)]   , [ 0.3438696] , [0.0152867] , [  22.495] ,
    [Tipo de administração (Pública)]   , [ 0.1222539] , [0.0153891] , [   7.944] ,
    [Prazo de integralização (2 anos)]  , [ 1.7122496] , [0.1120452] , [  15.282] ,
    [Prazo de integralização (3 anos)]  , [ 2.1894498] , [0.1091304] , [  20.063] ,
    [Prazo de integralização (4 anos)]  , [ 2.2939549] , [0.1091393] , [  21.019] ,
    [Prazo de integralização (5 anos)]  , [ 2.3490929] , [0.1091144] , [  21.529] ,
    [Prazo de integralização (6 anos)]  , [ 2.3586600] , [0.1091174] , [  21.616] ,
    [Prazo de integralização (7 anos)]  , [ 1.8257122] , [0.1095745] , [  16.662] ,
    [Prazo de integralização (8 anos)]  , [ 2.3518163] , [0.1153984] , [  20.380] ,
    [Prazo de integralização (9 anos)]  , [ 2.4495912] , [0.1095914] , [  22.352] ,
    [Prazo de integralização (10 anos)] , [ 2.4405378] , [0.1103832] , [  22.110] ,
    [Quantidade de ingressantes (log)]  , [ 0.9768587] , [0.0008204] , [1190.769] ,
  ),
  caption: "Estimativa dos coeficientes do modelo de regressão de Poisson.",
) <tab:modelo-poisson>

Realizando o teste de dispersão apresentado na @sec:reg-poisson com o modelo acima, temos que seu p-valor é menor que 2,2e16, com o valor 6,948751 para $phi.alt$. Ou seja, temos bastante evidência para rejeitar a hipótese nula. Com isso, o modelo final especificado na @sec:modelo-final pode ser finalmente ajustado.

O método `glm.nb` começou estimando o valor de 5,9732 para o parâmetro $theta$. Depois disso, o modelo ajustado, com AIC igual a 215.558 e BIC igual a 215.681, apresentou como estimativa dos coeficientes os valores presentes na @tab:modelo-bin-neg.

#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr),
    inset: 0.75em,
    [*Covariável*]                      , [*Estimativa*] , [*Erro padrão*] , [*_z-value_*] ,
    [Intercepto]                        , [-3.183171] , [0.172868] , [-18.414] ,
    [Modalidade de ensino (presencial)] , [-0.151741] , [0.016649] , [ -9.114] ,
    [Tipo de administração (Privada)]   , [ 0.300960] , [0.037509] , [  8.024] ,
    [Tipo de administração (Pública)]   , [ 0.110856] , [0.037685] , [  2.942] ,
    [Prazo de integralização (2 anos)]  , [ 1.939972] , [0.177700] , [ 10.917] ,
    [Prazo de integralização (3 anos)]  , [ 2.364277] , [0.167391] , [ 14.124] ,
    [Prazo de integralização (4 anos)]  , [ 2.517725] , [0.167434] , [ 15.037] ,
    [Prazo de integralização (5 anos)]  , [ 2.511231] , [0.167270] , [ 15.013] ,
    [Prazo de integralização (6 anos)]  , [ 2.507559] , [0.167309] , [ 14.988] ,
    [Prazo de integralização (7 anos)]  , [ 1.949313] , [0.169240] , [ 11.518] ,
    [Prazo de integralização (8 anos)]  , [ 2.540016] , [0.192112] , [ 13.222] ,
    [Prazo de integralização (9 anos)]  , [ 2.635591] , [0.169901] , [ 15.513] ,
    [Prazo de integralização (10 anos)] , [ 2.658740] , [0.174851] , [ 15.206] ,
    [Quantidade de ingressantes (log)]  , [ 0.976705] , [0.003276] , [298.181] ,
  ),
  caption: "Estimativa dos coeficientes do modelo de regressão Binomial Negativa.",
) <tab:modelo-bin-neg>

É possível perceber que os dois métodos apresentaram valores muito próximos para os coeficientes, o que é o esperado dado que os dois métodos apresentam a mesma modelagem para a média. Outro comportamento esperado é o erro padrão menor para os coeficientes, pois, como visto na @sec:reg-poisson, modelos de regressão de Poisson com dados sobredispersos acabam atribuindo valores menos corretos para essa informação se comparados com modelos que consideram esse fenômeno.

Também é interessante analisar o modelo por meio da utilização de um gráfico de quantis dos resíduos. Para esse diagnóstico, o cálculo dos resíduos foi feito utilizado o _randomized quantile residual_ (RQR), proposto por Dunn e Smyth em 1996~@dunn-1996, que serve para trabalhar com modelos de contagem~@feng-2020, com a visualização disponível na @img:qq-rqr, no qual os resíduos foram calculados utilizando o método `qresiduals` da biblioteca _countreg_~@r-countreg.

#figure(
  image(
    "images/qq-rqr.png",
    width: 100%
  ),
  caption: [
   Gráfico de quantis dos resíduos do tipo RQR.
  ]
) <img:qq-rqr>


É notável que o modelo não se ajustou bem aos dados, pois existe um desvio considerável dos pontos em relação da linha de identidade. Isso pode ter acontecido por diversos fatores, sendo um deles a hipótese dos dados não seguirem realmente uma distribuição Binomial Negativa.

Essa hipótese pode ser avaliada ao testar se os resíduos são normalmente distribuídos. Utilizando o teste de Anderson–Darling~@anderson-2011 para essa finalidade, calculamos seu p-valor em _R_ utilizando o método `ad.test` da biblioteca @r-nortest, que considera que esse valor é menor que 2.2e-16. Ou seja, temos bastante evidência para rejeitar a normalidade dos resíduos.

É possível visualizar esse comportamento dos resíduos ao analisar sua densidade (@img:densidade-residuos). Mesmo tendo uma distribuição aparentemente gaussiana, a média tende para a direita e a cauda esquerda é mais pesada.

#figure(
  image(
    "images/densidade-residuos.png",
    width: 100%
  ),
  caption: [
   Gráfico de densidade dos resíduos do tipo RQR.
  ]
) <img:densidade-residuos>

= Conclusão

== Interpretação dos resultados

Mesmo com o ajuste não ideal do modelo, ainda é pertinente interpretar seus coeficientes e resultados. Primeiramente, a hipótese inicial da forte relação entre a quantidade de ingressantes e desistências é percebido claramente na covariável "quantidade de ingressantes (log)", pois a estimativa para seu coeficiente foi a que mais teve evidência de ser diferente de zero.

A modalidade presencial também influência positivamente para um número menor de desistências. Isso é natural de se esperar dado que os cursos a distância foram aqueles com o maior número de alunos ingressantes no conjunto de dados. No entanto, cursos a distância possuem características únicas que tornam essa modalidade mais suscetíveis à evasão, como a falta de uma infraestrutura física robusta para o aprendizado, dificuldades inerentes ao meio digital como a falta de _feedbacks_ e apoio ao aluno, a demografia dos estudantes e outros fatores que prejudicam o processo de aprendizado~@almeida-2013.

Os prazos de integralização retornaram resultados coerentes para os coeficientes em relação à análise exploratória dos dados. No entanto, assim como aconteceu na análise exploratória, cursos com prazo de integralização igual a 7 anos possuem uma quantidade de desistências menor do que em relação a cursos que possuem esse valor igual a 6 ou 8 anos. Isso pode ser devido à abundância de cursos de medicina nessa categoria, nos quais já foi observado uma menor taxa de evasão em relação a outros cursos~@silva-2007.

== Limitações e trabalho futuro

As limitações da modelagem desenvolvida nesse trabalho se concentram principalmente na construção de um modelo que corresponda corretamente aos dados. Possivelmente, teria sido mais interessante ter construído um modelo que levasse mais em conta as diferenças entre as modalidades de ensino presencial e a distância. Mais do que isso, a construção de um modelo que conseguisse modelar a evolução do número de desistências ao longo dos anos de acompanhamento produziria, possivelmente, uma melhor análise do processo de evasão.

Isto posto, para continuar o desenvolvimento da modelagem feito nesse trabalho, é imprescindível a utilização de dados de outros anos disponibilizados pelo Inep, já que seria possível também estudar a mudança no comportamento da evasão no ensino superior ao longo dos últimos anos e relacionar com eventos e mudanças importantes da última década, como o aumento significativo do acesso à Internet.
