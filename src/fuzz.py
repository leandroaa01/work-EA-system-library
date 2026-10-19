#!/usr/bin/env python3
"""Teste aleatorio (semente fixa) da especificacao BIBLIOTECA.

Gera historicos aleatorios de operacoes (validas e invalidas) e verifica, com o
Maude de verdade:
  F1. invariante?(estado) == true            (P4, P5, R6, R7, E1, E3)
  F2. a forma normal de `estado` contem so construtores (suficiente completude)
  F3. podeX?(B,..) == (diagX(B,..) == ok)    (guarda coerente com diagnostico)
  F4. podeX?(B,..) == (opX(B,..) =/= B)      (P3: invalida => estado inalterado;
                                              valida => estado muda)
Tambem imprime quantos casos validos/invalidos cada guarda exercitou.

Uso: python3 fuzz.py [caminho-do-maude] [n-historicos] [dir-com-biblioteca.maude]
"""
import os
import random
import re
import subprocess
import sys
import tempfile

MAUDE = sys.argv[1] if len(sys.argv) > 1 else "maude"
N = int(sys.argv[2]) if len(sys.argv) > 2 else 300
BASE = sys.argv[3] if len(sys.argv) > 3 else os.path.dirname(os.path.abspath(__file__))
random.seed(2026)

CONSTRUTORES = {
    "biblioteca", "item", "livro", "usuario", "disponivel", "emprestado",
    "nilA", "nilU", "livroInexistente", "true", "false",
}
LIVROS, USUARIOS = 8, 3   # ids de livro 1..9 e de usuario 1..4 (colisoes e ausencias de proposito)


def L():
    return f"livro({random.randint(1, LIVROS + 1)})"


def U():
    return f"usuario({random.randint(1, USUARIOS + 1)})"


def passo(s):
    k = random.choice(["add", "rem", "reg", "remu", "emp", "emp", "emp", "emp", "dev"])
    if k == "add":
        return f'addLivro({s}, {L()}, "t{random.randint(0, 9)}")'
    if k == "rem":
        return f"removerLivro({s}, {L()})"
    if k == "reg":
        return f"registrarUsuario({s}, {U()})"
    if k == "remu":
        return f"removerUsuario({s}, {U()})"
    if k == "emp":
        return f"emprestar({s}, {L()}, {U()})"
    return f"devolver({s}, {L()}, {U()})"


def historico(n):
    s = "bibliotecaVazia"
    for u in range(1, USUARIOS + 1):          # prefixo: cadastra quase todos
        if random.random() < 0.85:
            s = f"registrarUsuario({s}, usuario({u}))"
    for l in range(1, LIVROS + 1):
        if random.random() < 0.85:
            s = f'addLivro({s}, livro({l}), "t{l}")'
    for _ in range(n):
        s = passo(s)
    return s


def checagens(s):
    l, u = L(), U()
    return [
        ("AddLivro", f"podeAddLivro?({s}, {l})", f"diagAddLivro({s}, {l})", f'addLivro({s}, {l}, "z")'),
        ("RemoverLivro", f"podeRemoverLivro?({s}, {l})", f"diagRemoverLivro({s}, {l})", f"removerLivro({s}, {l})"),
        ("Registrar", f"podeRegistrar?({s}, {u})", f"diagRegistrar({s}, {u})", f"registrarUsuario({s}, {u})"),
        ("RemoverUsuario", f"podeRemoverUsuario?({s}, {u})", f"diagRemoverUsuario({s}, {u})", f"removerUsuario({s}, {u})"),
        ("Emprestar", f"podeEmprestar?({s}, {l}, {u})", f"diagEmprestar({s}, {l}, {u})", f"emprestar({s}, {l}, {u})"),
        ("Devolver", f"podeDevolver?({s}, {l}, {u})", f"diagDevolver({s}, {l}, {u})", f"devolver({s}, {l}, {u})"),
    ]


def main():
    cmds, meta = [], []

    def cmd(c, tipo, s):
        cmds.append(f"reduce {c} .")
        meta.append((tipo, s))

    for _ in range(N):
        s = historico(random.randint(0, 14))
        cmd(f"invariante?({s})", "F1", s)
        cmd(s, "F2", s)
        for nome, pode, diag, op in checagens(s):
            cmd(f"{pode} == ({diag} == ok)", f"F3 {nome}", s)
            cmd(f"{pode} == ({op} =/= {s})", f"F4 {nome}", s)
            cmd(pode, f"STAT {nome}", s)

    with tempfile.NamedTemporaryFile("w", suffix=".maude", delete=False, dir=BASE) as f:
        f.write("load biblioteca.maude\n" + "\n".join(cmds) + "\nq\n")
        nome_arq = f.name
    try:
        out = subprocess.run([MAUDE, "-no-banner", "-no-advise", nome_arq],
                             capture_output=True, text=True, cwd=BASE).stdout
    finally:
        os.unlink(nome_arq)

    blocos = [b for b in out.split("==========================================") if "reduce in" in b]
    if len(blocos) != len(cmds):
        print(f"ERRO: {len(cmds)} comandos, {len(blocos)} resultados")
        return 1

    falhas, contagem, stat = 0, {}, {}
    for (tipo, s), b in zip(meta, blocos):
        m = re.search(r"result \S+: (.*)", b, re.S)
        r = m.group(1).replace("Bye.", "").strip() if m else "<sem resultado>"
        base = tipo.split()[0]
        contagem[base] = contagem.get(base, 0) + 1
        if base == "STAT":
            v = stat.setdefault(tipo.split()[1], {"true": 0, "false": 0})
            v[r] = v.get(r, 0) + 1
            continue
        if base == "F2":
            sem_strings = re.sub(r'"[^"]*"', '""', r)
            simbolos = set(re.findall(r"[A-Za-z_][A-Za-z0-9_?]*(?=\()|\b(?:nilA|nilU|disponivel|true|false)\b", sem_strings))
            ok = not (simbolos - CONSTRUTORES)
        else:
            ok = (r == "true")
        if not ok:
            falhas += 1
            print(f"FALHA {tipo}: {s}\n  resultado: {r[:200]}")

    print(f"{N} historicos; checagens: { {k: v for k, v in contagem.items() if k != 'STAT'} }; falhas: {falhas}")
    print("cobertura das guardas (valido/invalido):")
    for nome, v in stat.items():
        print(f"  {nome:15s} {v['true']:5d} / {v['false']:5d}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
