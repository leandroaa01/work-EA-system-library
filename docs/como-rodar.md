# Como rodar e interpretar o resultado

## 1. Instalar o Maude

O projeto foi executado com **Maude 3.5.1**. Qualquer versão 3.x deve servir.

- **Download:** <https://github.com/maude-lang/Maude/releases> (há versões para Linux, macOS Intel e macOS Apple Silicon). Baixe o `.zip`, extraia e use o executável `maude` da pasta (ele precisa ficar junto do `prelude.maude`).
- **No macOS**, se aparecer aviso de segurança: `xattr -dr com.apple.quarantine <pasta>` e `chmod +x maude`.
- **Verificar:** `maude --version` deve imprimir a versão.

Nos exemplos abaixo, `maude` é o caminho do executável (ex.: `/tmp/maude/maude`).

## 2. Rodar

Os exemplos assumem a pasta `src/`. A demo também roda de outra pasta (ex.: `maude -no-banner src/demo-biblioteca.maude`), pois o `load` dentro do arquivo é relativo ao próprio arquivo. Já os comandos digitados no modo interativo (`load biblioteca.maude`) são relativos à pasta onde você abriu o Maude.

```bash
cd src
maude -no-banner demo-biblioteca.maude < /dev/null
```

`< /dev/null` faz o Maude sair sozinho ao fim do arquivo. Sem isso ele fica no prompt `Maude>`; saia com `q` ou `quit .`.

**Salvar o log:**

```bash
maude -no-banner demo-biblioteca.maude < /dev/null > ../docs/execucao/log-demo.txt
```

**Modo interativo** (para experimentar termos):

```bash
maude -no-banner biblioteca.maude
```

e digite, por exemplo:

```maude
reduce totalLivros(addLivro(bibliotecaVazia, livro(1), "Dom Casmurro")) .
```

Para usar as constantes da demo (`lib0`, `lib1`, `ana`, `l1`…), carregue a demo (`load demo-biblioteca.maude .`) e depois `reduce qtdEmprestados(lib1) .`.

## 3. Conferência automática (tudo em Maude)

No fim dos testes da demo existe o módulo `CONFERENCIA`. Cada teste `[n]` é repetido como uma equação `tn` que compara o resultado com o valor esperado, e as seções A a G são agrupadas. As últimas linhas da seção de testes são:

```maude
reduce secaoA? .
...
reduce secaoG? .
reduce todos? .
```

Saída esperada: **sete** `result Bool: true` (seis seções e `todos?`).

```
reduce in CONFERENCIA : todos? .
rewrites: 50615 in 0ms cpu (1ms real) (77039573 rewrites/second)
result Bool: true
```

Se alguma seção der `false`, reduza os testes dela um a um (`reduce t17 .`) até achar qual divergiu. Os números `tN` são os mesmos de `*** [N]` na demo.

**Verificação exaustiva (opcional):**

```bash
maude -no-banner verificacao.maude < /dev/null
```

O arquivo `verificacao.maude` define regras de reescrita (`rl`) que aplicam cada operação a qualquer estado e usa `search` para percorrer **todos** os estados alcançáveis com até 4 livros e 2 usuários. A saída esperada é:

```
No solution.
states: 6613  rewrites: 9161861 ...
No solution.
states: 6613  rewrites: 81205087 ...
Solution 1 (state 1421) ...
```

- As duas primeiras buscas procuram **contraexemplos** (estado que viola o invariante; estado em que guarda, diagnóstico e efeito discordam). `No solution.` significa que não existe nenhum nos 6613 estados.
- As cinco seguintes procuram estados **interessantes** (usuário no limite de 3 livros, empréstimo recusado por E4, etc.) e têm que achar `Solution 1`. Elas mostram que a primeira busca não está vazia por acaso.
- Usamos `rl` só nesse arquivo, para explorar estados. A especificação em si (`biblioteca.maude`) continua só com equações.

## 4. Como ler a saída do Maude

Cada `reduce` produz um bloco assim:

```
==========================================
reduce in DEMO-BIBLIOTECA : totalLivros(lib0) .
rewrites: 192 in 0ms cpu (0ms real) (4682926 rewrites/second)
result NzNat: 5
```

| Linha | Significado |
|---|---|
| `reduce in DEMO-BIBLIOTECA : …` | módulo e termo reduzido (o Maude pode reordenar `+`, como `1 + totalLivros(lib0)`) |
| `rewrites: N` | quantas aplicações de equações foram feitas até a forma normal |
| `result Sort: valor` | **forma normal** e seu sort |

**Sorts que aparecem:**

| `result` | Significa |
|---|---|
| `Bool: true` / `false` | predicado ou comparação com `==` |
| `NzNat: n` / `Zero: 0` | número natural não nulo / zero (ambos são `Nat`) |
| `Item: item(...)` | um livro encontrado |
| `ItemOuErro: livroInexistente` | busca falhou |
| `Acervo: item(...) ; item(...)` | lista de livros (`nilA` é a lista vazia) |
| `Biblioteca: biblioteca(acervo, usuarios)` | estado completo |
| `Diagnostico: ok` ou `err…` | resultado de `diagX` |

**Como ler um item:** `item(livro(1), "Dom Casmurro", emprestado(usuario(1)))` é o livro 1, de título "Dom Casmurro", emprestado ao usuário 1 (Ana).

**Testes com `== lib` (operações inválidas):** `emprestar(lib1, l1, bruno) == lib1` dando `true` significa que a operação foi recusada e o estado **não mudou**. Se desse `false`, o estado teria mudado, e a regra não estaria sendo respeitada.

## 5. Como ler o trace (reescrita passo a passo)

No fim da demo, `set trace on .` mostra cada equação aplicada:

```
*********** equation
eq totalA(I:Item ; A:Acervo) = 1 + totalA(A:Acervo) .
I:Item --> item(livro(1), "Dom Casmurro", disponivel)
A:Acervo --> item(livro(6), "O chamado de Cthulhu", disponivel)
totalA(item(...) ; item(...))
--->
1 + totalA(item(livro(6), "O chamado de Cthulhu", disponivel))
```

| Parte | Significado |
|---|---|
| `eq …` | a equação usada (do código ou *built-in* do Maude para `Bool`/`Nat`) |
| `X --> valor` | substituição: com que valores as variáveis casaram |
| termo antes de `--->` | termo reescrito |
| termo depois de `--->` | resultado do passo |

Cada bloco é **um passo**. A sequência de passos é a derivação `t → t' → … → valor`. O exemplo "Cthulhu" tem 20 reescritas e está explicado passo a passo em `relatorio.md` §8.3.

Algumas equações de `Bool` aparecem no trace (`or`, `xor`, `and`): são definições internas do Maude e não do código do projeto.

Para desligar: `set trace off .`.

## 6. Problemas comuns

| Sintoma | Causa e solução |
|---|---|
| `Warning: … no parse for term` | erro de digitação ou parênteses faltando no termo. Em termos aninhados, confira os parênteses |
| `Warning: … bad token` | comentário mal escrito. Uma linha `*** (` **abre comentário de bloco** no Maude; escreva `*** texto` ou `*** [n] texto` |
| `Warning: … unable to locate file: biblioteca.maude` | `load` digitado no modo interativo fora de `src/`. Faça `cd src` ou use o caminho (`load src/biblioteca.maude`) |
| `result Biblioteca: …` com termo que ainda tem `emprestar(...)`, `addLivro(...)` etc. | termo **não reduziu totalmente**: falta equação ou o termo está mal formado (kind sem sort) |
| `command not found: maude` | Maude fora do `PATH`. Use o caminho completo do executável |
| Maude abre e não sai | faltou `< /dev/null` ou `q` ao final do arquivo |
| Aviso de segurança no macOS | veja a seção 1 (`xattr`) |

## 7. Onde ver cada coisa

| Quero ver | Arquivo |
|---|---|
| Especificação (sorts, operadores, equações) | `src/biblioteca.maude` |
| Testes e termos de exemplo | `src/demo-biblioteca.maude` |
| Saída real de uma execução | `docs/execucao/log-demo.txt` |
| Resultado da verificação exaustiva (`search`) | `docs/execucao/log-verificacao.txt` |
| Verificação exaustiva | `src/verificacao.maude` |
| Sorts e operadores como o Maude os enxerga | `docs/execucao/assinatura.txt` |
| Explicação formal completa | `docs/relatorio.md` |
