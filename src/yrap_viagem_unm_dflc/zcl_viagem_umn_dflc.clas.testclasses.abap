*"* use this source file for your ABAP unit test classes
CLASS ltcl_integration_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA:
      gv_cds_teste TYPE REF TO if_cds_test_environment.

    CLASS-METHODS:
      configuracao_classe,
      reseta_classe.

    METHODS:
      configuracao,
      reseta.

    METHODS:
      criar_viagem FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltcl_integration_test IMPLEMENTATION.

  METHOD criar_viagem.

    DATA(lv_hoje) = cl_abap_context_info=>get_system_date( ).
    DATA lt_viagens_entrada TYPE TABLE FOR CREATE yi_viagem_umn_dflc\\Viagem.

    lt_viagens_entrada = VALUE #( ( %cid        = 0
                                    agenciaid   = 070001   "Agencia 070001 existe, Agencia 1 não existe
                                    ClienteID   = 1
                                    DataInicio  = lv_hoje
                                    DataFim     = lv_hoje + 30
                                    TaxaReserva = 30
                                    PrecoTotal  = 330
                                    CodigoMoeda = 'EUR'
                                    Descricao   = |Test travel XYZ| ) ).

    MODIFY ENTITIES OF yi_viagem_umn_dflc
        ENTITY Viagem
           CREATE FIELDS (    AgenciaID
                              ClienteID
                              DataInicio
                              DataFim
                              TaxaReserva
                              PrecoTotal
                              CodigoMoeda
                              Descricao
                              Status )
             WITH lt_viagens_entrada
         MAPPED   DATA(mapped)
         FAILED   DATA(failed)
         REPORTED DATA(reported).

    cl_abap_unit_assert=>assert_initial( failed-viagem ).
    cl_abap_unit_assert=>assert_initial( reported-viagem ).

    COMMIT ENTITIES.

    DATA(lv_novo_id_viagem) = mapped-viagem[ 1 ]-ViagemID.

    SELECT * FROM yi_viagem_umn_dflc WHERE ViagemID = @lv_novo_id_viagem INTO TABLE @DATA(lt_viagem)  .

    cl_abap_unit_assert=>assert_not_initial( lt_viagem ).

    cl_abap_unit_assert=>assert_not_initial(
           VALUE #( lt_viagem[  ViagemID = lv_novo_id_viagem ] OPTIONAL )
       ).

    cl_abap_unit_assert=>assert_equals(
        exp = 'N'
        act = lt_viagem[ ViagemID = lv_novo_id_viagem ]-Status
      ).

  ENDMETHOD.

  METHOD configuracao_classe.

    gv_cds_teste = cl_cds_test_environment=>create_for_multiple_cds(
        i_for_entities = VALUE #( ( i_for_entity = 'yi_viagem_umn_dflc' )
                                  ( i_for_entity = 'yi_reserva_umn_dflc' ) )

                                ).
  ENDMETHOD.

  METHOD reseta_classe.
    gv_cds_teste->destroy( ).
  ENDMETHOD.

  METHOD configuracao.
  ENDMETHOD.

  METHOD reseta.

    ROLLBACK ENTITIES.
    gv_cds_teste->clear_doubles( ).

  ENDMETHOD.

ENDCLASS.
