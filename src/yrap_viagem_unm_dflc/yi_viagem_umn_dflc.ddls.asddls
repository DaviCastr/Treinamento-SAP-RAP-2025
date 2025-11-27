@EndUserText.label: 'Dados de viagem'
@Metadata.ignorePropagatedAnnotations: true
define root view entity YI_VIAGEM_UMN_DFLC
    
  as select from /dmo/travel as Viagem
  
  composition [0..*] of YI_RESERVA_UMN_DFLC  as _Reserva
  
  association [0..1] to /DMO/I_Agency   as _Agencia on $projection.AgenciaID = _Agencia.AgencyID
  association [0..1] to /DMO/I_Customer as _Cliente on $projection.ClienteID = _Cliente.CustomerID
  association [0..1] to I_Currency      as _Moeda   on $projection.CodigoMoeda = _Moeda.Currency

{
  key travel_id     as ViagemID,
      agency_id     as AgenciaID,
      customer_id   as ClienteID,
      begin_date    as DataInicio,
      end_date      as DataFim,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      booking_fee   as TaxaReserva,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      total_price   as PrecoTotal,
      currency_code as CodigoMoeda,
      description   as Descricao,
      status        as Status,
      @Semantics.user.createdBy: true
      createdby     as CriadoPor,
      @Semantics.systemDateTime.createdAt: true
      createdat     as CriadoEm,
      @Semantics.user.lastChangedBy: true
      lastchangedby as UltimaModificacaoPor,
      @Semantics.systemDateTime.lastChangedAt: true
      lastchangedat as UltimaModificacaoEm,

      /* associações*/
      _Reserva,
      _Agencia,
      _Cliente,
      _Moeda
}
