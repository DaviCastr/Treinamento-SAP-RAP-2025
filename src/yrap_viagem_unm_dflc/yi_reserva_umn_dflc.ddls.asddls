@EndUserText.label: 'Dados de Reserva'
@Metadata.ignorePropagatedAnnotations: true
define view entity YI_RESERVA_UMN_DFLC
  as select from /dmo/booking as Reserva

  association        to parent YI_VIAGEM_UMN_DFLC as _Viagem         on  $projection.ViagemID = _Viagem.ViagemID

  association [1..1] to /DMO/I_Carrier              as _Transportadora on  $projection.TransportadoraID = _Transportadora.AirlineID
  association [1..1] to /DMO/I_Customer             as _Cliente        on  $projection.ClienteID = _Cliente.CustomerID
  association [1..1] to /DMO/I_Connection           as _Conexao        on  $projection.TransportadoraID = _Conexao.AirlineID
                                                                       and $projection.ConexaoID        = _Conexao.ConnectionID
  association [1..1] to /DMO/I_Flight               as _Voo            on  $projection.TransportadoraID = _Voo.AirlineID
                                                                       and $projection.ConexaoID        = _Voo.ConnectionID
                                                                       and $projection.DataVoo          = _Voo.FlightDate
{
  key travel_id     as ViagemID,
  key booking_id    as ReservaID,
      booking_date  as DataReserva,
      customer_id   as ClienteID,
      carrier_id    as TransportadoraID,
      connection_id as ConexaoID,
      flight_date   as DataVoo,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      flight_price  as PrecoVoo,
      currency_code as CodigoMoeda,


      /* associações */
      _Viagem,
      _Transportadora,
      _Cliente,
      _Conexao,
      _Voo
}
