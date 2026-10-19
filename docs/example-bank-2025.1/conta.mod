-- Carrega os arquivos cliente.mod e transacao.mod primeiro
in cliente.mod
in transacao.mod

-- ============================================================
-- conta.mod: Contas Bancárias (Corrente e Poupança)
-- ============================================================
mod! CONTA {
  protecting(CLIENTE)
  protecting(TRANSACAO)
  protecting(INT)

  [ TipoConta Conta ]

  -- Tipos de Conta
  ops contaCorrente contaPoupanca : -> TipoConta { ctor }

  -- Construtor (Número, Agência, Titular, Saldo, LimiteEspecial, TaxaOperacao, TaxaRendimento, Tipo, Histórico)
  op conta : Nat Nat Cliente Int Nat Nat Nat TipoConta ListaTransacoes -> Conta { ctor }

  -- Métodos de Criação (Factory Operations)
  op criarCorrente : Nat Nat Cliente Nat Nat -> Conta
  op criarPoupanca : Nat Nat Cliente Nat Nat -> Conta

  -- Projeções
  op getNumero         : Conta -> Nat
  op getAgencia        : Conta -> Nat
  op getTitular        : Conta -> Cliente
  op getSaldo          : Conta -> Int
  op getLimiteEspecial : Conta -> Nat
  op getTaxaOperacao   : Conta -> Nat
  op getTaxaRendimento : Conta -> Nat
  op getTipoConta      : Conta -> TipoConta
  op getHistorico      : Conta -> ListaTransacoes

  -- Predicado de possibilidade de saque
  op podeSacar?         : Conta Int -> Bool

  -- Predicado de validade
  op valida?            : Conta -> Bool

  -- Funcionais básicos
  op depositar          : Conta Int String -> Conta
  op sacar              : Conta Int String -> Conta
  op aplicarRendimento  : Conta String -> Conta

  -- Variáveis usadas
  vars Num Ag : Nat
  var C : Cliente
  vars Lim TaxOp TaxRend : Nat
  vars S Val : Int
  var T : TipoConta
  var Hist : ListaTransacoes
  var D : String

  -- Equações dos Métodos de Criação
   eq criarCorrente(Num, Ag, C, Lim, TaxOp) =
     conta(Num, Ag, C, 0, Lim, TaxOp, 0, contaCorrente, nilTX) .

   eq criarPoupanca(Num, Ag, C, TaxOp, TaxRend) =
     conta(Num, Ag, C, 0, 0, TaxOp, TaxRend, contaPoupanca, nilTX) .

  -- Equações das projeções
  eq getNumero(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))         = Num .
  eq getAgencia(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))        = Ag .
  eq getTitular(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))        = C .
  eq getSaldo(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))          = S .
  eq getLimiteEspecial(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist)) = Lim .
  eq getTaxaOperacao(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))   = TaxOp .
  eq getTaxaRendimento(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist)) = TaxRend .
  eq getTipoConta(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))      = T .
  eq getHistorico(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist))      = Hist .

  -- Equação do predicado de saque
   eq podeSacar?(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist), Val) =
     (S + Lim) >= (Val + TaxOp) and Val > 0 .

   eq podeSacar?(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist), Val) =
     S >= Val and Val > 0 .

  -- Equações do predicado de validade
  --   Corrente: o saldo nunca ultrapassa o limite especial (S >= -Lim)
  --   Poupança: o saldo nunca fica negativo e não há limite especial
   eq valida?(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist)) =
     S + Lim >= 0 .

   eq valida?(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist)) =
     S >= 0 and Lim == 0 .

  -- Operação Depositar
   eq depositar(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist), Val, D) =
     if Val > 0 and Val > TaxOp then
        conta(Num, Ag, C, S + (Val - TaxOp), Lim, TaxOp, TaxRend, T, transacao(D, deposito, Val) | Hist)
     else
        conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, T, Hist)
     fi .

  -- Operação Sacar
   eq sacar(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist), Val, D) =
      if podeSacar?(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist), Val) then
         conta(Num, Ag, C, S - (Val + TaxOp), Lim, TaxOp, TaxRend, contaCorrente, transacao(D, saque, Val) | Hist)
      else
         conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist)
      fi .

   eq sacar(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist), Val, D) =
      if podeSacar?(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist), Val) then
         conta(Num, Ag, C, S - Val, Lim, TaxOp, TaxRend, contaPoupanca, transacao(D, saque, Val) | Hist)
      else
         conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist)
      fi .

  -- Aplicar Rendimento
   eq aplicarRendimento(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaPoupanca, Hist), D) =
     conta(Num, Ag, C, S + ((S * TaxRend) quo 10000), Lim, TaxOp, TaxRend, contaPoupanca,
           transacao(D, rendimento, (S * TaxRend) quo 10000) | Hist) .

   eq aplicarRendimento(conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist), D) =
     conta(Num, Ag, C, S, Lim, TaxOp, TaxRend, contaCorrente, Hist) .
}
