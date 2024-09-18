@EndUserText.label: 'Consumption view Email Citas'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_EMAIL_CITAS 
provider contract transactional_query
    as projection on ZI_EMAIL_CITAS
{
    key CitaId,
    Filename,
    EmailTo,
    EmailStatus,
    LastChangedAt
}
