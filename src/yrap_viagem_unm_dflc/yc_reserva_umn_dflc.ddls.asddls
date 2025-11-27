@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Dados de Reserva'
@Search.searchable: true
@Metadata.allowExtensions: true
define view entity YC_RESERVA_UMN_DFLC
  as projection on YI_RESERVA_UMN_DFLC as Viagem
{
      @Search.defaultSearchElement: true
  key ViagemID,
      @Search.defaultSearchElement: true
  key ReservaID,
      DataReserva,
      @Consumption.valueHelpDefinition: [ { entity: { name:     '/DMO/I_Customer',
                                                      element:     'CustomerID' } } ]
      ClienteID,
      @Consumption.valueHelpDefinition: [ { entity: { name:     '/DMO/I_Carrier',  element:     'AirlineID' } } ]
      TransportadoraID,
      @Consumption.valueHelpDefinition: [ { entity: { name:    '/DMO/I_Flight',
                                                      element: 'ConnectionID' },
                                            additionalBinding: [ { localElement: 'DataVoo',
                                                                   element:      'FlightDate',
                                                                   usage: #RESULT },
                                                                 { localElement: 'TransportadoraID',
                                                                        element: 'AirlineID',
                                                                          usage: #RESULT },
                                                                 { localElement: 'PrecoVoo',
                                                                        element: 'Price',
                                                                          usage: #RESULT },
                                                                 { localElement: 'CodigoMoeda',
                                                                        element: 'CurrencyCode',
                                                                          usage: #RESULT } ]
                                      } ]

      ConexaoID,
      DataVoo,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      PrecoVoo,
      @Consumption.valueHelpDefinition: [ { entity: { name:    'I_Currency',
                                                      element: 'Currency' } } ]

      CodigoMoeda,

      /* Associações */
      _Cliente,
      _Conexao,
      _Transportadora,
      _Viagem: redirected to parent YC_VIAGEM_UMN_DFLC,
      _Voo
}
