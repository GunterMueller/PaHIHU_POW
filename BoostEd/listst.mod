(*****************************************************************************)
(*  Module ListSt
 *  
 *  This module implements the class TextT. This class implements the data
 *  structure which is used to store the text in RAM while it is being edited.
 *  Each edit window uses one instance of this class to store the text. Files
 *  are always loaded into RAM completely before they can be edited.
 ******************************************************************************)

MODULE ListSt;


IMPORT
  SYSTEM, 
  WinDef, WinUser, 
  Strings, Utils, WinUtils, Options;


CONST

  MAXLENGTH*           =               2048;               (* maximum line length *)

  PEM_SHOWLINER*       =               WinUser.WM_USER+1000;
  (* Update der Zeilen/Spalteninformationen *)
  (* wParam: column, lParam: row            *)

  PEM_SHOWINSERTMODE*  =               WinUser.WM_USER+1001;
  (* Update der Einf�gemodusinformationen   *)
  (* wParam: 1(insert), 0(overwrite)        *)

  PEM_SHOWCHANGED*     =               WinUser.WM_USER+1002;
  (* Update der �nderungsinformationen      *)
  (* wParam: 1(ge�ndert), 0(nicht ge�ndert) *)

  PEM_DOUBLECLICK*     =               WinUser.WM_USER+1003;
  (* Doppelklick mit der linken Maustaste ist aufgetreten *)

  STEP*                =               10;                 (* Sprungrate f�r horizontales Scrolling *)
  hs*                  =               TRUE;               (* erm�glichen/sperren von horizontalem Scrolling *)

  Font1*               =              "Fixedsys";
  Font2*               =              "Courier";
  Font3*               =              "Courier New";
  Font1len*            =               8;
  Font2len*            =               7;


TYPE
  String               =               POINTER TO ARRAY OF CHAR;

  Line                 =               POINTER TO LineT;
  LineT                = RECORD                            (* Struktur einer Textzeile *)
    txt:                               String;             (* Text einer Zeile *)
    len:                               LONGINT;            (* L�nge einer Zeile *)
    next:                              Line;               (* n�chste Zeile *)
    prev:                              Line;               (* vorhergehende Zeile *)
    isCommented:                       BOOLEAN;            (* ist ein Kommentar in der Zeile vorhanden ? *)
    commentNesting:                    INTEGER;
  END (* LineT *) ;

  MarkT                = RECORD                            (* Markierung *)
    row*,                                                  (* Zeile und Spalte *)
    col*:                              LONGINT;
  END (* MarkT *) ;

  Text*                =               POINTER TO TextT;   (* Zeiger auf TextT *)
  TextT*               = RECORD
    head,
    tail,
    current:                           Line;               (* Beginn, Ende, Aktuell *)
    lines-:                            LONGINT;            (* Gesamtzahl Zeilen *)
    markStart*,
    markEnd*:                          MarkT;              (* f�r Markierung, Start und Ende der Markierung *)
    isSelected-:                       BOOLEAN;            (* ist eine Markierung vorhanden ? *)
    copyMark:                          LONGINT;
    commentsChecked:                   LONGINT;            (* Nummer der Zeile, bis zu der Kommentare gecheckt sind *)
  END (* TextT* *) ;


(* FUNKTIONEN F�R TEXTDATENSTRUKTUR *)

(*****************************************************************************)
PROCEDURE (VAR line: LineT) Init*     ();
  (* Initialisierung *)
BEGIN
  line.txt     := NIL;
  line.len     := 0;
  line.prev    := NIL;
  line.next    := NIL;
  line.isCommented := FALSE;
  line.commentNesting := 0;
END Init;


(*****************************************************************************)
PROCEDURE (VAR line: LineT) UpdateCommentInfo
                                      ();
(* Kommentare werden aktualisiert *)
VAR
  i:                                   LONGINT;
  txt:                                 String;
  sInx:                                LONGINT;
  sCh:                                 CHAR;
BEGIN
  txt          := line.txt;
  line.commentNesting := 0;
  i            := 0;
  WHILE txt[i]#0X DO
    sCh        := 0X;
    IF line.commentNesting<=0 THEN
      sInx     := 0;
      WHILE (Options.ActSyntaxColouring.StringDelims[sInx]#0X) & 
      (Options.ActSyntaxColouring.StringDelims[sInx]#txt[i]) DO
        INC(sInx);
      END (* WHILE (Options.ActSyntaxColouri *);
      IF Options.ActSyntaxColouring.StringDelims[sInx]#0X THEN
        sCh    := Options.ActSyntaxColouring.StringDelims[sInx];
        INC(i);
        WHILE (txt[i]#0X) & (txt[i]#sCh) DO
         INC(i)
        END (* WHILE (txt[i]#0X) & (txt[i]#sCh *);
        IF txt[i]=sCh THEN
          INC(i)
        END (* IF txt[i]=sCh *);
      END (* IF Options.ActSyntaxColouring.S *);
    END (* IF line.commentNesting<=0 *);
    IF sCh#0X THEN
    ELSIF txt[i]=Options.ActSyntaxColouring.CommentStart[0] THEN
      sInx     := 1;
      WHILE (Options.ActSyntaxColouring.CommentStart[sInx]#0X) & 
      (txt[i + sInx]=Options.ActSyntaxColouring.CommentStart[sInx]) DO
        INC(sInx);
      END (* WHILE (Options.ActSyntaxColouri *);
      IF Options.ActSyntaxColouring.CommentStart[sInx]=0X THEN
        INC(i, sInx);
        IF (line.commentNesting<=0) OR Options.ActSyntaxColouring.CommentsNested THEN
          INC(line.commentNesting);
        END (* IF (line.commentNesting<=0) OR  *);
        line.isCommented := TRUE;
      ELSE
        INC(i);
      END (* IF Options.ActSyntaxColouring.C *);
    ELSIF txt[i]=Options.ActSyntaxColouring.CommentEnd[0] THEN
      sInx     := 1;
      WHILE (Options.ActSyntaxColouring.CommentEnd[sInx]#0X) & 
      (txt[i + sInx]=Options.ActSyntaxColouring.CommentEnd[sInx]) DO
        INC(sInx);
      END (* WHILE (Options.ActSyntaxColouri *);
      IF Options.ActSyntaxColouring.CommentEnd[sInx]=0X THEN
        INC(i, sInx);
        IF (line.commentNesting>=0) OR Options.ActSyntaxColouring.CommentsNested THEN
          DEC(line.commentNesting);
        END (* IF (line.commentNesting>=0) OR  *);
        line.isCommented := TRUE;
      ELSE
        INC(i);
      END (* IF Options.ActSyntaxColouring.C *);
    ELSE
      INC(i);
    END (* IF sCh#0X *);
  END (* WHILE txt[i]#0X *);
END UpdateCommentInfo;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) InvalidateMarkArea*
                                      ();
(* Markierung aufheben *)
VAR
  done:                                WinDef.BOOL;

BEGIN
  IF text.isSelected THEN
    text.isSelected := FALSE;
    done       := WinUser.ShowCaret(WinDef.NULL);
    (* Caret anzeigen *)
  END (* IF text.isSelected *);
END InvalidateMarkArea;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) ResetMarkArea*
                                      ();
(* Markierung zur�cksetzen *)
BEGIN
  text.InvalidateMarkArea;
  text.markStart.row := 0;
  text.markStart.col := 0;
  text.markEnd.row := 0;
  text.markEnd.col := 0;
END ResetMarkArea;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) SetMarkArea*
                                      (row1,
                                       col1,
                                       row2,
                                       col2:               LONGINT);
(* Markierung setzen : Start (row1,col1), Stop(row2, col2) *)
VAR
  done:                                WinDef.BOOL;
BEGIN
  IF ~text.isSelected THEN
    text.isSelected := TRUE;
    done       := WinUser.HideCaret(WinDef.NULL);
    (* Caret verbergen *)
  END (* IF ~text.isSelected *);
  text.markStart.row := row1;
  text.markStart.col := col1;
  text.markEnd.row := row2;
  text.markEnd.col := col2;
END SetMarkArea;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) CheckMarkRange*
                                      (VAR swap:           BOOLEAN);
(* Markierungsbereich �berpr�fen und Markierungsvariablen setzen, Anfang vor Ende *)
(* liefert TRUE, wenn Positionen vertauscht wurden                                *)
  PROCEDURE Swap                        (VAR a,
                                         b:                  LONGINT);
  (* Vertauschen *)
  VAR
    h:                                   LONGINT;
  BEGIN
    h            := a;
    a            := b;
    b            := h;
  END Swap;

BEGIN
  swap         := FALSE;
  IF text.markStart.row>text.markEnd.row THEN
    Swap(text.markStart.row, text.markEnd.row);
    Swap(text.markStart.col, text.markEnd.col);
    swap       := TRUE;
  ELSIF text.markStart.row=text.markEnd.row THEN
    IF text.markStart.col>text.markEnd.col - 1 THEN
      Swap(text.markStart.col, text.markEnd.col);
      swap     := TRUE;
    END (* IF text.markStart.col>text.mark *);
  END (* IF text.markStart.row>text.mark *);
END CheckMarkRange;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) Init*     ();
(* Initialisierung der Textdatenstruktur *)
BEGIN
  text.head    := NIL;
  text.tail    := NIL;
  text.current := NIL;
  text.lines   := 0;
  text.ResetMarkArea;
  text.commentsChecked := 0;
END Init;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) SetCurrent(row:                LONGINT)
                                      :BOOLEAN;
(* aktuelle Zeile auf row setzen     *)
(* R�ckgabewert : TRUE (erfolgreich) *)
VAR
  cur:                                 Line;
  count:                               LONGINT;

BEGIN
  cur          := text.head;
  count        := 1;
  WHILE (cur#NIL) & (count<row) DO
    cur        := cur^.next;
    INC(count);
  END (* WHILE (cur#NIL) & (count<row) *);
  text.current := cur;
  RETURN cur#NIL;
END SetCurrent;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) CheckForComments
                                      (row:                LONGINT);
(* sicherstellen, da� Kommentare richtig gesetzt sind bis zur Zeile row *)
VAR
  cur:                                 Line;
  count:                               LONGINT;

BEGIN
  IF row>text.commentsChecked THEN
    cur        := text.head;
    count      := 0;
    WHILE (cur#NIL) & (count<row) DO
      cur.UpdateCommentInfo;
      cur      := cur^.next;
      INC(count);
    END (* WHILE (cur#NIL) & (count<row) *);
    text.commentsChecked := count;
  END (* IF row>text.commentsChecked *);
END CheckForComments;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) SetCurrentEx
                                      (row:                LONGINT;
                                       VAR nesting:        INTEGER)
                                      :BOOLEAN;
(* liefert die Summe der ge�ffneten und geschlossen Kommentare in vorherigen Zeilen in nesting *)

VAR
  cur:                                 Line;
  count,
  min:                                 LONGINT;

BEGIN
  cur          := text.head;
  count        := 1;
  nesting      := 0;
  min          := text.commentsChecked;
  IF min>row THEN
    min        := row
  END (* IF min>row *);
  WHILE (cur#NIL) & (count<min) DO
    nesting    := nesting+cur.commentNesting;
    cur        := cur^.next;
    INC(count);
  END (* WHILE (cur#NIL) & (count<min) *);
  WHILE (cur#NIL) & (count<row) DO
    cur.UpdateCommentInfo;
    nesting    := nesting+cur.commentNesting;
    cur        := cur^.next;
    INC(count);
  END (* WHILE (cur#NIL) & (count<row) *);
  IF count>text.commentsChecked THEN
    IF cur=NIL THEN
      DEC(count)
    ELSE
     cur.UpdateCommentInfo
    END (* IF cur=NIL *);
    text.commentsChecked := count;
  END (* IF count>text.commentsChecked *);
  text.current := cur;
  RETURN cur#NIL;
END SetCurrentEx;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) AddLine*  (VAR txt:            ARRAY OF CHAR)
                                      :BOOLEAN;
(* f�gt eine Zeile zum Text hinzu, die aktuelle Zeile wird auf die neue gesetzt *)
(* R�ckgabewert : TRUE (erfolgreich)                                            *)

VAR
  line:                                Line;

BEGIN
  NEW(line);
  IF line=NIL THEN
    RETURN FALSE
  END (* IF line=NIL *);
  line.Init;
  line.len     := Strings.Length(txt);
  NEW(line.txt, line.len + 1);
  IF line.txt=NIL THEN
    DISPOSE(line);
    RETURN FALSE;
  END (* IF line.txt=NIL *);
  line.next    := NIL;
  line.prev    := text.tail;
  COPY(txt, line.txt^);
  IF text.head=NIL THEN
    text.head  := line
  ELSE
   text.tail.next := line
  END (* IF text.head=NIL *);
  text.tail    := line;
  text.current := line;
  line.UpdateCommentInfo;
  INC(text.lines);
  RETURN TRUE;
END AddLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) BulkAddLine*
                                      (VAR txt-:           ARRAY OF CHAR;
                                       len:                LONGINT)
                                      :BOOLEAN;
(* f�gt eine Zeile mit einer gegebenen L�nge an den Text an, aktuelle Zeile wird nicht ver�ndert *)
(* R�ckgabewert : TRUE (erfolgreich)                                                             *)

VAR
  line:                                Line;

BEGIN
  NEW(line);
  IF line=NIL THEN
    RETURN FALSE
  END (* IF line=NIL *);
  line.Init;
  line.len     := len;
  NEW(line.txt, line.len + 1);
  IF line.txt=NIL THEN
    DISPOSE(line);
    RETURN FALSE;
  END (* IF line.txt=NIL *);
  line.next    := NIL;
  line.prev    := text.tail;
  COPY(txt, line.txt^);
  IF text.head=NIL THEN
    text.head  := line
  ELSE
   text.tail.next := line
  END (* IF text.head=NIL *);
  text.tail    := line;
  (*  line.UpdateCommentInfo; *)
  INC(text.lines);
  RETURN TRUE;
END BulkAddLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) InsertLine*
                                      (VAR txt:            ARRAY OF CHAR;
                                       row:                LONGINT)
                                      :BOOLEAN;
(* f�gt eine Zeile vor einer Zeile ein                                 *)
(* ist row gr��er als die Gesamtzahl der Zeilen, so wird die Zeile wie *)
(* bei AddLine eingef�gt                                               *)
(* aktuelle Zeile wird auf die neue Zeile gesetzt                      *)

VAR
  line,
  cur:                                 Line;
  done:                                BOOLEAN;

BEGIN
  IF (text.head=NIL) OR (row>text.lines) THEN
    RETURN text.AddLine(txt)
  END (* IF (text.head=NIL) OR (row>text *);
  NEW(line);
  IF line=NIL THEN
    RETURN FALSE
  END (* IF line=NIL *);
  line.Init;
  line.len     := Strings.Length(txt);
  NEW(line.txt, line.len + 1);
  IF line.txt=NIL THEN
    DISPOSE(line);
    RETURN FALSE;
  END (* IF line.txt=NIL *);
  done         := text.SetCurrent(row);
  ASSERT(done);
  cur          := text.current;
  line.next    := cur;
  line.prev    := cur.prev;
  IF cur=text.head THEN
    text.head  := line
  ELSE
   cur.prev.next := line
  END (* IF cur=text.head *);
  cur.prev     := line;
  COPY(txt, line.txt^);
  text.current := line;
  INC(text.lines);
  line.UpdateCommentInfo;
  RETURN TRUE;
END InsertLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) InsertNextLine*
                                      (VAR txt:            ARRAY OF CHAR)
                                      :BOOLEAN;
(* f�gt eine Zeile nach einer Zeile in den Text ein, existiert keine aktuelle Zeile  *)
(* so wird die Zeile wie bei AddLine eingef�gt, die aktuelle Zeile wird auf die neue *)
(* Zeile gesetzt                                                                     *)

VAR
  res:                                 BOOLEAN;
  line:                                Line;

BEGIN
  IF text.current=NIL THEN
    RETURN text.AddLine(txt)
  END (* IF text.current=NIL *);
  NEW(line);
  IF line=NIL THEN
    RETURN FALSE
  END (* IF line=NIL *);
  line.Init;
  line.len     := Strings.Length(txt);
  NEW(line.txt, line.len + 1);
  IF line.txt=NIL THEN
    DISPOSE(line);
    RETURN FALSE;
  END (* IF line.txt=NIL *);
  line.prev    := text.current;
  line.next    := text.current.next;
  IF text.current=text.tail THEN
    text.tail  := line
  ELSE
   text.current.next.prev := line
  END (* IF text.current=text.tail *);
  text.current.next := line;
  COPY(txt, line.txt^);
  text.current := line;
  INC(text.lines);
  line.UpdateCommentInfo;
  RETURN TRUE;
END InsertNextLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) DeleteCurrentLine*
                                      ()
                                      :BOOLEAN;
(* l�scht die aktuelle Zeile aus dem Text *)

VAR
  h:                                   Line;

BEGIN
  IF text.current=NIL THEN
    RETURN FALSE
  END (* IF text.current=NIL *);
  IF text.current=text.head THEN
    h          := text.head.next;
    DISPOSE(text.head.txt);
    DISPOSE(text.head);
    text.head  := h;
    IF h=NIL THEN
      text.tail := NIL
    ELSE
     h.prev    := NIL
    END (* IF h=NIL *);
    text.current := h;
  ELSIF text.current=text.tail THEN
    h          := text.tail.prev;
    DISPOSE(text.tail.txt);
    DISPOSE(text.tail);
    text.tail  := h;
    h.next     := NIL;
    text.current := h;
  ELSE
    h          := text.current;
    h.prev.next := h.next;
    h.next.prev := h.prev;
    text.current := h.next;
    DISPOSE(h.txt);
    DISPOSE(h);
  END (* IF text.current=text.head *);
  DEC(text.lines);
  RETURN TRUE;
END DeleteCurrentLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) DeleteLine*
                                      (row:                LONGINT)
                                      :BOOLEAN;
(* l�scht eine Zeile mit der Zeilennummer row aus dem Text, aktuelle Zeile wird auf *)
(* die n�chste Zeile gesetzt                                                        *)

VAR
  done:                                BOOLEAN;

BEGIN
  done         := text.SetCurrent(row);
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  RETURN text.DeleteCurrentLine();
END DeleteLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetLine*  (row:                LONGINT;
                                       VAR txt:            ARRAY OF CHAR;
                                       VAR len:            LONGINT)
                                      :BOOLEAN;
(* setzt einen Text txt in eine Zeile row, die L�nge wird in len zur�ckgegeben *)

VAR
  done:                                BOOLEAN;

BEGIN
  txt[0]       := 0X;
  len          := 0;
  done         := text.SetCurrent(row);
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  IF LEN(txt)<text.current.len + 1 THEN
    RETURN FALSE
  END (* IF LEN(txt)<text.current.len +  *);
  COPY(text.current.txt^, txt);
  len          := text.current.len;
  RETURN TRUE;
END GetLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetLineEx*(row:                LONGINT;
                                       VAR txt:            ARRAY OF CHAR;
                                       VAR len:            LONGINT;
                                       VAR isCommented:    BOOLEAN;
                                       VAR prevNesting:    INTEGER;
                                       VAR commentNesting: INTEGER)
                                      :BOOLEAN;
(* setzt einen Text txt in eine Zeile row, die L�nge wird in len zur�ckgegeben *)

VAR
  done:                                BOOLEAN;
BEGIN
  txt[0]       := 0X;
  len          := 0;
  isCommented  := FALSE;
  done         := text.SetCurrentEx(row, prevNesting);
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  IF LEN(txt)<text.current.len + 1 THEN
    RETURN FALSE
  END (* IF LEN(txt)<text.current.len +  *);
  COPY(text.current.txt^, txt);
  len          := text.current.len;
  isCommented  := text.current.isCommented;
  commentNesting := text.current.commentNesting;
  RETURN TRUE;
END GetLineEx;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetLineLength*
                                      (row:                LONGINT;
                                       VAR len:            LONGINT)
                                      :BOOLEAN;
(* liefert die L�nge einer Zeile row *)
VAR
  done:                                BOOLEAN;

BEGIN
  len          := 0;
  done         := text.SetCurrent(row);
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  len          := text.current.len;
  RETURN TRUE;
END GetLineLength;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetNextLine*
                                      (VAR txt:            ARRAY OF CHAR;
                                       VAR len:            LONGINT)
                                      :BOOLEAN;
(* liefert die Zeile nach der aktuellen Zeile zur�ck und die aktuelle Zeile wird auf diese *)
(* gesetzt                                                                                 *)

BEGIN
  IF (text.current=NIL) OR (text.current.next=NIL) THEN
    RETURN FALSE
  END (* IF (text.current=NIL) OR (text. *);
  text.current := text.current.next;
  IF LEN(txt)<text.current.len + 1 THEN
    RETURN FALSE
  END (* IF LEN(txt)<text.current.len +  *);
  COPY(text.current.txt^, txt);
  len          := text.current.len;
  RETURN TRUE;
END GetNextLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetNextLineEx*
                                      (VAR txt:            ARRAY OF CHAR;
                                       VAR len:            LONGINT;
                                       VAR isCommented:    BOOLEAN;
                                       VAR commentNesting: INTEGER)
                                      :BOOLEAN;
BEGIN
  IF (text.current=NIL) OR (text.current.next=NIL) THEN
    RETURN FALSE
  END (* IF (text.current=NIL) OR (text. *);
  text.current := text.current.next;
  IF LEN(txt)<text.current.len + 1 THEN
    RETURN FALSE
  END (* IF LEN(txt)<text.current.len +  *);
  COPY(text.current.txt^, txt);
  len          := text.current.len;
  text.current.UpdateCommentInfo;
  isCommented  := text.current.isCommented;
  commentNesting := text.current.commentNesting;
  RETURN TRUE;
END GetNextLineEx;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetPrevLine*
                                      (VAR txt:            ARRAY OF CHAR;
                                       VAR len:            LONGINT)
                                      :BOOLEAN;
(* liefert die vorhergehende Zeile zur�ck und die aktuelle Zeile wird auf diese gesetzt *)

BEGIN
  IF (text.current=NIL) OR (text.current.prev=NIL) THEN
    RETURN FALSE
  END (* IF (text.current=NIL) OR (text. *);
  text.current := text.current.prev;
  IF LEN(txt)<text.current.len + 1 THEN
    RETURN FALSE
  END (* IF LEN(txt)<text.current.len +  *);
  COPY(text.current.txt^, txt);
  len          := text.current.len;
  RETURN TRUE;
END GetPrevLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetCurrentLine*
                                      (VAR txt:            ARRAY OF CHAR;
                                       VAR len:            LONGINT)
                                      :BOOLEAN;
(* liefert die aktuelle Zeile zur�ck *)

BEGIN
  IF text.current=NIL THEN
    RETURN FALSE
  END (* IF text.current=NIL *);
  IF LEN(txt)<text.current.len + 1 THEN
    RETURN FALSE
  END (* IF LEN(txt)<text.current.len +  *);
  COPY(text.current.txt^, txt);
  len          := text.current.len;
  RETURN TRUE;
END GetCurrentLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) SetLine*  (row:                LONGINT;
                                       VAR txt:            ARRAY OF CHAR)
                                      :BOOLEAN;
(* der Inhalt einer Zeile wird durch txt ersetzt *)

VAR
  done:                                BOOLEAN;
  len:                                 LONGINT;
  newTxt:                              String;

BEGIN
  done         := text.SetCurrent(row);
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  len          := Strings.Length(txt);
  IF LEN(text.current.txt^)<len + 1 THEN
    NEW(newTxt, len + 10);
    IF newTxt=NIL THEN
      RETURN FALSE
    END (* IF newTxt=NIL *);
    DISPOSE(text.current.txt);
    text.current.txt := newTxt;
  END (* IF LEN(text.current.txt^)<len + *);
  COPY(txt, text.current.txt^);
  text.current.len := len;
  text.current.UpdateCommentInfo;
  RETURN TRUE;
END SetLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) SetLineEx*(row:                LONGINT;
                                       VAR txt:            ARRAY OF CHAR;
                                       VAR nestingChanged: BOOLEAN)
                                      :BOOLEAN;
(* der Inhalt einer Zeile wird durch txt ersetzt                                *)
(* nestingChanged wird gesetzt wenn sich bei den Kommentaren etwas ge�ndert hat *)

VAR
  done:                                BOOLEAN;
  len:                                 LONGINT;
  newTxt:                              String;
  nesting:                             INTEGER;

BEGIN
  done         := text.SetCurrent(row);
  nestingChanged := TRUE;
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  nesting      := text.current.commentNesting;
  len          := Strings.Length(txt);
  IF LEN(text.current.txt^)<len + 1 THEN
    NEW(newTxt, len + 10);
    IF newTxt=NIL THEN
      RETURN FALSE
    END (* IF newTxt=NIL *);
    DISPOSE(text.current.txt);
    text.current.txt := newTxt;
  END (* IF LEN(text.current.txt^)<len + *);
  COPY(txt, text.current.txt^);
  text.current.len := len;
  text.current.UpdateCommentInfo;
  nestingChanged := text.current.commentNesting#nesting;
  RETURN TRUE;
END SetLineEx;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) MergeLines*
                                      (row:                LONGINT)
                                      :BOOLEAN;
(* der Inhalt einer Zeile row und der folgenden Zeile wird miteinander vereint, die *)
(* aktuelle Zeile wird gesetzt                                                      *)

VAR
  done:                                BOOLEAN;
  newTxt:                              String;
  h:                                   Line;

BEGIN
  done         := text.SetCurrent(row);
  IF ~done OR (text.current.next=NIL) THEN
    RETURN FALSE
  END (* IF ~done OR (text.current.next= *);
  NEW(newTxt, text.current.len + text.current.next.len + 1);
  IF newTxt=NIL THEN
    RETURN FALSE
  END (* IF newTxt=NIL *);
  INC(text.current.len, text.current.next.len);
  COPY(text.current.txt^, newTxt^);
  Strings.Append(newTxt^, text.current.next.txt^);
  DISPOSE(text.current.txt);
  text.current.txt := newTxt;
  text.current.UpdateCommentInfo;
  h            := text.current;
  text.current := h.next;
  done         := text.DeleteCurrentLine();
  text.current := h;
  RETURN done;
END MergeLines;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) SplitLine*(row:                LONGINT;
                                       len1:               LONGINT;
                                       indent:             LONGINT)
                                      :BOOLEAN;
(* die Zeile row wird in zwei Teile geteilt, die L�nge des 1. Teils ist len1 Zeichen *)

VAR
  done:                                BOOLEAN;
  txt:                                 String;
  i,
  len2:                                LONGINT;
  h:                                   Line;

BEGIN
  done         := text.SetCurrent(row);
  IF ~done THEN
    RETURN FALSE
  END (* IF ~done *);
  h            := text.current;
  IF len1>h.len THEN
    len1       := h.len
  END (* IF len1>h.len *);
  len2         := h.len - len1;
  NEW(txt, len2 + 1+indent);
  IF txt=NIL THEN
    RETURN FALSE
  END (* IF txt=NIL *);
  FOR i:=0 TO indent-1 DO
   txt[i]      := " "
  END (* FOR i:=0 TO indent-1 *);
  FOR i:=0 TO len2-1 DO
   txt[i+indent] := h.txt[len1+i]
  END (* FOR i:=0 TO len2-1 *);
  h.txt[len1]  := 0X;
  h.len        := len1;
  h.UpdateCommentInfo;
  txt[indent + len2] := 0X;
  IF ~text.InsertNextLine(txt^) THEN
    RETURN FALSE
  END (* IF ~text.InsertNextLine(txt^) *);
  text.current := h;
  RETURN TRUE;
END SplitLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GoToLastLine*
                                      ();
(* zur letzten Zeile springen *)

BEGIN
  text.current := text.tail;
END GoToLastLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GoToFirstLine*
                                      ();
(* zur ersten Zeile springen *)

BEGIN
  text.current := text.head;
END GoToFirstLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetCurrentLineNo*
                                      (VAR row:            LONGINT);
(* liefert aktuelle Zeilennummer zur�ck *)

VAR
  cur:                                 Line;
BEGIN
  row          := 0;
  IF (text.current=NIL) OR (text.head=NIL) THEN
    RETURN 
  END (* IF (text.current=NIL) OR (text. *);
  row          := 1;
  cur          := text.head;
  WHILE (cur#NIL) & (cur#text.current) DO
    INC(row);
    cur        := cur.next;
  END (* WHILE (cur#NIL) & (cur#text.cur *);
END GetCurrentLineNo;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetFirstMarkedLine*
                                      (VAR txt:            ARRAY OF CHAR)
                                      :BOOLEAN;
(* liefert den Inhalt der 1.Zeile der Markierung *)

VAR
  buf:                                 String;
  len:                                 LONGINT;
  swap:                                BOOLEAN;

BEGIN
  IF ~text.isSelected THEN
    txt[0]     := 0X;
    RETURN FALSE
  END (* IF ~text.isSelected *);
  NEW(buf, MAXLENGTH);
  IF buf=NIL THEN
    txt[0]     := 0X;
    RETURN FALSE
  END (* IF buf=NIL *);
  text.CheckMarkRange(swap);
  text.copyMark := text.markStart.row;
  IF ~text.GetLine(text.markStart.row, buf^, len) THEN
    DISPOSE(buf);
    RETURN FALSE
  END (* IF ~text.GetLine(text.markStart *);
  IF text.markStart.row#text.markEnd.row THEN
    Strings.Copy(buf^, txt, text.markStart.col, len - text.markStart.col + 1);
  ELSE
    Strings.Copy(buf^, txt, text.markStart.col, text.markEnd.col - text.markStart.col);
  END (* IF text.markStart.row#text.mark *);
  DISPOSE(buf);
  RETURN TRUE;
END GetFirstMarkedLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetNextMarkedLine*
                                      (VAR txt:            ARRAY OF CHAR)
                                      :BOOLEAN;
(* liefert den Inhalt der n�chsten Zeile einer Markierung *)

VAR
  len,
  row:                                 LONGINT;
  buf:                                 String;

BEGIN
  txt[0]       := 0X;
  IF ~text.isSelected OR (text.copyMark>=text.markEnd.row) THEN
    RETURN FALSE
  END (* IF ~text.isSelected OR (text.co *);
  INC(text.copyMark);
  IF text.copyMark=text.markEnd.row THEN
    NEW(buf, MAXLENGTH);
    IF buf=NIL THEN
      RETURN FALSE
    END (* IF buf=NIL *);
    IF ~text.GetNextLine(buf^, len) THEN
      DISPOSE(buf);
      RETURN FALSE
    END (* IF ~text.GetNextLine(buf^, len) *);
    Strings.Copy(buf^, txt, 1, text.markEnd.col - 1);
  ELSE
    IF ~text.GetNextLine(txt, len) THEN
      RETURN FALSE
    END (* IF ~text.GetNextLine(txt, len) *);
  END (* IF text.copyMark=text.markEnd.r *);
  RETURN TRUE;
END GetNextMarkedLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) ResetContents*
                                      ();
(* Inhalt zur�cksetzen *)

VAR
  line,
  h:                                   Line;

BEGIN
  line         := text.tail;
  WHILE line#NIL DO
    h          := line;
    line       := line.prev;
    IF h.txt#NIL THEN
      DISPOSE(h.txt)
    END (* IF h.txt#NIL *);
    DISPOSE(h);
  END (* WHILE line#NIL *);
  text.Init;
END ResetContents;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) GetMarkedTextSize*
                                      ()
                                      :LONGINT;
(* Speicherplatz berechnen f�r markierten Text inklusive Zeilenvorschub *)

VAR
  rows,
  size:                                LONGINT;
  swap,
  done:                                BOOLEAN;

BEGIN
  IF ~text.isSelected THEN
    RETURN 0
  END (* IF ~text.isSelected *);
  text.CheckMarkRange(swap);
  size         := 0;
  IF text.markStart.row=text.markEnd.row THEN
    RETURN text.markEnd.col - text.markStart.col;
  ELSE
    rows       := text.markEnd.row - text.markStart.row + 1;
    done       := text.SetCurrent(text.markStart.row);
    ASSERT(done);
    size       := text.current.len - text.markStart.col + 3;
    DEC(rows);
    WHILE rows>1 DO
      text.current := text.current.next;
      ASSERT(text.current#NIL);
      size     := size+text.current.len+2;
      DEC(rows);
    END (* WHILE rows>1 *);
    text.current := text.current.next;
    ASSERT(text.current#NIL);
    size       := size + text.markEnd.col + 2;
    RETURN size;
  END (* IF text.markStart.row=text.mark *);
END GetMarkedTextSize;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) InsertInLine*
                                      (VAR txt:            ARRAY OF CHAR;
                                       pos:                LONGINT;
                                       row:                LONGINT)
                                      :BOOLEAN;
(* f�gt einen String txt an der Position pos in der Zeile row ein, wenn m�glich,        *)
(* ansonsten wird der String an den Text angeh�ngt, wenn die Zeile noch nicht existiert *)

VAR
  len:                                 LONGINT;
  buf:                                 String;
  done:                                BOOLEAN;

BEGIN
  NEW(buf, MAXLENGTH);
  IF buf=NIL THEN
    RETURN FALSE
  END (* IF buf=NIL *);
  IF ~text.GetLine(row, buf^, len) THEN
    DISPOSE(buf);
    RETURN text.AddLine(txt);
  END (* IF ~text.GetLine(row, buf^, len *);
  IF pos>len + 1 THEN
    pos        := len + 1
  END (* IF pos>len + 1 *);
  Strings.Insert(txt, buf^, pos);
  done         := text.SetLine(row, buf^);
  DISPOSE(buf);
  RETURN done;
END InsertInLine;


(*****************************************************************************)
PROCEDURE (VAR text: TextT) DeleteInLine*
                                      (pos:                LONGINT;
                                       len:                LONGINT;
                                       row:                LONGINT)
                                      :BOOLEAN;
(* L�scht len Zeichen aus einer Zeile row beginnend an der Position pos *)

VAR
  buf:                                 String;
  bufLen:                              LONGINT;
  done:                                BOOLEAN;

BEGIN
  IF len<=0 THEN
    RETURN TRUE
  END (* IF len<=0 *);
  NEW(buf, MAXLENGTH);
  IF buf=NIL THEN
    RETURN FALSE
  END (* IF buf=NIL *);
  IF ~text.GetLine(row, buf^, bufLen) THEN
    DISPOSE(buf);
    RETURN FALSE
  END (* IF ~text.GetLine(row, buf^, buf *);
  IF pos>bufLen THEN
    pos        := bufLen + 1
  END (* IF pos>bufLen *);
  IF pos + len - 1>bufLen THEN
    len        := bufLen - pos + 1
  END (* IF pos + len - 1>bufLen *);
  IF (pos=1) & (len=bufLen) THEN
    buf[0]     := 0X;
  ELSE
    Strings.Delete(buf^, pos, len);
  END (* IF (pos=1) & (len=bufLen) *);
  done         := text.SetLine(row, buf^);
  DISPOSE(buf);
  RETURN done;
END DeleteInLine;


(*****************************************************************************)
(*****************************************************************************)
BEGIN
  ;
END ListSt.


