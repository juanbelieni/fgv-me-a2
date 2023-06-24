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

== Modelo

=== Regressão de Poisson e suas limitações

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

onde $g(dot)$ é uma função positiva qualquer. No _R_, é possível realizar esse teste por meio do método `AER::dispersiontest`.

Caso haja evidência para os casos citados, i.e., que os dados não sejam equidispersos, uma possível alternativa para contornar essa limitação do modelo é incluir um parâmetro de dispersão $phi.alt$. Com essa correção, o novo modelo, chamado de regressão Quasi-Poisson~@ver-2007, possui a seguinte descrição:

$
E[D_i | bold(X)_i]     = & mu_i, \
"Var"(D_i | bold(X)_i) = & phi.alt dot mu_i.
$

Outra alternativa é construir um GLM com a distribuição Binomial Negativa, que também possui um parâmetro de dispersão. Por possuir uma parametrização relativamente parecida com a regressão de Poisson, como será visto posteriormente, e não depender de métodos de quasi-verossimilhança, foi escolhida sua utilização.

=== Regressão Binomial Negativa

A regressão Binomial Negativa começa com uma modelagem similar para média de $D_i$, mas introduz um novo parâmetro $kappa$ que descreve sua variância~@ver-2007. Para a modelagem que está sendo feito nesse trabalho, o modelo em questão seria descrito da seguinte forma:

$
E[D_i | bold(X)_i]     = & mu_i = exp(beta_0 + bold(X)_i^T bold(beta')), \
"Var"(D_i | bold(X)_i) = & mu_i + kappa mu_i^2.
$

Esta definição dá à regressão Binomial Negativa uma maior flexibilidade em modelar o comportamento envolvendo a variável de interesse e as covariáveis, se comparado com uma regressão de Poisson tradicional~@gardner-1995, sendo ainda possível utilizar máximo verossimilhança para estimar os parâmetros necessários.

No _R_, a biblioteca _MASS_ oferece uma implementação que permite estimar modelos desse tipo~@r-mass, que pode ser feito utilizando o método `glm.nb`, uma modificação do método `glm` que estima um parâmetro $theta = 1/kappa$ por máxima verossimilhança, utilizado posteriormente para ajustar os parâmetros e outros valores associados ao modelo.

== Covariáveis <sec:covariaveis>

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
      Gráfico de dispersão entre o prazo de integralização e a quantidade de desistências.
    ]
  ) <img:desistencias-por-prazo-integralizacao>],
  [#figure(
    image(
      "images/evasao-por-prazo-integralizacao.png",
      width: 100%
    ),
    caption: [
      Gráfico de dispersão entre o prazo de integralização e o percentual de evasão.
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
    Boxplot e distribuição das desistências por região.
  ]
) <img:desistencias-por-regiao>

A maior diferença se apresenta, nesse caso, na distribuição dos pontos onde a classificação de região não se aplica. No conjunto de dados, isso significa que o curso é ofertado a distância. Dessa maneira, conseguímos utilizar a variável que informa a modalidade de ensino para condificar essa discrepância.

= Resultados

= Conclusão
