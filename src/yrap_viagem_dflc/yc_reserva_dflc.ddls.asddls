@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Reserva BO - Projeção'
@Search.searchable: true
@Metadata.allowExtensions: true
define view entity YC_RESERVA_DFLC
  as projection on YI_RESERVA_DFLC as Reserva

{
  key ReservaUUID,
      ViagemUUID,
      @Search.defaultSearchElement: true
      ReservaID,
      DataReserva,
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Customer', element: 'CustomerID'  } }]
      @ObjectModel.text.element: ['NomeCliente']
      @Search.defaultSearchElement: true
      ClienteID,
      _Cliente.LastName as NomeCliente,
      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Carrier', element: 'AirlineID' }}]
      @ObjectModel.text.element: ['NomeTransportadora']
      TransportadoraID,
      _Transportadora.Name   as NomeTransportadora,
      @Consumption.valueHelpDefinition: [ {entity: {name: '/DMO/I_Flight', element: 'ConnectionID'},
                                           additionalBinding: [ { localElement: 'TransportadoraID',    element: 'AirlineID' },
                                                                { localElement: 'DataVoo',     element: 'FlightDate',   usage: #RESULT},
                                                                { localElement: 'PrecoVoo',    element: 'Price',        usage: #RESULT },
                                                                { localElement: 'CodigoMoeda', element: 'CurrencyCode', usage: #RESULT } ] } ]
      ConexaoID,
      DataVoo,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      PrecoVoo,
      @Consumption.valueHelpDefinition: [{entity: {name: 'I_Currency', element: 'Currency' }}]
      CodigoMoeda,
      UltimaModificacaoEmLocal,
      
      /* Associations */
      _Cliente,
      _Conexao,
      _Moeda,
      _Transportadora,
      _Viagem: redirected to parent YC_VIAGEM_DFLC,
      _Voo
}
