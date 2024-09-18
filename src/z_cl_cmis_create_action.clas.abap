CLASS z_cl_cmis_create_action DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS Z_CL_CMIS_CREATE_ACTION IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA:
      lt_properties  TYPE cmis_t_client_property,
      ls_property    LIKE LINE OF lt_properties,
      ls_user        TYPE string,
      lo_cmis_client TYPE REF TO if_cmis_client,
      ls_value       LIKE LINE OF ls_property-values,
      ls_content     TYPE cmis_s_content_raw,
      lv_print       TYPE string.

**********************************************************************
* Get the CMIS Client                                                                                      *
**********************************************************************
    lo_cmis_client = z_cl_get_cmis_client=>get_client(  ).

    out->write( '*-----------------------------------------------------') .
    out->write( '* Executing create') .
    out->write( '*-----------------------------------------------------') .

**********************************************************************
*Get the repository                                                                                         *
**********************************************************************
    CALL METHOD lo_cmis_client->get_repository_info
    EXPORTING
    iv_repository_id = 'c237d6e2-779d-41d4-a55c-2a9c7a73bdee' "pass the id of the created repository
      IMPORTING
        es_repository_info = DATA(ls_repository).

**********************************************************************
*Create a folder                                                                                              *
**********************************************************************
    ls_property-id        = cl_cmis_property_ids=>object_type_id.
    ls_value-string_value = cl_cmis_constants=>base_type_id-cmis_folder. "specify the type as cmis:folder
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    CLEAR: ls_property,  ls_value.

    ls_property-id        = cl_cmis_property_ids=>name. "specify the name of the file
    ls_value-string_value = |Test{  cl_abap_context_info=>get_system_date( ) }{ cl_abap_context_info=>get_system_time( ) }|.
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    "call create_folder
    CALL METHOD lo_cmis_client->create_folder
      EXPORTING
        iv_repository_id = ls_repository-id
        it_properties    = lt_properties
        iv_folder_id     = ls_repository-root_folder_id
      IMPORTING
        es_object        = DATA(ls_cmis_object).

    out->write('Folder created successfully.').
    out->write( '-----------------------------------------------------') .

    CALL METHOD lo_cmis_client->get_object_by_path
      EXPORTING
        iv_repository_id             = ls_repository-id
        iv_path                      = ls_value-string_value
*        iv_include_acl               =
*        iv_filter                    =
*        iv_include_relationships     =
*        iv_rendition_filter          =
*        iv_include_allowable_actions =
*        iv_include_policy_ids        =
      IMPORTING
        es_object                    = DATA(lt_folder)
      .
*    CATCH cx_cmis_permission_denied.
*    CATCH cx_cmis_not_supported.
*    CATCH cx_cmis_object_not_found.
*    CATCH cx_cmis_invalid_argument.
*    CATCH cx_cmis_filter_not_valid.
*    CATCH cx_cmis_runtime.

    DATA: ls_folder_id   TYPE string.

*   LOOP AT lt_folder-properties INTO DATA(lv_objects).
      DATA(lv_properties) = lt_folder-properties-properties.
      READ TABLE lv_properties INTO DATA(ls_objectid_prop)  WITH KEY id = cl_cmis_property_ids=>object_id.
      READ TABLE ls_objectid_prop-value INTO DATA(ls_objectid) INDEX 1.
      IF ls_objectid_prop-id CS 'cmis:objectID'.
        IF ls_objectid-string_value IS NOT INITIAL.
          ls_folder_id = ls_objectid-string_value.
        ENDIF.
      ENDIF.

*    ENDLOOP.

**********************************************************************
* Create a document                                                                                         *
**********************************************************************

    CLEAR: ls_property,  ls_value.
    ls_property-id        = cl_cmis_property_ids=>object_type_id.
    ls_value-string_value = cl_cmis_constants=>base_type_id-cmis_document. "specify the type as cmis:document
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    CLEAR: ls_property,  ls_value.

    ls_property-id        = cl_cmis_property_ids=>name. "specify the name
    ls_value-string_value = |Doc{  cl_abap_context_info=>get_system_date( ) }{ cl_abap_context_info=>get_system_time( ) }.txt|.
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    "specify the content-stream details
    ls_content-filename = 'content'.
    ls_content-mime_type = 'text/plain'.
    lv_print = ' This is a file'.
    ls_content-stream = cl_abap_conv_codepage=>create_out(
                            codepage = `UTF-8`)->convert( source = lv_print ).

    "Call create_document
    CALL METHOD lo_cmis_client->create_document(
      EXPORTING
        iv_repository_id = ls_repository-id
        it_properties    = lt_properties
        is_content       = ls_content
        iv_folder_id     = ls_folder_id
*        iv_folder_id     = ls_repository-root_folder_id
      IMPORTING
        es_object        = ls_cmis_object ).

    out->write( cl_web_http_utility=>encode_x_base64( ls_content-stream ) ).

    out->write('Document created successfully.').
    out->write( '-----------------------------------------------------') .

  ENDMETHOD.
ENDCLASS.
