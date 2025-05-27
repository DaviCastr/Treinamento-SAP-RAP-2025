@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Viagem BO - Projeção'
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity YC_VIAGEM_DFLC
  provider contract transactional_query
  as projection on YI_VIAGEM_DFLC as Viagem
{
  key ViagemUUID,
      @Search.defaultSearchElement: true
      ViagemID,
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Agency', element: 'AgencyID'} }]
      @ObjectModel.text.element: ['NomeAgencia']
      @Search.defaultSearchElement: true
      AgenciaID,
      _Agencia.Name     as NomeAgencia,
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer', element: 'CustomerID'} }]
      @ObjectModel.text.element: ['NomeCliente']
      @Search.defaultSearchElement: true
      ClienteID,
      _Cliente.LastName as NomeCliente,
      DataInicio,
      DataFim,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      TaxaReserva,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      PrecoTotal,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency'} }]
      CodigoMoeda,
      Descricao,
      StatusViagem,
      UltimaModificacaoEm,
      UltimaModificacaoEmLocal,

      /* Associations */
      _Agencia,
      _Cliente,
      _Moeda,
      _Reserva : redirected to composition child YC_RESERVA_DFLC
}
