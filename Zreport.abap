REPORT z_print_po_pdf.

DATA: gv_ebeln TYPE ekko-ebeln,        " Purchase Order Number
      gv_bukrs TYPE ekko-bukrs,        " Company Code
      gv_butxt TYPE t001-butxt,        " Company Name
      gv_aedat TYPE ekko-aedat,        " PO Date
      gv_ernam TYPE ekko-ernam,        " Prepared by
      gv_name_first TYPE adrp-name_first, " First Name of Preparer
      gv_name_last TYPE adrp-name_last,   " Last Name of Preparer
      gv_lifnr TYPE ekko-lifnr,        " Vendor Number
      gv_waers TYPE ekko-waers,        " Currency
      gv_zterm TYPE ekko-zterm,        " Payment Terms
      gv_inco1 TYPE ekko-inco1,        " Incoterms
      gv_inco2 TYPE ekko-inco2,        " Incoterms Location
      gv_taxnum TYPE dfkkbptaxnum-taxnum, " Vendor GST Number
      lt_items TYPE TABLE OF ekpo,     " Table for PO Items
      lt_schedules TYPE TABLE OF eket, " Table for Delivery Schedules
      gv_total_amount TYPE p DECIMALS 2,  " Total Amount
      gv_total_tax TYPE p DECIMALS 2,     " Total Tax
      gv_gross_total TYPE p DECIMALS 2.   " Gross Total

* Select Header Information
SELECT SINGLE bukrs ebeln aedat ernam lifnr waers zterm inco1 inco2
  FROM ekko
  INTO (gv_bukrs, gv_ebeln, gv_aedat, gv_ernam, gv_lifnr, gv_waers, gv_zterm, gv_inco1, gv_inco2)
  WHERE ebeln = gv_ebeln.

* Fetch Company Name
SELECT SINGLE butxt
  FROM t001
  INTO gv_butxt
  WHERE bukrs = gv_bukrs.

* Fetch Vendor Information
SELECT SINGLE name_first name_last
  FROM adrp
  INTO (gv_name_first, gv_name_last)
  WHERE persnumber = ( SELECT SINGLE persnumber FROM usr21 WHERE bname = gv_ernam ).

* Fetch Vendor GST Number
SELECT SINGLE taxnum
  FROM dfkkbptaxnum
  INTO gv_taxnum
  WHERE lifnr = gv_lifnr AND taxnumtyp = 'IN3'.   "Assuming IN3 is for GST

* Fetch PO Items
SELECT ebeln ebelp matnr txz01 menge meins netpr
  INTO TABLE lt_items
  FROM ekpo
  WHERE ebeln = gv_ebeln.

* Fetch Delivery Schedule
SELECT ebeln ebelp eindt
  INTO TABLE lt_schedules
  FROM eket
  WHERE ebeln = gv_ebeln.

* Calculate Taxes (GST/CGST/SGST/IGST)
CALL FUNCTION 'CALCULATE_TAXES_NET'
  EXPORTING
    i_ebeln = gv_ebeln
  IMPORTING
    e_total_tax = gv_total_tax.

* Calculate Totals
LOOP AT lt_items INTO DATA(ls_item).
  gv_total_amount = gv_total_amount + ls_item-netpr * ls_item-menge.
ENDLOOP.
gv_gross_total = gv_total_amount + gv_total_tax.

* Adobe Form Call
CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
  EXPORTING
    i_name     = 'ZPO_FORM'
  IMPORTING
    e_funcname = DATA(gv_fm_name).

CALL FUNCTION gv_fm_name
  EXPORTING
    /1bcdwb/docparams = DATA(l_doc_params)
    ebeln             = gv_ebeln
    bukrs             = gv_bukrs
    butxt             = gv_butxt
    aedat             = gv_aedat
    ernam             = gv_ernam
    name_first        = gv_name_first
    name_last         = gv_name_last
    lifnr             = gv_lifnr
    waers             = gv_waers
    taxnum            = gv_taxnum
    total_amount      = gv_total_amount
    total_tax         = gv_total_tax
    gross_total       = gv_gross_total
  TABLES
    items             = lt_items
    schedules         = lt_schedules
  EXCEPTIONS
    OTHERS            = 1.

IF sy-subrc = 0.
  WRITE: 'PO printed successfully'.
ELSE.
  WRITE: 'Error in printing PO'.
ENDIF.
