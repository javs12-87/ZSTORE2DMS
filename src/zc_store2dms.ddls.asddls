@EndUserText.label: 'Consumption view STORE2DMS'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_STORE2DMS
  provider contract transactional_query
  as projection on ZI_STORE2DMS
{
  key CitaId,
      RepositoryId,
      ObjectID,
      Filename,
      Mimetype,
      Attachment,
      GeneratedPDF,
      EmailDestination,
      EmailStatus,
      LastChangedAt
}
