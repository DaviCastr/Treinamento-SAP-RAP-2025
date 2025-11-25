CLASS ycx_viagem_dflc DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF Data_Inicio_Maior_Data_Fim,
        msgid TYPE symsgid VALUE 'YVIAGEM_MSG_DFLC',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'GV_DATAINICIO',
        attr2 TYPE scx_attrname VALUE 'GV_DATAFIM',
        attr3 TYPE scx_attrname VALUE 'GV_VIAGEMID',
        attr4 TYPE scx_attrname VALUE '',
      END OF Data_Inicio_Maior_Data_Fim .
    CONSTANTS:
      BEGIN OF Data_Inicio_Menor_Data_Sistema,
        msgid TYPE symsgid VALUE 'YVIAGEM_MSG_DFLC',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'GV_DATAINICIO',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF Data_Inicio_Menor_Data_Sistema .
    CONSTANTS:
      BEGIN OF Cliente_Nao_Existe,
        msgid TYPE symsgid VALUE 'YVIAGEM_MSG_DFLC',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'GV_CLIENTEID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF Cliente_Nao_Existe .
    CONSTANTS:
      BEGIN OF Agencia_Nao_Existe,
        msgid TYPE symsgid VALUE 'YVIAGEM_MSG_DFLC',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'GV_AGENCIAID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF Agencia_Nao_Existe .
    CONSTANTS:
      BEGIN OF Sem_Autorizacao,
        msgid TYPE symsgid VALUE 'YVIAGEM_MSG_DFLC',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF Sem_Autorizacao .

    DATA gv_datainicio TYPE /dmo/begin_date  READ-ONLY.
    DATA gv_datafim    TYPE /dmo/end_date    READ-ONLY.
    DATA gv_viagemid   TYPE /dmo/travel_id   READ-ONLY.
    DATA gv_clienteid  TYPE /dmo/customer_id READ-ONLY.
    DATA gv_agenciaid  TYPE /dmo/agency_id   READ-ONLY.

    INTERFACES if_abap_behv_message .
    INTERFACES if_t100_dyn_msg .
    INTERFACES if_t100_message .

    METHODS constructor
      IMPORTING
        iv_tipo       TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
        iv_id         LIKE if_t100_message=>t100key OPTIONAL
        iv_classepai  TYPE REF TO cx_root OPTIONAL
        iv_datainicio TYPE /dmo/begin_date OPTIONAL
        iv_datafim    TYPE /dmo/end_date OPTIONAL
        iv_viagemid   TYPE /dmo/travel_id OPTIONAL
        iv_clienteid  TYPE /dmo/customer_id OPTIONAL
        iv_agenciaid  TYPE /dmo/agency_id  OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycx_viagem_dflc IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor(  previous = iv_classepai  ).

    CLEAR me->textid.

    IF iv_id IS INITIAL.

      if_t100_message~t100key = if_t100_message=>default_textid.

    ELSE.

      if_t100_message~t100key = iv_id.

    ENDIF.

    me->if_abap_behv_message~m_severity = iv_tipo.
    me->gv_datainicio = iv_datainicio.
    me->gv_datafim    = iv_datafim.
    me->gv_viagemid   = |{ iv_viagemid  ALPHA = OUT }|.
    me->gv_clienteid  = |{ iv_clienteid ALPHA = OUT }|.
    me->gv_agenciaid  = |{ iv_agenciaid ALPHA = OUT }|.

  ENDMETHOD.


ENDCLASS.
