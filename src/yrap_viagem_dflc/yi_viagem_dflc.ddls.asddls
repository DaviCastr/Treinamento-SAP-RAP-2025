@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Viagem BO'
@Metadata.ignorePropagatedAnnotations: true
define root view entity YI_VIAGEM_DFLC
  as select from ytviagem_dflc as Viagem

  //Reservas
  composition [0..*] of YI_RESERVA_DFLC as _Reserva
  //Agência
  association [0..1] to /DMO/I_Agency   as _Agencia  on $projection.AgenciaID = _Agencia.AgencyID
  //Cliente
  association [0..1] to /DMO/I_Customer as _Cliente  on $projection.ClienteID = _Cliente.CustomerID
  //Moeda
  association [0..1] to I_Currency      as _Moeda    on $projection.CodigoMoeda = _Moeda.Currency
{
  key viagem_uuid                 as ViagemUUID,
      viagem_id                   as ViagemID,
      agencia_id                  as AgenciaID,
      cliente_id                  as ClienteID,
      data_inicio                 as DataInicio,
      data_fim                    as DataFim,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      taxa_reserva                as TaxaReserva,
      @Semantics.amount.currencyCode: 'CodigoMoeda'
      preco_total                 as PrecoTotal,
      codigo_moeda                as CodigoMoeda,
      descricao                   as Descricao,
      status_geral                as StatusGeral,
      @Semantics.user.createdBy: true
      criado_por                  as CriadoPor,
      @Semantics.systemDateTime.createdAt: true
      criado_em                   as CriadoEm,
      @Semantics.user.lastChangedBy: true
      ultima_modificacao_por      as UltimaModificacaoPor,
      @Semantics.systemDateTime.lastChangedAt: true
      ultima_modificacao_em       as UltimaModificacaoEm,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      ultima_modificacao_em_local as UltimaModificacaoEmLocal,

      /* Associações */
      _Reserva,
      _Agencia,
      _Cliente,
      _Moeda
}
