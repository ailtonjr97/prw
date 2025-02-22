//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL MOD_PEDIDO DESCRIPTION 'APIs exclusivas do módulo pedido.'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA filial     AS STRING
    WSDATA numero     AS STRING
    WSDATA cliente    AS STRING
    WSDATA vendedor   AS STRING

    //Métodos
    WSMETHOD GET GRID     DESCRIPTION 'Retorna informações utilizadas na grid' WSSYNTAX '/MOD_PEDIDO/grid?{updated_at, limit, page, filial, numero, cliente, vendedor}' PATH 'grid'    PRODUCES APPLICATION_JSON
    WSMETHOD GET UNICO    DESCRIPTION 'Retorna um unico registro'              WSSYNTAX '/MOD_PEDIDO/unico?{updated_at, limit, page, filial, numero}'                   PATH 'unico'   PRODUCES APPLICATION_JSON
    WSMETHOD GET ITEMS    DESCRIPTION 'Retorna itens do orcamento'             WSSYNTAX '/MOD_PEDIDO/items?{updated_at, limit, page, filial, numero}'                   PATH 'items'   PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET GRID WSSERVICE MOD_PEDIDO
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
    Local cAliasWS        := 'SC5'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    //Efetua a busca dos registros
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL, CLI.A1_NOME AS A1_NOME, VEND.A3_NREDUZ AS A3_NOME FROM SC5010 TAB " + CRLF
    cQueryTab += " INNER JOIN SA1010 CLI ON TAB.C5_CLIENTE = CLI.A1_COD AND TAB.C5_LOJACLI = CLI.A1_LOJA" + CRLF
    cQueryTab += " INNER JOIN SA3010 VEND ON TAB.C5_VEND1 = VEND.A3_COD" + CRLF
    cQueryTab += " WHERE TAB.C5_FILIAL LIKE '%"+::filial+"%' AND TAB.C5_NUM LIKE '%"+::numero+"%' AND VEND.A3_NOME LIKE '%"+::vendedor+"%' AND CLI.A1_NOME LIKE '%"+::cliente+"%' AND TAB.R_E_C_D_E_L_ = 0 " + CRLF
    cQueryTab += " ORDER BY TABREC DESC "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se não encontrar registros
    If QRY_TAB->(EoF())
        jResponse['objects'] := {}
    Else
        jResponse['objects'] := {}

        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())

        //O tamanho do retorno, será o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf

        //Pegando total de páginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
        
        //Se vier página
        If ! Empty(::page)
            nPagina := ::page
        EndIf

        //Se a página vier zerada ou negativa ou for maior que o máximo, será 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf

        //Se a página for diferente de 1, pula os registros
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
            
            //Se ultrapassar o limite, encerra o laço
            If nAtual > nTamanho
                Exit
            EndIf

            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
            
            oRegistro := JsonObject():New()
            oRegistro['C5_FILIAL']    := (cAliasWS)->C5_FILIAL
            oRegistro['C5_NUM']       := (cAliasWS)->C5_NUM
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

WSMETHOD GET UNICO WSSERVICE MOD_PEDIDO
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
    Local cAliasWS        := 'SC5'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    // Efetua a busca dos registros
    cQueryTab := " SELECT TOP 100 ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), TAB.C5_XOBS)),'') AS C5_XOBS, TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SC5010 TAB " + CRLF
    cQueryTab += " WHERE TAB.C5_FILIAL LIKE '%"+::filial+"%' AND TAB.C5_NUM LIKE '%"+::numero+"%' AND TAB.R_E_C_D_E_L_ = 0 " + CRLF
    cQueryTab += " ORDER BY TABREC DESC "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se não encontrar registros
    If QRY_TAB->(EoF())
        //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(404) 
        jResponse['errorId']  := 'ALL003'
        jResponse['error']    := 'Registro(s) não encontrado(s)'
        jResponse['solution'] := 'A consulta de registros não retornou nenhuma informação'
    Else
        jResponse['objects'] := {}

        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())

        //O tamanho do retorno, será o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf

        //Pegando total de páginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
        
        //Se vier página
        If ! Empty(::page)
            nPagina := ::page
        EndIf

        //Se a página vier zerada ou negativa ou for maior que o máximo, será 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf

        //Se a página for diferente de 1, pula os registros
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
            
            //Se ultrapassar o limite, encerra o laço
            If nAtual > nTamanho
                Exit
            EndIf

            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
            
            oRegistro := JsonObject():New()
            oRegistro['C5_FILIAL']    := (cAliasWS)->C5_FILIAL
            oRegistro['C5_NUM']       := (cAliasWS)->C5_NUM
            oRegistro['C5_XPEDTR']    := (cAliasWS)->C5_XPEDTR
            oRegistro['C5_XNUMORC']   := (cAliasWS)->C5_XNUMORC
            oRegistro['C5_CLIENTE']   := (cAliasWS)->C5_CLIENTE
            oRegistro['C5_LOJACLI']   := (cAliasWS)->C5_LOJACLI
            oRegistro['C5_LOJAENT']   := (cAliasWS)->C5_LOJAENT
            oRegistro['C5_XESTADO']   := (cAliasWS)->C5_XESTADO
            oRegistro['C5_EMISSAO']   := (cAliasWS)->C5_EMISSAO
            oRegistro['C5_FECENT']    := (cAliasWS)->C5_FECENT
            oRegistro['C5_XPRCATU']   := (cAliasWS)->C5_XPRCATU
            oRegistro['C5_TIPO']     := (cAliasWS)->C5_TIPO
            oRegistro['C5_CLIENT']   := (cAliasWS)->C5_CLIENT
            oRegistro['C5_TRANSP']   := (cAliasWS)->C5_TRANSP
            oRegistro['C5_REDESP']   := (cAliasWS)->C5_REDESP
            oRegistro['C5_TIPOCLI']  := (cAliasWS)->C5_TIPOCLI
            oRegistro['C5_CONDPAG']  := (cAliasWS)->C5_CONDPAG
            oRegistro['C5_TABELA']   := (cAliasWS)->C5_TABELA
            oRegistro['C5_VEND1']    := (cAliasWS)->C5_VEND1
            oRegistro['C5_COMIS1']   := (cAliasWS)->C5_COMIS1
            oRegistro['C5_VEND2']    := (cAliasWS)->C5_VEND2
            oRegistro['C5_COMIS2']   := (cAliasWS)->C5_COMIS2
            oRegistro['C5_DESCFI']   := (cAliasWS)->C5_DESCFI
            oRegistro['C5_TPFRETE']  := (cAliasWS)->C5_TPFRETE
            oRegistro['C5_FRETE']    := (cAliasWS)->C5_FRETE
            oRegistro['C5_SEGURO']   := (cAliasWS)->C5_SEGURO
            oRegistro['C5_FRTCFOP']  := (cAliasWS)->C5_FRTCFOP
            oRegistro['C5_PESOL']    := (cAliasWS)->C5_PESOL
            oRegistro['C5_PBRUTO']   := (cAliasWS)->C5_PBRUTO
            oRegistro['C5_VOLUME1']  := (cAliasWS)->C5_VOLUME1
            oRegistro['C5_ESPECI1']  := (cAliasWS)->C5_ESPECI1
            oRegistro['C5_NOTA']     := (cAliasWS)->C5_NOTA
            oRegistro['C5_MENPAD']   := (cAliasWS)->C5_MENPAD
            oRegistro['C5_TIPLIB']   := (cAliasWS)->C5_TIPLIB
            oRegistro['C5_CLIREM']   := (cAliasWS)->C5_CLIREM
            oRegistro['C5_LOJAREM']  := (cAliasWS)->C5_LOJAREM
            oRegistro['C5_NATUREZ']  := (cAliasWS)->C5_NATUREZ
            oRegistro['C5_DESCMUN']  := (cAliasWS)->C5_DESCMUN
            oRegistro['C5_XOBS']     := (cAliasWS)->C5_XOBS

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

WSMETHOD GET ITEMS WSSERVICE MOD_PEDIDO
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
    Local cAliasWS        := 'SC6'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    // Efetua a busca dos registros
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SC6010 TAB " + CRLF
    cQueryTab += " WHERE TAB.C6_FILIAL = '"+::filial+"' AND TAB.C6_NUM = '"+::numero+"' AND TAB.R_E_C_D_E_L_ = 0 " + CRLF
    cQueryTab += " ORDER BY TAB.C6_ITEM ASC "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se não encontrar registros
    If QRY_TAB->(EoF())
        //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(404) 
        jResponse['errorId']  := 'ALL003'
        jResponse['error']    := 'Registro(s) não encontrado(s)'
        jResponse['solution'] := 'A consulta de registros não retornou nenhuma informação'
    Else
        jResponse['objects'] := {}

        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())

        //O tamanho do retorno, será o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf

        //Pegando total de páginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
        
        //Se vier página
        If ! Empty(::page)
            nPagina := ::page
        EndIf

        //Se a página vier zerada ou negativa ou for maior que o máximo, será 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf

        //Se a página for diferente de 1, pula os registros
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
            
            //Se ultrapassar o limite, encerra o laço
            If nAtual > nTamanho
                Exit
            EndIf

            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
            
            oRegistro := JsonObject():New()
            oRegistro['C6_FILIAL']    := (cAliasWS)->C6_FILIAL
            oRegistro['C6_ITEM']      := (cAliasWS)->C6_ITEM
            oRegistro['C6_PRODUTO']   := (cAliasWS)->C6_PRODUTO
            oRegistro['C6_DESCRI']    := (cAliasWS)->C6_DESCRI
            oRegistro['C6_UM']        := (cAliasWS)->C6_UM
            oRegistro['C6_QTDVEN']    := (cAliasWS)->C6_QTDVEN
            oRegistro['C6_PRCVEN']    := (cAliasWS)->C6_PRCVEN
            oRegistro['C6_VALOR']     := (cAliasWS)->C6_VALOR
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
