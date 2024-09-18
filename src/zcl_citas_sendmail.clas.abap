CLASS zcl_citas_sendmail DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CITAS_SENDMAIL IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA lv_response TYPE string.
    DATA ls_cita_s type string.
    DATA ls_email TYPE c LENGTH 512.
    DATA ls_cita TYPE c LENGTH 512.
    DATA ls_attachment_id type string.
    DATA(lt_param) = request->get_form_fields( ).
    READ TABLE lt_param REFERENCE INTO DATA(lr_email) WITH KEY name = 'email'.
    READ TABLE lt_param REFERENCE INTO DATA(lr_cita) WITH KEY name = 'cita'.

    IF sy-subrc = 0.

      ls_email = lr_email->value.
      ls_cita = lr_cita->value.

      SELECT GeneratedPDF FROM zi_store2dms WHERE CitaId = @ls_cita INTO @DATA(lt_details).
      ENDSELECT.

      ls_attachment_id = lt_details.

      CALL METHOD zcl_send_email_dms=>sendmail
        EXPORTING
          cita_id     = ls_cita
          pdf_id      = ls_attachment_id
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

      response->set_text( 'Email sent' ).

    ELSE.
      response->set_status( i_code = 400 i_reason = 'Error').
    ENDIF.

  ENDMETHOD.
ENDCLASS.
