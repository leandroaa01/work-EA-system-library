-- ============================================================
-- cliente.mod: Modelagem do Cliente do Banco
-- ============================================================
mod! CLIENTE {
  protecting(STRING)
  protecting(BOOL)

  -- Sort (Abordagem pura)
  [ Cliente ]

  -- Construtor
  op newCliente : String String String -> Cliente { ctor }

  -- Operações de projeção
  op getName  : Cliente -> String
  op getCPF   : Cliente -> String
  op getEmail : Cliente -> String

  -- Predicado de Validade
  op valido? : Cliente -> Bool

  -- Variáveis
  vars N C E : String

  -- Definição das Projeções
  eq getName(newCliente(N, C, E))  = N .
  eq getCPF(newCliente(N, C, E))   = C .
  eq getEmail(newCliente(N, C, E)) = E .

  -- Definição da validade
  eq valido?(newCliente(N, C, E)) = (N =/= "") and (C =/= "") and (E =/= "") .
}