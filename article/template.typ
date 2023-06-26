#let project(title: "", authors: (), date: none, body) = {

  // --- Basic ---

  set document(
    author: authors.map(a => a.name),
    title: title,
  )

  set page(
    numbering: "1",
    number-align: center,
  )

  set text(
    lang: "pt",
    region: "br",
    font: "New Computer Modern Sans",
    size: 11pt
  )

  set heading(numbering: "1.1")
  show heading: it => pad(bottom: 0.25em, it)

  show link: underline



  // --- Title ---

  align(center)[
    #block(text(weight: 700, 1.75em, title))
    #v(1em, weak: true)
    #date.display("[day]/[month]/[year]")
  ]

  // --- Authors ---

  pad(
    top: 1em,
    bottom: 1.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(3, authors.len()),
      gutter: 1em,
      ..authors.map(author => align(center)[
        *#author.name* \
        #author.email \
        #author.affiliation
      ]),
    ),
  )

  // --- Outline --

  pad(
    bottom: 1em,
    outline()
  )

  // --- Body ---

  set math.equation(numbering: "(1)")
  set par(justify: true)

  show figure: it => pad(bottom: 1em, it)

  body

  // --- Bibliography ---

  show " and ": " e "
  show " Available: ": " Disponível em: "

  pagebreak(weak: true)
  bibliography("refs.bib")
}
