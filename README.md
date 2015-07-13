# tePLSQL
Template Engine for PLSQL. 

tePLSQL is a template engine written completly in PLSQL, generate text output (HTML web pages, e-mails, configuration files, source code, etc.) based on templates. Templates are written with embebed Dynamic PLSQL . 

With tePLSQL you should prepare the data to display in your PLSQL packages and do business calculations, and then the template displays that already prepared data. In the template you are focusing on how to present the data, and outside the template you are focusing on what data to present.

tePLSQL is very simple, is encoded in less than 200 lines. Its operation is equally simple, but effective. The variables are linked to the template using a simple substitution, whereas the PLSQL embedded code is executed and its result is stored in a buffer, which is concatenated to the template once the PLSQL block is complete.

Therefore, templates include two types of directives:
- Variable directives
- Code directives

The variables are defined in a key-value associative array that receives as parameter by the render. Within the templates reference to ahce variables via `${varName}`.

Code directives embedded PLSQL within the template. Therefore we can use any language instruction as well as packages, query tables and others. Code directive must be contained between the marks `<% %>`.

tePSLQL was created when I noticed that there was no separation between business logic and views in my developments. Furthermore it is very useful in code generators template-based, such as Table APIs.

## Getting started

### Install
Download and compile TEPLSQL.pks and TEPLSQL.pkb. No schema grants are necesary.

### Usage

#### Basic Example
With Text template.

    DECLARE
       p_template   VARCHAR2(32000);
       p_vars       teplsql.t_assoc_array;
    BEGIN
       p_template    :=q'[Hi ${FullName}!
    Today <% tePLSQL.print(to_char(sysdate, 'DD-MM-YYYY')); %> is a great day!
    <% 
        --Using variable in the query 
        FOR c1 IN (SELECT username FROM all_users WHERE username = '${username}')
        LOOP
            tePLSQL.print('Username: ' || c1.username || CHR(10));
        END LOOP;
       %> ]';

       --Key-value variables. 
       p_vars ('FullName') := 'Oscar Salvador Magallanes';   
       p_vars ('username') := 'SYS';

       p_template  := teplsql.render (p_template,p_vars);

       DBMS_OUTPUT.put_line (p_template);
    END;
    
    Hi Oscar Salvador Magallanes!
    Today 13-07-2015 is a great day!
    Username: SYS

    PL/SQL procedure successfully completed.
    Elapsed: 00:00:00.02


#### HTML Example
set timing on;

    DECLARE
       p_template   CLOB;
       p_vars       teplsql.t_assoc_array;
    BEGIN
       p_template  :=
          q'[<!DOCTYPE html>
    <html>
      <head>
        <title>${title}</title>
      </head>
      <body>
      <h1> Print Sequence numbers </h1>
      <br>
      <%
        for i in ${initValue} .. ${lastValue}
        loop
            tePLSQL.print(i);
            tePLSQL.print('<br>');        
        end loop;    
      %>    
      <h1> Print the Odd numbers of sequence </h1>
      <br>    
       <% 
        /*Yoy can insert PLSQL comments as always*/ 
        for i in ${initValue} .. ${lastValue}
        loop
            if mod(i,2) <> 0 
            then
                tePLSQL.print(i);
                tePLSQL.print('<br>');
            end if;        
        end loop;
       %>
      </body>
    </html>]';

       --Key-value variables.
       p_vars ('title') := 'Number sequence';
       p_vars ('initValue') := 5;
       p_vars ('lastValue') := 20;

       p_template  := teplsql.render (p_template, p_vars);

       DBMS_OUTPUT.put_line (p_template);
    END;

    <!DOCTYPE html>
    <html>
      <head>
        <title>Number sequence</title>
      </head>
      <body>
      <h1> Print Sequence numbers </h1>
      <br>
      5<br>6<br>7<br>8<br>9<br>10<br>11<br>12<br>13<br>14<br>15<br>16<br>17<br>18<br>19<br>20<br>
        
      <h1> Print the Odd numbers of sequence </h1>
      <br>    
       5<br>7<br>9<br>11<br>13<br>15<br>17<br>19<br>
      </body>
    </html>
    PL/SQL procedure successfully completed.
    Elapsed: 00:00:00.02


## Contributing

If you have ideas, get in touch directly.

Please inser at the bottom of your commit message the following line using your name and e-mail address .

    Signed-off-by: Your Name <you@example.org>

This can be automatically added to pull requests by committing with:

    git commit --signoff

## License
Copyright 2015 Oscar Salvador Magallanes 

tePLSQL is under MIT license. 
