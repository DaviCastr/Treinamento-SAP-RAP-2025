CLASS lcl_Reserva DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calcularReservaID FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Reserva~calcularReservaID.

    METHODS calcularPrecoTotal FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Reserva~calcularPrecoTotal.

ENDCLASS.

CLASS lcl_Reserva IMPLEMENTATION.

  METHOD calcularReservaID.

    DATA lv_max_reservaid TYPE /dmo/booking_id.
    DATA lt_atualizacao   TYPE TABLE FOR UPDATE yi_viagem_dflc\\Reserva.

    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
    ENTITY Reserva BY \_Viagem
      FIELDS ( ViagemUUID )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens).

    LOOP AT lt_viagens REFERENCE INTO DATA(lo_viagem).

      READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
        ENTITY Viagem BY \_Reserva
          FIELDS ( ReservaID )
        WITH VALUE #( ( %tky = lo_viagem->%tky ) )
        RESULT DATA(lt_reservas).

      lv_max_reservaid = '0000'.

      LOOP AT lt_reservas REFERENCE INTO DATA(lo_reserva).

        IF lo_reserva->ReservaID > lv_max_reservaid.

          lv_max_reservaid = lo_reserva->ReservaID.

        ENDIF.

      ENDLOOP.

      " Provide a Reserva ID for all Reservas that have none.
      LOOP AT lt_reservas REFERENCE INTO lo_reserva WHERE ReservaID IS INITIAL.

        lv_max_reservaid += 10.
        APPEND VALUE #( %tky      = lo_reserva->%tky
                        ReservaID = lv_max_reservaid
                      ) TO lt_atualizacao.

      ENDLOOP.

    ENDLOOP.

    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
    ENTITY Reserva
      UPDATE FIELDS ( ReservaID ) WITH lt_atualizacao
    REPORTED DATA(ls_atualizacao_mensagens).

    reported = CORRESPONDING #( DEEP ls_atualizacao_mensagens ).

  ENDMETHOD.

  METHOD calcularPrecoTotal.

    READ ENTITIES OF yi_viagem_dflc IN LOCAL MODE
    ENTITY Reserva BY \_Viagem
      FIELDS ( ViagemUUID )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_viagens)
      FAILED DATA(ls_falhas).


    MODIFY ENTITIES OF yi_viagem_dflc IN LOCAL MODE
    ENTITY Viagem
      EXECUTE recalcularPrecoTotal
      FROM CORRESPONDING #( lt_viagens )
    REPORTED DATA(ls_execucao_mensagens).

    reported = CORRESPONDING #( DEEP ls_execucao_mensagens ).

  ENDMETHOD.

ENDCLASS.
