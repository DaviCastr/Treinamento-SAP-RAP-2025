CLASS lcl_Reserva DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Reserva.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Reserva.

    METHODS read FOR READ
      IMPORTING keys FOR READ Reserva RESULT result.

    METHODS rba_Viagem FOR READ
      IMPORTING keys_rba FOR READ Reserva\_Viagem FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lcl_Reserva IMPLEMENTATION.

  METHOD update.

    DATA lt_mensagens TYPE /dmo/t_message.
    DATA ls_entidade_legada_entrada  TYPE /dmo/booking.
    DATA ls_entidade_legada_x TYPE /dmo/s_booking_inx.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

      ls_entidade_legada_entrada = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).

      ls_entidade_legada_x-booking_id  = <entity>-ReservaID.
      ls_entidade_legada_x-_intx       = CORRESPONDING ysrap_reserva_x_dflc( <entity> MAPPING FROM ENTITY ).
      ls_entidade_legada_x-action_code = /dmo/if_flight_legacy=>action_code-update.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = VALUE /dmo/s_travel_in( travel_id = <entity>-ViagemID )
          is_travelx  = VALUE /dmo/s_travel_inx( travel_id = <entity>-ViagemID )
          it_booking  = VALUE /dmo/t_booking_in( ( CORRESPONDING #( ls_entidade_legada_entrada ) ) )
          it_bookingx = VALUE /dmo/t_booking_inx( ( ls_entidade_legada_x ) )
        IMPORTING
          et_messages = lt_mensagens.



      IF lt_mensagens IS INITIAL.

        APPEND VALUE #( ViagemID  = <entity>-ViagemID
                        ReservaID = ls_entidade_legada_entrada-booking_id ) TO mapped-Reserva.

      ELSE.

        "Falha
        APPEND VALUE #( ViagemID  = <entity>-ViagemID
                        ReservaID = ls_entidade_legada_entrada-booking_id ) TO failed-Reserva.

        LOOP AT lt_mensagens REFERENCE INTO DATA(lo_mensagem).

          "Mensagens
          APPEND VALUE #( ViagemID  = <entity>-ViagemID
                          ReservaID = ls_entidade_legada_entrada-booking_id
                          %msg      = new_message( id       = lo_mensagem->msgid
                                                   number   = lo_mensagem->msgno
                                                   v1       = lo_mensagem->msgv1
                                                   v2       = lo_mensagem->msgv2
                                                   v3       = lo_mensagem->msgv3
                                                   v4       = lo_mensagem->msgv4
                                                   severity = CONV #( lo_mensagem->msgty ) )
         ) TO reported-Reserva.

        ENDLOOP.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD delete.

    DATA lt_mensagens TYPE /dmo/t_message.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = VALUE /dmo/s_travel_in( travel_id = <key>-ViagemID )
          is_travelx  = VALUE /dmo/s_travel_inx( travel_id = <key>-ViagemID )
          it_booking  = VALUE /dmo/t_booking_in( ( booking_id = <key>-ReservaID ) )
          it_bookingx = VALUE /dmo/t_booking_inx( ( booking_id  = <key>-ReservaID
                                                    action_code = /dmo/if_flight_legacy=>action_code-delete ) )
        IMPORTING
          et_messages = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        APPEND VALUE #( ViagemID  = <key>-ViagemID
                        ReservaID = <key>-ReservaID ) TO mapped-Reserva.

      ELSE.

        "Falha
        APPEND VALUE #( ViagemID  = <key>-ViagemID
                        ReservaID = <key>-ReservaID ) TO failed-Reserva.

        LOOP AT lt_mensagens REFERENCE INTO DATA(lo_mensagem).

          "Mensagens
          APPEND VALUE #( ViagemID  = <key>-ViagemID
                          ReservaID = <key>-ReservaID
                          %msg      = new_message( id       = lo_mensagem->msgid
                                                   number   = lo_mensagem->msgno
                                                   v1       = lo_mensagem->msgv1
                                                   v2       = lo_mensagem->msgv2
                                                   v3       = lo_mensagem->msgv3
                                                   v4       = lo_mensagem->msgv4
                                                   severity = CONV #( lo_mensagem->msgty ) )
         ) TO reported-Reserva.

        ENDLOOP.


      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD read.

    DATA: ls_entidade_egada_pai_saida    TYPE /dmo/travel,
          lt_entidade_legada_filha_saida TYPE /dmo/t_booking,
          lt_mensagens                   TYPE /dmo/t_message.

    "Agrupa por viagens
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key_parent>)
                            GROUP BY <key_parent>-ViagemID .

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <key_parent>-ViagemID
        IMPORTING
          es_travel    = ls_entidade_egada_pai_saida
          et_booking   = lt_entidade_legada_filha_saida
          et_messages  = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        "Para cada viagem seleciona as reservas.
        LOOP AT GROUP <key_parent> ASSIGNING FIELD-SYMBOL(<key>)
                                       GROUP BY <key>-%key.

          READ TABLE lt_entidade_legada_filha_saida REFERENCE INTO DATA(lo_entidade_legada_filha)
                                                                 WITH KEY travel_id  = <key>-%key-ViagemID
                                                                          booking_id = <key>-%key-ReservaID .
          "Verifica se encontrou o registro solicitado
          IF sy-subrc = 0.

            INSERT CORRESPONDING #( lo_entidade_legada_filha->* MAPPING TO ENTITY ) INTO TABLE result.

          ELSE.

            "Caso não encontre retorna erro
            INSERT
              VALUE #( ViagemID    = <key>-ViagemID
                       ReservaID   = <key>-ReservaID
                       %fail-cause = if_abap_behv=>cause-not_found )
              INTO TABLE failed-reserva.

          ENDIF.

        ENDLOOP.

      ELSE.

        "Caso a viagem não exista
        LOOP AT GROUP <key_parent> ASSIGNING <key>.
          failed-Reserva = VALUE #(  BASE failed-reserva
                                     FOR msg IN lt_mensagens
                                     ( %key-ViagemID    = <key>-ViagemID
                                       %key-ReservaID   = <key>-ReservaID
                                       %fail-cause      = COND #( WHEN msg-msgty = 'E' AND ( msg-msgno = '016' OR msg-msgno = '009' )
                                                                     THEN if_abap_behv=>cause-not_found
                                                                     ELSE if_abap_behv=>cause-unspecific ) ) ).
        ENDLOOP.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD rba_Viagem.

    DATA: ls_viagem_saida  TYPE /dmo/travel,
          lt_reserva_saida TYPE /dmo/t_booking,
          ls_viagem        LIKE LINE OF result,
          lt_mensagens     TYPE /dmo/t_message.

    "Executa a função para pegar apenas a viagem e no caso uma execução por viagem.
    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<fs_viagem>)
                                 GROUP BY <fs_viagem>-ViagemID.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <fs_viagem>-%key-ViagemID
        IMPORTING
          es_travel    = ls_viagem_saida
          et_messages  = lt_mensagens.

      IF lt_mensagens IS INITIAL.

        LOOP AT GROUP <fs_viagem> ASSIGNING FIELD-SYMBOL(<fs_reserva>).

          "Preenche campos chaves na associação de navegação.
          INSERT VALUE #( source-%key = <fs_reserva>-%key
                          target-%key = ls_viagem_saida-travel_id )
           INTO TABLE association_links .

          IF  result_requested  = abap_true.

            "Preenche campos requisitados
            ls_viagem = CORRESPONDING #( ls_viagem_saida MAPPING TO ENTITY ).

            INSERT ls_viagem INTO TABLE result.

          ENDIF.

        ENDLOOP.

      ELSE.

        "Preenche com falhas em caso de erro.
        failed-Reserva = VALUE #(  BASE failed-reserva
                              FOR msg IN lt_mensagens
                              ( %key-ViagemID    = <fs_viagem>-%key-ViagemID
                                %key-ReservaID   = <fs_viagem>-%key-ReservaID
                                %fail-cause      = COND #( WHEN msg-msgty = 'E' AND ( msg-msgno = '016' OR msg-msgno = '009' )
                                                            THEN if_abap_behv=>cause-not_found
                                                            ELSE if_abap_behv=>cause-unspecific ) ) ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
