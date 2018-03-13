// Nombre     : ADM_CTAtoJSON
// Proposito  : Convertir Plan de Cuentas en Json 
// Dependencia: tab_DPCTA

#INCLUDE "DPXBASE.CH"

FUNC MAIN()
  LOCAL nTab:=2,aData1:={},aData2:={},aData3:={},aData4:={}
  LOCAL cMemo:='',a1,a2,a3,a4,cTipo1,cTipo2,cTipo3,cTipo4

**** INICIO ARCHIVO
    cMemo:='{'+CRLF+;
           SPACE(nTab)+'"country_code": "ve",'+CRLF+;
           SPACE(nTab)+'"name": "Venezuela - Chart of Accounts",'+CRLF+;
           SPACE(nTab)+'"tree":'+CRLF+;
           SPACE(nTab)+'{'

//*** Nivel 1 ***
    aData1:=ASQL('SELECT CTA_DESCRI,CTA_CODIGO FROM DPCTA WHERE CTA_ACTIVO = 1 HAVING LENGTH(CTA_CODIGO) = 1')
    //ViewArray(aData1)

    FOR  a1=1 TO LEN(aData1)
      cTipo1:=''

      DO CASE
        CASE aData1[a1,2]='1'
          cTipo1='Asset'
        CASE aData1[a1,2]='2'
          cTipo1='Liability'
        CASE aData1[a1,2]='3'
          cTipo1='Equity'
        CASE aData1[a1,2]='4'
          cTipo1='Income'
        CASE aData1[a1,2]='5'
          cTipo1='Expense'
        CASE aData1[a1,2]='6'
          cTipo1='Expense'
      ENDCASE
      
      cMemo:=cMemo+CRLF+;
             SPACE(nTab*2)+'"'+RTRIM(aData1[a1,1])+'": {'+CRLF

//*** Nivel 2 ***
	  aData2:=ASQL('SELECT CTA_DESCRI,CTA_CODIGO FROM DPCTA WHERE CTA_ACTIVO = 1 HAVING LEFT(CTA_CODIGO,1)'+GetWhere('=',aData1[a1,2])+' AND LENGTH(CTA_CODIGO) = 2 ')
			 
      FOR  a2=1 TO LEN(aData2)
        cTipo2:=''
		cMemo:=cMemo+SPACE(nTab*3)+'"'+RTRIM(aData2[a2,1])+'" :{'+CRLF

//*** Nivel 3 ***
        aData3:=ASQL("SELECT CTA_DESCRI,CTA_CODIGO FROM DPCTA WHERE CTA_ACTIVO = 1 HAVING LEFT(CTA_CODIGO,2)"+GetWhere("=",aData2[a2,2])+" AND LENGTH(CTA_CODIGO) = 4 ")
								 
        FOR  a3=1 TO LEN(aData3)
          cTipo3:=""
          cMemo:=cMemo+SPACE(nTab*4)+'"'+RTRIM(aData3[a3,1])+'" :{'+CRLF

//*** Nivel 4 ***
          aData4:=ASQL("SELECT CTA_DESCRI,CTA_CODIGO FROM DPCTA WHERE CTA_ACTIVO = 1 HAVING LEFT(CTA_CODIGO,4)"+GetWhere("=",aData3[a3,2])+" AND LENGTH(CTA_CODIGO) = 6 ")
						 
          FOR  a4=1 TO LEN(aData4)
            cTipo4:=""
            cMemo:=cMemo+SPACE(nTab*5)+'"'+RTRIM(aData4[a4,1])+'" :{'

            cMemo:=cMemo+''+CRLF+;
            SPACE(nTab*5)+'"account_number": "'+RTRIM(aData4[a4,2])+'"'+CRLF
            cMemo:=cMemo+SPACE(ntab*5)+'}'

            cMemo:=cMemo+IIF(a4<LEN(aData4),","+CRLF,"")
          NEXT a4

          cMemo:=cMemo+''+CRLF+;
          SPACE(nTab*4)+',"account_number": "'+RTRIM(aData3[a3,2])+'"'+CRLF
          cMemo:=cMemo+SPACE(ntab*4)+'}'

          cMemo:=cMemo+IIF(a3<LEN(aData3),","+CRLF,"")
        NEXT a3

        cMemo:=cMemo+''+CRLF+;
        SPACE(nTab*3)+',"account_number": "'+RTRIM(aData2[a2,2])+'"'+CRLF
        cMemo:=cMemo+SPACE(ntab*3)+'}'

        cMemo:=cMemo+IIF(a2<LEN(aData2),','+CRLF,'')
      NEXT a2

      cMemo:=cMemo+''+CRLF+;
             SPACE(nTab*2)+',"account_number": "'+RTRIM(aData1[a1,2])+'"'+CRLF+;
             SPACE(ntab*2)+',"root_type": "'+cTipo1+'"'+CRLF+;
             SPACE(nTab*2)+'}'
     
      cMemo:=cMemo+IIF(a1<LEN(aData1),','+CRLF,'')
 
    NEXT a1

*** FINAL ARCHIVO
    cMemo:=cMemo+CRLF+;
           SPACE(ntab)+"}"+CRLF+"}"
           
    PANTALLA(cMemo)
                        
RETURN .T.

FUNCTION PANTALLA(cMemo)
  LOCAL oFont,oFontB,oDlg,oBtn,oMemo
  LOCAL nTop:=100,nLeft:=10,nAncho:=450,nAlto:=498,nClrPane1:=16774636,cTitulo:="Crtl+C para Copiar"

    DEFINE FONT oFont   NAME "Courier New" SIZE 0, -14 BOLD
    DEFINE FONT oFontB  NAME "Arial"       SIZE 0, -12 BOLD

    DEFINE DIALOG oDlg TITLE cTitulo;
                  COLOR NIL, 16773862

    @ 00,00 GET oMemo  VAR cMemo;
            MEMO SIZE 80,80; 
            READONLY;
            FONT oFont

    @ 12,15 BUTTON " Cerrar "; 
            FONT oFontB;
            SIZE 40,14;
            ACTION oDlg:End()

    ACTIVATE DIALOG oDlg ON INIT (oDlg:Move(nTop,nLeft,nAncho,nAlto,.T.),;
                                 oMemo:SetSize(nAncho-10,nAlto-70,.T.),;
                                 oMemo:SetColor(NIL,12713983),;
                                 DPFOCUS(oBtn),.F.)  

RETURN .T.
//EOF