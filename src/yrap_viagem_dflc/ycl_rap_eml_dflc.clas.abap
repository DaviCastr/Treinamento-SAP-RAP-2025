CLASS ycl_rap_eml_dflc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS: metodo_read   IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      metodo_create IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      metodo_update IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      metodo_delete IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.



CLASS ycl_rap_eml_dflc IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    "-->Operações de leitura
    "me->metodo_read( out = out ).

    "-->Operações de modificação
    "me->metodo_update( out = out ).

    "-->Operações de criação
    "me->metodo_create( out = out ).

    "-->Operações de exclusão
    me->metodo_delete( out = out ).

  ENDMETHOD.

  METHOD metodo_create.

    " 7 - MODIFY Create
    MODIFY ENTITIES OF yi_viagem_dflc
      ENTITY Viagem
        CREATE
          SET FIELDS WITH VALUE
            #( ( %cid        = 'ID'
                 AgenciaID   = '70012'
                 ClienteID   = '14'
                 DataInicio  = cl_abap_context_info=>get_system_date( )
                 DataFim     = cl_abap_context_info=>get_system_date( ) + 10
                 Descricao   = 'Eu gosto de RAP' ) )

     MAPPED DATA(ls_campos_mapeados)
     FAILED DATA(ls_falhas)
     REPORTED DATA(ls_mensagens).

    out->write( ls_campos_mapeados-Viagem ).

    COMMIT ENTITIES
      RESPONSE OF yi_viagem_dflc
      FAILED     DATA(ls_falhas_commit)
      REPORTED   DATA(ls_mensagens_commit).

    out->write( 'Criação concluída.' ).

  ENDMETHOD.

  METHOD metodo_delete.

    " 8 - MODIFY Delete
    MODIFY ENTITIES OF yi_viagem_dflc
      ENTITY Viagem
        DELETE FROM
          VALUE
            #( ( ViagemUUID  = '1E0416C6E6B71FE08EED33DA9CE6E611' ) )

     FAILED DATA(ls_falhas_delete)
     REPORTED DATA(ls_mensagens_delete).

    COMMIT ENTITIES
      RESPONSE OF yi_viagem_dflc
      FAILED     DATA(ls_falhas_commit)
      REPORTED   DATA(ls_mensagens_commit).

    out->write( 'Exclusão concluída' ).

  ENDMETHOD.

  METHOD metodo_read.

    " 1 - READ
    "READ ENTITIES OF YI_VIAGEM_DFLC
    "  ENTITY Viagem
    "    FROM VALUE #( ( ViagemUUID = '97E909E129B791571900FDE605BA7F5C' ) )
    "  RESULT DATA(lt_viagens).


    " 2 - READ com campos
    "READ ENTITIES OF YI_VIAGEM_DFLC
    "  ENTITY Viagem
    "    FIELDS ( AgenciaID ClienteID )
    "  WITH VALUE #( ( ViagemUUID = '97E909E129B791571900FDE605BA7F5C' ) )
    "  RESULT DATA(lt_viagens).


    " 3 - READ com todos os campos
    "READ ENTITIES OF YI_VIAGEM_DFLC
    "  ENTITY Viagem
    "    ALL FIELDS
    "  WITH VALUE #( ( ViagemUUID = '97E909E129B791571900FDE605BA7F5C' ) )
    "  RESULT DATA(lt_viagens).

    "out->write( lt_viagens ).


    " 4 - READ por associação
    "READ ENTITIES OF YI_VIAGEM_DFLC
    "  ENTITY Viagem BY \_Reserva
    "    ALL FIELDS WITH VALUE #( ( ViagemUUID = 'A7DA09E129B791571900FDE605BA7F5C' ) )
    "  RESULT DATA(lt_reservas).

    "out->write( lt_reservas ).


    " 5 - Falha no READ
    READ ENTITIES OF yi_viagem_dflc
      ENTITY Viagem
        ALL FIELDS WITH VALUE #( ( ViagemUUID = '11111111111111111111111111111111' ) )
      RESULT DATA(lt_viages)
      FAILED DATA(ls_falhas)
      REPORTED DATA(ls_mensagens).

    out->write( lt_viages ).
    out->write( ls_falhas ).
    out->write( ls_mensagens ).

  ENDMETHOD.

  METHOD metodo_update.

    " 6 - MODIFY Atualização
    MODIFY ENTITIES OF yi_viagem_dflc
      ENTITY Viagem
        UPDATE
          SET FIELDS WITH VALUE
            #( ( ViagemUUID  = 'A7DA09E129B791571900FDE605BA7F5C'
                 Descricao = 'Gosto muito de RAP' ) )

     FAILED DATA(ls_falhas)
     REPORTED DATA(ls_mensagens).

    " 6b - Commit Entities
    COMMIT ENTITIES
      RESPONSE OF yi_viagem_dflc
      FAILED     DATA(ls_falhas_commit)
      REPORTED   DATA(ls_mensagens_commit).

    out->write( 'Atualização concluída' ).

  ENDMETHOD.

ENDCLASS.
