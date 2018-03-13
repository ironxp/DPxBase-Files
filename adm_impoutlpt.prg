// Nombre     : ADM_IMPOUTLPT
// Proposito  : Imprimir Documento en LPT (Tickera-Espon)
// Dependencia: tab_DPDOCCLI, tab_DPMOVINV

#INCLUDE "DPXBASE.CH"

FUNC MAIN(cDocSuc,cDocTip,cDocCod,nDocNum)
  LOCAL oTable,aData:={},I,J,nCopy
  LOCAL cSql,cNombre,cCedula,cMemo:="",cOutLpt:="LPT3:"
  LOCAL nPorDes,cTipIva,lPrint:=.T.

  DEFAULT cDocSuc:=oDp:cSucursal,;
          cDocTip:="PED"        ,;
          cDocCod:=STRZERO(1,10),;
          nDocNum:=STRZERO(1,10)

/*
// PARA PRUEBAS
cDocTip:="TIK"
cDocCod:="B054"
nDocNum:="0000000005"

escpos20ePSON.pdf PARA REVISAR COMANDOS DE IMPRESION, LOS COMANDOS SE SUMAN PARA OBTENER LA COMBINACION
chr(27)+"!"+chr(8) NEGRITAS
chr(27)+"!"+chr(153) La impresora imprimirá a 12 cpp, en negrita, altura doble y subrayado.
*/

    IF "LPT3"$cOutLpt .AND. !ISPRINTER()
      MensajeErr("Impresora "+cLpt+" no está en Línea, Revise papel","Impresora Fuera de Linea")
      RETURN .F.
    ENDIF


    FOR  nCopy=1 TO 2

//Consulta para el Encabezado y Pie de Pagina
    cSql:="SELECT DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO,DOC_FECHA,DOC_HORA,DOC_CODVEN,DOC_NETO,"+;
          "DOC_DCTO,DOC_RECARG,DOC_OTROS,DOC_CONDIC,DOC_FCHVEN,DOC_HORA,DOC_IMPOTR,"+;
          "DOC_USUARI,DOC_BASNET,DOC_MTOIVA,DOC_MTOEXE,DOC_ASODOC,"+;
          "CCG_NOMBRE,CCG_RIF,CCG_TEL1,CCG_DIR1,CCG_DIR2,CLI_NOMBRE,CLI_RIF,CLI_TEL1,CLI_DIR1,CLI_DIR2,CLI_OBS1 "+;
          "FROM DPDOCCLI "+;
          "INNER JOIN DPCLIENTES ON DOC_CODIGO=CLI_CODIGO "+;
          "LEFT  JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO "+;
          "WHERE DOC_CODSUC"+GetWhere("=",cDocSuc)+;
          " AND DOC_TIPDOC "+GetWhere("=",cDocTip)+;
          " AND DOC_CODIGO "+GetWhere("=",cDocCod)+;
          " AND DOC_NUMERO "+GetWhere("=",nDocNum)+;
          " AND DOC_ACT = 1"

    oTable:=OpenTable(cSql,.T.)
//oTable:Browse() 

    IF cDocCod="0000000000"
      cNombre=oTable:CCG_NOMBRE
      cCedula=oTable:CCG_RIF
    ELSE
      cNombre=oTable:CLI_NOMBRE
      cCedula=oTable:CLI_RIF
    ENDIF

    oTable:GoTop()

**** ENCABEZADO
//Ancho Maximo (40):
//         "0123456789012345678901234567890123456789"+CRLF+;

    cMemo:=IIF(nCopy=1,"                SENIAT                  ",chr(27)+"!"+chr(24)+"            C O P I A     ")+CRLF+;
           chr(27)+"!"+chr(8)+"NOMBRE DE LA EMPRESA J-12345678-9"+CRLF+;
           chr(27)+"!"+chr(1)+IIF(nCopy=1,"DIRECCION LINEA 1 DE LA EMPRESA DE VENTA"+CRLF,"")+;
           IIF(nCopy=1,"DIRECCION LINEA 2 DE LA EMPRESA DE VENTA"+CRLF,"")+;
           IIF(nCopy=1,"TEL:0000-0000000  -  0000-0000000       "+CRLF,"")+;
           "                                        "+CRLF+;
           PADR("Cliente:"+cNombre,32)              +CRLF+;
           PADR("RIF/CI :"+cCedula,32)              +CRLF+;
           "Control Nro: "+SPACE(17)+        nDocNum+CRLF+;
           "Fecha : "+DTOC(oTable:DOC_FECHA)+SPACE(9)+"Hora:"+oTable:DOC_HORA+CRLF+;
           "----------------------------------------"

**** CONTENIDO
//Consulta para el Detalle del Documento
    aData:=ASQL("SELECT INV_CODIGO,INV_DESCRI,MOV_CANTID,MOV_UNDMED,MOV_PRECIO,"+;
                "MOV_TOTAL,MOV_IVA,MOV_DESCUE,MOV_LISTA,MOV_TIPIVA "+;
                "FROM DPMOVINV "+;
                "INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO "+;
                " WHERE MOV_CODSUC"+GetWhere("=",cDocSuc)+;
                "   AND MOV_TIPDOC"+GetWhere("=",cDocTip)+;
                "   AND MOV_CODCTA"+GetWhere("=",cDocCod)+;
                "   AND MOV_DOCUME"+GetWhere("=",nDocNum)+;
                "   AND MOV_TIPO  ='I' AND MOV_INVACT = 1")
//ViewArray(aData)

    FOR  I=1 TO LEN(aData)
      nPorDes:=aData[I,5]
      cTipIva:=aData[I,7]
      IIF(cTipIva=0,cTipIva:=" E",cTipIva:=" ")

      cMemo:=cMemo+;
        IIF(Empty(cMemo),"",CRLF)+;
        PADL(aData[I,2],40)+CRLF+;
        DEC(PADL(aData[I,3],6))+" "+PADL(aData[I,4],3)+""+;
        PADL(aData[I,5],14)+PADL(cTipIva,2)+DEC(TRAN(aData[I,6],"999,999,999.99"))
    NEXT I


*** PIE DE PAGINA
    cMemo:=cMemo+CRLF+;
           "----------------------------------------"+CRLF+;
           SPACE(11)+"SUB-TOTAL: "+DEC(TRAN(oTable:DOC_BASNET,"999,999,999,999.99"))+CRLF+;
           SPACE(11)+"EXENTO   : "+DEC(TRAN(oTable:DOC_MTOEXE,"999,999,999,999.99"))+CRLF+;
           SPACE(11)+"IVA (12%): "+DEC(TRAN(oTable:DOC_MTOIVA,"999,999,999,999.99"))+CRLF+;
           SPACE(11)+"TOTAL    : "+DEC(TRAN(oTable:DOC_NETO,"999,999,999,999.99"))+CRLF+;
           "                                    "+CRLF+;
           IIF(nCopy=1,"*** SLOGAN DE LA EMPRESA PARA MOSTRAR***"+CRLF,"")+;
           IIF(nCopy=1,"MH                            Z1B9056545"+CRLF,"")+;
           " "+CRLF+;
           IIF(nCopy=1,"+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+"+CRLF,CRLF)+;
           IIF(nCopy=2," "+CRLF,"")+;
           IIF(nCopy=2," "+CRLF,"")

    oTable:End()

*** CUADRO DE DIALOGO O IMPRESION DIRECTA

      IF lPrint
        IIF(nCopy=1,PANTALLA(cMemo,cOutLpt),PRINTLPT(cMemo,cOutLpt))
      ELSE
        PANTALLA(cMemo,cOutLpt)
      ENDIF

    NEXT nCopy

                               
RETURN .T.

FUNCTION PANTALLA(cMemo,cOutLpt)
   LOCAL oFont,oFontB,oDlg,oBtn,oMemo
   LOCAL nTop:=100,nLeft:=10,nAncho:=360,nAlto:=498,nClrPane1:=16774636,cTitulo:="RECIBO DE PAGO"


   DEFINE FONT oFont   NAME "Courier New" SIZE 0, -14 BOLD
   DEFINE FONT oFontB  NAME "Arial"       SIZE 0, -12 BOLD

   DEFINE DIALOG oDlg TITLE cTitulo;
                 COLOR NIL, 16773862

   @ 00,00 GET oMemo  VAR cMemo;
           MEMO SIZE 80,80; 
           READONLY;
           FONT oFont

   @ 12,03 BUTTON oBtn PROMPT " Imprimir "; 
           FONT oFontB;
           SIZE 40,14;
           ACTION (MsgRun("Imprimiendo","Por Favor Espere",{||PRINTLPT(cMemo,cOutLpt)}),oDlg:End())

   @ 12,15 BUTTON " Cerrar "; 
           FONT oFontB;
           SIZE 40,14;
           ACTION oDlg:End()

   ACTIVATE DIALOG oDlg ON INIT (oDlg:Move(nTop,nLeft,nAncho,nAlto,.T.),;
                                 oMemo:SetSize(nAncho-10,nAlto-70,.T.),;
                                 oMemo:SetColor(NIL,12713983),;
                                 DPFOCUS(oBtn),.F.)  

RETURN .T.

FUNCTION PRINTLPT(cMemo,cOutLpt)
    Set(24,cOutLpt,.T. )
    Set(23,"ON" )

    cMemo:=ANSITOOEM(cMemo)
    QOut(cMemo)

    Set(23,"OFF" )
    Set PRINT OFF
    Set PRINT TO

RETURN .T.

FUNCTION DEC(cConDev)
    cConDev:=STRTRAN(cConDev,".",";")
    cConDev:=STRTRAN(cConDev,",",".")
    cConDev:=STRTRAN(cConDev,";",",")
RETURN cConDev

//EOF