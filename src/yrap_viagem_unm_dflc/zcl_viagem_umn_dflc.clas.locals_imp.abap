CLASS lcl_Viagem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Viagem RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Viagem.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Viagem.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Viagem.

    METHODS read FOR READ
      IMPORTING keys FOR READ Viagem RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Viagem.

    METHODS rba_Reserva FOR READ
      IMPORTING keys_rba FOR READ Viagem\_Reserva FULL result_requested RESULT result LINK association_links.

    METHODS cba_Reserva FOR MODIFY
      IMPORTING entities_cba FOR CREATE Viagem\_Reserva.

ENDCLASS.

CLASS lcl_Viagem IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA lt_mensagens               TYPE /dmo/t_message.
    DATA ls_entidade_legada_entrada TYPE /dmo/travel.
    DATA ls_entidade_legada_saida   TYPE /dmo/travel.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

      ls_entidade_legada_entrada = CORRESPONDING #( <entity> MAPPING FROM ENTITY USING CONTROL ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_CREATE'
        EXPORTING
          is_travel   = CORRESPONDING /dmo/s_travel_in( ls_entidade_legada_entrada )
        IMPORTING
          es_travel   = ls_entidade_legada_saida
          et_messages = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        APPEND VALUE #( %cid     = <entity>-%cid
                        ViagemID = ls_entidade_legada_saida-travel_id ) TO mapped-Viagem.

      ELSE.

        "Preenche
        APPEND VALUE #( ViagemID = ls_entidade_legada_saida-travel_id ) TO failed-Viagem.

        "fill reported structure to be displayed on the UI
        APPEND VALUE #( ViagemID = ls_entidade_legada_saida-travel_id
                        %msg     = new_message( id       = lt_mensagens[ 1 ]-msgid
                                                number   = lt_mensagens[ 1 ]-msgno
                                                v1       = lt_mensagens[ 1 ]-msgv1
                                                v2       = lt_mensagens[ 1 ]-msgv2
                                                v3       = lt_mensagens[ 1 ]-msgv3
                                                v4       = lt_mensagens[ 1 ]-msgv4
                                                severity = CONV #( lt_mensagens[ 1 ]-msgty ) )
       ) TO reported-Viagem.


      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    DATA ls_entidade_legada_entrada TYPE /dmo/travel.
    DATA ls_entidade_legada_x       TYPE /dmo/s_travel_inx . "referência para x de estrutura da (> BAPIs)
    DATA lt_mensagens               TYPE /dmo/t_message.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

      ls_entidade_legada_entrada = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).
      ls_entidade_legada_x-travel_id = <entity>-ViagemID.
      ls_entidade_legada_x-_intx = CORRESPONDING ysrap_viagem_x_dflc( <entity> MAPPING FROM ENTITY ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = CORRESPONDING /dmo/s_travel_in( ls_entidade_legada_entrada )
          is_travelx  = ls_entidade_legada_x
        IMPORTING
          et_messages = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        APPEND VALUE #( ViagemID = ls_entidade_legada_entrada-travel_id ) TO mapped-Viagem.

      ELSE.

        "Falhas
        APPEND VALUE #( ViagemID = ls_entidade_legada_entrada-travel_id ) TO failed-Viagem.
        "Mensagens
        APPEND VALUE #( ViagemID = ls_entidade_legada_entrada-travel_id
                        %msg = new_message( id       = lt_mensagens[ 1 ]-msgid
                                            number   = lt_mensagens[ 1 ]-msgno
                                            v1       = lt_mensagens[ 1 ]-msgv1
                                            v2       = lt_mensagens[ 1 ]-msgv2
                                            v3       = lt_mensagens[ 1 ]-msgv3
                                            v4       = lt_mensagens[ 1 ]-msgv4
                                            severity = CONV #( lt_mensagens[ 1 ]-msgty ) )
       ) TO reported-Viagem.

      ENDIF.


    ENDLOOP.

  ENDMETHOD.

  METHOD delete.

    DATA lt_mensagens TYPE /dmo/t_message.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_DELETE'
        EXPORTING
          iv_travel_id = <key>-ViagemID
        IMPORTING
          et_messages  = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        APPEND VALUE #( ViagemID = <key>-ViagemID ) TO mapped-Viagem.

      ELSE.

        "Falhas
        APPEND VALUE #( ViagemID = <key>-ViagemID ) TO failed-Viagem.

        "Mensagens para exibir no front-end
        APPEND VALUE #( ViagemID = <key>-ViagemID
                        %msg = new_message( id       = lt_mensagens[ 1 ]-msgid
                                            number   = lt_mensagens[ 1 ]-msgno
                                            v1       = lt_mensagens[ 1 ]-msgv1
                                            v2       = lt_mensagens[ 1 ]-msgv2
                                            v3       = lt_mensagens[ 1 ]-msgv3
                                            v4       = lt_mensagens[ 1 ]-msgv4
                                            severity = CONV #( lt_mensagens[ 1 ]-msgty ) )
       ) TO reported-Viagem.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    DATA: ls_entidade_legada_saida TYPE /dmo/travel,
          lt_mensagens             TYPE /dmo/t_message.

    LOOP AT keys INTO DATA(key) GROUP BY key-ViagemID.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = key-ViagemID
        IMPORTING
          es_travel    = ls_entidade_legada_saida
          et_messages  = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        "PReenche resultado
        INSERT CORRESPONDING #( ls_entidade_legada_saida MAPPING TO ENTITY ) INTO TABLE result.

      ELSE.

        "Falha
        APPEND VALUE #( ViagemID = key-ViagemID ) TO failed-Viagem.

        LOOP AT lt_mensagens INTO DATA(ls_mensagem).

          "Mensagens
          APPEND VALUE #( ViagemID = key-ViagemID
                          %msg = new_message( id       = ls_mensagem-msgid
                                              number   = ls_mensagem-msgno
                                              v1       = ls_mensagem-msgv1
                                              v2       = ls_mensagem-msgv2
                                              v3       = ls_mensagem-msgv3
                                              v4       = ls_mensagem-msgv4
                                              severity = CONV #( ls_mensagem-msgty ) )


         ) TO reported-Viagem.

        ENDLOOP.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD lock.

    "Pegando objeto de bloqueio da tabela
    TRY.
        DATA(lock) = cl_abap_lock_object_factory=>get_instance( iv_name = '/DMO/ETRAVEL' ).
      CATCH cx_abap_lock_failure.
        "handle exception
    ENDTRY.


    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      TRY.

          TRY.
              "Nome do campo na tabela
              lock->enqueue(
                  it_parameter  = VALUE #( (  name = 'TRAVEL_ID' value = REF #( <key>-ViagemID ) ) )
              ).
            CATCH cx_abap_lock_failure.
              "handle exception
          ENDTRY.

          "Se já existir bloqueio
        CATCH cx_abap_foreign_lock INTO DATA(lx_foreign_lock).

          "Falha
          APPEND VALUE #( ViagemID = <key>-ViagemID ) TO failed-Viagem.
          "Mensagens
          APPEND VALUE #( ViagemID = <key>-ViagemID
                          %msg = new_message( id = '/DMO/CM_FLIGHT_LEGAC'
                                              number = '032'
                                              v1 = <key>-ViagemID
                                              v2 = lx_foreign_lock->user_name
                                              severity = CONV #( 'E' ) )
         ) TO reported-Viagem.

      ENDTRY.

    ENDLOOP.

  ENDMETHOD.

  METHOD rba_Reserva.

    DATA: ls_entidade_legada_pai_saida   TYPE /dmo/travel,
          lt_entidade_legada_filha_saida TYPE /dmo/t_booking,
          ls_reserva_entidade            LIKE LINE OF result,
          lt_mensagens                   TYPE /dmo/t_message.

    LOOP AT keys_rba  ASSIGNING FIELD-SYMBOL(<key_rba>) GROUP  BY <key_rba>-ViagemID.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <key_rba>-ViagemID
        IMPORTING
          es_travel    = ls_entidade_legada_pai_saida
          et_booking   = lt_entidade_legada_filha_saida
          et_messages  = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        LOOP AT lt_entidade_legada_filha_saida ASSIGNING FIELD-SYMBOL(<fs_booking>).

          "Preenche os campos chaves
          INSERT
            VALUE #(
                source-%key = <key_rba>-%key
                target-%key = VALUE #(
                  ViagemID  = <fs_booking>-travel_id
                  ReservaID = <fs_booking>-booking_id
              )
            )
            INTO TABLE  association_links .

          "Retorna campos requisitados
          IF result_requested = abap_true.

            ls_reserva_entidade = CORRESPONDING #( <fs_booking> MAPPING TO ENTITY ).
            INSERT ls_reserva_entidade INTO TABLE result.

          ENDIF.

        ENDLOOP.

      ELSE.

        "Em caso de erro
        failed-Viagem = VALUE #(
          BASE failed-Viagem
          FOR msg IN lt_mensagens (
            %key = <key_rba>-ViagemID
            %fail-cause = COND #(
              WHEN msg-msgty = 'E' AND  ( msg-msgno = '016' OR msg-msgno = '009' )
              THEN if_abap_behv=>cause-not_found
              ELSE if_abap_behv=>cause-unspecific
            )
          )
        ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD cba_Reserva.

    DATA lt_mensagens        TYPE /dmo/t_message.
    DATA lt_reserva_lista    TYPE /dmo/t_booking.
    DATA ls_reserva_entidade TYPE /dmo/booking.
    DATA lv_reserva_id       TYPE /dmo/booking_id VALUE '0'.

    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<entity_cba>).

      DATA(lv_ViagemID) = <entity_cba>-ViagemID.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = lv_ViagemID
        IMPORTING
          et_booking   = lt_reserva_lista
          et_messages  = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        IF lt_reserva_lista IS NOT INITIAL.

          "Recupera último ID de reserva para a viagem
          lv_reserva_id = lt_reserva_lista[ lines( lt_reserva_lista ) ]-booking_id.

        ENDIF.

        LOOP AT <entity_cba>-%target ASSIGNING FIELD-SYMBOL(<entity>).

          ls_reserva_entidade = CORRESPONDING #( <entity> MAPPING FROM ENTITY USING CONTROL ) .

          lv_reserva_id += 1.
          ls_reserva_entidade-booking_id = lv_reserva_id.

          CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
            EXPORTING
              is_travel   = VALUE /dmo/s_travel_in( travel_id = lv_viagemid )
              is_travelx  = VALUE /dmo/s_travel_inx( travel_id = lv_viagemid )
              it_booking  = VALUE /dmo/t_booking_in( ( CORRESPONDING #( ls_reserva_entidade ) ) )
              it_bookingx = VALUE /dmo/t_booking_inx(
                (
                  booking_id  = ls_reserva_entidade-booking_id
                  action_code = /dmo/if_flight_legacy=>action_code-create
                )
              )
            IMPORTING
              et_messages = lt_mensagens.

          IF lt_mensagens IS INITIAL.

            INSERT
              VALUE #(
                %cid = <entity>-%cid
                ViagemID = lv_viagemid
                ReservaID = ls_reserva_entidade-booking_id
              )
              INTO TABLE mapped-reserva.

          ELSE.


            INSERT VALUE #( %cid = <entity>-%cid ViagemID = lv_viagemid ) INTO TABLE failed-Reserva.

            LOOP AT lt_mensagens INTO DATA(ls_mensagem) WHERE msgty = 'E' OR msgty = 'A'.

              INSERT
                 VALUE #(
                   %cid       = <entity>-%cid
                   ViagemID   = <entity>-ViagemID
                   %msg       = new_message( id       = ls_mensagem-msgid
                                             number   = ls_mensagem-msgno
                                             severity = if_abap_behv_message=>severity-error
                                             v1       = ls_mensagem-msgv1
                                             v2       = ls_mensagem-msgv2
                                             v3       = ls_mensagem-msgv3
                                             v4       = ls_mensagem-msgv4 ) )
                 INTO TABLE reported-Reserva.

            ENDLOOP.

          ENDIF.

        ENDLOOP.

      ELSE.

        "Falha
        APPEND VALUE #( ViagemID = lv_viagemid ) TO failed-Viagem.
        "Mensagens
        APPEND VALUE #( ViagemID = lv_viagemid
                        %msg = new_message( id       = lt_mensagens[ 1 ]-msgid
                                            number   = lt_mensagens[ 1 ]-msgno
                                            v1       = lt_mensagens[ 1 ]-msgv1
                                            v2       = lt_mensagens[ 1 ]-msgv2
                                            v3       = lt_mensagens[ 1 ]-msgv3
                                            v4       = lt_mensagens[ 1 ]-msgv4
                                            severity = CONV #( lt_mensagens[ 1 ]-msgty ) )
       ) TO reported-viagem.


      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_YI_VIAGEM_UMN_DFLC DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_YI_VIAGEM_UMN_DFLC IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.

    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_SAVE'.

  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
