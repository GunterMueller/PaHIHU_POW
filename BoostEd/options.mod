(******************************************************************************
 *  Module Options                                         V 1.00.03
 *  
 *  This module contains all configurable options of the editor.
 *  Option settings can be temporarily saved to support the implementation
 *  of a cancel when editing the options in a dialog box.
(*                                                                           *)
(*  UPDATED                                                                  *)
(*   2003OCT23 KlS color for keywords added                                      *)
 ******************************************************************************)

MODULE Options;

IMPORT 
  GlobWin;

CONST
  FONTNAMELEN*         =               100;
  FONT_FIXEDSYS*       =              "Fixedsys";
  FONT_COURIER*        =              "Courier";
  FONT_COURIERNEW*     =              "Courier New";
  MAXDELIMLEN*         =                 4;                (* maximum length for comment delimiters *)
  MAXSTRINGDELIMS*     =                 3;                (* maximum number of different string literal delimiters *)

  COMMENT_RED*         =                 0;                (* color default for comments *)
  COMMENT_GREEN*       =               180;                (* color default for comments *)
  COMMENT_BLUE*        =                 0;                (* color default for comments *)

  KEYWORD_RED*         =                 0;                (* color default for keywords *)
  KEYWORD_GREEN*       =                 0;                (* color default for keywords *)
  KEYWORD_BLUE*        =               255;                (* color default for keywords *)

VAR
  syntax*:                             BOOLEAN;            (* Oberon-2 Syntax Unterst�tzung ? *)
  smartDel*:                           BOOLEAN;            (* F�hrende Leerzeichen l�schen *)
  indentWidth*:                        LONGINT;            (* Anzahl Leerzeichen bei indent Level *)
  insert*:                             BOOLEAN;            (* Einf�ge/�berschreibemodus *)
  autoIndent*:                         BOOLEAN;
  tabsize*:                            LONGINT;
  useTabs*:                            BOOLEAN;
  mouse*:                              BOOLEAN;            (* rechte Maustaste f�r Themensuche verwenden *)
  colorComments*:                      BOOLEAN;
  commentStart*:                       ARRAY MAXDELIMLEN OF CHAR;
  commentEnd*:                         ARRAY MAXDELIMLEN OF CHAR;
  commentLine*:                        ARRAY MAXDELIMLEN OF CHAR; (* currently not used *)
  commentsNested*:                     BOOLEAN;
  stringDelims*:                       ARRAY MAXSTRINGDELIMS+1 OF CHAR;
  fontSize*:                           LONGINT;
  fontName*:                           ARRAY FONTNAMELEN OF CHAR;
  printerFontSize*:                    LONGINT;            (* Schriftgr��e *)
  printerFontName*:                    ARRAY FONTNAMELEN OF CHAR;

  printMarginLeft*,
  printMarginRight*,
  printMarginTop*,
  printMarginBottom*:                  LONGINT;            (* margin in 1/100 inches from edges of sheet *)
  printLineNumbers*:                   BOOLEAN;
  printDate*:                          BOOLEAN;
  
  CommentColor*:                       LONGINT;            (* RGB value to define the color used for comments *)
  KeyWordColor*:                       LONGINT;            (* RGB value to define the color used for keywords *)

  hsyntax:                             BOOLEAN;            (* Oberon-2 Syntax Unterst�tzung ? *)
  hsmartDel:                           BOOLEAN;            (* F�hrende Leerzeichen l�schen *)
  hindentWidth:                        LONGINT;            (* Anzahl Leerzeichen bei indent Level *)
  hinsert:                             BOOLEAN;            (* Einf�ge/�berschreibemodus *)
  hautoIndent:                         BOOLEAN;
  htabsize:                            LONGINT;
  huseTabs:                            BOOLEAN;
  hmouse:                              BOOLEAN;
  hfontSize:                           LONGINT;
  hfontName:                           ARRAY FONTNAMELEN OF CHAR;
  hPrinterFontSize:                    LONGINT;
  hPrinterFontName:                    ARRAY FONTNAMELEN OF CHAR;
  hColorComments:                      BOOLEAN;

  
(******************************************************************************************)
PROCEDURE TmpSave*;
(* Tempdaten speichern *)
BEGIN
  hsyntax:=     syntax;
  hsmartDel:=   smartDel;
  hindentWidth:=indentWidth;
  hinsert:=     insert;
  hautoIndent:= autoIndent;
  htabsize   := tabsize;
  huseTabs   := useTabs; 
  hmouse     := mouse;
  hfontSize  := fontSize;
  COPY(fontName,hfontName);
  hPrinterFontSize  := printerFontSize;
  COPY(printerFontName,hPrinterFontName);
  hColorComments:=colorComments;
END TmpSave;

(******************************************************************************************)

PROCEDURE Restore*;
(* Daten wiederherstellen *)

BEGIN
  syntax:=     hsyntax;
  smartDel:=   hsmartDel;
  indentWidth:=hindentWidth;
  insert:=     hinsert;
  autoIndent:= hautoIndent;
  tabsize   := htabsize;
  useTabs   := huseTabs; 
  mouse     := hmouse;
  fontSize  := hfontSize;
  COPY(hfontName,fontName);
  printerFontSize  := hPrinterFontSize;
  COPY(hPrinterFontName,printerFontName);
  colorComments:=hColorComments;
END Restore;

(*****************************************************************************)
(*****************************************************************************)
(* Initialisierung der Einstellungen *)

BEGIN
  autoIndent           := TRUE;
  insert               := TRUE;
  useTabs              := TRUE;
  tabsize              :=   3;
  mouse                := TRUE;
  syntax               := TRUE;
  smartDel             := TRUE;
  indentWidth          :=   2;
  insert               := TRUE;
  colorComments        := TRUE;
  fontSize             :=  12;
  fontName             := FONT_FIXEDSYS;
  printerFontSize      :=  10;
  printerFontName      := FONT_COURIERNEW;

  printMarginLeft      :=  40;
  printMarginRight     :=  40;
  printMarginTop       :=  60;
  printMarginBottom    := 100;
  printLineNumbers     := TRUE;
  printDate            := TRUE;
  
  commentStart         := "(*";
  commentEnd           := "*)";
  commentLine          := "";
  commentsNested       := TRUE;
  stringDelims[0]      := '"';
  stringDelims[1]      := "'";
  stringDelims[2]      :=   0X;
  
  CommentColor         := GlobWin.RGB(COMMENT_RED, COMMENT_GREEN, COMMENT_BLUE);
  KeyWordColor         := GlobWin.RGB(KEYWORD_RED, KEYWORD_GREEN, KEYWORD_BLUE);
  
END Options.


