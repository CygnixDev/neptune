lexer grammar RuneScriptLexer;

@members {
private int depth = 0;
public boolean stringTemplates = false;

// type of the last token emitted on the default channel
private int lastType = -1;

@Override
public Token emit() {
    Token token = super.emit();
    if (token.getChannel() == DEFAULT_TOKEN_CHANNEL) {
        lastType = token.getType();
    }
    return token;
}

// whether the next token directly follows a prefix that makes it a variable, constant, proc or label name
private boolean afterNamePrefix() {
    return lastType == DOLLAR || lastType == MOD || lastType == CARET || lastType == TILDE || lastType == AT;
}

// whether the text lexed so far starts with a literal followed by '+', which makes the '+' an addition
private boolean startsWithLiteralPlus() {
    String text = getText();
    String head = text.substring(0, text.indexOf('+'));
    return head.matches("[0-9]+|0[xX][0-9a-fA-F]+|[0-9]+(_[0-9]+){4}|true|false|null");
}

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
fragment IdentifierChar
    : [a-zA-Z0-9_.:]
    ;

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
// config names may contain '+' (e.g. dragon_dagger_p++, antidote+4, cheese+tom_batta). a name after a prefix
// ($a+1, ~b+1) or a literal (1+2, 0xff+1, true+1) still ends at the '+', but an unprefixed config name doesn't:
// calc(bones+1) reads as the name bones+1, so write calc(bones + 1)
PLUS_IDENTIFIER : {!afterNamePrefix()}? IdentifierChar+ ('+' IdentifierChar*)+ {!startsWithLiteralPlus()}?
                  -> type(IDENTIFIER) ;
IDENTIFIER      : IdentifierChar+ ;
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
STRING_SWITCH_TAG   : '<switch,' -> type(STRING_PARTIAL_TAG) ;
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
    | 'str_he'
    | 'str_she'
    | 'shad'
    | 'u'
    | 'img'
    | 'gt'
    | 'lt'
    ;
