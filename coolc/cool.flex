/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */

%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;



/*
 *  Add Your own definitions here
 */
#include <stdlib.h>
#include <cstdlib>

int commentNestingLevel = 0;
%}


/*
 * Define names for regular expressions here.
 */


DARROW          =>
ASSIGN    <=
INTEGER   [0-9]+
OBJECT_IDENTIFIER [a-z]([a-zA-Z0-9_]*)
TYPE_IDENTIFIER [A-Z]([a-zA-Z0-9_]*)
COMMENT_START \(\*
COMMENT_END \*\)
NEWLINE   \n


%x comment
%x STR
%%

 /*
  *  Nested comments
  */
 

COMMENT_START     {commentNestingLevel++; BEGIN(comment); }
<comment>COMMENT_END       {commentNestingLevel--;
         if (commentNestingLevel == 0)
            BEGIN(INITIAL);
         else if (commentNestingLevel < 0) {
            cool_yylval.error_msg = "Unmatched *) found.";
            return (ERROR);
          }
          }
  <comment>NEWLINE      {curr_lineno++;}
  <comment>.    {/* eat anything else */}
  <comment><<EOF>>  { cool_yylval.error_msg = "Unindented comment."; return ERROR; }

{OBJECT_IDENTIFIER} { cool_yylval.symbol = idtable.add_string(yytext, yyleng);
        return (OBJECTID);
      }
{TYPE_IDENTIFIER} { cool_yylval.symbol = idtable.add_string(yytext, yyleng); 
        return (TYPEID);
      }
{INTEGER}   { int parse_int = strtol(yytext, &yytext + yyleng, 10); 
        cool_yylval.symbol = inttable.add_int(parse_int); 
        return (INT_CONST);
      }
 /*
  *  The multiple-character operators.
  */
{DARROW}    { return (DARROW); }
{ASSIGN}    { return (ASSIGN); }
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

class   { return (CLASS); }
else    { return (ELSE); }
fi    { return (FI); }
if    { return (IF); }
in    { return (IN); }
inherits  { return (INHERITS); }
isvoid    { return (ISVOID); }
let     { return (LET); }
loop    { return (LOOP); }
pool    { return (POOL); }
then    { return (THEN); }
while     { return (WHILE); }
case    { return (CASE); }
esac    { return (ESAC); }
new     { return (NEW); }
of    { return (OF); }
not     { return (NOT); }
"+"     { return ('+'); }
"-"     { return ('-'); }
"*"     { return ('*'); }
"="     { return ('='); }
"<"     { return ('<'); }
\.    { return ('.'); }
"~"     { return ('~'); }
","     { return (','); }
";"     { return (';'); }
":"     { return (':'); }
"("     { return ('('); }
")"     { return (')'); }
"@"     { return ('@'); }
"{"     { return ('{'); }
"}"     { return ('}'); }

{NEWLINE} { curr_lineno++; }
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


\"    { string_buf_ptr = string_buf; BEGIN(STR); }
<STR>\"     { BEGIN(0);
      *string_buf_ptr = '\0';
      cool_yylval.symbol = stringtable.add_string(string_buf);
      /* TODO */
      return STR_CONST;
    }

<STR>NEWLINE  { cool_yylval.error_msg = yytext; curr_lineno++; }

<STR>\\[0-7]{1,3} {
         /* octal escape sequence */
         int result;

         (void) sscanf( yytext + 1, "%o", &result );

         if ( result > 0xff )
            cool_yylval.error_msg = "error - constant is out-of-bounds";

         *string_buf_ptr++ = result;
         }

 <STR>\\[0-9]+ {
               cool_yylval.error_msg = "error - bad escape sequence";
         }

 <STR>{
  "\\n" { *string_buf_ptr++ = '\n';}
  "\\t"   { *string_buf_ptr++ = '\t';}
  "\\r"   { *string_buf_ptr++ = '\r';}
  "\\b"   { *string_buf_ptr++ = '\b';}
  "\\f"   { *string_buf_ptr++ = '\f';}
  "\\." { *string_buf_ptr++ = yytext[1]; }
}

<<EOF>>    { yyterminate(); }

%%