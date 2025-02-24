//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL VENDEDORES DESCRIPTION 'APIs exclusivas do módulo vendedores.'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA cod        AS STRING
    WSDATA nome       AS STRING
    WSDATA filial     AS STRING

    //Métodos
    WSMETHOD GET     GRID               DESCRIPTION 'Retorna informações na grid' WSSYNTAX '/vendedores/grid?{updated_at,   limit, page, cod, nome}'         PATH 'grid'   PRODUCES APPLICATION_JSON
    WSMETHOD GET     UNICO              DESCRIPTION 'Retorna um unico resultado'  WSSYNTAX '/vendedores/unico?{updated_at,  limit, page, filial, cod}'       PATH 'unico'  PRODUCES APPLICATION_JSON
    WSMETHOD PUT     UPDATE_VENDEDORES  DESCRIPTION 'Atualiza um registro'        WSSYNTAX '/vendedores/update?{updated_at, limit, page, filial, cod}'       PATH 'update' PRODUCES APPLICATION_JSON
    WSMETHOD DELETE  DELETE_VENDEDORES  DESCRIPTION 'Deleta um registro'          WSSYNTAX '/vendedores/delete?{updated_at, limit, page, filial, cod, loja}' PATH 'delete' PRODUCES APPLICATION_JSON
    WSMETHOD POST    CREATE_VENDEDORES  DESCRIPTION 'Cria um registro'            WSSYNTAX '/vendedores/create?{updated_at, limit, page}'                    PATH 'create' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET GRID WSSERVICE VENDEDORES
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
    Local cAliasWS        := 'SA3'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    //Efetua a busca dos registros
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SA3010 TAB " + CRLF
    cQueryTab += " WHERE TAB.A3_COD LIKE '%"+::cod+"%' AND TAB.A3_NOME LIKE '%"+::nome+"%' " + CRLF
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
            oRegistro['A3_FILIAL']    := (cAliasWS)->A3_FILIAL
            oRegistro['A3_COD']       := (cAliasWS)->A3_COD
            oRegistro['A3_NOME']      := (cAliasWS)->A3_NOME
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

WSMETHOD POST CREATE_VENDEDORES WSRECEIVE WSRESTFUL VENDEDORES
    Local lRet      := .T.
    Local aArea     := GetArea()
    Local oJson
    Local cJson     := Self:GetContent()
    Local cError    := ''
    Local nOpc      := 3 //Número 3 indica create
    Local aSA1Auto := {}
    Local aAI0Auto := {}
    
    Private lMsErroAuto := .F.
    Private lAutoErrNoFile := .T.
    
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error')
        lRet    := .F.
    Else

        If lRet
        
        //----------------------------------
        // Dados do Cliente
        //----------------------------------
        aAdd(aSA1Auto,{"A1_FILIAL",  '0101   ',                                 NIL})
        aAdd(aSA1Auto,{"A1_COD",     GetSxeNum("SA1","A1_COD"),                 NIL})
        aAdd(aSA1Auto,{"A1_LOJA",    AllTrim(oJson:GetJsonObject('A1_LOJA')),   NIL})
        aAdd(aSA1Auto,{"A1_NOME",    AllTrim(oJson:GetJsonObject('A1_NOME')),   NIL})
        aAdd(aSA1Auto,{"A1_EMAIL",    AllTrim(oJson:GetJsonObject('A1_EMAIL')), NIL})
        
        //---------------------------------------------------------
        // Dados do Complemento do Cliente
        //---------------------------------------------------------
        aAdd(aAI0Auto,{"AI0_CODCLI", AllTrim(oJson:GetJsonObject('AI0_CODCLI')), NIL})
        
        //------------------------------------
        // Chamada para cadastrar o cliente.
        //------------------------------------
        MSExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpc, {}) //Colocar aAI0Auto ao invés do objeto vazio {} para alterar dados complementares do cliente.
        
        IF lMsErroAuto
            self:setStatus(500)
            self:setResponse("ERRO AO ALTERAR" + GetAutoGRLog())
            lRet := .T.
        ELSE
            Self:SetResponse("Alterado com sucesso.")
        EndIF 

        EndIf    
        
    EndIf

    RestArea(aArea)
    FreeObj(oJson)
    
Return

WSMETHOD DELETE DELETE_VENDEDORES WSRECEIVE WSRESTFUL VENDEDORES
    Local lRet      := .T.
    Local aArea     := GetArea()
    Local oJson
    Local cJson     := Self:GetContent()
    Local cError    := ''
    Local nOpc      := 5 //Número 5 indica delete
    Local aSA1Auto := {}
    Local aAI0Auto := {}
    
    Private lMsErroAuto := .F.
    Private lAutoErrNoFile := .T.
    
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error')
        lRet    := .F.
    Else

        If lRet
        
        //----------------------------------
        // Dados do Cliente
        //----------------------------------
        aAdd(aSA1Auto,{"A1_FILIAL",  AllTrim(oJson:GetJsonObject('A1_FILIAL')), NIL})
        aAdd(aSA1Auto,{"A1_COD",     AllTrim(oJson:GetJsonObject('A1_COD')),    NIL})
        aAdd(aSA1Auto,{"A1_LOJA",    AllTrim(oJson:GetJsonObject('A1_LOJA')),   NIL})
        
        //---------------------------------------------------------
        // Dados do Complemento do Cliente
        //---------------------------------------------------------
        aAdd(aAI0Auto,{"AI0_CODCLI", AllTrim(oJson:GetJsonObject('AI0_CODCLI')), NIL})
        
        //------------------------------------
        // Chamada para cadastrar o cliente.
        //------------------------------------
        MSExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpc, {}) //Colocar aAI0Auto ao invés do objeto vazio {} para alterar dados complementares do cliente.
        
        IF lMsErroAuto
            self:setStatus(500)
            self:setResponse("ERRO AO DELETAR" + GetAutoGRLog())
            lRet := .T.
        ELSE
            Self:SetResponse("Deletado com sucesso.")
        EndIF 

        EndIf    
        
    EndIf

    RestArea(aArea)
    FreeObj(oJson)
    
Return

WSMETHOD PUT UPDATE_VENDEDORES WSRECEIVE WSRESTFUL VENDEDORES
    Local lRet      := .T.
    Local aArea     := GetArea()
    Local oJson
    Local cJson     := Self:GetContent()
    Local cError    := ''
    Local nOpc      := 4 //Número 4 indica update
    Local aSA3Auto := {}
    
    Private lMsErroAuto := .F.
    Private lAutoErrNoFile := .T.
    
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
    IF !Empty(cError)
        SetRestFault(500,'Parser Json Error')
        lRet    := .F.
    Else

        If lRet
        
        //----------------------------------
        // Dados do Cliente
        //----------------------------------
        aAdd(aSA3Auto,{"A3_FILIAL",  AllTrim(oJson:GetJsonObject('A3_FILIAL')),  NIL})
        aAdd(aSA3Auto,{"A3_COD",     AllTrim(oJson:GetJsonObject('A3_COD')),     NIL})
        aAdd(aSA3Auto,{"A3_NOME",    AllTrim(oJson:GetJsonObject('A3_NOME')),    NIL})
        aAdd(aSA3Auto,{"A3_NREDUZ",  AllTrim(oJson:GetJsonObject('A3_NREDUZ')),  NIL})
        aAdd(aSA3Auto,{"A3_END",     AllTrim(oJson:GetJsonObject('A3_END')),     NIL})
        aAdd(aSA3Auto,{"A3_BAIRRO",  AllTrim(oJson:GetJsonObject('A3_BAIRRO')),  NIL})
        aAdd(aSA3Auto,{"A3_MUN",     AllTrim(oJson:GetJsonObject('A3_MUN')),     NIL})

        aAdd(aSA3Auto,{"A3_CEP",     AllTrim(oJson:GetJsonObject('A3_CEP')),     NIL})
        aAdd(aSA3Auto,{"A3_DDDTEL",  AllTrim(oJson:GetJsonObject('A3_DDDTEL')),  NIL})
        aAdd(aSA3Auto,{"A3_TEL",     AllTrim(oJson:GetJsonObject('A3_TEL')),     NIL})
        aAdd(aSA3Auto,{"A3_FAX",     AllTrim(oJson:GetJsonObject('A3_FAX')),     NIL})
        aAdd(aSA3Auto,{"A3_EMAIL",   AllTrim(oJson:GetJsonObject('A3_EMAIL')),     NIL})
        
        
        //------------------------------------
        // Chamada para cadastrar o cliente.
        //------------------------------------
        MSExecAuto({|a,b,c| MATA040(a,b,c)}, aSA3Auto, nOpc, {})
        
        IF lMsErroAuto
            self:setStatus(500)
            self:setResponse(GetAutoGRLog())
            lRet := .T.
        ELSE
            Self:SetResponse("Alterado com sucesso.")
        EndIF 

        EndIf    
        
    EndIf

    RestArea(aArea)
    FreeObj(oJson)
    
Return

WSMETHOD GET UNICO WSSERVICE VENDEDORES
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
    Local cAliasWS        := 'SA3'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    // Efetua a busca dos registros
    cQueryTab := " SELECT TOP 1 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SA3010 TAB " + CRLF
    cQueryTab += " WHERE TAB.A3_FILIAL = '"+::filial+"' AND TAB.A3_COD = '"+::cod+"' "
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
            oRegistro['A3_FILIAL']    := (cAliasWS)->A3_FILIAL
            oRegistro['A3_COD']       := (cAliasWS)->A3_COD
            oRegistro['A3_NOME']      := (cAliasWS)->A3_NOME
            oRegistro['A3_NREDUZ']    := (cAliasWS)->A3_NREDUZ
            oRegistro['A3_END']       := (cAliasWS)->A3_END
            oRegistro['A3_BAIRRO']    := (cAliasWS)->A3_BAIRRO
            oRegistro['A3_MUN']       := (cAliasWS)->A3_MUN
            oRegistro['A3_EST']       := (cAliasWS)->A3_EST

            oRegistro['A3_CEP']       := (cAliasWS)->A3_CEP
            oRegistro['A3_DDDTEL']    := (cAliasWS)->A3_DDDTEL
            oRegistro['A3_TEL']       := (cAliasWS)->A3_TEL
            oRegistro['A3_MSBLQL']    := (cAliasWS)->A3_MSBLQL
            oRegistro['A3_FAX']       := (cAliasWS)->A3_FAX

            oRegistro['A3_EMAIL']     := (cAliasWS)->A3_EMAIL
            oRegistro['A3_SUPER']     := (cAliasWS)->A3_SUPER
            oRegistro['A3_XSETOR']    := (cAliasWS)->A3_XSETOR

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
