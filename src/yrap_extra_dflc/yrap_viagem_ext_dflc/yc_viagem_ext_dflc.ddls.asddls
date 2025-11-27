@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Viagem BO - Projeção'
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity YC_VIAGEM_EXT_DFLC
  provider contract transactional_query
  as projection on YI_VIAGEM_EXT_DFLC as Viagem
{
  key ViagemUUID,
      @Search.defaultSearchElement: true
      ViagemID,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_CE_AGENCIA_DFLC', element: 'AgencyId'} }]
      @Search.defaultSearchElement: true
      AgenciaID,
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
      _Moeda
      
}
