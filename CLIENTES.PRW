//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL CLIENTES DESCRIPTION 'APIs exclusivas do m�dulo clientes.'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA cod        AS STRING
    WSDATA name       AS STRING
    WSDATA filial     AS STRING
    WSDATA loja       AS STRING
    WSDATA cgc        AS STRING

    //M�todos
    WSMETHOD GET    GRID           DESCRIPTION 'Retorna informa��es na grid' WSSYNTAX '/clientes/grid?{updated_at, limit, page, cod, name, cgc}'      PATH 'grid'   PRODUCES APPLICATION_JSON
    WSMETHOD GET    UNICO          DESCRIPTION 'Retorna um unico resultado'  WSSYNTAX '/clientes/unico?{updated_at, limit, page, filial, cod, loja}'  PATH 'unico'  PRODUCES APPLICATION_JSON
    WSMETHOD PUT    UPDATE_CLIENTE DESCRIPTION 'Atualiza um registro'        WSSYNTAX '/clientes/update?{updated_at, limit, page, filial, cod, loja}' PATH 'update' PRODUCES APPLICATION_JSON
    WSMETHOD PUT    DELETE_CLIENTE DESCRIPTION 'Deleta um registro'          WSSYNTAX '/clientes/delete?{updated_at, limit, page, filial, cod, loja}' PATH 'delete' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD PUT DELETE_CLIENTE WSRECEIVE WSRESTFUL CLIENTES
Local lRet      := .T.
Local aArea     := GetArea()
Local oJson
Local cJson     := Self:GetContent()
Local cError    := ''
Local nOpc      := 5 //N�mero 5 indica delete
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
    MSExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpc, {}) //Colocar aAI0Auto ao inv�s do objeto vazio {} para alterar dados complementares do cliente.
    
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

WSMETHOD PUT UPDATE_CLIENTE WSRECEIVE WSRESTFUL CLIENTES
Local lRet      := .T.
Local aArea     := GetArea()
Local oJson
Local cJson     := Self:GetContent()
Local cError    := ''
Local nOpc      := 4 //N�mero 4 indica update
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
    aAdd(aSA1Auto,{"A1_NOME",    AllTrim(oJson:GetJsonObject('A1_NOME')),   NIL})
    
    //---------------------------------------------------------
    // Dados do Complemento do Cliente
    //---------------------------------------------------------
    aAdd(aAI0Auto,{"AI0_CODCLI", AllTrim(oJson:GetJsonObject('AI0_CODCLI')), NIL})
    
    //------------------------------------
    // Chamada para cadastrar o cliente.
    //------------------------------------
    MSExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpc, {}) //Colocar aAI0Auto ao inv�s do objeto vazio {} para alterar dados complementares do cliente.
    
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

WSMETHOD GET GRID WSSERVICE CLIENTES
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
    Local cAliasWS        := 'SA1'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    //Efetua a busca dos registros
    cQueryTab := " SELECT TOP 500 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SA1010 TAB " + CRLF
    cQueryTab += " WHERE TAB.A1_COD LIKE '%"+::cod+"%' AND TAB.A1_NOME LIKE '%"+::name+"%' AND TAB.A1_CGC LIKE '%"+::cgc+"%'" + CRLF
    cQueryTab += " AND TAB.R_E_C_D_E_L_ = 0 "
    TCQuery cQueryTab New Alias 'QRY_TAB'

    //Se n�o encontrar registros
    If QRY_TAB->(EoF())
        jResponse['objects']  := {}
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
            oRegistro['A1_FILIAL']    := (cAliasWS)->A1_FILIAL
            oRegistro['A1_COD']       := (cAliasWS)->A1_COD
            oRegistro['A1_LOJA']      := (cAliasWS)->A1_LOJA
            oRegistro['A1_NOME']      := (cAliasWS)->A1_NOME
            oRegistro['A1_CGC']       := (cAliasWS)->A1_CGC
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

WSMETHOD GET UNICO WSSERVICE CLIENTES
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
    Local cAliasWS        := 'SA1'

    If ! Empty(::updated_at)
        data := ::updated_at
    EndIf

    // Efetua a busca dos registros
    cQueryTab := " SELECT TOP 1 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SA1010 TAB " + CRLF
    cQueryTab += " WHERE TAB.A1_FILIAL LIKE '%"+::filial+"%' AND TAB.A1_COD LIKE '%"+::cod+"%' AND TAB.A1_LOJA LIKE '%"+::loja+"%' "
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
            oRegistro['A1_FILIAL']    := (cAliasWS)->A1_FILIAL
            oRegistro['A1_COD']       := (cAliasWS)->A1_COD
            oRegistro['A1_LOJA']      := (cAliasWS)->A1_LOJA
            oRegistro['A1_NOME']      := (cAliasWS)->A1_NOME
            oRegistro['A1_CGC']       := (cAliasWS)->A1_CGC
            oRegistro['A1_PESSOA']    := (cAliasWS)->A1_PESSOA
            oRegistro['A1_END']       := (cAliasWS)->A1_END
            oRegistro['A1_NREDUZ']    := (cAliasWS)->A1_NREDUZ
            oRegistro['A1_BAIRRO']    := (cAliasWS)->A1_BAIRRO

            oRegistro['A1_TIPO']      := (cAliasWS)->A1_TIPO
            oRegistro['A1_EST']       := (cAliasWS)->A1_EST
            oRegistro['A1_CEP']       := (cAliasWS)->A1_CEP
            oRegistro['A1_COD_MUN']   := (cAliasWS)->A1_COD_MUN

            oRegistro['A1_TABELA']    := (cAliasWS)->A1_TABELA
            oRegistro['A1_VEND']      := (cAliasWS)->A1_VEND
            oRegistro['A1_XCARTEI']   := (cAliasWS)->A1_XCARTEI

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
