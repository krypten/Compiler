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

int string_error = 0;
int escape_pending = 0;
int commentNestingLevel = 0;

%}


/*
 * Define names for regular expressions here.
 */


DARROW      	    =>
ASSIGN    			<-
LE 					<=
INTEGER   			[0-9]+
OBJECT_IDENTIFIER 	[a-z]([a-zA-Z0-9_]*)
TYPE_IDENTIFIER 	[A-Z]([a-zA-Z0-9_]*)
SELF            	[:@,;(){}=<~/\-\*\+\.]
NEWLINE   			\n
SPACE           	[ \r\f\t\v]+
WS 					[\n\f\r\t\v\32 ]
CLASS 				[cC][lL][aA][sS][sS]
ELSE 				[eE][lL][sS][eE]
FI 					[fF][iI]
IF 					[iI][fF]
IN 					[iI][nN]
INHERITS 			[iI][nN][hH][eE][rR][iI][tT][sS]
LET 				[lL][eE][tT]
LOOP 				[lL][oO][oO][pP]
POOL 				[pP][oO][oO][lL]
THEN 				[tT][hH][eE][nN]
WHILE 				[wW][hH][iI][lL][eE]
CASE 				[cC][aA][sS][eE]
ESAC 				[eE][sS][aA][cC]
OF 					[oO][fF]
NEW 				[nN][eE][wW]
TRUE 				t[rR][uU][eE]
FALSE 				f[aA][lL][sS][eE]
ISVOID 				[iI][sS][vV][oO][iI][dD]
NOT 				[nN][oO][tT]

%x COMMENT
%x STR

%%

 /*
  *  Nested COMMENTs
  */
 

<INITIAL>"(*"		{ commentNestingLevel++; BEGIN(COMMENT); }
<COMMENT>"(*"	   	{ commentNestingLevel++; }
<COMMENT>NEWLINE    { curr_lineno++;}
<COMMENT>.			{/* eat anything else */}
<COMMENT>"*)"		{
						commentNestingLevel--;
						if (commentNestingLevel == 0)
							BEGIN(0);
						else if (commentNestingLevel < 0) {
							cool_yylval.error_msg = "Unmatched *)";
							return (ERROR);
						}
					}
<COMMENT><<EOF>>  	{
						cool_yylval.error_msg = "EOF in COMMENT";
						BEGIN(0);
						return ERROR;
					}
<INITIAL>"*)"		{
						cool_yylval.error_msg = "Unmatched *)";
						return ERROR;
					}

<INITIAL>--.*		{ /* no-op, COMMENT to EOL */ }


 /*
  *  The multiple-character operators.
  */

{DARROW}   	 		{ return (DARROW); }
{ASSIGN}   			{ return (ASSIGN); }
{LE}				{ return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}   	{ return (CLASS); }
{ELSE}    	{ return (ELSE); }
{FI}    	{ return (FI); }
{IF}    	{ return (IF); }
{IN}    	{ return (IN); }
{INHERITS} 	{ return (INHERITS); }
{ISVOID}	{ return (ISVOID); }
{LET}     	{ return (LET); }
{LOOP}    	{ return (LOOP); }
{POOL}    	{ return (POOL); }
{THEN}   	{ return (THEN); }
{WHILE}   	{ return (WHILE); }
{CASE}    	{ return (CASE); }
{ESAC}    	{ return (ESAC); }
{NEW}     	{ return (NEW); }
{OF}    	{ return (OF); }
{NOT}     	{ return (NOT); }
"+"     	{ return ('+'); }
"-"     	{ return ('-'); }
"*"     	{ return ('*'); }
"="     	{ return ('='); }
"<"     	{ return ('<'); }
"\."   		{ return ('.'); }
"~"     	{ return ('~'); }
","     	{ return (','); }
";"     	{ return (';'); }
":"     	{ return (':'); }
"("     	{ return ('('); }
")"     	{ return (')'); }
"@"     	{ return ('@'); }
"{"     	{ return ('{'); }
"}"     	{ return ('}'); }
{WS}		{}


<INITIAL>{FALSE}	{
                    	cool_yylval.boolean = 0;
                    	return BOOL_CONST;
                	}
<INITIAL>{TRUE}     {
                    	cool_yylval.boolean = 1;
                    	return BOOL_CONST;
                	}

<INITIAL>{NEWLINE} { curr_lineno++; }


<INITIAL>{OBJECT_IDENTIFIER} {
						cool_yylval.symbol = idtable.add_string(yytext, yyleng);
						return (OBJECTID);
      				}
<INITIAL>{TYPE_IDENTIFIER} {
						cool_yylval.symbol = idtable.add_string(yytext, yyleng);
						return (TYPEID);
					}
<INITIAL>{INTEGER}  {
						int parse_int = strtol(yytext, &yytext + yyleng, 30); 
        				cool_yylval.symbol = inttable.add_int(parse_int); 
        				return (INT_CONST);
        			}
<INITIAL>{SELF}		{ 
						return *(yytext); /* too be addressed in later stages. */ 
					}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


<INITIAL>"\"" 		{ string_buf_ptr = string_buf; BEGIN(STR); }
<STR>"\""     		{
      					*string_buf_ptr = '\0';
      					cool_yylval.symbol = stringtable.add_string(string_buf);
      					BEGIN(0);
      					return STR_CONST;
    				}

<STR><<EOF>> 		{
						cool_yylval.error_msg = "EOF in string constant";
						BEGIN(0);
						return ERROR;
					}
<STR>NEWLINE  		{
						curr_lineno++;
						if (!string_error) {
							cool_yylval.error_msg = "Unterminated string constant";
							return(ERROR); 
							}
					}

<STR>				{
  "\\n"   { *string_buf_ptr++ = '\n';}
  "\\t"   { *string_buf_ptr++ = '\t';}
  "\\r"   { *string_buf_ptr++ = '\r';}
  "\\b"   { *string_buf_ptr++ = '\b';}
  "\\f"   { *string_buf_ptr++ = '\f';}
  "\\"    { *string_buf_ptr++ = '\\';  *string_buf_ptr = '\0'; }
  "." 	  { *string_buf_ptr++ = yytext[0]; }
  '\0'	  {	 cool_yylval.error_msg = "String contains escaped null character.";
            return(ERROR);
          }
}


<INITIAL>.		{ 
					cool_yylval.error_msg = yytext;
					return(ERROR); 
				}
%%