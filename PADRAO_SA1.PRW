//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"


WSRESTFUL PADRAO_SA1 DESCRIPTION 'Tabela SA1 - Clientes'
    //Atributos
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
    WSDATA filial     AS STRING
    WSDATA cliente    AS STRING
    WSDATA loja       AS STRING

    //Métodos
    WSMETHOD GET PADRAO_CONSULTA DESCRIPTION 'Consulta padrao do cliente' WSSYNTAX '/PADRAO_SA1/cliente?{updated_at, limit, page, filial, cliente, loja}' PATH 'cliente' PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET PADRAO_CONSULTA WSSERVICE PADRAO_SA1
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
    cQueryTab := " SELECT TOP 100 TAB.R_E_C_N_O_ AS TABREC, TAB.R_E_C_D_E_L_ AS RECDEL FROM SA1010 TAB " + CRLF
    cQueryTab += " WHERE TAB.A1_FILIAL LIKE '%"+::filial+"%' AND TAB.A1_COD LIKE '%"+::cliente+"%' AND TAB.A1_LOJA LIKE '%"+::loja+"%' ORDER BY TABREC DESC " + CRLF
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
            oRegistro['A1_COD']    := (cAliasWS)->A1_COD
            oRegistro['A1_NOME']   := (cAliasWS)->A1_NOME
            oRegistro['A1_CGC']    := (cAliasWS)->A1_CGC
            oRegistro['A1_END']    := (cAliasWS)->A1_END
            oRegistro['A1_MUN']    := (cAliasWS)->A1_MUN
            oRegistro['A1_EST']    := (cAliasWS)->A1_EST
            oRegistro['A1_CEP']    := (cAliasWS)->A1_CEP
            oRegistro['A1_LOJA']   := (cAliasWS)->A1_LOJA
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
