-- ============================================================
-- transacao.mod: Modelagem de Transações e Histórico de Extrato
-- ============================================================
mod! TRANSACAO {
  protecting(STRING)
  protecting(INT)

  -- Sorts 
  [ TipoTransacao Transacao ListaTransacoes ]

  -- Tipos das transações
  ops deposito saque transferenciaEnviada transferenciaRecebida rendimento : -> TipoTransacao { ctor }

  -- Construtor de Transação
  op transacao : String TipoTransacao Int -> Transacao { ctor }

  -- Operações de Projeção
  op getDataHora : Transacao -> String
  op getTipo     : Transacao -> TipoTransacao
  op getValor    : Transacao -> Int

  -- Construtores de Lista de Transações (Histórico)
  op nilTX : -> ListaTransacoes { ctor }
  op _|_   : Transacao ListaTransacoes -> ListaTransacoes { ctor r-assoc }

  -- Variáveis
  var D : String
  var T : TipoTransacao
  var V : Int
  var h : Transacao

  -- Equações 
  eq getDataHora(transacao(D, T, V)) = D .
  eq getTipo(transacao(D, T, V))     = T .
  eq getValor(transacao(D, T, V))    = V .


}