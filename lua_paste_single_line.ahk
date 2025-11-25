#SingleInstance Force
#Requires AutoHotkey v2.0

; Hotkey to flatten clipboard Lua and type it out
^!v::
{
    text := A_Clipboard
    cleaned := FlattenLua(text)
    ; -- DEBUG: write cleaned to file to confirm parser output before sending
    ; FileDelete A_ScriptDir "\flattened_out.lua"
    ; FileAppend cleaned, A_ScriptDir "\flattened_out.lua", "UTF-8"
    SendLong(cleaned)
    Return
}

; -----------------------------
; SendLong: send safely in chunks
; -----------------------------
SendLong(text, chunkSize := 800, delayMs := 25) {
    if chunkSize < 1
        chunkSize := 200
    pos := 1
    len := StrLen(text)
    while pos <= len {
        chunk := SubStr(text, pos, chunkSize)
        ; Use SendText for v2 (reliable)
        SendText chunk
        Sleep delayMs
        pos += chunkSize
    }
}

; -----------------------------
; FlattenLua: robust parser
; -----------------------------
FlattenLua(text) {
    if text == "" {
        return ""
    }

    ; Normalize newlines -> '\n'
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")

    i := 1
    len := StrLen(text)
    out := ""

    state := "normal"  ; normal | string | longstring | linecomment | blockcomment
    strDelim := ""     ; ' or "
    longLevel := 0     ; number of = signs in a long bracket (0 for [[]], 1 for [=[ ]=], etc.)

    while i <= len {
        ch := SubStr(text, i, 1)
        next := (i < len) ? SubStr(text, i+1, 1) : ""

        if state = "normal" {
            ; --- detect start of block comment: --[=*[  (Lua long-comment)
            if ch = "-" && next = "-" {
                third := (i+2 <= len) ? SubStr(text, i+2, 1) : ""
                if third = "[" {
                    ; possible block comment with long bracket; count '='
                    j := i+3
                    eqCount := 0
                    while j <= len && SubStr(text, j, 1) = "=" {
                        eqCount++
                        j++
                    }
                    if j <= len && SubStr(text, j, 1) = "[" {
                        ; confirmed block comment start: --[=*[ 
                        state := "blockcomment"
                        longLevel := eqCount
                        i := j + 1  ; position after the '[', continue
                        continue
                    }
                }
                ; if not a long bracket block comment, treat as line comment
                state := "linecomment"
                i += 2
                continue
            }

            ; --- detect start of long string: [=*[ ... ]=*]
            if ch = "[" {
                ; count '='
                j := i+1
                eqCount := 0
                while j <= len && SubStr(text, j, 1) = "=" {
                    eqCount++
                    j++
                }
                if j <= len && SubStr(text, j, 1) = "[" {
                    ; long string start
                    state := "longstring"
                    longLevel := eqCount
                    out .= SubStr(text, i, j - i + 1) ; append the opening [=*[ (keeps exact delimiter)
                    i := j + 1
                    continue
                }
            }

            ; --- detect normal string start
            if ch = "'" || ch = '"' {
                state := "string"
                strDelim := ch
                out .= ch
                i++
                continue
            }

            ; --- newline -> space
            if ch = "`n" {
                out .= " "
                i++
                continue
            }

            ; --- normal char
            out .= ch
            i++
            continue
        }

        ; -----------------------
        ; inside a normal quoted string
        ; -----------------------
        if state = "string" {
            out .= ch
            if ch = "\\" { ; escape: include next char literally (if any)
                if i < len {
                    out .= SubStr(text, i+1, 1)
                    i += 2
                    continue
                } else {
                    i++
                    continue
                }
            }
            if ch = strDelim {
                ; To ensure it's not an escaped quote, check how many backslashes precede it
                ; Count run of backslashes immediately before this position
                k := i - 1
                bs := 0
                while k >= 1 && SubStr(text, k, 1) = "\\" {
                    bs++
                    k--
                }
                if (Mod(bs, 2) = 0) { ; even number of backslashes => quote is not escaped
                    state := "normal"
                    strDelim := ""
                }
            }
            i++
            continue
        }

        ; -----------------------
        ; inside a long string (or multiline string) with level longLevel
        ; we must find the matching ]=*=]
        ; -----------------------
        if state = "longstring" {
            ; detect possible closing: ] followed by same number of '=' then ]
            if ch = "]" {
                ; try to match
                j := i+1
                matched := true
                for k in 1..longLevel {
                    if j > len || SubStr(text, j, 1) != "=" {
                        matched := false
                        break
                    }
                    j++
                }
                if matched && j <= len && SubStr(text, j, 1) = "]" {
                    ; closing found
                    out .= SubStr(text, i, j - i + 1) ; append the closing delimiter including '='s and trailing ]
                    i := j + 1
                    state := "normal"
                    longLevel := 0
                    continue
                }
            }

            ; newline -> space inside long string (as requested)
            if ch = "`n" {
                out .= " "
                i++
                continue
            }

            out .= ch
            i++
            continue
        }

        ; -----------------------
        ; inside a line comment: skip until newline
        ; -----------------------
        if state = "linecomment" {
            if ch = "`n" {
                state := "normal"
                out .= " "
            }
            i++
            continue
        }

        ; -----------------------
        ; inside a block comment started by --[=*[ ... ]
        ; we must find closing ]=*=]
        ; -----------------------
        if state = "blockcomment" {
            ; detect closing sequence: ] then longLevel times '=' then ]
            if ch = "]" {
                j := i+1
                matched := true
                for k in 1..Floor(longLevel) {
                    if j > len || SubStr(text, j, 1) != "=" {
                        matched := false
                        break
                    }
                    j++
                }
                if matched && j <= len && SubStr(text, j, 1) = "]" {
                    ; close found, resume normal after it
                    i := j + 1
                    state := "normal"
                    longLevel := 0
                    continue
                }
            }
            i++
            continue
        }
    }

    ; final collapse of whitespace (preserve single spaces)
    out := RegExReplace(out, "\s+", " ")
    return Trim(out)
}