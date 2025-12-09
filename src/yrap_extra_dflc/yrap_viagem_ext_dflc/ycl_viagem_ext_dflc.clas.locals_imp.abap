CLASS lcl_Viagem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validarAgencia FOR VALIDATE ON SAVE
      IMPORTING keys FOR Viagem~validarAgencia.
    METHODS testeAcao FOR MODIFY
      IMPORTING keys FOR ACTION Viagem~testeAcao.

ENDCLASS.

CLASS lcl_Viagem IMPLEMENTATION.

  METHOD validarAgencia.

    " Ler os dados da viagem para pegar a agência
    READ ENTITIES OF yi_viagem_ext_dflc IN LOCAL MODE
      ENTITY Viagem
        FIELDS ( AgenciaID ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    DATA lt_agencias TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    " Pega todas as agencias selcionadas e retira as duplicadas.
    lt_agencias = CORRESPONDING #( lt_viagens DISCARDING DUPLICATES MAPPING agency_id = AgenciaID EXCEPT * ).

    DELETE lt_agencias WHERE agency_id IS INITIAL.

    DATA lt_filtros       TYPE if_rap_query_filter=>tt_name_range_pairs .
    DATA lt_ranges        TYPE if_rap_query_filter=>tt_range_option .
    DATA lt_agencies_data TYPE TABLE OF ysc_agencia_dflc=>tys_z_travel_agency_es_5_type.

    IF lt_agencias IS NOT INITIAL.

      lt_ranges  = VALUE #( FOR <fs_agency> IN lt_agencias (  sign = 'I' option = 'EQ' low = <fs_agency>-agency_id ) ).
      lt_filtros = VALUE #( ( name = 'AGENCYID'  range = lt_ranges ) ).

      TRY.

          NEW ycl_ce_agencia_dflc( )->get_agencies(
            EXPORTING
              it_filters            = lt_filtros
              iv_is_data_requested  = abap_true
              iv_is_count_requested = abap_false
            IMPORTING
              et_agencies           = lt_agencies_data
            ) .

        CATCH /iwbep/cx_cp_remote
              /iwbep/cx_gateway
              cx_web_http_client_error
              cx_http_dest_provider_error

       INTO DATA(lo_excecao).

          DATA(lv_mensagem) = cl_message_helper=>get_latest_t100_exception( lo_excecao )->if_message~get_text( ) .

          LOOP AT lt_viagens REFERENCE INTO DATA(lo_viagem).

            APPEND VALUE #( %tky = lo_viagem->%tky ) TO failed-Viagem.

            APPEND VALUE #( %tky        = lo_viagem->%tky
                            %state_area = 'VALIDAR_AGENCIA'
                            %msg        =  new_message_with_text( severity = if_abap_behv_message=>severity-error text = lv_mensagem )
                            %element-AgenciaID = if_abap_behv=>mk-on )
              TO reported-Viagem.

          ENDLOOP.

          RETURN.

      ENDTRY.

    ENDIF.


    LOOP AT lt_viagens REFERENCE INTO lo_viagem.

      " limpa o stado das mensagens
      APPEND VALUE #(  %tky               = lo_viagem->%tky
                       %state_area        = 'VALIDAR_AGENCIA' )
        TO reported-viagem.

      IF lo_viagem->AgenciaID IS INITIAL
      OR NOT line_exists( lt_agencies_data[ agencyid = lo_viagem->AgenciaID ] ).

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

  METHOD testeAcao.


  ENDMETHOD.

ENDCLASS.
