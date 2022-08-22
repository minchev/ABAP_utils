"Program for direct editing of ABAP source code w/o dev key
REPORT zbc_progedit.

TABLES: sscrfields.

DATA: BEGIN OF gt_source OCCURS 0,
        line(1024),
      END OF gt_source,
      filename TYPE progstruc,
      mtdkey   TYPE seocpdkey.

DATA: gt_tfdir     TYPE TABLE OF tfdir,
      gt_tftit     TYPE TABLE OF tftit,
      gt_funct     TYPE TABLE OF funct,
      gt_enlfdir   TYPE TABLE OF enlfdir,
      gt_trdir     TYPE TABLE OF trdir WITH HEADER LINE,
      gt_fupararef TYPE TABLE OF sfupararef,
      gt_uincl     TYPE TABLE OF abaptxt255.

*$*$
SELECTION-SCREEN SKIP 2.
SELECTION-SCREEN PUSHBUTTON 10(4) pb_edit USER-COMMAND c_edit.
SELECTION-SCREEN PUSHBUTTON 20(4) pb_insr USER-COMMAND c_insr.
SELECTION-SCREEN PUSHBUTTON 30(4) pb_exec USER-COMMAND c_exec.
SELECTION-SCREEN PUSHBUTTON 40(4) pb_dele USER-COMMAND c_dele.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN ULINE.
SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(20) tprogram FOR FIELD progname.
  PARAMETERS : progname TYPE progname.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(20) tclass FOR FIELD pclass.
  PARAMETERS : pclass   TYPE progname.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(20) tmethod FOR FIELD pmethod.
  PARAMETERS : pmethod  TYPE progname.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(20) tfunc FOR FIELD pfunc.
  PARAMETERS : pfunc    TYPE rs38l-name.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.
SELECTION-SCREEN PUSHBUTTON /40(4) pb_load USER-COMMAND c_load.
SELECTION-SCREEN PUSHBUTTON  50(4) pb_chg  USER-COMMAND c_edit.
SELECTION-SCREEN PUSHBUTTON  60(4) pb_save USER-COMMAND c_save.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN ULINE.

*$*$
INITIALIZATION.
  pb_edit  = '@0Z@'.
  pb_insr  = '@HK@'.
  pb_exec  = '@15@'.
  pb_dele  = '@11@'.
  APPEND 'REPORT ZWM_RFC_GENERATED.' TO gt_source.

  pb_load  = '@48@'.
  pb_chg   = '@0Q@'.
  pb_save  = '@2L@'.

  tprogram = 'Program'.
  tclass   = 'Class'.
  tmethod  = 'Method'.
  tfunc    = 'Function module'.

*$*$
AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'C_LOAD'.
      IF pclass IS NOT INITIAL AND pmethod IS NOT INITIAL.
        mtdkey-clsname = pclass.
        mtdkey-cpdname = pmethod.
        CALL METHOD cl_oo_classname_service=>get_method_include
          EXPORTING
            mtdkey = mtdkey
          RECEIVING
            result = filename
          EXCEPTIONS
            OTHERS = 1.
        IF sy-subrc = 0.
          progname = filename.
        ENDIF.
      ELSEIF pfunc IS NOT INITIAL.
        CALL FUNCTION 'FUNC_GET_OBJECT'
          EXPORTING
            funcname           = pfunc
          TABLES
            ptfdir             = gt_tfdir
            ptftit             = gt_tftit
            pfunct             = gt_funct
            penlfdir           = gt_enlfdir
            ptrdir             = gt_trdir
            pfupararef         = gt_fupararef
            uincl              = gt_uincl
          EXCEPTIONS
            function_not_exist = 1
            version_not_found  = 2
            OTHERS             = 3.
        IF sy-subrc = 0.
          READ TABLE gt_trdir INDEX 1.
          progname = gt_trdir-name.
        ENDIF.
      ENDIF.
      CHECK NOT progname IS INITIAL.
      READ REPORT progname INTO gt_source.
    WHEN 'C_SAVE'.
      INSERT   REPORT progname FROM gt_source.
    WHEN 'C_EDIT'.
      EDITOR-CALL FOR gt_source.
    WHEN 'C_INSR'.
      INSERT   REPORT 'ZWM_RFC_GENERATED' FROM gt_source.
    WHEN 'C_EXEC'.
      INSERT   REPORT 'ZWM_RFC_GENERATED' FROM gt_source.
      GENERATE REPORT 'ZWM_RFC_GENERATED'.
      IF sy-subrc = 0.
        SUBMIT zwm_rfc_generated VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        EDITOR-CALL FOR REPORT 'ZWM_RFC_GENERATED'.
      ENDIF.
    WHEN 'C_DELE'.
      DELETE REPORT 'ZWM_RFC_GENERATED'.
      MESSAGE s600(fr) WITH 'Return code:' sy-subrc.
  ENDCASE.