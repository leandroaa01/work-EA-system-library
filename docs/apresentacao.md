# Guia para a apresentação

> O enunciado do trabalho **não define** formato, duração ou obrigatoriedade de slides. Este roteiro é uma sugestão (~12 a 15 minutos). Confirme com o professor o tempo e se há perguntas ao final.

## Slides prontos

`docs/slides/apresentacao-biblioteca.pptx`: 17 slides mais 1 de backup (mecanismos do Maude), 16:9, editável no PowerPoint e no Google Slides. **Cada slide tem notas do apresentador** com o que falar (veja em *Exibir → Notas*). Os slides seguem o roteiro da seção 2 abaixo:

| Slides | Roteiro |
|---|---|
| 1–2 | Introdução (etapa 1) |
| 3 | Abstração (etapa 2) |
| 4 | Regras (etapa 5) |
| 5–6 | Assinatura (etapa 3) |
| 7–9 | Estruturas algébricas e equações (etapas 4 e 5) |
| 10–11 | Guardas e situações inválidas (etapa 5) |
| 12–13 | Demonstração e reescrita passo a passo (etapa 6) |
| 14 | Propriedades (etapa 7) |
| 15–17 | Verificação, análise e conclusão (etapa 8) |
| 18 | Backup para perguntas |

A fonte usada é Calibri. Se faltar na máquina da apresentação, o PowerPoint troca por outra e o texto pode quebrar diferente; abra os slides lá antes.

## 1. O que levar pronto

| Item | Para quê |
|---|---|
| Maude instalado e testado no notebook | demonstração ao vivo |
| Terminal aberto em `src/`, com `maude -no-banner` já carregado | evitar perder tempo digitando |
| `src/biblioteca.maude` e `src/demo-biblioteca.maude` abertos no editor | mostrar o código |
| `docs/execucao/log-demo.txt` aberto | plano B se o Maude falhar na hora |
| Slides curtos (5 a 8) ou o próprio `docs/relatorio.md` | seguir o roteiro |
| Cópia do relatório em PDF | caso peçam |

**Plano B:** se o Maude não rodar, mostre o `log-demo.txt` (saída real da execução) e explique as linhas.

## 2. Roteiro sugerido

| # | Tempo | Conteúdo | Material |
|---|---|---|---|
| 1 | 1 min | Problema e objetivo: especificar (não implementar) um sistema de biblioteca. A cadeia *informal → abstração → assinatura → equações → termos → propriedades* | `relatorio.md` §1 |
| 2 | 2 min | **Abstração**: o que é livro, usuário, acervo, empréstimo; o que foi ignorado (datas, multas, reservas) | `relatorio.md` §2 |
| 3 | 2 min | **Assinatura**: sorts, construtores vs. definidos, camadas de módulos | `relatorio.md` §3, `biblioteca.maude` |
| 4 | 2 min | **Estruturas algébricas**: acervo como **monóide** (`assoc` + `id: nilA`) e `Status` | `relatorio.md` §4 |
| 5 | 2 min | **Regras** R1–R7 e extras E1–E4 e onde cada uma é imposta (guarda ou invariante) | `relatorio.md` §2.3, §5.2 |
| 6 | 4 min | **Demonstração ao vivo** (ver §3 abaixo) | terminal |
| 7 | 2 min | **Propriedades**: P1–P5 e como foram provadas (indução estrutural) | `relatorio.md` §9 |
| 8 | 1 min | Limitações e conclusão | `relatorio.md` §10.3, §11 |

## 3. Demonstração ao vivo (4 min)

Rode `maude -no-banner demo-biblioteca.maude < /dev/null` (ou carregue no interativo) e destaque **cinco** resultados:

1. **Consulta básica** [1]: `totalLivros(lib0)` dá `5`.
2. **Exemplo-guia** [24]: `totalLivros(addLivro(lib0, l6, "O chamado de Cthulhu")) == totalLivros(lib0) + 1` dá `true`.
3. **Operação inválida** [37]: `emprestar(lib1, l1, bruno) == lib1` dá `true`, ou seja, livro já emprestado deixa o estado **inalterado** (R2).
4. **Erro explícito** [55]: `diagEmprestar(lib1, l1, bruno)` dá `errLivroJaEmprestado`.
5. **Invariante em estado inválido** [71]: `idsUnicos?(ruim1)` dá `false`.

Depois dos testes, mostre as sete linhas `result Bool: true` do módulo `CONFERENCIA` (o Maude conferindo os 75 testes sozinho). Se houver tempo, rode `maude -no-banner verificacao.maude < /dev/null`: são 6613 estados e `No solution.` nas duas primeiras buscas (o invariante nunca é violado).

Se sobrar tempo, mostre o **trace** (reescrita passo a passo) do exemplo "Cthulhu": no interativo, `set trace on .` e depois o `reduce` de [T1]. No final do `demo-biblioteca.maude` há três exemplos prontos.

**Dica:** o `lib1` é a "história" (Ana pega 3 livros, Bruno pega e devolve, Carla pega o l3). Conte essa história antes de mostrar os testes inválidos; fica fácil de acompanhar.

## 4. Perguntas prováveis e respostas curtas

| Pergunta | Resposta |
|---|---|
| Por que `Status` em vez de duas listas (disponíveis e emprestados)? | Assim a relação usuário–livro fica dentro do dado, a unicidade do dono é automática e R7 vira uma contagem não trivial. |
| O que significa `assoc id: nilA`? | O operador `_;_` é associativo e `nilA` é elemento neutro, ou seja, é um **monóide**. As equações valem módulo essas leis. |
| Qual a diferença entre construtor e operador definido? | Construtores (`[ctor]`) geram os valores; definidos têm equações que os reduzem a construtores. |
| Como operações inválidas são tratadas? | Guarda `if podeX? then … else B fi`: estado inalterado. Além disso, `diagX` informa qual erro ocorreu. |
| Como R7 é garantida? | Provada por indução para **todo** estado: cada item é `disponivel` ou `emprestado(U)`, então os dois contadores somam o total. |
| Por que não usou `rl`? | A especificação é equacional (`fmod`). Só no arquivo separado `verificacao.maude` usamos `rl`, para o `search` percorrer todos os estados alcançáveis e conferir o invariante. |
| Por que `ceq`/`owise` não aparecem? | Usei `if_then_else_fi` como no exemplo do professor; os padrões das equações são disjuntos, então `owise` não foi necessário. |
| Como sabem que o código funciona? | 75 testes com resultado esperado conferido dentro do próprio Maude (módulo `CONFERENCIA`, tudo `true`) e `search` sobre os 6613 estados alcançáveis com 4 livros e 2 usuários, sem violação do invariante. |
| Isso prova que está correto? | As propriedades foram provadas em papel por indução; os testes validam instâncias. A suficiente completude não foi checada com a ferramenta SCC. |
| O que não foi modelado? | Datas, multas, reservas, renovação, múltiplos exemplares por título, concorrência (`relatorio.md` §10.3). |
| Por que limite de 3 empréstimos? | Regra extra E4 para mostrar uma regra numérica; o valor é arbitrário e fica em `limiteEmprestimos`. |

## 5. Divisão sugerida entre os integrantes

Cada pessoa precisa saber explicar **o projeto inteiro em alto nível** e uma parte em detalhe.

| Parte | Conteúdo |
|---|---|
| Abstração e regras | seções 2 e 6 do relatório |
| Assinatura e monóide | seções 3 e 4; módulos `LIVRO-USUARIO`, `ACERVO`, `USUARIOS` |
| Equações e guardas | seção 5; módulo `BIBLIOTECA` |
| Testes e demonstração | seção 8; `demo-biblioteca.maude`; trace |
| Propriedades e análise | seções 9 e 10 |

## 6. Checklist antes de apresentar

- [ ] Rodar a demo completa uma vez na máquina da apresentação.
- [ ] Todos sabem o que é cada regra (R1–R7, E1–E4) sem consultar.
- [ ] Todos conseguem explicar o monóide e o papel de `Status`.
- [ ] Combinar quem faz a demonstração ao vivo.
- [ ] Confirmar o tamanho do grupo (o enunciado permite **até 4**; o `README.md` lista 5 autores).
- [ ] Enviar o trabalho por e-mail até **30 de outubro** para valdigleis@dimap.ufrn.br (relatório, `biblioteca.maude`, `demo-biblioteca.maude`, `verificacao.maude`, exemplos de execução).
