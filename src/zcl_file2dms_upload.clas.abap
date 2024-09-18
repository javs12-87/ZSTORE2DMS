CLASS zcl_file2dms_upload DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS: co_repositoryID  TYPE string VALUE 'c237d6e2-779d-41d4-a55c-2a9c7a73bdee'.

    CLASS-METHODS upload_file
      IMPORTING
        VALUE(cita_id)        TYPE char10 OPTIONAL
        VALUE(filename)       TYPE zfilename_dt OPTIONAL
        VALUE(mime_type)      TYPE zmimetype_dt OPTIONAL
        VALUE(attachment)     TYPE zattachment_dt OPTIONAL
      RETURNING
        VALUE(ro_cmis_object) TYPE cmis_s_object
      RAISING
        cx_cmis_permission_denied
        cx_cmis_runtime
        cx_cmis_invalid_argument
        cx_cmis_not_supported
        cx_cmis_object_not_found
        cx_cmis_unauthorized
        cx_cmis_oauth .

    CLASS-METHODS upload_genpdf2folder
      IMPORTING
        VALUE(folder_id)        TYPE string OPTIONAL
        VALUE(attachment_b64)     TYPE string OPTIONAL
      RETURNING
        VALUE(ro_cmis_object) TYPE cmis_s_object
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



CLASS ZCL_FILE2DMS_UPLOAD IMPLEMENTATION.


  METHOD upload_file.

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

**********************************************************************
*Get the repository                                                                                         *
**********************************************************************
    CALL METHOD lo_cmis_client->get_repository_info
      EXPORTING
        iv_repository_id   = zcl_file2dms_upload=>co_repositoryid
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
    ls_value-string_value = |{ cita_id }{  cl_abap_context_info=>get_system_date( ) }{ cl_abap_context_info=>get_system_time( ) }|.
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

**********************************************************************
*Get folder id                                                                                              *
**********************************************************************
    CALL METHOD lo_cmis_client->get_object_by_path
      EXPORTING
        iv_repository_id = ls_repository-id
        iv_path          = ls_value-string_value
      IMPORTING
        es_object        = DATA(lt_folder).

    DATA: ls_folder_id   TYPE string.

    DATA(lv_properties) = lt_folder-properties-properties.
    READ TABLE lv_properties INTO DATA(ls_objectid_prop)  WITH KEY id = cl_cmis_property_ids=>object_id.
    READ TABLE ls_objectid_prop-value INTO DATA(ls_objectid) INDEX 1.
    IF ls_objectid_prop-id CS 'cmis:objectID'.
      IF ls_objectid-string_value IS NOT INITIAL.
        ls_folder_id = ls_objectid-string_value.
      ENDIF.
    ENDIF.

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
    ls_value-string_value = filename.
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    "specify the content-stream details
    ls_content-filename = filename.
    ls_content-mime_type = mime_type.
    ls_content-stream = attachment.

    "Call create_document
    CALL METHOD lo_cmis_client->create_document(
      EXPORTING
        iv_repository_id = ls_repository-id
        it_properties    = lt_properties
        is_content       = ls_content
        iv_folder_id     = ls_folder_id
      IMPORTING
        es_object        = ls_cmis_object ).

    ro_cmis_object = ls_cmis_object.

  ENDMETHOD.


  METHOD upload_genpdf2folder.

  DATA:
      lt_properties  TYPE cmis_t_client_property,
      ls_property    LIKE LINE OF lt_properties,
      ls_user        TYPE string,
      lo_cmis_client TYPE REF TO if_cmis_client,
      ls_value       LIKE LINE OF ls_property-values,
      ls_content     TYPE cmis_s_content_raw,
      lv_print       TYPE string,
      ls_cmis_object type cmis_s_object,
      ls_object_id   TYPE string,
      ro_cmis_query  TYPE cmis_s_object_list.

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
*Query object ID to get parents                                                                                         *
**********************************************************************
      CONDENSE folder_id.

      CALL METHOD lo_cmis_client->query
      EXPORTING
        iv_repository_id = zcl_file2dms_upload=>co_repositoryid
        iv_statement     = 'SELECT sap:parentIds FROM cmis:document where cmis:objectId = ''' && |{ folder_id }| && ''''
*       iv_search_all_versions       =
*       iv_include_relationships     =
*       iv_rendition_filter          =
*       iv_include_allowable_actions =
*       iv_max_items     =
*       iv_skip_count    =
      IMPORTING
        es_query_result  = ro_cmis_query.

    LOOP AT ro_cmis_query-objects INTO DATA(lv_objects).
      DATA(lv_properties) = lv_objects-properties-properties.
      READ TABLE lv_properties INTO DATA(ls_objectid_prop)  WITH KEY id = 'sap:parentIds'.
      READ TABLE ls_objectid_prop-value INTO DATA(ls_objectid) INDEX 1.
      IF ls_objectid_prop-id CS 'sap:parentIds'.
        IF ls_objectid-string_value IS NOT INITIAL.
          ls_object_id = ls_objectid-string_value.
        ENDIF.
      ENDIF.

    ENDLOOP.


    CLEAR: ls_property,  ls_value.
    ls_property-id        = cl_cmis_property_ids=>object_type_id.
    ls_value-string_value = cl_cmis_constants=>base_type_id-cmis_document. "specify the type as cmis:document
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    CLEAR: ls_property,  ls_value.

    ls_property-id        = cl_cmis_property_ids=>name. "specify the name
    ls_value-string_value = |GeneratedPDF{  cl_abap_context_info=>get_system_date( ) }{ cl_abap_context_info=>get_system_time( ) }.pdf|.
    APPEND ls_value TO ls_property-values.
    APPEND ls_property TO lt_properties.

    "specify the content-stream details
    ls_content-filename = |GeneratedPDF{  cl_abap_context_info=>get_system_date( ) }{ cl_abap_context_info=>get_system_time( ) }.pdf|.
    ls_content-mime_type = 'application/pdf;base64'.

    DATA(ls_tmp) =  cl_web_http_utility=>decode_x_base64( attachment_b64 ).
    ls_content-stream = ls_tmp.
    "ls_content-stream = cl_abap_conv_codepage=>create_out( )->convert( source = attachment_b64 ).
    "attachment_b64.

    "Call create_document
    CALL METHOD lo_cmis_client->create_document(
      EXPORTING
        iv_repository_id = ls_repository-id
        it_properties    = lt_properties
        is_content       = ls_content
        iv_folder_id     = ls_object_id
      IMPORTING
        es_object        = ls_cmis_object ).

    ro_cmis_object = ls_cmis_object.

  ENDMETHOD.
ENDCLASS.
