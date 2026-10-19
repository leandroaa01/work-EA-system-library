#!/usr/bin/env python3
"""Confere cada `result` do Maude contra o comentario `*** esperado:` da demo.

Uso: maude -no-banner demo-biblioteca.maude < /dev/null > log.txt
     python3 verificar.py demo-biblioteca.maude log.txt
"""
import re
import sys


def squash(s):
    return re.sub(r"\s+", "", s)


def main(demo_path, log_path):
    demo = open(demo_path, encoding="utf-8").read().split("*** TRACE-BEGIN")[0]
    esperados = []
    pendente = None
    for linha in demo.splitlines():
        m = re.match(r"\s*\*\*\* \[(\d+)\].*", linha)
        if m:
            numero = m.group(1)
        m = re.match(r"\s*\*\*\* esperado:\s*(.*)", linha)
        if m:
            pendente = m.group(1).strip()
        elif linha.startswith("reduce") and pendente is not None:
            esperados.append((numero, pendente))
            pendente = None

    log = open(log_path, encoding="utf-8").read()
    blocos = [b for b in log.split("==========================================") if "reduce in" in b]
    blocos = blocos[: len(esperados)]
    resultados = []
    for b in blocos:
        m = re.search(r"result \S+: (.*?)(?:\Z)", b, re.S)
        resultados.append(m.group(1) if m else "<SEM RESULTADO>")

    divergencias = 0
    if len(resultados) != len(esperados):
        print(f"ERRO: {len(esperados)} esperados, {len(resultados)} resultados")
        divergencias += 1
    for (numero, esp), obtido in zip(esperados, resultados):
        if squash(esp) != squash(obtido):
            divergencias += 1
            print(f"DIVERGENCIA [{numero}]: esperado={esp!r} obtido={obtido.strip()!r}")
    print(f"{len(esperados)} testes conferidos, {divergencias} divergencia(s)")
    return 1 if divergencias else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
