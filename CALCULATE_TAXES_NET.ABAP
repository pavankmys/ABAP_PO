FUNCTION CALCULATE_TAXES_NET.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_EBELN) TYPE EKKO-EBELN
*"  EXPORTING
*"     VALUE(E_TOTAL_TAX) TYPE P DECIMALS 2
*"     VALUE(E_CGST) TYPE P DECIMALS 2
*"     VALUE(E_SGST) TYPE P DECIMALS 2
*"     VALUE(E_IGST) TYPE P DECIMALS 2
*"  TABLES
*"      T_ITEMS STRUCTURE EKPO
*"----------------------------------------------------------------------
  DATA: lv_item TYPE ekpo,           " PO item structure
        lv_net_price TYPE ekpo-netpr, " Net Price
        lv_quantity TYPE ekpo-menge,  " Quantity
        lv_item_total TYPE p DECIMALS 2,
        lv_cgst_rate TYPE p DECIMALS 2,
        lv_sgst_rate TYPE p DECIMALS 2,
        lv_igst_rate TYPE p DECIMALS 2,
        lv_tax_code TYPE ekpo-mwskz.  " Tax Code

  CLEAR: E_TOTAL_TAX, E_CGST, E_SGST, E_IGST.

  " Loop through each item in the PO
  LOOP AT t_items INTO lv_item.
    lv_net_price = lv_item-netpr.
    lv_quantity = lv_item-menge.

    " Fetch the tax code for the item
    SELECT SINGLE mwskz
      INTO lv_tax_code
      FROM ekpo
      WHERE ebeln = I_EBELN
      AND ebelp = lv_item-ebelp.

    " Fetch the tax rates for CGST, SGST, and IGST based on the tax code
    SELECT SINGLE cgst sgst igst
      INTO (lv_cgst_rate, lv_sgst_rate, lv_igst_rate)
      FROM ztax_rates  " Assume we have a custom table ZTAX_RATES
      WHERE tax_code = lv_tax_code.

    " Calculate the total amount for the item
    lv_item_total = lv_net_price * lv_quantity.

    " Calculate the taxes for this item
    E_CGST = E_CGST + (lv_item_total * lv_cgst_rate / 100).
    E_SGST = E_SGST + (lv_item_total * lv_sgst_rate / 100).
    E_IGST = E_IGST + (lv_item_total * lv_igst_rate / 100).

  ENDLOOP.

  " Total tax is the sum of CGST, SGST, and IGST
  E_TOTAL_TAX = E_CGST + E_SGST + E_IGST.

ENDFUNCTION.
