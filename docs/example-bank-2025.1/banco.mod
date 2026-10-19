-- Carrega conta.mod (que por sua vez carrega cliente.mod e transacao.mod)
in conta.mod

-- ============================================================
-- banco.mod: O Banco como uma lista de contas
-- ============================================================
mod! BANCO {
  protecting(CONTA)

  -- ContaOuErro é supersort de Conta: permite que a busca
  -- devolva um valor de erro quando a conta não existe
  [ Conta < ContaOuErro ]
  [ Banco ]

  -- Erro de busca
  op contaInexistente : -> ContaOuErro { ctor }

  -- Construtores da lista de contas (mesmo estilo do histórico)
  op nilB : -> Banco { ctor }
  op _;_  : Conta Banco -> Banco { ctor r-assoc }

  -- ----------------------------------------------------------
  -- Consultas
  -- ----------------------------------------------------------
  op numContas  : Banco -> Nat
  op existe?    : Banco Nat -> Bool
  op buscar     : Banco Nat -> ContaOuErro
  op saldoTotal : Banco -> Int
  op contasDe   : Banco String -> Banco       

  -- ----------------------------------------------------------
  -- Operações sobre o banco (por número de conta)
  -- Quando a conta não existe ou a operação é inválida,
  -- o banco permanece inalterado.
  -- ----------------------------------------------------------
  op abrirConta     : Banco Conta -> Banco
  op depositarEm    : Banco Nat Int String -> Banco
  op sacarDe        : Banco Nat Int String -> Banco
  op renderPoupancas : Banco String -> Banco
  op transferir     : Banco Nat Nat Int String -> Banco   -- origem, destino, valor, data

  -- Predicado de possibilidade de transferência
  op podeTransferir? : Banco Nat Nat Int -> Bool

  -- ----------------------------------------------------------
  -- Validade do banco: todas as contas válidas e números únicos
  -- ----------------------------------------------------------
  op valido?          : Banco -> Bool
  op todasValidas?    : Banco -> Bool
  op numerosUnicos?   : Banco -> Bool

  -- ----------------------------------------------------------
  -- Auxiliares
  -- ----------------------------------------------------------
  op podeSacarEm? : Banco Nat Int -> Bool
  op enviarDe     : Banco Nat Int String -> Banco
  op receberEm    : Banco Nat Int String -> Banco
  -- Débito/crédito de transferência numa conta (registram os
  -- tipos transferenciaEnviada / transferenciaRecebida no extrato)
  op enviar  : Conta Int String -> Conta
  op receber : Conta Int String -> Conta

  -- Variáveis
  var A      : Conta
  var B      : Banco
  vars N O Dst : Nat
  var V      : Int
  vars D Cpf : String
  -- variáveis para casar com o construtor conta(...)
  vars Num Ag : Nat
  var C       : Cliente
  vars Lim TaxOp TaxRend : Nat
  var S       : Int
  var T       : TipoConta
  var Hist    : ListaTransacoes

  -- ----------------------------------------------------------
  -- Consultas
  -- ----------------------------------------------------------
  eq numContas(nilB)  = 0 .
  eq numContas(A ; B) = 1 + numContas(B) .

  eq existe?(nilB, N)  = false .
  eq existe?(A ; B, N) = (getNumero(A) == N) or existe?(B, N) .

  eq buscar(nilB, N)  = contaInexistente .
  eq buscar(A ; B, N) = if getNumero(A) == N then A else buscar(B, N) fi .

  eq saldoTotal(nilB)  = 0 .
  eq saldoTotal(A ; B) = getSaldo(A) + saldoTotal(B) .

  eq contasDe(nilB, Cpf)  = nilB .
  eq contasDe(A ; B, Cpf) =
     if getCPF(getTitular(A)) == Cpf then A ; contasDe(B, Cpf) else contasDe(B, Cpf) fi .

  -- ----------------------------------------------------------
  -- Abertura: só abre se o número ainda não existe no banco
  -- ----------------------------------------------------------
  eq abrirConta(B, A) = if existe?(B, getNumero(A)) then B else A ; B fi .

  -- ----------------------------------------------------------
  -- Depósito e saque: percorrem a lista e reutilizam CONTA
  -- ----------------------------------------------------------
  eq depositarEm(nilB, N, V, D)  = nilB .
  eq depositarEm(A ; B, N, V, D) =
     if getNumero(A) == N then depositar(A, V, D) ; B
     else A ; depositarEm(B, N, V, D) fi .

  eq sacarDe(nilB, N, V, D)  = nilB .
  eq sacarDe(A ; B, N, V, D) =
     if getNumero(A) == N then sacar(A, V, D) ; B
     else A ; sacarDe(B, N, V, D) fi .

  -- ----------------------------------------------------------
  -- Rendimento em lote (corrente não é afetada, ver CONTA)
  -- ----------------------------------------------------------
  eq renderPoupancas(nilB, D)  = nilB .
  eq renderPoupancas(A ; B, D) = aplicarRendimento(A, D) ; renderPoupancas(B, D) .

  -- ----------------------------------------------------------
  -- Transferência
  --   A origem paga como num saque (corrente: valor + taxa;
  --   poupança: só o valor) e o destino recebe o valor integral.
  -- ----------------------------------------------------------
  eq podeSacarEm?(nilB, N, V)  = false .
  eq podeSacarEm?(A ; B, N, V) =
     if getNumero(A) == N then podeSacar?(A, V) else podeSacarEm?(B, N, V) fi .

  eq podeTransferir?(B, O, Dst, V) =
     existe?(B, Dst) and (O =/= Dst) and podeSacarEm?(B, O, V) .

  eq transferir(B, O, Dst, V, D) =
     if podeTransferir?(B, O, Dst, V)
     then receberEm(enviarDe(B, O, V, D), Dst, V, D)
     else B fi .

  eq enviarDe(nilB, N, V, D)  = nilB .
  eq enviarDe(A ; B, N, V, D) =
     if getNumero(A) == N then enviar(A, V, D) ; B
     else A ; enviarDe(B, N, V, D) fi .

  eq receberEm(nilB, N, V, D)  = nilB .
  eq receberEm(A ; B, N, V, D) =
     if getNumero(A) == N then receber(A, V, D) ; B
     else A ; receberEm(B, N, V, D) fi .

  eq enviar(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist), V, D) =
     conta(Num, Ag, C, S - (V + TaxOp), Lim, TaxOp, TaxRend, contaCorrente,
           transacao(D, transferenciaEnviada, V) | Hist) .
  eq enviar(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist), V, D) =
     conta(Num, Ag, C, S - V, Lim, TaxOp, TaxRend, contaPoupanca,
           transacao(D, transferenciaEnviada, V) | Hist) .

  eq receber(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist), V, D) =
     conta(Num, Ag, C, S + V, Lim, TaxOp, TaxRend, T,
           transacao(D, transferenciaRecebida, V) | Hist) .

  -- ----------------------------------------------------------
  -- Validade do banco
  -- ----------------------------------------------------------
  eq todasValidas?(nilB)  = true .
  eq todasValidas?(A ; B) = valida?(A) and todasValidas?(B) .

  eq numerosUnicos?(nilB)  = true .
  eq numerosUnicos?(A ; B) = not existe?(B, getNumero(A)) and numerosUnicos?(B) .

  eq valido?(B) = todasValidas?(B) and numerosUnicos?(B) .
}
