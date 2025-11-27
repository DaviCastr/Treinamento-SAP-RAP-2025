CLASS ycl_ce_agencia_dflc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_rap_query_provider.

    TYPES ty_r_agencies TYPE RANGE OF ysc_agencia_dflc=>tys_z_travel_agency_es_5_type-agencyid.
    TYPES ty_t_agencies TYPE TABLE OF ysc_agencia_dflc=>tys_z_travel_agency_es_5_type.

    METHODS get_agencies
      IMPORTING
        it_filters            TYPE if_rap_query_filter=>tt_name_range_pairs   OPTIONAL
        iv_top                TYPE i OPTIONAL
        iv_skip               TYPE i OPTIONAL
        iv_is_data_requested  TYPE abap_bool
        iv_is_count_requested TYPE abap_bool
      EXPORTING
        et_agencies           TYPE ty_t_agencies
        ev_count              TYPE int8
      RAISING
        /iwbep/cx_cp_remote
        /iwbep/cx_gateway
        cx_web_http_client_error
        cx_http_dest_provider_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_ce_agencia_dflc IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA lt_agencies TYPE ty_t_agencies.
    DATA lv_count    TYPE int8.
    DATA lt_filters  TYPE if_rap_query_filter=>tt_name_range_pairs .
    DATA lt_ranges   TYPE if_rap_query_filter=>tt_range_option .

    lt_ranges = VALUE #( (  sign = 'I' option = 'GE' low = '070015' ) ).

    lt_filters = VALUE #( ( name = 'AGENCYID'  range = lt_ranges ) ).

    TRY.

        get_agencies(
          EXPORTING
            it_filters            = lt_filters
            iv_top                = 3
            iv_skip               = 1
            iv_is_count_requested = abap_true
            iv_is_data_requested  = abap_true
          IMPORTING
            et_agencies           = lt_agencies
            ev_count              = lv_count
          ) .

        out->write( |Total de registros = { lv_count }| ) .
        out->write( lt_agencies ).

      CATCH cx_root INTO DATA(exception).

        out->write( cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ) ).

    ENDTRY.


  ENDMETHOD.

  METHOD get_agencies.

    DATA: lo_filter_factory   TYPE REF TO /iwbep/if_cp_filter_factory,
          lo_filter_node      TYPE REF TO /iwbep/if_cp_filter_node,
          lo_root_filter_node TYPE REF TO /iwbep/if_cp_filter_node.

    DATA: lo_http_client        TYPE REF TO if_web_http_client,
          lo_odata_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
          lo_read_list_request  TYPE REF TO /iwbep/if_cp_request_read_list,
          lo_read_list_response TYPE REF TO /iwbep/if_cp_response_read_lst.

    DATA lv_consume_service_name TYPE cl_web_odata_client_factory=>ty_service_definition_name.

    DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( i_url = 'https://sapes5.sapdevcenter.com' ).

    lo_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_http_destination ).

    lv_consume_service_name = to_upper( 'YSC_AGENCIA_DFLC' ).

*    lo_odata_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
*      EXPORTING
*        iv_service_definition_name = lv_consume_service_name
*        io_http_client             = lo_http_client
*        iv_relative_service_root   = '/sap/opu/odata/sap/ZAGENCYCDS_SRV/' ).

    lo_odata_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
       EXPORTING
          is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                              proxy_model_id      = lv_consume_service_name
                                              proxy_model_version = '0001' )
         io_http_client             = lo_http_client
         iv_relative_service_root   = '/sap/opu/odata/sap/ZAGENCYCDS_SRV/' ).


    " Cria requisição
    lo_read_list_request = lo_odata_client_proxy->create_resource_for_entity_set( 'Z_TRAVEL_AGENCY_ES_5' )->create_request_for_read( ).

    " Cria filtros
    lo_filter_factory = lo_read_list_request->create_filter_factory( ).

    LOOP AT it_filters  INTO DATA(ls_filtro).

      lo_filter_node  = lo_filter_factory->create_by_range( iv_property_path = ls_filtro-name
                                                            it_range         = ls_filtro-range ).
      IF lo_root_filter_node IS INITIAL.

        lo_root_filter_node = lo_filter_node.

      ELSE.
        lo_root_filter_node = lo_root_filter_node->and( lo_filter_node ).
      ENDIF.
    ENDLOOP.

    IF lo_root_filter_node IS NOT INITIAL.
      lo_read_list_request->set_filter( lo_root_filter_node ).
    ENDIF.

    IF iv_is_data_requested = abap_true.

      lo_read_list_request->set_skip( iv_skip ).

      IF iv_top > 0 .

        lo_read_list_request->set_top( iv_top ).

      ENDIF.

    ENDIF.

    IF iv_is_count_requested = abap_true.

      lo_read_list_request->request_count(  ).

    ENDIF.

    IF iv_is_data_requested = abap_false.

      lo_read_list_request->request_no_business_data(  ).

    ENDIF.

    " Executa e recebe o resultado e contagem se requisitado
    lo_read_list_response = lo_read_list_request->execute( ).

    IF iv_is_data_requested = abap_true.

      lo_read_list_response->get_business_data( IMPORTING et_business_data = et_agencies ).

    ENDIF.

    IF iv_is_count_requested = abap_true.

      ev_count = lo_read_list_response->get_count(  ).

    ENDIF.

  ENDMETHOD.

  METHOD if_rap_query_provider~select.

    DATA lt_agencies TYPE ty_t_agencies.
    DATA lv_count    TYPE int8.

    DATA(lv_top)              = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip)             = io_request->get_paging( )->get_offset( ).
    DATA(lv_requested_fields) = io_request->get_requested_elements( ).
    DATA(lv_sort_order)       = io_request->get_sort_elements( ).

    TRY.

        DATA(lt_filter_condition) = io_request->get_filter( )->get_as_ranges( ).

        get_agencies(
             EXPORTING
               it_filters            = lt_filter_condition
               iv_top                = CONV i( lv_top )
               iv_skip               = CONV i( lv_skip )
               iv_is_data_requested  = io_request->is_data_requested( )
               iv_is_count_requested = io_request->is_total_numb_of_rec_requested(  )
             IMPORTING
               et_agencies           = lt_agencies
               ev_count              = lv_count  ) .

        IF io_request->is_total_numb_of_rec_requested(  ).

          io_response->set_total_number_of_records( lv_count ).

        ENDIF.

        IF io_request->is_data_requested(  ).

          io_response->set_data( lt_agencies ).

        ENDIF.

      CATCH cx_root INTO DATA(exception).

        DATA(lv_exception_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
