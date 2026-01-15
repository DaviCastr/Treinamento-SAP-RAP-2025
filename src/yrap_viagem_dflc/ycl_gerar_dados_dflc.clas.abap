CLASS ycl_gerar_dados_dflc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_gerar_dados_dflc IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    " Deleta dados existentes para não inserir duplicados
    DELETE FROM ytviagem_dflc.
    DELETE FROM ytviagemd_dflc.
    DELETE FROM ytreserva_dflc.
    DELETE FROM ytreservad_dflc.

    COMMIT WORK.

    " insert travel demo data
    INSERT ytviagem_dflc FROM (
        SELECT
          FROM /dmo/travel
          FIELDS
            uuid(  )      AS viagem_uuid,
            travel_id     AS viagem_id,
            agency_id     AS agencia_id,
            customer_id   AS cliente_id,
            begin_date    AS data_inicio,
            end_date      AS data_fim,
            booking_fee   AS taxa_reserva,
            total_price   AS preco_total,
            currency_code AS codigo_moeda,
            description   AS descricao,
            CASE status
              WHEN 'B' THEN 'A' " Aceito/Aprovado
              WHEN 'X' THEN 'X' " Cancelado
              ELSE 'O'          " Aberto/Em Aberto
            END           AS status_geral,
            createdby     AS criado_por,
            createdat     AS criado_em,
            lastchangedby AS ultima_modificacao_por,
            lastchangedat AS ultima_modificacao_em,
            lastchangedat AS ultima_modificacao_em_local
            ORDER BY travel_id UP TO 200 ROWS
      ).

    COMMIT WORK.

    " Inserindo dados
    INSERT ytreserva_dflc FROM (
        SELECT
          FROM   /dmo/booking    AS booking
            JOIN ytviagem_dflc AS z
            ON   booking~travel_id = z~viagem_id
          FIELDS
            uuid( )                  AS reserva_uuid,
            z~viagem_uuid            AS viagem_uuid,
            booking~booking_id       AS reserva_id,
            booking~booking_date     AS data_reserva,
            booking~customer_id      AS cliente_id,
            booking~carrier_id       AS transportadora_id,
            booking~connection_id    AS conexao_id,
            booking~flight_date      AS data_voo,
            booking~flight_price     AS preco_voo,
            booking~currency_code    AS codigo_moeda,
            z~criado_por             AS criado_por,
            z~ultima_modificacao_por AS ultima_modificacao_por,
            z~ultima_modificacao_em  AS ultima_modificacao_por_local
      ).

    COMMIT WORK.

    out->write( 'Dados demonstrativos inseridos.').

  ENDMETHOD.

ENDCLASS.
