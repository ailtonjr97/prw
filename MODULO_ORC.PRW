//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL MODULO_ORC DESCRIPTION 'APIs exclusivas do m�dulo or�amento.'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA filial     AS STRING
    WSDATA numero     AS STRING
    WSDATA cliente    AS STRING
    WSDATA loja       AS STRING
    WSDATA vendedor   AS STRING

    //M�todos
    WSMETHOD GET GRID     DESCRIPTION 'Retorna informa��es utilizadas na grid' WSSYNTAX '/MODULO_ORC/grid?{updated_at, limit, page, filial, numero}'                     PATH 'grid'  PRODUCES APPLICATION_JSON
    WSMETHOD GET UNICO    DESCRIPTION 'Retorna informa��es utilizadas na grid' WSSYNTAX '/MODULO_ORC/unico?{updated_at, limit, page, filial, numero, cliente, vendedor}' PATH 'unico' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET GRID WSSERVICE MODULO_ORC
    Local lRet            := .T.
    Local jResponse       := JsonObject():New()
    Local cQueryTab       := ''
    Local nTamanho        := 100
    Local nTotal          := 0
    Local nPags           := 0
    Local nPagina         := 0
    Local nAtual          := 0
    Local data            := ''
    Local oRegistro
    Local cAliasWS        := 'SCJ'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    //Efetua a busca dos registros
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL, CLI.A1_NOME AS A1_NOME, VEND.A3_NOME AS A3_NOME FROM SCJ010 TAB " + CRLF
    cQueryTab += " INNER JOIN SA1010 CLI ON TAB.CJ_CLIENTE = CLI.A1_COD AND TAB.CJ_LOJA = CLI.A1_LOJA" + CRLF
    cQueryTab += " INNER JOIN SA3010 VEND ON TAB.CJ_XVEND1 = VEND.A3_COD" + CRLF
    cQueryTab += " WHERE TAB.R_E_C_D_E_L_ = 0 AND TAB.CJ_FILIAL LIKE '%"+::filial+"%' AND TAB.CJ_NUM LIKE '%"+::numero+"%' AND CLI.A1_NOME LIKE '%"+::cliente+"%' AND VEND.A3_NOME LIKE '%"+::vendedor+"%'" + CRLF
    cQueryTab += " ORDER BY TABREC DESC "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se n�o encontrar registros
    If QRY_TAB->(EoF())
        //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
        Self:setStatus(404) 
        jResponse['errorId']  := 'ALL003'
        jResponse['error']    := 'Registro(s) n�o encontrado(s)'
        jResponse['solution'] := 'A consulta de registros n�o retornou nenhuma informa��o'
    Else
        jResponse['objects'] := {}

        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())

        //O tamanho do retorno, ser� o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf

        //Pegando total de p�ginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
        
        //Se vier p�gina
        If ! Empty(::page)
            nPagina := ::page
        EndIf

        //Se a p�gina vier zerada ou negativa ou for maior que o m�ximo, ser� 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf

        //Se a p�gina for diferente de 1, pula os registros
        If nPagina != 1
            QRY_TAB->(DbSkip((nPagina-1) * nTamanho))
        EndIf

        //Adiciona os dados para a meta
        jJsonMeta := JsonObject():New()
        jJsonMeta['total']         := nTotal
        jJsonMeta['current_page']  := nPagina
        jJsonMeta['total_page']    := nPags
        jJsonMeta['total_items']   := nTamanho
        jResponse['meta'] := jJsonMeta

        //Percorre os registros
        While ! QRY_TAB->(EoF())
            nAtual++
            
            //Se ultrapassar o limite, encerra o la�o
            If nAtual > nTamanho
                Exit
            EndIf

            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
            
            oRegistro := JsonObject():New()
            oRegistro['CJ_FILIAL']    := (cAliasWS)->CJ_FILIAL
            oRegistro['CJ_NUM']       := (cAliasWS)->CJ_NUM
            oRegistro['CJ_CLIENTE']   := (cAliasWS)->CJ_CLIENTE
            oRegistro['CJ_LOJA']      := (cAliasWS)->CJ_LOJA
            oRegistro['A1_NOME']      := QRY_TAB->A1_NOME
            oRegistro['A3_NOME']      := QRY_TAB->A3_NOME
            oRegistro['R_E_C_N_O_']   := QRY_TAB->TABREC
            oRegistro['R_E_C_D_E_L_'] := QRY_TAB->RECDEL
            aAdd(jResponse['objects'], oRegistro)

            QRY_TAB->(DbSkip())
        EndDo
    EndIf
    QRY_TAB->(DbCloseArea())

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet

WSMETHOD GET UNICO WSSERVICE MODULO_ORC
    Local lRet            := .T.
    Local jResponse       := JsonObject():New()
    Local cQueryTab       := ''
    Local nTamanho        := 100
    Local nTotal          := 0
    Local nPags           := 0
    Local nPagina         := 0
    Local nAtual          := 0
    Local data            := ''
    Local oRegistro
    Local cAliasWS        := 'SCJ'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    // Efetua a busca dos registros
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SCJ010 TAB " + CRLF
    cQueryTab += " WHERE TAB.CJ_FILIAL LIKE '%"+::filial+"%' AND TAB.CJ_NUM LIKE '%"+::numero+"%' AND TAB.CJ_CLIENTE LIKE '%"+::cliente+"%' AND TAB.CJ_LOJA LIKE '%"+::loja+"%' " + CRLF
    cQueryTab += " ORDER BY TABREC DESC "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se n�o encontrar registros
    If QRY_TAB->(EoF())
        //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
        Self:setStatus(404) 
        jResponse['errorId']  := 'ALL003'
        jResponse['error']    := 'Registro(s) n�o encontrado(s)'
        jResponse['solution'] := 'A consulta de registros n�o retornou nenhuma informa��o'
    Else
        jResponse['objects'] := {}

        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())

        //O tamanho do retorno, ser� o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf

        //Pegando total de p�ginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
        
        //Se vier p�gina
        If ! Empty(::page)
            nPagina := ::page
        EndIf

        //Se a p�gina vier zerada ou negativa ou for maior que o m�ximo, ser� 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf

        //Se a p�gina for diferente de 1, pula os registros
        If nPagina != 1
            QRY_TAB->(DbSkip((nPagina-1) * nTamanho))
        EndIf

        //Adiciona os dados para a meta
        jJsonMeta := JsonObject():New()
        jJsonMeta['total']         := nTotal
        jJsonMeta['current_page']  := nPagina
        jJsonMeta['total_page']    := nPags
        jJsonMeta['total_items']   := nTamanho
        jResponse['meta'] := jJsonMeta

        //Percorre os registros
        While ! QRY_TAB->(EoF())
            nAtual++
            
            //Se ultrapassar o limite, encerra o la�o
            If nAtual > nTamanho
                Exit
            EndIf

            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
            
            oRegistro := JsonObject():New()
            oRegistro['CJ_FILIAL']    := (cAliasWS)->CJ_FILIAL
            oRegistro['CJ_NUM']       := (cAliasWS)->CJ_NUM
            oRegistro['CJ_EMISSAO']   := (cAliasWS)->CJ_EMISSAO
            oRegistro['CJ_PROSPE']    := (cAliasWS)->CJ_PROSPE
            oRegistro['CJ_LOJPRO']    := (cAliasWS)->CJ_LOJPRO
            oRegistro['CJ_CLIENTE']   := (cAliasWS)->CJ_CLIENTE
            oRegistro['CJ_LOJA']      := (cAliasWS)->CJ_LOJA
            oRegistro['CJ_CLIENT']    := (cAliasWS)->CJ_CLIENT
            oRegistro['CJ_LOJAENT']   := (cAliasWS)->CJ_LOJAENT
            oRegistro['CJ_CONDPAG']   := (cAliasWS)->CJ_CONDPAG
            oRegistro['CJ_DESC3']     := (cAliasWS)->CJ_DESC3
            oRegistro['CJ_DESC4']     := (cAliasWS)->CJ_DESC4
            oRegistro['CJ_TABELA']    := (cAliasWS)->CJ_TABELA
            oRegistro['CJ_DESC1']     := (cAliasWS)->CJ_DESC1
            oRegistro['CJ_PARC1']     := (cAliasWS)->CJ_PARC1
            oRegistro['CJ_DATA1']     := (cAliasWS)->CJ_DATA1
            oRegistro['CJ_DESC2']     := (cAliasWS)->CJ_DESC2
            oRegistro['CJ_PARC2']     := (cAliasWS)->CJ_PARC2
            oRegistro['CJ_DATA2']     := (cAliasWS)->CJ_DATA2
            oRegistro['CJ_PARC3']     := (cAliasWS)->CJ_PARC3
            oRegistro['CJ_DATA3']     := (cAliasWS)->CJ_DATA3
            oRegistro['CJ_PARC4']     := (cAliasWS)->CJ_PARC4
            oRegistro['CJ_DATA4']     := (cAliasWS)->CJ_DATA4
            oRegistro['CJ_STATUS']    := (cAliasWS)->CJ_STATUS
            oRegistro['CJ_COTCLI']    := (cAliasWS)->CJ_COTCLI
            oRegistro['CJ_FRETE']     := (cAliasWS)->CJ_FRETE
            oRegistro['CJ_SEGURO']    := (cAliasWS)->CJ_SEGURO
            oRegistro['CJ_DESPESA']   := (cAliasWS)->CJ_DESPESA
            oRegistro['CJ_FRETAUT']   := (cAliasWS)->CJ_FRETAUT
            oRegistro['CJ_VALIDA']    := (cAliasWS)->CJ_VALIDA
            oRegistro['CJ_TIPO']      := (cAliasWS)->CJ_TIPO
            oRegistro['CJ_MOEDA']     := (cAliasWS)->CJ_MOEDA
            oRegistro['CJ_TIPLIB']    := (cAliasWS)->CJ_TIPLIB
            oRegistro['CJ_TPCARGA']   := (cAliasWS)->CJ_TPCARGA
            oRegistro['CJ_DESCONT']   := (cAliasWS)->CJ_DESCONT
            oRegistro['CJ_PDESCAB']   := (cAliasWS)->CJ_PDESCAB
            oRegistro['CJ_PROPOST']   := (cAliasWS)->CJ_PROPOST
            oRegistro['CJ_NROPOR']    := (cAliasWS)->CJ_NROPOR
            oRegistro['CJ_REVISA']    := (cAliasWS)->CJ_REVISA
            oRegistro['CJ_TXMOEDA']   := (cAliasWS)->CJ_TXMOEDA
            oRegistro['CJ_TIPOCLI']   := (cAliasWS)->CJ_TIPOCLI
            oRegistro['CJ_TPFRETE']   := (cAliasWS)->CJ_TPFRETE
            oRegistro['CJ_INDPRES']   := (cAliasWS)->CJ_INDPRES
            oRegistro['CJ_CODA1U']    := (cAliasWS)->CJ_CODA1U
            oRegistro['CJ_XESTADO']   := (cAliasWS)->CJ_XESTADO
            oRegistro['R_E_C_N_O_']   := QRY_TAB->TABREC
            oRegistro['R_E_C_D_E_L_'] := QRY_TAB->RECDEL
            aAdd(jResponse['objects'], oRegistro)

            QRY_TAB->(DbSkip())
        EndDo
    EndIf
    QRY_TAB->(DbCloseArea())

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet