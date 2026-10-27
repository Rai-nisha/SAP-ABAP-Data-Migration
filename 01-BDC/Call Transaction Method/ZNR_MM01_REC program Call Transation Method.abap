REPORT znr_mm01_09
       NO STANDARD PAGE HEADING LINE-SIZE 255.

TYPES: BEGIN OF lty_data,
         matnr TYPE matnr,
         mbrsh TYPE mbrsh,
         mtart TYPE mtart,
         maktx TYPE maktx,
         meins TYPE meins,
       END OF lty_data.

DATA: lt_data TYPE TABLE OF lty_data,
      wa_data TYPE lty_data.
DATA: lv_file TYPE string.
DATA: lt_bdcdata TYPE TABLE OF bdcdata,
      wa_bdcdata TYPE bdcdata.
DATA: lt_messtab TYPE TABLE OF bdcmsgcoll,
      wa_messtab TYPE bdcmsgcoll.
DATA: lv_message TYPE string.


PARAMETERS: p_file TYPE localfile.      "here localfile is the sap predefine data element"

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      program_name  = syst-cprog       " Module pool program name for screen field
      dynpro_number = syst-dynnr       " Dynpro number where F4 help is needed
      field_name    = '   '            " name of field where path is to be entered
    IMPORTING
      file_name     = p_file.  " Path name selected by user with help of Filemngr


START-OF-SELECTION.
  lv_file = p_file.      "type casting"

  "Now we will read the data from selected file"
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = lv_file          " Name of file
*     filetype                = 'ASC'            " File Type (ASC or BIN)
      has_field_separator     = 'X'              " Columns Separated by Tabs in Case of ASCII Upload
*     header_length           = 0                " Length of Header for Binary Data
*     read_by_line            = 'X'              " The file will be written to the internal table line-by-line
*     dat_mode                = space            " Numeric and Date Fields Imported in ws_download 'DAT' Format
*     codepage                =                  " Character Representation for Output
*     ignore_cerr             = abap_true        " Specifies whether to ignore errors converting character sets
*     replacement             = '#'              " Replacement Character for Non-Convertible Characters
*     check_bom               = space            " The consistency of the codepage and byte order mark will be checked
*     virus_scan_profile      =                  " Virus Scan Profile
*     no_auth_check           = space            " Switch off Check for Access Rights
*  IMPORTING
*     filelength              =                  " File Length
*     header                  =                  " File Header in Case of Binary Upload
    TABLES
      data_tab                = lt_data         " Transfer table for file contents
*  CHANGING
*     isscanperformed         = space            " File already scanned
    EXCEPTIONS
      file_open_error         = 1                " File does not exist and cannot be opened
      file_read_error         = 2                " Error when reading file
      no_batch                = 3                " Front-End Function Cannot Be Executed in Backgrnd
      gui_refuse_filetransfer = 4                " Incorrect front end or error on front end
      invalid_type            = 5                " Incorrect parameter FILETYPE
      no_authority            = 6                " No Authorization for Upload
      unknown_error           = 7
      bad_data_format         = 8                " Cannot Interpret Data in File
      header_not_allowed      = 9                " Invalid header
      separator_not_allowed   = 10               " Invalid separator
      header_too_long         = 11               " The header information is limited to 1023 bytes at present
      unknown_dp_error        = 12               " Error when calling data provider
      access_denied           = 13               " Access to File Denied
      dp_out_of_memory        = 14               " Not Enough Memory in Data Provider
      disk_full               = 15               " Storage Medium full
      dp_timeout              = 16               " Timeout of Data Provider
      OTHERS                  = 17.

  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.



** Include bdcrecx1_s:
** The call transaction using is called WITH AUTHORITY-CHECK!
** If you have own auth.-checks you can use include bdcrecx1 instead.
*  INCLUDE bdcrecx1_s.
*
*start-of-selection.

*---------------------------------------------------------------------------------------------------------------*
* 1st - Here i have called the recording inside the loop.
* 2nd - I have copy past the logic of subroutine( bdc_dynpro and bdc_field ) from this bdcrecx1_s sap include.
* 3rd - for internal table with header line to with out header line.
*---------------------------------------------------------------------------------------------------------------*

  LOOP AT lt_data INTO wa_data.
*    PERFORM open_group.

    PERFORM bdc_dynpro      USING 'SAPLMGMM' '0060'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'RMMG1-MTART'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.
    PERFORM bdc_field       USING 'RMMG1-MATNR'
                                   wa_data-matnr.
    PERFORM bdc_field       USING 'RMMG1-MBRSH'
                                   wa_data-mbrsh.
    PERFORM bdc_field       USING 'RMMG1-MTART'
                                   wa_data-mtart.
    PERFORM bdc_dynpro      USING 'SAPLMGMM' '0070'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'MSICHTAUSW-DYTXT(01)'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.
    PERFORM bdc_field       USING 'MSICHTAUSW-KZSEL(01)'
                                  'X'.
    PERFORM bdc_dynpro      USING 'SAPLMGMM' '4004'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=BU'.
    PERFORM bdc_field       USING 'MAKT-MAKTX'
                                   wa_data-maktx.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'MARA-MEINS'.
    PERFORM bdc_field       USING 'MARA-MEINS'
                                   wa_data-meins.

*    we are calling Call Transaction Method inside the loop because we have to call MM01 for each and evey record.
    CALL TRANSACTION 'MM01' USING lt_bdcdata MODE 'E' UPDATE 'S' MESSAGES INTO lt_messtab.
    REFRESH: lt_bdcdata.
*    PERFORM bdc_transaction USING 'MM01'.

*    PERFORM close_group.
  ENDLOOP.
  LOOP AT lt_messtab INTO wa_messtab.
    CALL FUNCTION 'MESSAGE_TEXT_BUILD'
      EXPORTING
        msgid               = wa_messtab-msgid " Message ID
        msgnr               = wa_messtab-msgnr " Number of message
        msgv1               = wa_meSStab-msgv1 " Parameter 1
        msgv2               = wa_meSStab-msgv2 " Parameter 2
        msgv3               = wa_meSStab-msgv3 " Parameter 3
        msgv4               = wa_meSStab-msgv4 " Parameter 4
      IMPORTING
        message_text_output = lv_message. " Output message text

    WRITE : / lv_message.
  ENDLOOP.

*----------------------------------------------------------------------*
*        Start new screen                                              *
*----------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR wa_bdcdata.
  wa_bdcdata-program  = program.
  wa_bdcdata-dynpro   = dynpro.
  wa_bdcdata-dynbegin = 'X'.
  APPEND wa_bdcdata TO lt_bdcdata.
ENDFORM.

*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
  CLEAR wa_bdcdata.
  wa_bdcdata-fnam = fnam.
  wa_bdcdata-fval = fval.
  APPEND wa_bdcdata TO lt_bdcdata.
ENDFORM.
