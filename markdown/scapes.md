## Escapar parênteses (e espaços) em links no Markdown

Para escapar parênteses (e espaços) em links no Markdown de forma que funcione em qualquer plataforma, a melhor prática é usar codificação de URL (Percent-encoding) substituindo ( por %28 e ) por %29. Além disso, remova as aspas simples ao redor do caminho, pois elas invalidam o link no Markdown padrão.

1. Solução Recomendada (Codificação de URL)

Substitua os parênteses pelos seus códigos hexadecimais e os espaços por %20 (ou mantenha os espaços se usar colchetes angulares, como mostrado abaixo):
```markdown
![imagem SVG](/docs/workflows/sequence_diagrams/Middleware%20Anti-CSRF%20Flow%20%28Rust%20Axum%29.svg)
```

2. Alternativa Limpa (Colchetes Angulares < >)

Na especificação CommonMark e no GitHub Flavored Markdown (GFM), você pode envolver todo o caminho com < e >. Isso permite usar espaços e parênteses normalmente sem precisar codificá-los:
```markdown
![imagem SVG](</docs/workflows/sequence_diagrams/Middleware Anti-CSRF Flow (Rust Axum).svg>)
```


