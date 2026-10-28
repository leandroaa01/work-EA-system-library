# Resumo do projeto: o que foi feito e por quê

Use este arquivo para **explicar o trabalho** sem reler o relatório inteiro. Os detalhes formais estão em `relatorio.md`.

## 1. Em uma frase

Especificamos um sistema de biblioteca (acervo, usuários, empréstimos) como uma **álgebra** em Maude: o comportamento é definido só por **sorts, operadores e equações**, e foi testado executando as equações por reescrita.

## 2. O que o trabalho pede

Especificar (não implementar) um sistema, seguindo a cadeia *descrição informal → abstração → assinatura → equações → termos → propriedades*, com operações sobre coleção, regras R1–R7, pelo menos 5 situações inválidas e pelo menos 10 testes. Escolhemos a **Proposta 1: Sistema de Biblioteca**.

## 3. As decisões principais

| # | Decisão | Por quê | Alternativa descartada |
|---|---|---|---|
| 1 | `IdLivro` e `IdUsuario` são **sorts distintos** (`livro(Nat)`, `usuario(Nat)`) | evita misturar livro 1 com usuário 1; o Maude acusa o erro de tipo | usar `Nat` direto nos dois |
| 2 | O estado do livro é `Status`: `disponivel` ou `emprestado(IdUsuario)` | a relação usuário–livro fica **dentro do dado**; um livro só tem um dono; R7 passa a ser contagem não trivial | tabela separada de empréstimos |
| 3 | `Acervo` é lista com `assoc id: nilA` (**monóide**) | concatenar é simples (`A ; item(...)`) e o monóide fica explícito na assinatura | lista recursiva `Item Acervo` (mais próxima do exemplo do professor, mas esconde o monóide) |
| 4 | `Usuarios` é outro monóide (`nilU`, `_&_`) | mesma ideia, código uniforme | conjunto (exigiria comutatividade) |
| 5 | Estado global `biblioteca(Acervo, Usuarios)` | análogo ao `BANCO`, mas com duas coleções | dois estados separados |
| 6 | Operação inválida **não muda o estado** (`if podeX? then … else B fi`) | operações totais e seguras, como `abrirConta`/`sacar` do exemplo | devolver erro e perder o estado |
| 7 | Mesmo assim existe **erro explícito**: `buscar` → `livroInexistente`, e `diagX` → `err…` | permite dizer *qual* regra falhou | só estado inalterado |
| 8 | Guardas separadas (`podeEmprestar?`…) | pré-condições nomeadas, testáveis sozinhas | condições soltas dentro das equações |
| 9 | Invariantes como predicados (`idsUnicos?`, `contagemOk?`, `invariante?`) | permitem testar R6/R7 até em estados montados à mão | confiar que as operações preservam |
| 10 | Base **equacional** (`fmod`); `rl` só em `verificacao.maude` | o enunciado pede equações; as regras `rl` servem apenas para o `search` explorar estados | modelar tudo com `rl` |
| 11 | Módulos em camadas com `protecting` | imita `CLIENTE`/`CONTA` → `BANCO` | um módulo único |

## 4. Regras do enunciado e extras

| Regra | Onde é imposta |
|---|---|
| R1 livro tem que pertencer ao acervo | guarda `podeEmprestar?` |
| R2 não emprestar livro emprestado | guarda `podeEmprestar?` |
| R3 devolver torna o livro disponível | equação de `devolver` (`definirStatus(.., disponivel)`) |
| R4 só devolve quem tem o livro | guarda `podeDevolver?` |
| R5 só remove livro disponível | guarda `podeRemoverLivro?` |
| R6 id único | guarda `podeAddLivro?` e invariante `idsUnicos?` |
| R7 disp + emp = total | invariante `contagemOk?`, provado para todo estado |

**Extras** (o enunciado permite, desde que justificadas):

| Regra | Descrição | Justificativa |
|---|---|---|
| E1 | não registrar usuário duplicado | senão "o usuário" fica ambíguo |
| E2 | não remover usuário com livros | evita empréstimo sem dono |
| E3 | só emprestar a usuário registrado | consequência de E2 |
| E4 | limite de 3 empréstimos | exemplo de regra numérica (valor arbitrário, em `limiteEmprestimos`) |

## 5. O código, módulo por módulo (`src/biblioteca.maude`)

```
LIVRO-USUARIO ──> ACERVO ────────┐
              └─> USUARIOS ──────┴─> BIBLIOTECA ──> DIAGNOSTICO
```

| Módulo | O que define | Ideia-chave |
|---|---|---|
| `LIVRO-USUARIO` | ids, `Status`, `Item` e as operações `getId`, `comStatus`, `itemDisponivel?`, `itemDe?` | um item é `item(id, título, status)` |
| `ACERVO` | lista de itens e operações sobre ela: `totalA`, `existeA?`, `buscarA`, `removerA`, `definirStatus`… | toda operação recursiva tem 2 casos: `nilA` e `I ; A` (cabeça + resto) |
| `USUARIOS` | lista de usuários: `existeU?`, `removerU`… | idem |
| `BIBLIOTECA` | estado, consultas, guardas, modificadores e invariantes | cada modificador é `if guarda then novo estado else estado original fi` |
| `DIAGNOSTICO` | `diagEmprestar` etc., que devolvem `ok` ou `err…` | mesmas condições das guardas, mas dizendo o motivo |

**Convenção:** operadores com `[ctor]` são **construtores** (geram os valores). Os demais são **definidos** e têm equações que os reduzem a construtores. Operadores terminados em `A` (`totalA`, `existeA?`…) atuam sobre o acervo; os sem sufixo (`totalLivros`, `pertence?`…) atuam sobre a `Biblioteca`.

### Os trechos que mais vale saber explicar

**O monóide:**

```maude
op nilA : -> Acervo [ctor] .
op _;_ : Acervo Acervo -> Acervo [ctor assoc id: nilA] .
```

`assoc` = `(a ; b) ; c = a ; (b ; c)`; `id: nilA` = `nilA ; a = a = a ; nilA`. Por isso o padrão `I ; A` casa com qualquer acervo não vazio (com `A = nilA` se houver um só item) e bastam duas equações por operador.

**Uma consulta recursiva:**

```maude
eq existeA?(nilA, L) = false .
eq existeA?(I ; A, L) = (getId(I) == L) or existeA?(A, L) .
```

Caso vazio: não existe. Caso não vazio: é a cabeça ou está no resto.

**Uma operação com guarda:**

```maude
eq emprestar(biblioteca(A, Us), L, U) =
  if podeEmprestar?(biblioteca(A, Us), L, U)
  then biblioteca(definirStatus(A, L, emprestado(U)), Us)
  else biblioteca(A, Us) fi .
```

Se a guarda for falsa, o resultado é o próprio estado.

**R7, a parte não trivial:**

```maude
eq contagemOk?(B) = (qtdDisponiveis(B) + qtdEmprestados(B)) == totalLivros(B) .
```

`qtdDisponiveis` e `qtdEmprestados` são calculadas por equações **separadas** sobre o `Status`. A igualdade com o total é um teorema (provado por indução), não uma definição.

### Mecanismos do Maude (significado formal, em 1 linha cada)

| Mecanismo | Significado |
|---|---|
| `fmod` | módulo funcional: a semântica é a álgebra inicial (termos iguais só se deduzíveis das equações) |
| `protecting` | importa outro módulo sem criar nem colapsar valores dele |
| `[ctor]` | marca construtor |
| `subsort A < B` | todo `A` também é `B` (ex.: `Item < Acervo`: um item é um acervo de um elemento) |
| `assoc` / `id:` | associatividade / elemento neutro (juntos: monóide) |
| `if_then_else_fi` | escolhe o ramo conforme a guarda reduz a `true` ou `false` |
| `==` / `=/=` | igualdade entre formas normais |
| `ceq`, `[owise]` | **não usados**: `ceq` seria equação condicional; `owise`, "se nenhuma outra equação casar" |
| `rl`, `search` | só em `verificacao.maude`: `rl` é regra de reescrita não equacional, `search` percorre os estados alcançáveis |

## 6. As 10 situações inválidas

| # | Situação | Regra | Teste |
|---|---|---|---|
| I1 | emprestar livro inexistente | R1 | [36] |
| I2 | emprestar livro já emprestado | R2 | [37], [38] |
| I3 | devolver livro não emprestado | R4 | [39] |
| I4 | devolver livro emprestado a **outro** usuário | R4 | [40] |
| I5 | remover livro emprestado | R5 | [41] |
| I6 | adicionar id repetido | R6 | [43] |
| I7 | registrar usuário repetido | E1 | [45] |
| I8 | emprestar a usuário não registrado | E3 | [46] |
| I9 | remover usuário com livros | E2 | [47] |
| I10 | passar do limite de empréstimos | E4 | [49] |

Em todas, o teste é do tipo `operação(...) == estado`, e dá `true` (estado inalterado).

## 7. Como foi verificado

| O quê | Como | Resultado |
|---|---|---|
| 75 testes da demo | módulo `CONFERENCIA` (em Maude): cada teste vira uma equação `tN` que compara com o esperado | 6 seções e `todos?` dão `true` |
| Reescrita passo a passo | `set trace on` (3 exemplos, inclusive "Cthulhu") | 20 reescritas até `2` |
| Todos os estados alcançáveis (4 livros, 2 usuários) | `verificacao.maude`: `search` com 28 regras `rl` | 6613 estados, invariante e coerência sem violação |
| Sensibilidade da verificação | 7 defeitos injetados numa cópia (sem R2, R4, R5, R6, E2, E3, E4) | os 7 foram detectados |

Todas as saídas são **reais** (Maude 3.5.1). Os logs estão em `docs/execucao/`.

## 8. Propriedades provadas (indução estrutural sobre o acervo)

| Propriedade | Ideia da prova |
|---|---|
| **P1** `totalLivros(addLivro(B,x)) = totalLivros(B) + 1` se `x` é novo | lema: `totalA(A ; C) = totalA(A) + totalA(C)`, por indução em `A` |
| **P2** `devolver(emprestar(B,l,u),l,u) = B` se o empréstimo era permitido | `definirStatus` aplicado duas vezes mantém só o último status; o livro estava disponível antes |
| **P3** guarda falsa ⇒ estado inalterado | direto da equação `if false then a else b fi = b` |
| **P4** R7 vale em todo estado | indução em `A`: cada item é `disponivel` ou `emprestado(U)`, e cada caso soma 1 dos dois lados |
| **P5** `addLivro` preserva ids únicos | lema: `idsUnicosA?(A ; I) = idsUnicosA?(A) ∧ ¬existeA?(A, getId(I))` |

**Limite honesto:** o Maude não reduz propriedades com variável livre (`b : Biblioteca`), pois as guardas dependem da forma de `b`. Por isso as provas estão no relatório (em papel) e os testes validam instâncias concretas.

## 9. O que não foi modelado

Datas, prazos, multas, reservas, renovação, múltiplos exemplares por título (cada exemplar tem id próprio), autores/ISBN, histórico, perfis de usuário, concorrência. São escolhas de abstração, não esquecimentos (`relatorio.md` §10.3).

## 10. Limitações a admitir se perguntarem

- A **suficiente completude** (todo termo fechado reduz a construtores) não foi checada com a ferramenta SCC do Maude. Só há evidência indireta: nos 6613 estados da `verificacao.maude`, `invariante?(B) =/= true` não tem solução, então nenhum termo travou sem reduzir.
- A verificação exaustiva só cobre 4 livros e 2 usuários (limite do espaço de estados). Para tamanho arbitrário valem as provas em papel.
- O limite de 3 empréstimos é arbitrário.
- As provas P1–P5 são em papel, não mecanizadas.
- O Maude reordena operandos comutativos de `Nat` ao imprimir (`1 + total(...)`); é só exibição.

## 11. Armadilhas que encontramos (bom para mostrar que entendemos a ferramenta)

- Uma linha `*** (` abre **comentário de bloco** no Maude, mesmo com espaço, e quebra o parse. Por isso os testes usam `*** [n]`.
- A comparação `== lib` é entre **formas normais**: só funciona porque o sistema é terminante e confluente.
- Uma busca que dá `No solution` pode estar vazia por engano. Por isso a `verificacao.maude` inclui buscas que **têm** que achar solução (V3 a V7), e validamos tudo quebrando o código de propósito: cada um dos 7 defeitos injetados foi detectado.

## 12. Glossário rápido

| Termo | Significado |
|---|---|
| Sort | tipo |
| Assinatura | sorts + operadores com suas aridades |
| Construtor | operador que gera valores (`[ctor]`) |
| Operador definido | operador reduzido por equações a construtores |
| Forma normal | termo que não pode mais ser reescrito (o resultado) |
| Monóide | conjunto com operação associativa e elemento neutro |
| Guarda | predicado `podeX?` que decide se a operação vale |
| Invariante | propriedade que todo estado válido satisfaz |
| Indução estrutural | provar caso base (`nilA`) e passo (`I ; A`) |
