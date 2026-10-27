# Especificação Algébrica de um Sistema de Biblioteca em Maude

**Disciplina:** Estruturas Algébricas — Uso das Estruturas Algébricas para a Especificação de Sistemas
**Sistema:** Proposta 1 — Sistema de Biblioteca
**Ferramenta:** Maude 3.5.1 (execuções reais, macOS arm64)
**Arquivos:** `src/biblioteca.maude`, `src/demo-biblioteca.maude`, `src/verificacao.maude`, `docs/execucao/*`

---

## 1. Introdução

O objetivo é especificar, de forma precisa e consistente, um sistema de biblioteca (acervo, usuários e empréstimos) usando estruturas algébricas. O comportamento do sistema é definido **só** pela assinatura e pelas equações; não há implementação imperativa. O trabalho percorre a cadeia

> **Descrição informal → Abstração → Assinatura → Equações → Termos → Propriedades**

| Etapa | Onde aparece |
|---|---|
| Descrição informal → Abstração | Seção 2 |
| Assinatura | Seções 3 e 4 |
| Equações | Seção 5 |
| Termos (execução por reescrita) | Seção 8 |
| Propriedades | Seção 9 |

A especificação responde à pergunta central assim: os **objetos** são livros, usuários, acervo e biblioteca; as **operações** são as 11 funcionalidades do enunciado (mais auxiliares e diagnósticos); as **leis** são as equações, que impõem as regras R1–R7 e as regras extras E1–E4.

**Decisões de interpretação** (onde o enunciado era aberto, escolheu-se a opção mais simples):

- Operação inválida deixa o **estado inalterado** (mesma política do exemplo do Banco). Além disso há consultas com **erro explícito** (`buscar`, módulo `DIAGNOSTICO`).
- A coleção é uma **lista com `assoc` e `id:`** (monóide), e não a lista recursiva `Item Acervo`.
- Todos os identificadores estão em **português**.

---

## 2. Descrição informal e abstração

### 2.1 Entidades

| Entidade | Representação | Atributos |
|---|---|---|
| Identificador de livro | `livro(Nat)`, sort `IdLivro` | número |
| Identificador de usuário | `usuario(Nat)`, sort `IdUsuario` | número |
| Status | `disponivel` \| `emprestado(IdUsuario)` | quem está com o livro |
| Livro (item do acervo) | `item(IdLivro, String, Status)` | id único, título, status |
| Acervo | lista de itens (monóide) | |
| Usuários | lista de `IdUsuario` (monóide) | |
| Empréstimo | **não é uma entidade separada**: é o status `emprestado(U)` do item | |
| Biblioteca (estado) | `biblioteca(Acervo, Usuarios)` | |

### 2.2 Funcionalidades

| Fn | Operador | Tipo |
|---|---|---|
| F1 Adicionar livro | `addLivro` | modificador |
| F2 Remover livro | `removerLivro` | modificador |
| F3 Registrar usuário | `registrarUsuario` | modificador |
| F4 Remover usuário | `removerUsuario` | modificador |
| F5 Emprestar | `emprestar` | modificador |
| F6 Devolver | `devolver` | modificador |
| F7 Livro pertence ao acervo? | `pertence?` | predicado |
| F8 Livro disponível? | `disponivel?` | predicado |
| F9 Usuário possui livro? | `possui?` | predicado |
| F10 Quantidade no acervo | `totalLivros` | consulta |
| F11 Quantidade emprestada | `qtdEmprestados` | consulta |

### 2.3 Regras

| Regra | Enunciado resumido | Imposta por |
|---|---|---|
| R1 | Só empresta o que pertence ao acervo | guarda `podeEmprestar?` |
| R2 | Não empresta o que já está emprestado | guarda `podeEmprestar?` |
| R3 | Devolução torna o livro disponível | equação de `devolver` (`definirStatus(.., disponivel)`) |
| R4 | Só devolve quem tem o livro | guarda `podeDevolver?` |
| R5 | Só remove livro disponível | guarda `podeRemoverLivro?` |
| R6 | Id de livro único | guarda `podeAddLivro?` **e** invariante `idsUnicos?` |
| R7 | #disp + #emp = #total | invariante `contagemOk?` (provado para todo estado) |

**Regras extras e justificativas**

| Regra | Descrição | Justificativa |
|---|---|---|
| E1 | Não registrar usuário duplicado | Sem isso, "o usuário" deixaria de ser bem definido (consulta e remoção ambíguas). |
| E2 | Não remover usuário com livros emprestados | Evita empréstimos "órfãos" (livro emprestado a quem não existe mais). |
| E3 | Só emprestar a usuário registrado | Consequência natural de E2: todo dono de empréstimo está registrado. |
| E4 | Limite de 3 empréstimos por usuário (`limiteEmprestimos`) | Mostra uma regra numérica com `Nat`; 3 ainda permite "vários livros simultâneos". |

### 2.4 Decisões de abstração (o que foi ignorado)

Datas, prazos, multas, reservas, renovações, autores/ISBN/categorias, **múltiplos exemplares do mesmo título** (cada exemplar é um livro com id próprio), histórico de empréstimos, perfis de usuário, autenticação e concorrência. Ver 10.3.

---

## 3. Assinatura

### 3.1 Sorts e subsorts

| Sort | Módulo | Papel |
|---|---|---|
| `IdLivro`, `IdUsuario`, `Status`, `Item` | `LIVRO-USUARIO` | dados atômicos |
| `Acervo`, `ItemOuErro` | `ACERVO` | coleção; resultado de busca |
| `Usuarios` | `USUARIOS` | coleção de usuários |
| `Biblioteca` | `BIBLIOTECA` | estado global |
| `Diagnostico` | `DIAGNOSTICO` | erro explícito |

Subsorts: `Item < Acervo`, `Item < ItemOuErro`, `IdUsuario < Usuarios`. Importados: `Nat`, `String`, `Bool`.

### 3.2 Construtores versus operadores definidos

| Categoria | Operadores |
|---|---|
| **Construtores** `[ctor]` | `livro`, `usuario`, `disponivel`, `emprestado`, `item`, `nilA`, `_;_`, `livroInexistente`, `nilU`, `_&_`, `biblioteca`, `ok`, `err…` (9 constantes de `Diagnostico`) |
| **Definidos** (sem `[ctor]`) | `getId`, `getTitulo`, `getStatus`, `comStatus`, `itemDisponivel?`, `itemDe?`, `totalA`, `qtdDisponiveisA`, `qtdEmprestadosA`, `existeA?`, `disponivelA?`, `possuiA?`, `buscarA`, `livrosDeA`, `idsUnicosA?`, `removerA`, `definirStatus`, `totalU`, `existeU?`, `removerU`, `unicosU?`, `bibliotecaVazia`, `limiteEmprestimos`, todas as consultas, guardas, modificadores e invariantes de `BIBLIOTECA`, `donosRegA?`, `diag…` |

### 3.3 CONTRATO DA ASSINATURA

Legenda de categoria: **C** construtor, **Q** consulta, **M** modificador, **P** predicado de guarda, **I** invariante, **A** auxiliar.

| Operador | Aridade | Cat. | Equações | Regra(s) |
|---|---|---|---|---|
| `livro` / `usuario` | `Nat -> IdLivro` / `-> IdUsuario` | C | — | R6 (tipos distintos) |
| `disponivel` | `-> Status` | C | — | R3 |
| `emprestado` | `IdUsuario -> Status` | C | — | R2, R4 |
| `item` | `IdLivro String Status -> Item` | C | — | R6 |
| `getId`, `getTitulo`, `getStatus` | `Item -> …` | A | 1 cada | — |
| `comStatus` | `Item Status -> Item` | A | 1 | R3 |
| `itemDisponivel?`, `itemDe?` | `Item (IdUsuario) -> Bool` | A | 2 cada | R2, R4 |
| `nilA`, `_;_` | `-> Acervo`, `Acervo Acervo -> Acervo` | C | axiomas `assoc id:` | monóide |
| `livroInexistente` | `-> ItemOuErro` | C | — | erro de busca |
| `totalA` | `Acervo -> Nat` | Q | vazio, não vazio | R7 |
| `qtdDisponiveisA`, `qtdEmprestadosA` | `Acervo -> Nat` | Q | vazio + 2 casos de status | R7 |
| `existeA?`, `disponivelA?`, `possuiA?` | `Acervo … -> Bool` | Q | vazio, não vazio (cabeça/resto) | R1, R2, R4 |
| `buscarA` | `Acervo IdLivro -> ItemOuErro` | Q | vazio → erro; não vazio | erro de busca |
| `livrosDeA` | `Acervo IdUsuario -> Acervo` | Q | vazio; não vazio | E2, E4 |
| `idsUnicosA?` | `Acervo -> Bool` | I | vazio; não vazio | R6 |
| `removerA` | `Acervo IdLivro -> Acervo` | A | vazio; achou; não achou | R5 |
| `definirStatus` | `Acervo IdLivro Status -> Acervo` | A | vazio; achou; não achou | R3 |
| `nilU`, `_&_` | `Usuarios` | C | axiomas `assoc id:` | monóide |
| `totalU`, `existeU?`, `removerU`, `unicosU?` | `Usuarios … ` | Q/A/I | vazio; não vazio | E1, E2 |
| `biblioteca` | `Acervo Usuarios -> Biblioteca` | C | — | estado |
| `bibliotecaVazia`, `limiteEmprestimos` | constantes | A | 1 cada | E4 |
| `totalLivros`, `qtdEmprestados`, `qtdDisponiveis`, `totalUsuarios` | `Biblioteca -> Nat` | Q | 1 cada | F10, F11, R7 |
| `pertence?`, `disponivel?`, `possui?`, `existeUsuario?` | `Biblioteca … -> Bool` | Q | 1 cada | F7, F8, F9 |
| `buscar` | `Biblioteca IdLivro -> ItemOuErro` | Q | 1 | erro de busca |
| `livrosDe`, `qtdDe` | `Biblioteca IdUsuario -> Acervo / Nat` | Q | 1 cada | E2, E4 |
| `podeAddLivro?` | `Biblioteca IdLivro -> Bool` | P | 1 | R6 |
| `podeRemoverLivro?` | idem | P | 1 | R5 |
| `podeRegistrar?`, `podeRemoverUsuario?` | `Biblioteca IdUsuario -> Bool` | P | 1 cada | E1, E2 |
| `podeEmprestar?` | `Biblioteca IdLivro IdUsuario -> Bool` | P | 1 | R1, R2, E3, E4 |
| `podeDevolver?` | idem | P | 1 | R4 |
| `addLivro` | `Biblioteca IdLivro String -> Biblioteca` | M | 1 (`if`) | F1, R6 |
| `removerLivro` | `Biblioteca IdLivro -> Biblioteca` | M | 1 (`if`) | F2, R5 |
| `registrarUsuario`, `removerUsuario` | `Biblioteca IdUsuario -> Biblioteca` | M | 1 cada (`if`) | F3, F4, E1, E2 |
| `emprestar`, `devolver` | `Biblioteca IdLivro IdUsuario -> Biblioteca` | M | 1 cada (`if`) | F5, F6, R1–R4, E3, E4 |
| `idsUnicos?`, `usuariosUnicos?`, `contagemOk?`, `donosRegistrados?` | `Biblioteca -> Bool` | I | 1 cada | R6, E1, R7, E3 |
| `invariante?` | `Biblioteca -> Bool` | I | 1 | R6 ∧ R7 ∧ E1 ∧ E3 |
| `donosRegA?` | `Acervo Usuarios -> Bool` | A | vazio; 2 status | E3 |
| `diagAddLivro`, `diagRemoverLivro`, `diagRegistrar`, `diagRemoverUsuario`, `diagEmprestar`, `diagDevolver` | `Biblioteca … -> Diagnostico` | Q | 1 cada | erro explícito |

### 3.4 Variáveis

Todas declaradas com sort, agrupadas por sort e por módulo. Exemplos de `ACERVO`: `var A : Acervo . var I : Item . vars L L1 : IdLivro . vars U : IdUsuario . var T : String . var S : Status .` Em `BIBLIOTECA`: `var B : Biblioteca . var Us : Usuarios .`, e assim por diante.

---

## 4. Estruturas de dados algébricas

### 4.1 Acervo como monóide

```maude
op nilA : -> Acervo [ctor] .
op _;_  : Acervo Acervo -> Acervo [ctor assoc id: nilA] .
```

`(Acervo, _;_, nilA)` é um **monóide**: a operação é **associativa**, `(a ; b) ; c = a ; (b ; c)`, e `nilA` é **elemento neutro**, `nilA ; a = a = a ; nilA`. Os atributos `assoc` e `id: nilA` declaram essas duas leis. Efeitos formais:

1. **Termos equivalentes são o mesmo elemento.** Os parênteses de `;` não importam, e `nilA` some. Uma lista de 3 itens é um único termo "achatado".
2. **Equações valem módulo as leis.** O padrão `I ; A` (com `I : Item`, `A : Acervo`) casa com todo acervo não vazio, tomando `I` como o primeiro item e `A` como o resto. Para um acervo unitário, `A = nilA`. Assim bastam **duas** equações por operador recursivo, "vazio" e "cabeça + resto".
3. **O casamento é determinístico.** Como `_;_` não é comutativo, `I ; A` só casa tomando o primeiro item. A ordem de inserção (cronológica, `A ; novo`) é preservada.

`Usuarios` (`nilU`, `_&_`) é um segundo monóide, construído da mesma forma. A escolha por `assoc id:` em vez da lista recursiva `Item Acervo` simplifica a concatenação (`A ; item(...)`) e torna o monóide explícito na assinatura, ao custo de o casamento ser equacional (mais sofisticado). Funcionou sem problema de terminação ou confluência, e o teste aleatório (seção 8.4) confirma.

### 4.2 Relação usuário–livro via `Status`

A relação não é uma tabela à parte: está **dentro do dado**. Cada `item` carrega `disponivel` ou `emprestado(U)`. Vantagens:

- A unicidade do dono é automática: um livro tem um único status.
- **R7 fica não trivial**: `qtdDisponiveisA` e `qtdEmprestadosA` são computadas por equações separadas, e `contagemOk?` as soma e compara com `totalA`.
- "Vários livros por usuário" é natural: vários itens com `emprestado(U)` (`livrosDe`).

### 4.3 Erro de busca

`ItemOuErro` é supersort de `Item` com a constante `livroInexistente`, análogo a `ContaOuErro`/`contaInexistente` do exemplo do Banco.

---

## 5. Equações

Padrão geral: **projeções e consultas** por recursão sobre o monóide; **modificadores** `if podeX? then novo else B fi`.

### 5.1 Casos cobertos por operador recursivo

| Operador | Vazio (`nilA`) | Não vazio | Elemento não existe | Fronteira |
|---|---|---|---|---|
| `totalA` | `0` | `1 + totalA(A)` | n/a | unitário: `totalA(I ; nilA) = 1` |
| `qtdDisponiveisA` / `qtdEmprestadosA` | `0` | 2 casos (um por construtor de `Status`) | n/a | idem |
| `existeA?` | `false` | `(getId(I) == L) or existeA?(A, L)` | percorre tudo → `false` | primeiro/último |
| `disponivelA?` | `false` | `if getId(I)==L then itemDisponivel?(I) else … fi` | `false` | primeiro/último |
| `possuiA?` | `false` | `if getId(I)==L then itemDe?(I,U) else … fi` | `false` | idem |
| `buscarA` | `livroInexistente` | `if getId(I)==L then I else buscarA(A,L) fi` | `livroInexistente` | idem |
| `livrosDeA` | `nilA` | `if itemDe?(I,U) then I ; … else … fi` | `nilA` | idem |
| `idsUnicosA?` | `true` | `not existeA?(A, getId(I)) and idsUnicosA?(A)` | n/a | unitário |
| `removerA` | `nilA` | `if getId(I)==L then A else I ; removerA(A,L) fi` | acervo inalterado | remove primeiro/meio/último |
| `definirStatus` | `nilA` | `if getId(I)==L then comStatus(I,S) ; A else I ; … fi` | acervo inalterado | idem |

### 5.2 Como cada regra vira equação, guarda ou invariante

```maude
*** R1 (pertence), R2 (disponível), E3 (usuário registrado), E4 (limite)
eq podeEmprestar?(B, L, U) =
   existeUsuario?(B, U) and pertence?(B, L) and disponivel?(B, L)
   and (qtdDe(B, U) < limiteEmprestimos) .

eq emprestar(biblioteca(A, Us), L, U) =
   if podeEmprestar?(biblioteca(A, Us), L, U)
   then biblioteca(definirStatus(A, L, emprestado(U)), Us)
   else biblioteca(A, Us) fi .

*** R4: só devolve o livro emprestado a ESSE usuário
eq podeDevolver?(B, L, U) = possui?(B, U, L) .

*** R5: só remove se pertence e está disponível
eq podeRemoverLivro?(B, L) = pertence?(B, L) and disponivel?(B, L) .

*** R6: id novo
eq podeAddLivro?(B, L) = not pertence?(B, L) .

*** R7: (#disp + #emp) == #total
eq contagemOk?(B) = (qtdDisponiveis(B) + qtdEmprestados(B)) == totalLivros(B) .
```

R3 está na equação de `devolver`, que chama `definirStatus(A, L, disponivel)`.

---

## 6. Situações inválidas

Política: **estado inalterado** (guarda `podeX?` falsa ⇒ equação devolve o próprio `biblioteca(A, Us)`). O erro explícito está em `diagX` (`ok` ou `err…`) e em `buscar`.

| # | Situação inválida | Regra | Tratamento | Termo (teste) |
|---|---|---|---|---|
| I1 | Emprestar livro inexistente | R1 | inalterado; `errLivroInexistente` | [36], [54] |
| I2 | Emprestar livro já emprestado (a outro ou ao mesmo usuário) | R2 | inalterado; `errLivroJaEmprestado` | [37], [38], [55] |
| I3 | Devolver livro não emprestado | R4 | inalterado; `errNaoEmprestadoAoUsuario` | [39] |
| I4 | Devolver livro emprestado a **outro** usuário | R4 | inalterado; `errNaoEmprestadoAoUsuario` | [40], [59] |
| I5 | Remover livro emprestado (e inexistente) | R5 | inalterado; `errLivroEmprestado` / `errLivroInexistente` | [41], [42], [60] |
| I6 | Adicionar livro com id repetido | R6 | inalterado; `errIdRepetido` | [43], [44], [61] |
| I7 | Registrar usuário repetido | E1 | inalterado; `errUsuarioRepetido` | [45], [62] |
| I8 | Emprestar a usuário não registrado | E3 | inalterado; `errUsuarioInexistente` | [46], [56] |
| I9 | Remover usuário com livros (e inexistente) | E2 | inalterado; `errUsuarioComLivros` | [47], [48], [63] |
| I10 | Exceder o limite de empréstimos | E4 | inalterado; `errLimiteExcedido` | [49], [57] |
| I11 | Busca de livro inexistente | — | valor de erro `livroInexistente` | [18] |

---

## 7. Implementação em Maude

### 7.1 Organização em camadas

```
LIVRO-USUARIO ──> ACERVO ────────┐
              └─> USUARIOS ──────┴─> BIBLIOTECA ──> DIAGNOSTICO
```

Cada `fmod` usa `protecting` (importa sem alterar a semântica dos sorts importados: sem "lixo" nem identificação indevida). O arquivo é carregado com `load biblioteca.maude`.

### 7.2 Mecanismos Maude e seu significado formal

| Mecanismo | Significado formal | Onde |
|---|---|---|
| `fmod … endfm` | Módulo funcional: a semântica é a **álgebra inicial** \(T_{\Sigma/E}\). Dois termos fechados são iguais sse deduzíveis de `E` (módulo axiomas). Reescrever orientado ⇒ forma normal. | todos |
| `protecting M` | Importação que preserva a álgebra inicial de `M` (sem novos valores nem colapsos). | todos |
| `sort`, `subsort A < B` | `A ⊆ B` entre carregadores; um `A` pode ocupar lugar de `B`. | `Item < Acervo`, `Item < ItemOuErro`, `IdUsuario < Usuarios` |
| `[ctor]` | Marca o operador como construtor (\(\Sigma_C\)). Não muda a semântica; delimita os valores canônicos e permite verificar suficiente completude. | construtores |
| `assoc` | \((x * y) * z = x * (y * z)\). Os termos são classes módulo associatividade, e o casamento é feito sobre listas achatadas. | `_;_`, `_&_` |
| `id: e` | `e` é neutro: \(e * x = x = x * e\). Com `assoc`, define **monóide**. Permite `A = nilA` em `I ; A`. | `_;_`, `_&_` |
| `if_then_else_fi` | `if true then a else b fi = a`; `if false then a else b fi = b`. Implementa as **guardas** de forma explícita. | modificadores, buscas |
| `==`, `=/=` | Igualdade/desigualdade entre formas normais (decidível: o sistema é terminante e confluente). | testes e guardas |
| `ceq l = r if c` *(não usado)* | Equação condicional: `l = r` vale quando `c` reduz a `true`. Equivale ao `if`. | — |
| `[owise]` *(não usado)* | Aplica a equação só se nenhuma outra casar. Não foi necessário, pois todas as equações têm padrões disjuntos. | — |
| `rl` *(só na verificação)* | Regra de reescrita não equacional. A especificação é **equacional**; `rl` aparece apenas em `verificacao.maude`, para o `search`. | 8.4 |

### 7.3 Trecho: um modificador completo

```maude
eq addLivro(biblioteca(A, Us), L, T) =
   if podeAddLivro?(biblioteca(A, Us), L)
   then biblioteca(A ; item(L, T, disponivel), Us)
   else biblioteca(A, Us) fi .
```

### 7.4 Pontos de atenção encontrados na prática

- Em Maude, uma linha `*** (` abre **comentário de bloco**, mesmo com espaço. A demo usa `*** [n]` em vez de `*** (n)`.
- Ao imprimir, o Maude reordena operandos comutativos de `Nat` (`1 + totalLivros(lib0)`). Isso só afeta a exibição.

---

## 8. Parte experimental

Execução: `cd src && maude -no-banner demo-biblioteca.maude`, Maude 3.5.1. O log completo está em `docs/execucao/log-demo.txt`. Ao final dos testes, o módulo `CONFERENCIA` (também em Maude) repete cada teste `[n]` como uma equação `tN` que compara o resultado com o valor esperado; as seções A a G e `todos?` reduzem a `true`: **75 testes, 0 divergências**, sem nenhum `Warning`.

### 8.1 Estados usados

- `lib0`: 4 usuários (`ana`=1, `bruno`=2, `carla`=3, `davi`=4) e 5 livros (l1 "Dom Casmurro", l2 "Memorias Postumas", l3 "Grande Sertao Veredas", l4 "Vidas Secas", l5 "Capitaes da Areia").
- `lib1` (história `h1…h7`): entra l6 "O chamado de Cthulhu"; Ana pega l1, l2, l4; Bruno pega l3 e devolve; Carla pega l3. Resultado: 6 livros, 4 emprestados, 2 disponíveis.
- `pequena`: 1 livro, 1 usuário (para os traces).
- `ruim1`, `ruim2`, `ruim3`: estados montados à mão, **inválidos**.

### 8.2 Resultados (saídas reais do Maude)

| Teste | Regra / propriedade | Termo (resumido) | Resultado |
|---|---|---|---|
| [1] | F10 | `totalLivros(lib0)` | `5` |
| [2] | F3 | `totalUsuarios(lib0)` | `4` |
| [3]/[4] | F7 | `pertence?(lib0, l1)` / `(lib0, l6)` | `true` / `false` |
| [5] | F8 | `disponivel?(lib0, l1)` | `true` |
| [6]/[7] | F11, R7 | `qtdEmprestados(lib0)` / `qtdDisponiveis(lib0)` | `0` / `5` |
| [8]–[10] | | `totalLivros`, `qtdEmprestados`, `qtdDisponiveis` de `lib1` | `6`, `4`, `2` |
| [11]–[13] | F9 | `possui?(lib1, ana, l1)` / `(bruno, l3)` / `(carla, l3)` | `true` / `false` / `true` |
| [14]/[15] | F8 | `disponivel?(lib1, l1)` / `(lib1, l6)` | `false` / `true` |
| [16]/[17] | vazio | `totalLivros(bibliotecaVazia)` / `pertence?(…, l1)` | `0` / `false` |
| [18] | erro de busca | `buscar(lib0, l7)` | `livroInexistente` |
| [19] | busca | `buscar(lib1, l6)` | `item(livro(6), "O chamado de Cthulhu", disponivel)` |
| [20] | vários livros por usuário | `livrosDe(lib1, ana)` | 3 itens: `livro(1)`, `livro(2)`, `livro(4)`, todos `emprestado(usuario(1))` |
| [21]/[22] | | `qtdDe(lib1, ana)` / `livrosDe(lib1, davi)` | `3` / `nilA` |
| [23] | **Cthulhu** | `totalLivros(addLivro(lib0, l6, "O chamado de Cthulhu"))` | `6` |
| [24]–[26] | **P1** | `… == totalLivros(B) + 1` para `lib0`, `bibliotecaVazia`, `lib1` | `true` ×3 |
| [27]/[28] | composto (R3, R5) | `emprestar → devolver → removerLivro` de l5: total / pertence | `4` / `false` |
| [29]/[30] | **R3** | `disponivel?` após emprestar / após devolver | `false` / `true` |
| [31] | **P2** | `devolver(emprestar(lib0,l1,ana),l1,ana) == lib0` | `true` |
| [32]–[35] | F2–F4, fronteiras | remover 1 / único / primeiro-meio-último; registrar+remover usuário | `true` ×4 |
| [36] | **R1** (I1) | `emprestar(lib0, l7, ana) == lib0` | `true` |
| [37]/[38] | **R2** (I2) | `emprestar(lib1, l1, bruno) == lib1` / `(…, l1, ana)` | `true` ×2 |
| [39]/[40] | **R4** (I3, I4) | `devolver(lib0,l1,ana) == lib0` / `devolver(lib1,l1,bruno) == lib1` | `true` ×2 |
| [41]/[42] | **R5** (I5) | `removerLivro(lib1, l1) == lib1` / `(lib0, l7) == lib0` | `true` ×2 |
| [43]/[44] | **R6** (I6) | `addLivro(lib0, l1, …) == lib0` / `totalLivros(…)` | `true` / `5` |
| [45]–[50] | E1, E3, E2, E4, fronteira | inválidos extras mantêm o estado | `true` ×6 |
| [51] | operação válida muda o estado | `qtdEmprestados(emprestar(lib1, l5, bruno))` | `5` |
| [52]/[53] | guardas | `podeEmprestar?(lib1,l5,ana)` / `(…,bruno)` | `false` / `true` |
| [54]–[63] | diagnóstico | `diagX(...)` | `errLivroInexistente`, `errLivroJaEmprestado`, `errUsuarioInexistente`, `errLimiteExcedido`, `ok`, `errNaoEmprestadoAoUsuario`, `errLivroEmprestado`, `errIdRepetido`, `errUsuarioRepetido`, `errUsuarioComLivros` |
| [64] | guarda ⇔ diagnóstico | `podeDevolver? == (diagDevolver == ok)` | `true` |
| [65]–[68] | **R7** | `lib0`, `lib1`, `h1…h7`, após inválidas e remoções | `true` ×4 |
| [69]/[70] | **P4, P5** | `invariante?` na história e após operações | `true` ×2 |
| [71]/[72] | **R6** (estado à mão) | `idsUnicos?(ruim1)` / `invariante?(ruim1)` | `false` / `false` |
| [73]/[74] | R6/E1 (estado à mão) | `donosRegistrados?(ruim2)` / `usuariosUnicos?(ruim3)` | `false` / `false` |
| [75] | R7 por construção | `contagemOk?(ruim1) and contagemOk?(ruim2)` | `true` |

São **75 termos**: 17 básicos e de fronteira ([1]–[17]), 5 de busca e livros de um usuário ([18]–[22]), 4 do exemplo-guia ([23]–[26]), 9 compostos ([27]–[35]), 15 **inválidos** ([36]–[50], cobrindo I1–I10) mais 1 operação válida de contraste ([51]), 13 de guardas e diagnóstico ([52]–[64]) e 11 de R7 e invariantes ([65]–[75]).

Exemplo de saída literal do Maude (teste [20]):

```
reduce in DEMO-BIBLIOTECA : livrosDe(lib1, ana) .
rewrites: 928 in 0ms cpu (0ms real) (~ rewrites/second)
result Acervo: item(livro(1), "Dom Casmurro", emprestado(usuario(1))) ; item(
    livro(2), "Memorias Postumas", emprestado(usuario(1))) ; item(livro(4),
    "Vidas Secas", emprestado(usuario(1)))
```

### 8.3 Reescrita passo a passo — exemplo-guia

Com `B = biblioteca(item(livro(1), "Dom Casmurro", disponivel), usuario(1))`, o termo `totalLivros(addLivro(B, livro(6), "O chamado de Cthulhu"))` foi reduzido com `set trace on` (teste [T1]; 20 reescritas, resultado `2`). Derivação extraída do trace real (nomes das equações do código):

| Passo | Termo | Equação aplicada |
|---|---|---|
| 1 | `totalLivros(addLivro(B, l6, "…"))` → `totalLivros(if podeAddLivro?(B, l6) then B' else B fi)` | `addLivro` |
| 2 | `podeAddLivro?(B, l6)` → `not pertence?(B, l6)` | `podeAddLivro?` (R6) |
| 3 | `pertence?(B, l6)` → `existeA?(item(l1,…), l6)` | `pertence?` |
| 4 | `existeA?(item(l1,…), l6)` → `existeA?(nilA, l6) or getId(item(l1,…)) == l6` | `existeA?` não vazio (`A = nilA`, **identidade do monóide**) |
| 5 | `existeA?(nilA, l6)` → `false`; `getId(item(l1,…))` → `livro(1)`; `livro(1) == livro(6)` → `false` | `existeA?` vazio; `getId`; `==` |
| 6 | `false or false` → `false`; `not false` → `true` | equações de `Bool` |
| 7 | `if true then B' else B fi` → `B' = biblioteca(item(l1,…) ; item(l6,…), usuario(1))` | `if_then_else_fi` |
| 8 | `totalLivros(B')` → `totalA(item(l1,…) ; item(l6,…))` | `totalLivros` |
| 9 | `totalA(I ; A)` → `1 + totalA(item(l6,…))` → `1 + (1 + totalA(nilA))` | `totalA` não vazio (2×) |
| 10 | `totalA(nilA)` → `0`; `0 + 1` → `1`; `1 + 1` → `2` | `totalA` vazio; `_+_` |

Instanciações da propriedade (testes [23]–[26]): `lib0` dá `5 + 1 = 6`; `bibliotecaVazia` (fronteira) dá `0 + 1 = 1`; `lib1` dá `6 + 1 = 7`. Todas satisfazem `totalLivros(addLivro(B, x)) = totalLivros(B) + 1`.

Outras duas reescritas passo a passo (no log): **[T2]** `contagemOk?` (R7), 14 equações aplicadas até `true`; **[T3]** `emprestar` com livro inexistente, em que a equação `if` escolhe o ramo `else` e devolve `B` (R1).

### 8.4 Verificação exaustiva com `search`

O arquivo `src/verificacao.maude` complementa os 75 termos. Nele, um módulo `DINAMICA` declara 28 regras de reescrita (`rl`), uma para cada operação aplicada a constantes (4 livros, 2 usuários): `rl [emp11] : B => emprestar(B, livro(1), usuario(1)) .` e assim por diante. As regras só servem para o `search` explorar estados; a especificação continua totalmente equacional. A partir de `bibliotecaVazia`, o `search` percorre **todos** os estados alcançáveis. Operações inválidas deixam o estado igual, então não criam estados novos. Resultado (log em `docs/execucao/log-verificacao.txt`):

| Busca | Resultado |
|---|---|
| V1: estado com `invariante?(B) =/= true` (R6, R7, E1, E3) | `No solution`, 6613 estados |
| V2: estado em que `podeX?`, `diagX == ok` e "o estado muda" discordam, ou P2/R3 falham, para todo par (livro, usuário) | `No solution`, 6613 estados |
| V3: usuário 1 com 3 livros (limite) | `Solution 1` (estado 1421) |
| V4: `diagEmprestar` dá `errLimiteExcedido` (E4) | `Solution 1` (estado 2701) |
| V5: `diagEmprestar` dá `errLivroJaEmprestado` (R2) | `Solution 1` (estado 44) |
| V6: `diagRemoverUsuario` dá `errUsuarioComLivros` (E2) | `Solution 1` (estado 42) |
| V7: os 4 livros emprestados | `Solution 1` (estado 5941) |

V1 e V2 usam `=/= true` e não `== false`, o que também acusaria um termo que não chegasse a construtores. V3 a V7 mostram que os estados interessantes são alcançáveis, ou seja, `No solution` em V1 e V2 não é um resultado vazio por engano. O espaço é finito (6613 estados) porque R6 impede ids repetidos; sem R6, o espaço seria infinito.

A verificação foi **validada por mutação**: em cópias de `biblioteca.maude` com um defeito de cada vez, V1 ou V2 (limitadas a `search [1,10]`) encontram um contraexemplo.

| Defeito injetado | Quem detecta |
|---|---|
| sem R6 (aceita id repetido) | V1 (estado 7) e V2 |
| sem E2 (remove usuário com livros) | V1 (estado 131) e V2 |
| sem E3 (empresta a usuário não registrado) | V1 (estado 12) e V2 |
| sem E4 (sem limite de empréstimos) | V2 (estado 2701) |
| sem R2 (empresta livro já emprestado) | V2 |
| sem R5 (remove livro emprestado) | V2 |
| sem R4 (devolve livro de outro usuário) | V2 |

O limite do método: a busca vale só para 4 livros e 2 usuários. Para tamanho arbitrário valem as provas por indução (seção 10).

---

## 9. Propriedades

Notação: `A` acervo, `B = biblioteca(A, Us)`.

**P1.** Se `¬existeA?(A, L)`, então `totalLivros(addLivro(B, L, T)) = totalLivros(B) + 1`.

*Lema 1:* `totalA(A ; C) = totalA(A) + totalA(C)`. Indução estrutural em `A`.
- Base `A = nilA`: `totalA(nilA ; C) = totalA(C) = 0 + totalA(C)` (identidade e equação de `totalA(nilA)`).
- Passo `A = I ; A'`: `totalA(I ; A' ; C) = 1 + totalA(A' ; C) = 1 + totalA(A') + totalA(C) = totalA(I ; A') + totalA(C)`, usando a hipótese de indução (HI).

*Prova de P1:* a guarda reduz a `true` (hipótese). Então `totalLivros(addLivro(B, L, T)) = totalA(A ; item(L,T,disponivel)) = totalA(A) + totalA(item(…)) = totalA(A) + 1`, pois `totalA(item ; nilA) = 1 + 0`. ∎

**P2.** Se `podeEmprestar?(B, L, U)`, então `devolver(emprestar(B, L, U), L, U) = B` e, em particular, `disponivel?(…, L) = true` (R3).

*Lema 2 (R3):* `disponivelA?(definirStatus(A, L, disponivel), L) = existeA?(A, L)`. Indução em `A`: vazio dá `false = false`. Em `I ; A'`, se `getId(I) = L`, o item vira disponível e `itemDisponivel?` dá `true`; caso contrário, aplica-se a HI ao resto.
*Lema 3:* `possuiA?(definirStatus(A, L, emprestado(U)), U, L) = existeA?(A, L)`. Mesma indução.
*Lema 4:* `definirStatus(definirStatus(A, L, S1), L, S2) = definirStatus(A, L, S2)`, e `definirStatus(A, L, S) = A` se o item `L` já tem status `S`. Indução em `A`.

*Prova de P2:* o empréstimo foi permitido, então `L ∈ A`, está disponível e `emprestar` produz `A1 = definirStatus(A, L, emprestado(U))`. Pelo Lema 3, `podeDevolver?` é verdadeira. Logo `devolver` produz `definirStatus(A1, L, disponivel) = definirStatus(A, L, disponivel)` (Lema 4), que é `A`, pois `L` já estava disponível (Lema 4, segunda parte). ∎ (Teste [31] instancia P2 forte.)

**P3 (guarda ⇒ estado inalterado).** Para todo modificador `m`, se `podeX?` reduz a `false`, então `m(B, …) = B`.
*Prova:* cada modificador é `if podeX?(…) then … else biblioteca(A, Us) fi`; pela equação `if false then a else b fi = b`, o resultado é `biblioteca(A, Us) = B`. ∎ **Idempotência:** `emprestar(emprestar(B,L,U),L,U) = emprestar(B,L,U)`, pois, após o 1º empréstimo válido, `L` não está mais disponível (Lema 2/3) e a 2ª chamada cai no ramo `else`.

**P4 (R7 preservado por todas as operações).**
*Lema 5:* para **todo** `A`, `qtdDisponiveisA(A) + qtdEmprestadosA(A) = totalA(A)`. Indução em `A`:
- Base: `0 + 0 = 0`.
- Passo `A = item(L,T,S) ; A'`, por casos nos **dois** construtores de `Status`: se `S = disponivel`, `(1 + qD(A')) + qE(A') = 1 + total(A')`; se `S = emprestado(U)`, `qD(A') + (1 + qE(A')) = 1 + total(A')`. Ambos usam a HI. ∎

Como o Lema 5 vale para **todo** acervo, `contagemOk?` vale para todo estado, e é portanto preservado por **toda** operação (que sempre produz um `Biblioteca`). A não trivialidade vem de o status só ter dois construtores. Para o invariante completo (R6, E1, E3):

| Operação | Por que preserva `invariante?` |
|---|---|
| `addLivro` | guarda garante id novo; Lema 6 abaixo |
| `removerLivro` | remover elemento de lista sem repetição mantém ausência de repetição; e o item removido estava disponível (sem dono) |
| `registrarUsuario` | guarda garante usuário novo (`unicosU?` preservado) |
| `removerUsuario` | guarda exige `qtdDe(U) = 0`, então nenhum item aponta para `U`; `donosRegistrados?` preservado |
| `emprestar` | guarda exige usuário registrado (E3) e livro disponível |
| `devolver` | só troca `emprestado(U)` por `disponivel`; ids e usuários não mudam |

**P5.** Se `idsUnicos?(B)` e `podeAddLivro?(B, L)`, então `idsUnicos?(addLivro(B, L, T))`.
*Lema 6:* `idsUnicosA?(A ; I) = idsUnicosA?(A) ∧ ¬existeA?(A, getId(I))`. Indução em `A`: base `idsUnicosA?(I) = ¬existeA?(nilA, …) ∧ true = true`; passo por `existeA?` sobre `I' ; A'` e a HI. A guarda de R6 fornece o segundo conjunto. ∎

*Observação técnica:* propriedades com variável livre (ex.: `b : Biblioteca`) não reduzem em Maude, porque as guardas dependem da forma de `b`. Por isso as provas são por indução (acima), e **validadas com instâncias concretas** na demo (testes [24]–[31], [65]–[70]) e com a verificação exaustiva (8.4).

---

## 10. Análise da especificação

### 10.1 (i) Por que esses sorts e operadores?

Um sort por papel do domínio: **identificadores distintos** (`IdLivro`, `IdUsuario`) evitam misturar livro e usuário; `Status` embute a relação usuário–livro no dado; `Item`/`Acervo`/`Usuarios` representam as coleções como monóides; `Biblioteca` junta o estado (duas coleções). Os operadores seguem o padrão do exemplo do Banco: construtores mínimos; **projeções** e **consultas** definidas por recursão; **modificadores** sempre guardados por predicados `podeX?`; **invariantes** (`idsUnicos?`, `contagemOk?`, `invariante?`) como predicados, e funções auxiliares por camada (`totalA`, `definirStatus`…) mantendo os módulos pequenos.

### 10.2 (ii) A especificação representa corretamente o sistema?

Sim, no nível de abstração escolhido. Cada funcionalidade F1–F11 tem um operador, e cada regra R1–R7 tem uma guarda ou invariante testado (seção 6 e 8). O comportamento foi checado por 75 termos e por uma busca em todos os 6613 estados alcançáveis com 4 livros e 2 usuários, e as propriedades P1–P5 foram provadas por indução e instanciadas. Duas escolhas merecem registro: o limite E4 é arbitrário (`3`), e `emprestar` ao mesmo usuário que já tem o livro é inválido (R2).

### 10.3 (iii) O que não foi representado

Datas, prazos e multas; reservas e filas de espera; renovação; múltiplos exemplares de um título como entidade única (cada exemplar é um livro com id próprio); autores, ISBN e categorias; histórico de empréstimos; perfis de usuário (professor, aluno) com limites diferentes; persistência e concorrência (duas operações simultâneas); remoção de usuário com preservação de histórico. Ids em `Nat` não validam formato.

### 10.4 (iv) Propriedades expressas

R1–R7 como guardas e invariantes; E1–E4; P1 (cardinalidade após inserção), P2 (devolver desfaz emprestar), P3 (guarda ⇒ estado inalterado, idempotência), P4 (R7 vale em todo estado e é preservado por todas as operações), P5 (unicidade de ids preservada por `addLivro`). Além disso, a equivalência `podeX? ⇔ diagX = ok ⇔ estado muda` foi verificada em 12000 casos (8.4).

### 10.5 (v) Como as operações inválidas são impedidas/representadas

1. **Estado inalterado**: todo modificador é `if podeX? then … else B fi`, logo uma operação inválida é a identidade (P3).
2. **Predicados `podeX?`**: tornam as pré-condições explícitas e consultáveis (`podeEmprestar?` agrega R1, R2, E3 e E4).
3. **Erro explícito**: `buscar` devolve `livroInexistente`, e `diagX` retorna a constante de erro que identifica **qual** pré-condição falhou. Não confundir com exceção: o erro é um valor da álgebra.
4. **Invariantes** (`invariante?`): detectam estados corrompidos, montados à mão, que as operações nunca produzem ([71]–[74]).

---

## 11. Conclusão

A cadeia **informal → abstração → assinatura → equações → termos → propriedades** foi percorrida inteira. A biblioteca é uma álgebra de construtores (`biblioteca`, `item`, `_;_`, `_&_`, `emprestado`, …) com operadores definidos por equações confluentes e terminantes, onde dois monóides representam as coleções e o `Status` embute a relação usuário–livro. A política de **estado inalterado** torna as operações totais e seguras, enquanto os diagnósticos explicam as falhas. As execuções reais (75 termos, 0 divergências, 0 avisos) e a busca em 6613 estados sem violação do invariante sustentam as provas por indução.

**Limitações do trabalho:** a suficiente completude não foi checada com a ferramenta SCC do Maude (só há evidência indireta, em V1); a busca exaustiva cobre apenas 4 livros e 2 usuários; as provas foram feitas em papel.

### Apêndice — Reprodução e arquivos

```bash
cd src
maude -no-banner demo-biblioteca.maude < /dev/null > ../docs/execucao/log-demo.txt
maude -no-banner verificacao.maude < /dev/null > ../docs/execucao/log-verificacao.txt
```

| Arquivo | Conteúdo |
|---|---|
| `src/biblioteca.maude` | 5 módulos: `LIVRO-USUARIO`, `ACERVO`, `USUARIOS`, `BIBLIOTECA`, `DIAGNOSTICO` (código completo) |
| `src/demo-biblioteca.maude` | `DEMO-BIBLIOTECA`, 75 testes numerados, `CONFERENCIA` (auto-conferência) e 3 traces |
| `src/verificacao.maude` | `COERENCIA` e `DINAMICA` (regras `rl`) com 7 buscas `search` |
| `docs/execucao/log-demo.txt` | log real completo |
| `docs/execucao/log-verificacao.txt` | saída das buscas de `verificacao.maude` |
| `docs/execucao/assinatura.txt` | `show sorts` e `show ops` do módulo final |
