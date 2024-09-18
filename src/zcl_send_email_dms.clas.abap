CLASS zcl_send_email_dms DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS sendMail
      IMPORTING
        VALUE(cita_id)     TYPE c OPTIONAL
        VALUE(PDF_id)      TYPE string OPTIONAL
        VALUE(send_to)     TYPE c OPTIONAL
      RETURNING
        VALUE(send_result) TYPE string
      RAISING
        cx_cmis_permission_denied
        cx_cmis_runtime
        cx_cmis_invalid_argument
        cx_cmis_not_supported
        cx_cmis_object_not_found
        cx_cmis_unauthorized
        cx_cmis_oauth .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SEND_EMAIL_DMS IMPLEMENTATION.


  METHOD sendmail.
    DATA:
      lt_properties  TYPE cmis_t_client_property,
      ls_property    LIKE LINE OF lt_properties,
      ls_user        TYPE string,
      lo_cmis_client TYPE REF TO if_cmis_client,
      ls_value       LIKE LINE OF ls_property-values,
      ls_content     TYPE cmis_s_content_raw,
      lv_print       TYPE string,
      ls_cmis_object TYPE cmis_s_object,
      ls_object_id   TYPE string,
      ro_cmis_query  TYPE cmis_s_object_list,
      ls_cmis_stream TYPE cmis_s_content_raw.

**********************************************************************
* Get the CMIS Client                                                                                      *
**********************************************************************
    lo_cmis_client = z_cl_get_cmis_client=>get_client(  ).


**********************************************************************
*Get the repository                                                                                         *
**********************************************************************
    CALL METHOD lo_cmis_client->get_repository_info
      EXPORTING
        iv_repository_id   = zcl_file2dms_upload=>co_repositoryid
      IMPORTING
        es_repository_info = DATA(ls_repository).

**********************************************************************
*Get Content Stream                                                                                         *
**********************************************************************
    CALL METHOD lo_cmis_client->get_content_stream
      EXPORTING
        iv_repository_id = ls_repository-id
        iv_object_id     = PDF_id
*       iv_stream_id     =
*       iv_offset        =
*       iv_length        =
*       iv_mime_type     =
      IMPORTING
        es_content       = ls_cmis_stream.
*    CATCH cx_cmis_permission_denied.
*    CATCH cx_cmis_runtime.
*    CATCH cx_cmis_invalid_argument.
*    CATCH cx_cmis_not_supported.
*    CATCH cx_cmis_object_not_found.
*    CATCH cx_cmis_constraint.

**********************************************************************
*Send Email                                                                                     *
**********************************************************************

    TRY.

        DATA(lo_config) = cl_bcs_mail_system_config=>create_instance( ).

        lo_config->modify_default_sender_address( iv_default_address = 'jorge.baltazar@sap.com'
                            iv_default_name = 'Liverpool Citas' ).

        DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).
        lo_mail->set_sender( 'jorge.baltazar@sap.com' ).
        lo_mail->add_recipient( send_to ).
        " lo_mail->add_recipient( iv_address = 'recipient2@yourcompany.com' iv_copy = cl_bcs_mail_message=>cc ).
        lo_mail->set_subject( 'Test Mail: Cita' ) ##NO_TEXT.
        lo_mail->set_main( cl_bcs_mail_textpart=>create_instance(
          iv_content      = 'TEST'
          iv_content_type = 'text/html'
        ) ).

        DATA: ls_mime    TYPE c LENGTH 128.

        ls_mime = ls_cmis_stream-mime_type.

        lo_mail->add_attachment( cl_bcs_mail_binarypart=>create_instance(
          iv_content      = ls_cmis_stream-stream
          iv_content_type = ls_mime
          iv_filename     = ls_cmis_stream-filename
        ) ).

         lo_mail->send( IMPORTING et_status = DATA(lt_status) ).
*        lo_mail->send_async( ).
*        CATCH cx_bcs_mail..

      CATCH cx_bcs_mail_config INTO DATA(write_error).
        "handle exception
      CATCH cx_bcs_mail INTO DATA(lx_mail).
        " handle exceptions here
    ENDTRY.


  ENDMETHOD.
ENDCLASS.
