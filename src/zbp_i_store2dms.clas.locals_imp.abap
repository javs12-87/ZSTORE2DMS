CLASS lhc_ZI_STORE2DMS DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_store2dms RESULT result.
    METHODS send2dms FOR DETERMINE ON SAVE
      IMPORTING keys FOR zi_store2dms~send2dms.
    METHODS createpdf FOR MODIFY
      IMPORTING keys FOR ACTION zi_store2dms~createpdf RESULT result.
    METHODS sendemail FOR MODIFY
      IMPORTING keys FOR ACTION zi_store2dms~sendemail RESULT result.

ENDCLASS.

CLASS lhc_ZI_STORE2DMS IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD send2DMS.

    DATA: ls_citaid   TYPE char10,
          ls_filename TYPE zfilename_dt,
          cmis_object TYPE cmis_s_object.

    READ ENTITIES OF zi_store2dms IN LOCAL MODE
        ENTITY zi_store2dms
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_attachment).

    LOOP AT lt_attachment INTO DATA(lt_attachment_data).
      DATA(ls_attachment) = lt_attachment_data-Attachment.
      ls_citaid = lt_attachment_data-CitaId.
      DATA(ls_mime) = lt_attachment_data-Mimetype.
      ls_filename = lt_attachment_data-Filename.

**********************************************************************
* Upload file                                                                                     *
**********************************************************************
      CALL METHOD zcl_file2dms_upload=>upload_file
        EXPORTING
          cita_id        = ls_citaid
          filename       = ls_filename
          mime_type      = ls_mime
          attachment     = ls_attachment
        RECEIVING
          ro_cmis_object = cmis_object.
*    CATCH cx_cmis_permission_denied.
*    CATCH cx_cmis_runtime.
*    CATCH cx_cmis_invalid_argument.
*    CATCH cx_cmis_not_supported.
*    CATCH cx_cmis_object_not_found.
*    CATCH cx_cmis_unauthorized.
*    CATCH cx_cmis_oauth.

**********************************************************************
* Update values on save                                                                                      *
**********************************************************************
      DATA: ls_cmisid TYPE string.

      DATA(lv_properties) = cmis_object-properties-properties.
      READ TABLE lv_properties INTO DATA(ls_objectid_prop)  WITH KEY id = cl_cmis_property_ids=>object_id.
      READ TABLE ls_objectid_prop-value INTO DATA(ls_objectid) INDEX 1.
      IF ls_objectid_prop-id CS 'cmis:objectID'.
        IF ls_objectid-string_value IS NOT INITIAL.
          ls_cmisid = ls_objectid-string_value.
        ENDIF.
      ENDIF.

      MODIFY ENTITIES OF zi_store2dms IN LOCAL MODE
      ENTITY zi_store2dms
      UPDATE
      FIELDS ( ObjectId RepositoryId ) WITH VALUE #( ( %tky = lt_attachment_data-%tky ObjectId = ls_cmisid RepositoryId = zcl_file2dms_upload=>co_repositoryid ) ).

    ENDLOOP.


  ENDMETHOD.

  METHOD createPDF.

    DATA: ls_citaid   TYPE char10,
          ls_objectid TYPE string,
          lt_cmis_obj TYPE cmis_s_object,
          ls_cmisid   TYPE string.

    READ ENTITIES OF zi_store2dms IN LOCAL MODE
        ENTITY zi_store2dms
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_attachment).

    LOOP AT lt_attachment INTO DATA(lt_attachment_data).
      DATA(ls_attachment) = lt_attachment_data-Attachment.
      ls_citaid = lt_attachment_data-CitaId.
      ls_objectid = lt_attachment_data-ObjectID.
      DATA(ls_mime) = lt_attachment_data-Mimetype.

      CALL METHOD zcl_file2dms_createpdf=>create_form
        EXPORTING
          citaid        = ls_citaid
          attachment    = ls_attachment
        RECEIVING
          r_gen_pdf_b64 = DATA(lv_pdfb64).

      CALL METHOD zcl_file2dms_upload=>upload_genpdf2folder
        EXPORTING
          folder_id      = ls_objectid
          attachment_b64 = lv_pdfb64
        RECEIVING
          ro_cmis_object = lt_cmis_obj.
*    CATCH cx_cmis_permission_denied.
*    CATCH cx_cmis_runtime.
*    CATCH cx_cmis_invalid_argument.
*    CATCH cx_cmis_not_supported.
*    CATCH cx_cmis_object_not_found.
*    CATCH cx_cmis_unauthorized.
*    CATCH cx_cmis_oauth.

      DATA(lv_properties) = lt_cmis_obj-properties-properties.
      READ TABLE lv_properties INTO DATA(ls_objectid_prop)  WITH KEY id = cl_cmis_property_ids=>object_id.
      READ TABLE ls_objectid_prop-value INTO DATA(ls_tmp) INDEX 1.
      IF ls_objectid_prop-id CS 'cmis:objectID'.
        IF ls_tmp-string_value IS NOT INITIAL.
          ls_cmisid = ls_tmp-string_value.
        ENDIF.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zi_store2dms IN LOCAL MODE
      ENTITY zi_store2dms
      UPDATE
      FIELDS ( GeneratedPDF ) WITH VALUE #( ( %tky = lt_attachment_data-%tky GeneratedPDF = ls_cmisid ) ).


    IF lt_cmis_obj-properties IS NOT INITIAL.
      INSERT VALUE #(
      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success text = 'PDF file generated: ' && |{ ls_cmisid }| )
    ) INTO TABLE reported-zi_store2dms.
    ENDIF.

  ENDMETHOD.

  METHOD sendEmail.

  DATA: ls_citaid   TYPE char10,
          ls_objectid TYPE string,
          ls_email     TYPE c length 512,
          lt_cmis_obj TYPE cmis_s_object,
          ls_cmisid   TYPE string.

    READ ENTITIES OF zi_store2dms IN LOCAL MODE
        ENTITY zi_store2dms
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_attachment).

    LOOP AT lt_attachment INTO DATA(lt_attachment_data).
      ls_citaid = lt_attachment_data-CitaId.
      ls_objectid = lt_attachment_data-GeneratedPDF.
      ls_email = lt_attachment_data-EmailDestination.

      CALL METHOD zcl_send_email_dms=>sendmail
        EXPORTING
          cita_id     = ls_citaid
          pdf_id      = ls_objectid
          send_to     = ls_email
        RECEIVING
          send_result = data(test)
        .
*      CATCH cx_cmis_permission_denied.
*      CATCH cx_cmis_runtime.
*      CATCH cx_cmis_invalid_argument.
*      CATCH cx_cmis_not_supported.
*      CATCH cx_cmis_object_not_found.
*      CATCH cx_cmis_unauthorized.
*      CATCH cx_cmis_oauth.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
