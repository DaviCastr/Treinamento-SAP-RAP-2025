@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Dados de viagem'
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity YC_VIAGEM_UMN_DFLC
  as projection on YI_VIAGEM_UMN_DFLC
{

  key ViagemID,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Agency', element: 'AgencyID' } } ]
      AgenciaID,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Customer', element: 'CustomerID' } } ]
      ClienteID,
      DataInicio,
      DataFim,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      TaxaReserva,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      PrecoTotal,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Currency', element: 'Currency' } } ]
      CodigoMoeda,
      Descricao,
      Status,
      CriadoPor,
      CriadoEm,
      UltimaModificacaoPor,
      UltimaModificacaoEm,

      /* Associações */
      _Agencia,
      _Cliente,
      _Moeda,
      _Reserva : redirected to composition child YC_RESERVA_UMN_DFLC

}
