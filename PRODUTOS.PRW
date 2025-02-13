//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL PRODUTOS DESCRIPTION 'APIs exclusivas do módulo produtos.'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA cod        AS STRING
    WSDATA desc       AS STRING

    //Métodos
    WSMETHOD GET GRID  DESCRIPTION 'Retorna informações na grid' WSSYNTAX '/produtos/grid?{updated_at, limit, page, cod, desc}' PATH 'grid'   PRODUCES APPLICATION_JSON
    WSMETHOD GET UNICO DESCRIPTION 'Retorna um unico resultado'  WSSYNTAX '/produtos/unico?{updated_at, limit, page, cod}'      PATH 'unico'  PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET UNICO WSSERVICE PRODUTOS
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
    Local cAliasWS        := 'SB1'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    // Efetua a busca dos registros
    cQueryTab := " SELECT TOP 1 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SB1010 TAB " + CRLF
    cQueryTab += " WHERE TAB.B1_COD LIKE '%"+::cod+"%' "
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
            oRegistro['B1_FILIAL']    := (cAliasWS)->B1_FILIAL
            oRegistro['B1_COD']       := (cAliasWS)->B1_COD
            oRegistro['B1_DESC']      := (cAliasWS)->B1_DESC

            oRegistro['B1_TIPO']      := (cAliasWS)->B1_TIPO
            oRegistro['B1_UM']        := (cAliasWS)->B1_UM
            oRegistro['B1_PESO']      := (cAliasWS)->B1_PESO
            oRegistro['B1_PESBRU']    := (cAliasWS)->B1_PESBRU
            oRegistro['B1_CODBAR']    := (cAliasWS)->B1_CODBAR
            oRegistro['B1_CODGTIN']   := (cAliasWS)->B1_CODGTIN
            oRegistro['B1_IMPORT']    := (cAliasWS)->B1_IMPORT
            oRegistro['B1_IPI']       := (cAliasWS)->B1_IPI
            oRegistro['B1_ORIGEM']    := (cAliasWS)->B1_ORIGEM

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


WSMETHOD GET GRID WSSERVICE PRODUTOS
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
    Local cAliasWS        := 'SB1'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    //Efetua a busca dos registros
    cQueryTab := " SELECT TOP 500 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SB1010 TAB " + CRLF
    cQueryTab += " WHERE TAB.B1_COD LIKE '%"+::cod+"%' AND TAB.B1_DESC LIKE '%"+::desc+"%' " + CRLF
    cQueryTab += " AND TAB.R_E_C_D_E_L_ = 0 "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se não encontrar registros
    If QRY_TAB->(EoF())
        jResponse['objects']  := {}
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
            oRegistro['B1_FILIAL']    := (cAliasWS)->B1_FILIAL
            oRegistro['B1_COD']       := (cAliasWS)->B1_COD
            oRegistro['B1_DESC']      := (cAliasWS)->B1_DESC
            oRegistro['B1_TIPO']      := (cAliasWS)->B1_TIPO
            oRegistro['B1_UM']        := (cAliasWS)->B1_UM
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
