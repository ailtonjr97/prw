//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL MODULO_PEDIDO DESCRIPTION 'APIs exclusivas do módulo pedido.'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA filial     AS STRING
    WSDATA numero     AS STRING

    //Métodos
    WSMETHOD GET GRID     DESCRIPTION 'Retorna informações utilizadas na grid' WSSYNTAX '/MODULO_PEDIDO/grid?{updated_at, limit, page, filial, numero}'   PATH 'grid'    PRODUCES APPLICATION_JSON
    WSMETHOD GET UNICO    DESCRIPTION 'Retorna um unico registro'              WSSYNTAX '/MODULO_PEDIDO/unico?{updated_at, limit, page, filial, numero}'  PATH 'unico'   PRODUCES APPLICATION_JSON
    WSMETHOD GET ITEMS    DESCRIPTION 'Retorna itens do orcamento'             WSSYNTAX '/MODULO_ORC/items?{updated_at, limit, page, filial, numero}'     PATH 'items'   PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET GRID WSSERVICE MODULO_PEDIDO
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
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SC5010 TAB " + CRLF
    cQueryTab += " WHERE TAB.C5_FILIAL LIKE '%"+::filial+"%' AND TAB.C5_NUM LIKE '%"+::numero+"%'  "
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

WSMETHOD GET UNICO WSSERVICE MODULO_PEDIDO
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
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SC5010 TAB " + CRLF
    cQueryTab += " WHERE TAB.C5_FILIAL LIKE '%"+::filial+"%' AND TAB.C5_NUM LIKE '%"+::numero+"%' " + CRLF
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
            oRegistro['C5_LOJAENT']   := (cAliasWS)->C5_LOJAENT
            
            oRegistro['C5_EMISSAO']   := (cAliasWS)->C5_EMISSAO
            oRegistro['C5_FECENT']    := (cAliasWS)->C5_FECENT
            oRegistro['C5_XPRCATU']   := (cAliasWS)->C5_XPRCATU

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

WSMETHOD GET ITEMS WSSERVICE MODULO_PEDIDO
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
    cQueryTab += " WHERE TAB.C6_FILIAL LIKE '%"+::filial+"%' AND TAB.C6_NUM LIKE '%"+::numero+"%' AND TAB.R_E_C_D_E_L_ = 0 " + CRLF
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
