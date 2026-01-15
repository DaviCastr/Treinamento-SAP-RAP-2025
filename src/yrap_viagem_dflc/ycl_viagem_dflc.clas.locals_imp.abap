CLASS lcl_Viagem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF status_viagem,
        aberto    TYPE c LENGTH 1  VALUE 'O', " Aberto
        aceito    TYPE c LENGTH 1  VALUE 'A', " Aceito
        cancelado TYPE c LENGTH 1  VALUE 'X', " Cancelado
      END OF status_viagem.



    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Viagem RESULT result.

    METHODS aceitarViagem FOR MODIFY
      IMPORTING keys FOR ACTION Viagem~aceitarViagem RESULT result.

    METHODS rejeitarViagem FOR MODIFY
      IMPORTING keys FOR ACTION Viagem~rejeitarViagem RESULT result.

    METHODS calcularPrecoTotal FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Viagem~calcularPrecoTotal.

    METHODS recalcularPrecoTotal FOR MODIFY
      IMPORTING keys FOR ACTION Viagem~recalcularPrecoTotal.

    METHODS definirStatusInicial FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Viagem~definirStatusInicial.

    METHODS calcularViagemID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Viagem~calcularViagemID.

    METHODS validarAgencia FOR VALIDATE ON SAVE
      IMPORTING keys FOR Viagem~validarAgencia.

    METHODS validarCliente FOR VALIDATE ON SAVE
      IMPORTING keys FOR Viagem~validarCliente.

    METHODS validarDatas FOR VALIDATE ON SAVE
      IMPORTING keys FOR Viagem~validarDatas.

    METHODS permitido_modificar IMPORTING iv_verifica_status  TYPE abap_bool
                                          iv_status_viagem    TYPE /dmo/overall_status
                                RETURNING VALUE(rv_permitido) TYPE abap_bool.

    METHODS permitido_deletar IMPORTING iv_verifica_status  TYPE abap_bool
                                        iv_status_viagem    TYPE /dmo/overall_status
                              RETURNING VALUE(rv_permitido) TYPE abap_bool.

    METHODS permitido_criar  RETURNING VALUE(rv_permitido) TYPE abap_bool.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Viagem RESULT result.

ENDCLASS.

CLASS lcl_Viagem IMPLEMENTATION.

  METHOD get_instance_features.

    " Recupera as viagens
    READ ENTITIES OF yi_viagem_dflc  IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( StatusViagem ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens)
      FAILED failed.

    result =
      VALUE #(
        FOR <ls_viagem> IN lt_viagens
          LET lv_aceito   =   COND #( WHEN <ls_viagem>-StatusViagem = status_viagem-aceito
                                      THEN if_abap_behv=>fc-o-disabled
                                      ELSE if_abap_behv=>fc-o-enabled  )
              lv_rejeitdo =   COND #( WHEN <ls_viagem>-StatusViagem = status_viagem-cancelado
                                      THEN if_abap_behv=>fc-o-disabled
                                      ELSE if_abap_behv=>fc-o-enabled )
          IN
            ( %tky                   = <ls_viagem>-%tky
              %action-aceitarViagem  = lv_aceito
              %action-rejeitarViagem = lv_rejeitdo
             ) ).

  ENDMETHOD.

  METHOD aceitarViagem.

    " Marca como aceito
    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
         UPDATE
           FIELDS ( StatusViagem )
           WITH VALUE #( FOR key IN keys
                           ( %tky         = key-%tky
                             StatusViagem = status_viagem-aceito ) )
      FAILED failed
      REPORTED reported.


    " Retorno
    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    result = VALUE #( FOR <ls_viagem> IN lt_viagens
                        ( %tky   = <ls_viagem>-%tky
                          %param = <ls_viagem> ) ).

  ENDMETHOD.

  METHOD calcularPrecoTotal.

    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
       ENTITY Viagem
         EXECUTE recalcularPrecoTotal
         FROM CORRESPONDING #( keys )
       REPORTED DATA(ls_recalcular_mensagens).

    reported = CORRESPONDING #( DEEP ls_recalcular_mensagens ).

  ENDMETHOD.

  METHOD recalcularPrecoTotal.

    TYPES: BEGIN OF ty_total_por_codigo_moeda,
             total        TYPE /dmo/total_price,
             codigo_moeda TYPE /dmo/currency_code,
           END OF ty_total_por_codigo_moeda.

    DATA: lt_total_por_codigo_moeda TYPE STANDARD TABLE OF ty_total_por_codigo_moeda.

    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
          ENTITY Viagem
             FIELDS ( TaxaReserva CodigoMoeda )
             WITH CORRESPONDING #( keys )
          RESULT DATA(lt_viagens).

    DELETE lt_viagens WHERE CodigoMoeda IS INITIAL.

    LOOP AT lt_viagens ASSIGNING FIELD-SYMBOL(<ls_viagem>).

      lt_total_por_codigo_moeda = VALUE #( ( total        = <ls_viagem>-TaxaReserva
                                             codigo_moeda = <ls_viagem>-CodigoMoeda ) ).

      READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
         ENTITY Viagem BY \_Reserva
            FIELDS ( PrecoVoo CodigoMoeda )
          WITH VALUE #( ( %tky = <ls_viagem>-%tky ) )
          RESULT DATA(lt_reservas).

      LOOP AT lt_reservas REFERENCE INTO DATA(lo_reserva) WHERE CodigoMoeda IS NOT INITIAL.

        COLLECT VALUE ty_total_por_codigo_moeda( total        = lo_reserva->PrecoVoo
                                                 codigo_moeda = lo_reserva->CodigoMoeda ) INTO lt_total_por_codigo_moeda.

      ENDLOOP.

      CLEAR <ls_viagem>-PrecoTotal.

      LOOP AT lt_total_por_codigo_moeda INTO DATA(single_total_per_CodigoMoeda).

        " Converte a moeda se necessário
        IF single_total_per_CodigoMoeda-codigo_moeda = <ls_viagem>-CodigoMoeda.

          <ls_viagem>-PrecoTotal += single_total_per_CodigoMoeda-total.

        ELSE.

          /dmo/cl_flight_amdp=>convert_currency(
             EXPORTING
               iv_amount                   =  single_total_per_CodigoMoeda-total
               iv_currency_code_source     =  single_total_per_CodigoMoeda-codigo_moeda
               iv_currency_code_target     =  <ls_viagem>-CodigoMoeda
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             IMPORTING
               ev_amount                   = DATA(total_Reserva_price_per_curr)
            ).

          <ls_viagem>-PrecoTotal += total_Reserva_price_per_curr.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    " Modifica o valor do preço total
    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        UPDATE FIELDS ( PrecoTotal )
        WITH CORRESPONDING #( lt_viagens ).

  ENDMETHOD.

  METHOD rejeitarViagem.

    " Rejeitar
    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
       ENTITY Viagem
          UPDATE
            FIELDS ( StatusViagem )
            WITH VALUE #( FOR key IN keys
                            ( %tky         = key-%tky
                              StatusViagem = status_viagem-cancelado ) )
       FAILED failed
       REPORTED reported.

    " Resposta
    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    result = VALUE #( FOR <ls_viagem> IN lt_viagens
                        ( %tky   = <ls_viagem>-%tky
                          %param = <ls_viagem> ) ).

  ENDMETHOD.

  METHOD definirStatusInicial.

    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( StatusViagem ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    " Remove linhas que já estevem com status preenchidos
    DELETE lt_viagens WHERE StatusViagem IS NOT INITIAL.

    CHECK lt_viagens IS NOT INITIAL.

    " Adiciona status inicial
    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
    ENTITY Viagem
      UPDATE
        FIELDS ( StatusViagem )
        WITH VALUE #( FOR <ls_viagem> IN lt_viagens
                      ( %tky         = <ls_viagem>-%tky
                        StatusViagem = status_viagem-aberto ) )
    REPORTED DATA(lt_status_mensagens).

    reported = CORRESPONDING #( DEEP lt_status_mensagens ).

  ENDMETHOD.

  METHOD calcularViagemID.

    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( ViagemID ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    DELETE lt_viagens WHERE ViagemID IS NOT INITIAL.

    CHECK lt_viagens IS NOT INITIAL.

    " Seleciona o maior id cadastrado
    SELECT SINGLE
        FROM  ytviagem_dflc
        FIELDS MAX( viagem_id ) AS ViagemID
        INTO @DATA(lv_maior_id).

    " Adiciona o id
    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
    ENTITY Viagem
      UPDATE
        FROM VALUE #( FOR <ls_viagem> IN lt_viagens INDEX INTO lv_index (
          %tky              = <ls_viagem>-%tky
          ViagemID          = lv_maior_id + lv_index
          %control-ViagemID = if_abap_behv=>mk-on ) )
    REPORTED DATA(lt_viagem_id_mensagens).

    reported = CORRESPONDING #( DEEP lt_viagem_id_mensagens ).

  ENDMETHOD.

  METHOD validarAgencia.

    " Ler os dados da viagem para pegar a agência
    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( AgenciaID ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).


    DATA lt_agencias TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    " Pega todas as agencias selcionadas e retira as duplicadas.
    lt_agencias = CORRESPONDING #( lt_viagens DISCARDING DUPLICATES MAPPING agency_id = AgenciaID EXCEPT * ).

    DELETE lt_agencias WHERE agency_id IS INITIAL.

    IF lt_agencias IS NOT INITIAL.

      " Checa se existe
      SELECT FROM /dmo/agency FIELDS agency_id
        FOR ALL ENTRIES IN @lt_agencias
        WHERE agency_id = @lt_agencias-agency_id
        INTO TABLE @DATA(lt_agencias_banco).

    ENDIF.

    " Verifica a agencia preenchida
    LOOP AT lt_viagens REFERENCE INTO DATA(lo_viagem).

      " limpa o stado das mensagens
      APPEND VALUE #(  %tky               = lo_viagem->%tky
                       %state_area        = 'VALIDAR_AGENCIA' )
        TO reported-viagem.

      IF lo_viagem->AgenciaID IS INITIAL
      OR NOT line_exists( lt_agencias_banco[ agency_id = lo_viagem->AgenciaID ] ).

        "Marca como falha
        APPEND VALUE #( %tky = lo_viagem->%tky ) TO failed-viagem.

        "Adiciona mensagem de erro
        APPEND VALUE #( %tky        = lo_viagem->%tky
                        %state_area = 'VALIDAR_AGENCIA'
                        %msg        = NEW ycx_viagem_dflc( iv_tipo      = if_abap_behv_message=>severity-error
                                                           iv_id        = ycx_viagem_dflc=>agencia_nao_existe
                                                           iv_agenciaid = lo_viagem->AgenciaID )
                        %element-AgenciaID = if_abap_behv=>mk-on )
          TO reported-viagem.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validarCliente.

    " Ler dados da viagem
    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( ClienteID ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    DATA lt_clientes TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Pega os códigos do cliente retirando os possíveis duplicados
    lt_clientes = CORRESPONDING #( lt_viagens DISCARDING DUPLICATES MAPPING customer_id = ClienteID EXCEPT * ).

    DELETE lt_clientes WHERE customer_id IS INITIAL.

    IF lt_clientes IS NOT INITIAL.

      " Pega os clientes do banco de dados
      SELECT FROM /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @lt_clientes
        WHERE customer_id = @lt_clientes-customer_id
        INTO TABLE @DATA(lt_clientes_banco).

    ENDIF.

    " Verifica os clientes
    LOOP AT lt_viagens REFERENCE INTO DATA(lo_viagem).

      " limpa estado das mensagens
      APPEND VALUE #(  %tky        = lo_viagem->%tky
                       %state_area = 'VALIDAR_CLIENTE' )
        TO reported-viagem.

      IF lo_viagem->ClienteID IS INITIAL
      OR NOT line_exists( lt_clientes_banco[ customer_id = lo_viagem->ClienteID ] ).

        APPEND VALUE #(  %tky = lo_viagem->%tky ) TO failed-viagem.

        APPEND VALUE #(  %tky        = lo_viagem->%tky
                         %state_area = 'VALIDAR_CLIENTE'
                         %msg        = NEW ycx_viagem_dflc( iv_tipo      = if_abap_behv_message=>severity-error
                                                            iv_id        = ycx_viagem_dflc=>cliente_nao_existe
                                                            iv_clienteid = lo_viagem->ClienteID  )
                         %element-ClienteID = if_abap_behv=>mk-on )

          TO reported-viagem.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validarDatas.

    " Ler dados de viagem
    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( ViagemID DataInicio DataFim ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    " Realiza verredura nas viagens para verificar
    LOOP AT lt_viagens REFERENCE INTO DATA(lo_viagem).

      " limpa estado
      APPEND VALUE #(  %tky        = lo_viagem->%tky
                       %state_area = 'VALIDAR_DATAS' )
        TO reported-viagem.

      IF lo_viagem->DataFim < lo_viagem->DataInicio.

        APPEND VALUE #( %tky = lo_viagem->%tky ) TO failed-viagem.

        APPEND VALUE #( %tky               = lo_viagem->%tky
                        %state_area        = 'VALIDAR_DATAS'
                        %msg               = NEW ycx_viagem_dflc( iv_tipo       = if_abap_behv_message=>severity-error
                                                                  iv_id         = ycx_viagem_dflc=>data_inicio_maior_data_fim
                                                                  iv_datainicio = lo_viagem->DataInicio
                                                                  iv_datafim    = lo_viagem->DataFim
                                                                  iv_viagemid   = lo_viagem->ViagemID )
                        %element-DataInicio = if_abap_behv=>mk-on
                        %element-DataFim    = if_abap_behv=>mk-on ) TO reported-viagem.

      ELSEIF lo_viagem->DataInicio < cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #( %tky               = lo_viagem->%tky ) TO failed-viagem.

        APPEND VALUE #( %tky               = lo_viagem->%tky
                        %state_area        = 'VALIDAR_DATAS'
                        %msg               = NEW ycx_viagem_dflc( iv_tipo      = if_abap_behv_message=>severity-error
                                                                  iv_id    = ycx_viagem_dflc=>data_inicio_menor_data_sistema
                                                                  iv_datainicio = lo_viagem->DataInicio )
                        %element-DataInicio = if_abap_behv=>mk-on ) TO reported-viagem.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD permitido_criar.

    AUTHORITY-CHECK OBJECT 'YOSTS_DFLC'
        ID 'YOSTS_DFLC' DUMMY
        ID 'ACTVT' FIELD '01'.

    rv_permitido = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    " Como é apenas uma simulação marcamos aqui como permitido
    rv_permitido = abap_true.

  ENDMETHOD.


  METHOD permitido_deletar.

    IF iv_verifica_status = abap_true.

      AUTHORITY-CHECK OBJECT 'YOSTS_DFLC'
        ID 'YOSTS_DFLC' FIELD iv_status_viagem
        ID 'ACTVT' FIELD '06'.

    ELSE.

      AUTHORITY-CHECK OBJECT 'YOSTS_DFLC'
        ID 'YOSTS_DFLC' DUMMY
        ID 'ACTVT' FIELD '06'.

    ENDIF.

    rv_permitido = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    " Simulação de permissão total
    rv_permitido = abap_true.

  ENDMETHOD.


  METHOD permitido_modificar.

    IF iv_verifica_status = abap_true.

      AUTHORITY-CHECK OBJECT 'YOSTS_DFLC'
        ID 'YOSTS_DFLC' FIELD iv_status_viagem
        ID 'ACTVT' FIELD '02'.

    ELSE.

      AUTHORITY-CHECK OBJECT 'YOSTS_DFLC'
        ID 'YOSTS_DFLC' DUMMY
        ID 'ACTVT' FIELD '02'.

    ENDIF.

    rv_permitido = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    " Simulatndo acesso total.
    rv_permitido = abap_true.

  ENDMETHOD.


  METHOD get_instance_authorizations.

    DATA: lv_verifica_status       TYPE abap_bool,
          lv_atualizacao_requerida TYPE abap_bool,
          lv_exclusao_requerida    TYPE abap_bool,
          lv_atualizacao_permitida TYPE abap_bool,
          lv_exclusao_permitida    TYPE abap_bool.

    DATA: lt_falhas_viagem LIKE LINE OF failed-Viagem.

    " Read the existing travels
    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( StatusViagem ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens)
      FAILED failed.

    CHECK lt_viagens IS NOT INITIAL.

    "   In this example the authorization is defined based on the Activity + Travel Status
    "   For the Travel Status we need the before-image from the database. We perform this for active (is_draft=00) as well as for drafts (is_draft=01) as we can't distinguish between edit or new drafts
    SELECT FROM ytviagem_dflc
      FIELDS viagem_uuid, status_geral
      FOR ALL ENTRIES IN @lt_viagens
      WHERE viagem_uuid EQ @lt_viagens-ViagemUUID
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_viagens_gravadas).

    lv_atualizacao_requerida = COND #( WHEN requested_authorizations-%update                = if_abap_behv=>mk-on OR
                                            requested_authorizations-%action-aceitarViagem  = if_abap_behv=>mk-on OR
                                            requested_authorizations-%action-rejeitarViagem = if_abap_behv=>mk-on OR
                                            requested_authorizations-%action-Prepare        = if_abap_behv=>mk-on OR
                                            requested_authorizations-%action-Edit           = if_abap_behv=>mk-on OR
                                            requested_authorizations-%assoc-_Reserva        = if_abap_behv=>mk-on
                                       THEN abap_true ELSE abap_false ).

    lv_exclusao_requerida = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                                    THEN abap_true ELSE abap_false ).

    LOOP AT lt_viagens REFERENCE INTO DATA(lo_viagem).

      lv_atualizacao_permitida = lv_exclusao_permitida = abap_false.

      READ TABLE lt_viagens_gravadas REFERENCE INTO DATA(lo_viagem_gravada)
           WITH KEY viagem_uuid = lo_viagem->ViagemUUID BINARY SEARCH.

      lv_verifica_status = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

      IF lv_atualizacao_requerida = abap_true.

        IF lv_verifica_status = abap_true.

          lv_atualizacao_permitida = permitido_modificar( iv_verifica_status = lv_verifica_status  iv_status_viagem = lo_viagem_gravada->status_geral ).

          IF lv_atualizacao_permitida = abap_false.

            APPEND VALUE #( %tky        = lo_viagem->%tky
                            %msg        = NEW ycx_viagem_dflc( iv_tipo = if_abap_behv_message=>severity-error
                                                               iv_id   = ycx_viagem_dflc=>sem_autorizacao )
                          ) TO reported-Viagem.

          ENDIF.

          " Como não existe uma viagem já gravada em tabela, ele valida como criação
        ELSE.

          lv_atualizacao_permitida = permitido_criar( ).

          IF lv_atualizacao_permitida = abap_false.

            APPEND VALUE #( %tky        = lo_viagem->%tky
                            %msg        = NEW ycx_viagem_dflc( iv_tipo = if_abap_behv_message=>severity-error
                                                               iv_id   = ycx_viagem_dflc=>sem_autorizacao )
                          ) TO reported-Viagem.

          ENDIF.

        ENDIF.

      ENDIF.

      IF  lv_exclusao_requerida = abap_true.

        DATA(lv_status) = COND #( WHEN lo_viagem_gravada IS BOUND
                                        THEN lo_viagem_gravada->status_geral
                                        ELSE 'O ' ).

        lv_exclusao_permitida = permitido_deletar( iv_verifica_status = lv_verifica_status  iv_status_viagem = lv_status ).

        IF lv_exclusao_permitida = abap_false.

          APPEND VALUE #( %tky        = lo_viagem->%tky
                          %msg        = NEW ycx_viagem_dflc( iv_tipo = if_abap_behv_message=>severity-error
                                                             iv_id   = ycx_viagem_dflc=>sem_autorizacao )
                          ) TO reported-Viagem.

        ENDIF.

      ENDIF.

      APPEND VALUE #( %tky = lo_viagem->%tky
                      %update                = COND #( WHEN lv_atualizacao_permitida = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %action-aceitarViagem  = COND #( WHEN lv_atualizacao_permitida = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %action-rejeitarViagem = COND #( WHEN lv_atualizacao_permitida = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %action-Prepare        = COND #( WHEN lv_atualizacao_permitida = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %action-Edit           = COND #( WHEN lv_atualizacao_permitida = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %assoc-_Reserva        = COND #( WHEN lv_atualizacao_permitida = abap_true THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                      %delete                = COND #( WHEN lv_exclusao_permitida = abap_true    THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
                    )
        TO result.

    ENDLOOP.

  ENDMETHOD.


ENDCLASS.
