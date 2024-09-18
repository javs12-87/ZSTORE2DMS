@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view STORE2DMS'
define root view entity ZI_STORE2DMS
  as select from zcita_docs
{
  key cita_id               as CitaId,
      repository_id         as RepositoryId,
      object_id             as ObjectID,
      filename              as Filename,
      @Semantics.mimeType: true
      mimetype              as Mimetype,
      @Semantics.largeObject:
      { mimeType: 'Mimetype',
      fileName: 'Filename',
      contentDispositionPreference: #INLINE }
      attachment            as Attachment,
      genpdf_id as GeneratedPDF,
      @Semantics.eMail.address: true
      email_to as EmailDestination,
      @Semantics.eMail.received: true
      email_status as EmailStatus,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      
      //total ETag field
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt
}
