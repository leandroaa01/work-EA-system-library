# Algebraic Structures - Library System

## Authors
This project was developed by Carlos Alberto de Lima Neto (<carlos.neto.087@ufrn.edu.br>), Eduardo Nestor Ferreira Marinho (<eduardo.marinho.108@ufrn.edu.br>), Guilherme Augusto Pondofe Santana (<guilherme.pondofe.107@ufrn.edu.br>), Leandro Andrade de Araujo (<leandro.andrade.401@ufrn.edu.br>), and Maria Fernanda Magalhaes Freitas (<fernanda.magalhaes.071@ufrn.edu.br>), as part of the *EA* course at UFRN.

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

4. (Optional) Check every `result` against the `*** esperado:` comments and run the randomized property test:

```bash
maude -no-banner demo-biblioteca.maude < /dev/null > ../docs/execucao/log-demo.txt
python3 verificar.py demo-biblioteca.maude ../docs/execucao/log-demo.txt
python3 fuzz.py maude 2000
```

## Layout

- `src/biblioteca.maude`: layered modules `LIVRO-USUARIO`, `ACERVO`, `USUARIOS`, `BIBLIOTECA`, `DIAGNOSTICO`.
- `src/demo-biblioteca.maude`: `DEMO-BIBLIOTECA` with 75 numbered tests and 3 step-by-step traces.
- `docs/relatorio.md`: the report (in Portuguese).
- `docs/execucao/`: real execution logs and the module signature.
