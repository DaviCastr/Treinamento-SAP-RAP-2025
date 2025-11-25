CLASS ycl_hello_world_rap_dflc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_HELLO_WORLD_RAP_DFLC IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA(lv_nome) = 'Davi'.

    out->write( |Hello World { lv_nome }| ).


  ENDMETHOD.

ENDCLASS.
