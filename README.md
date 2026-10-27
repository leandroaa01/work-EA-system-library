# Algebraic Structures - Library System

## Authors
This project was developed by Carlos Alberto de Lima Neto (<carlos.neto.087@ufrn.edu.br>), Eduardo Nestor Ferreira Marinho (<eduardonestormarinho228@gmail.com>), Guilherme Augusto Pondofe Santana (<guilherme.pondofe.107@ufrn.edu.br>), Leandro Andrade de Araujo (<leandro.andrade.401@ufrn.edu.br>), and Maria Fernanda Magalhaes Freitas (<fernanda.magalhaes.071@ufrn.edu.br>), as part of the *EA* course at UFRN.

## Compilling and Running
1 Clone this repository:

```bash
git clone https://github.com/leandroaa01/work-EA-system-library.git
```


2. Navigate to the project directory:

```bash
cd work-EA-system-library
```

3. Run the specification (requires [Maude](https://maude.cs.illinois.edu/) 3.x):

```bash
cd src
maude -no-banner demo-biblioteca.maude < /dev/null
```

   The last block of `reduce` commands of the test section (module `CONFERENCIA`) compares every test with its expected value and must print `true`.

4. (Optional) Run the exhaustive check of the invariant (everything in Maude, no extra tools):

```bash
maude -no-banner verificacao.maude < /dev/null
```

## Layout

- `src/biblioteca.maude`: layered modules `LIVRO-USUARIO`, `ACERVO`, `USUARIOS`, `BIBLIOTECA`, `DIAGNOSTICO`.
- `src/demo-biblioteca.maude`: `DEMO-BIBLIOTECA` with 75 numbered tests, the automatic check `CONFERENCIA` and 3 step-by-step traces.
- `src/verificacao.maude`: exhaustive check with `search` over all states reachable with 4 books and 2 users.
- `docs/relatorio.md`: the report (in Portuguese).
- `docs/resumo-projeto.md`: project summary and design decisions (what to explain).
- `docs/como-rodar.md`: how to run the code and read Maude's output.
- `docs/apresentacao.md`: presentation guide (script, demo, likely questions).
- `docs/slides/apresentacao-biblioteca.pptx`: presentation slides (with speaker notes).
- `docs/execucao/`: real execution logs and the module signature.
