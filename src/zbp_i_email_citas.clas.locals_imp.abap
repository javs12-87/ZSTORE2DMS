CLASS lhc_ZI_EMAIL_CITAS DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_email_citas RESULT result.

ENDCLASS.

CLASS lhc_ZI_EMAIL_CITAS IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

*  METHOD sendEmail.
*
*   DATA: ls_citaid   TYPE char10,
*         ls_destination TYPE string,
*          ls_objectid TYPE string,
*          ls_email     TYPE string,
*          lt_cmis_obj TYPE cmis_s_object,
*          ls_cmisid   TYPE string.
*
*    READ ENTITIES OF zi_email_citas IN LOCAL MODE
*        ENTITY zi_email_citas
*        ALL FIELDS WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_attachment).
*
*    LOOP AT lt_attachment INTO DATA(lt_attachment_data).
*      ls_citaid = lt_attachment_data-CitaId.
*      ls_destination = lt_attachment_data-EmailTo.
*
*      select GeneratedPDF from zi_store2dms where CitaId = @ls_citaid into @DATA(lt_details).
*      endselect.
*
*      CALL METHOD zcl_send_email_dms=>sendmail
*        EXPORTING
*          cita_id     = ls_citaid
*          pdf_id      = lt_details
*          send_to     = ls_destination
*        RECEIVING
*          send_result = data(test)
*        .
**      CATCH cx_cmis_permission_denied.
**      CATCH cx_cmis_runtime.
**      CATCH cx_cmis_invalid_argument.
**      CATCH cx_cmis_not_supported.
**      CATCH cx_cmis_object_not_found.
**      CATCH cx_cmis_unauthorized.
**      CATCH cx_cmis_oauth.
*
*    ENDLOOP.
*
*  ENDMETHOD.


ENDCLASS.

CLASS lcl_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lcl_saver IMPLEMENTATION.
  METHOD save_modified.
    DATA: ls_email TYPE c length 512,
          lt_citas   TYPE STANDARD TABLE OF zi_email_citas,
          lt_citas_u TYPE STANDARD TABLE OF zi_email_citas.

    IF create-zi_email_citas IS NOT INITIAL.
      " Provide table of instance data of all instances that have been created during current transaction
      " Use %CONTROL to get information on what entity fields have been set when
      "creating the instance
      lt_citas = CORRESPONDING #( create-zi_email_citas ).

      LOOP AT lt_citas ASSIGNING FIELD-SYMBOL(<fs_citas>).

        READ TABLE create-zi_email_citas WITH TABLE KEY entity COMPONENTS CitaId = <fs_citas>-CitaId INTO DATA(lt_email_create).

        SELECT GeneratedPDF FROM zi_store2dms WHERE CitaId = @<fs_citas>-CitaId INTO @DATA(lt_details).
        ENDSELECT.

        ls_email = lt_email_create-EmailTo.

      CALL METHOD zcl_send_email_dms=>sendmail
        EXPORTING
          cita_id     = lt_email_create-CitaId
          pdf_id      = lt_details
          send_to     = ls_email
        RECEIVING
          send_result = DATA(test).
*      CATCH cx_cmis_permission_denied.
*      CATCH cx_cmis_runtime.
*      CATCH cx_cmis_invalid_argument.
*      CATCH cx_cmis_not_supported.
*      CATCH cx_cmis_object_not_found.
*      CATCH cx_cmis_unauthorized.
*      CATCH cx_cmis_oauth.

      ENDLOOP.
    ENDIF.
    IF update-zi_email_citas IS NOT INITIAL.
      " Provide table of instance data of all instances that have been updated during current transaction
      " Use %CONTROL to get information on what entity fields have been updated
      lt_citas = CORRESPONDING #( update-zi_email_citas ).

      LOOP AT lt_citas ASSIGNING FIELD-SYMBOL(<fs_citas_u>).

        READ TABLE update-zi_email_citas WITH TABLE KEY entity COMPONENTS CitaId = <fs_citas_u>-CitaId INTO DATA(lt_email_update).

      ENDLOOP.

    ENDIF.
    IF delete-zi_email_citas IS NOT INITIAL.
      " Provide table with keys of all instances that have been deleted during current transaction
      " NOTE: There is no information on fields when deleting instances
    ENDIF.
  ENDMETHOD.

ENDCLASS.
