#let sans-serif = ("Noto Sans CJK KR", )
#let serif = ("Noto Serif CJK KR", )
#let mono = ("Noto Sans Mono", "D2Coding", )

#let template(
  content
) = {
  let page-count = 0;
  set page(
    paper: "a4",
    margin: (left: 20mm, right: 20mm, top: 15mm, bottom: 15mm),
    numbering: "- 1 -"
  )
  set heading(numbering: "1.1)")
  show heading.where(level: 1): it => text(
    size: 13pt,
    font: sans-serif,
    weight: "medium",    
  )[
    
    #counter(heading).display("1.") #it.body
    
  ]
  show heading.where(level: 2): it => text(
    size: 12pt,
    font: serif,
    weight: "bold",    
  )[
    
    #counter(heading).display("1.1)") #it.body
    
  ]
  set text(size: 11pt, font: serif)
  content
}
