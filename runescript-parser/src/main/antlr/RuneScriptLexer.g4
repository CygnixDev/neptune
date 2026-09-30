lexer grammar RuneScriptLexer;

@members {
private int depth = 0;
public boolean stringTemplates = false;

// line and column of each open string's quote, innermost last
private final java.util.ArrayDeque<int[]> openQuotes = new java.util.ArrayDeque<>();

// reports the innermost open string as unterminated, at its opening quote
private void reportUnterminatedString() {
    int[] quote = openQuotes.pop();
    getErrorListenerDispatch().syntaxError(this, null, quote[0], quote[1], "unterminated string", null);
}

// strings still open at the end of input are unterminated too
@Override
public Token emitEOF() {
    while (!openQuotes.isEmpty()) {
        reportUnterminatedString();
    }
    return super.emitEOF();
}
}

// symbols
LPAREN      : '(' ;
RPAREN      : ')' ;
COLON       : ':' ;
SEMICOLON   : ';' ;
COMMA       : ',' ;
LBRACK      : '[' ;
RBRACK      : ']' ;
LBRACE      : '{' ;
RBRACE      : '}' ;
PLUS        : '+' ;
MINUS       : '-' ;
MUL         : '*' ;
DIV         : '/' ;
MOD         : '%' ;
AND         : '&' ;
OR          : '|' ;
EQ          : '=' ;
EXCL        : '!' ;
DOLLAR      : '$' ;
CARET       : '^' ;
TILDE       : '~' ;
AT          : '@' ;
GT          : '>' {if (depth > 0) {setType(STRING_EXPR_END); popMode();}} ;
GTE         : '>=' ;
LT          : '<' ;
LTE         : '<=' ;
INCREMENT   : '++' ;
DECREMENT   : '--' ;

// keywords
IF          : 'if' ;
ELSE        : 'else' ;
WHILE       : 'while' ;
CASE        : 'case' ;
DEFAULT     : 'default' ;
RETURN      : 'return' ;
CALC        : 'calc' ;
DEF_TYPE    : 'def_' IDENTIFIER ;
SWITCH_TYPE : 'switch_' IDENTIFIER ;

// literals
INTEGER_LITERAL : '-'? Digit+ ;
HEX_LITERAL     : '0' [xX] [0-9a-fA-F]+ ;
COORD_LITERAL   : Digit+ '_' Digit+ '_' Digit+ '_' Digit+ '_' Digit+ ;
BOOLEAN_LITERAL : 'true' | 'false' ;
CHAR_LITERAL    : '\'' (CharEscapeSequence | ~['\\\r\n]) '\'' ;
NULL_LITERAL    : 'null' ;

// comments
LINE_COMMENT    : '//' .*? ('\n' | EOF) -> channel(HIDDEN) ;
BLOCK_COMMENT   : '/*' .*? '*/' -> channel(HIDDEN) ;

// a basic digit rule
fragment Digit
    : [0-9]
    ;

// allows escaping specific characters in a char literal
fragment CharEscapeSequence
    : '\\' ('\\' | '\'')
    ;

// special
QUOTE_OPEN      : '"' {depth++; openQuotes.push(new int[] {_tokenStartLine, _tokenStartCharPositionInLine});}
                  -> pushMode(String) ;
IDENTIFIER      : [a-zA-Z0-9_.:]+ ;
WHITESPACE      : [ \t\n\r]+ -> channel(HIDDEN) ;

// string interpolation support
mode String ;

QUOTE_CLOSE         : '"' {depth--; openQuotes.pop();} -> popMode ;
// a line break inside a string: report it and end the string there, so the lines after it lex normally
STRING_UNTERMINATED : '\r'? '\n' {depth--; reportUnterminatedString();} -> type(QUOTE_CLOSE), popMode ;
STRING_TEXT         : (StringEscapeSequence | ~('\\' | '"' | '<' | '\r' | '\n'))+ ;
STRING_TAG          : '<' Tag ('=' ~('<' | '>')+)? '>' ;
STRING_CLOSE_TAG    : '</' Tag '>' ;
STRING_PARTIAL_TAG  : '<' Tag '=' ;
STRING_P_TAG        : '<p,' ~('<' | '>')+ '>'  ;
STRING_EXPR_START   : '<' -> pushMode(DEFAULT_MODE) ;
STRING_EXPR_END     : '>' ;
STRING_TEMPLATE     : {stringTemplates}? '<text_pronoun(' ~[<>\r\n]* ')>' ;

// allows escaping specific characters in a string
fragment StringEscapeSequence
    : '\\' ('\\' | '"' | '<')
    ;

// possible tags used in strings
fragment Tag
    : 'br'
    | 'col'
    | 'str'
    | 'shad'
    | 'u'
    | 'img'
    | 'gt'
    | 'lt'
    ;
