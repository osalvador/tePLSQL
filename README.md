# tePLSQL
Template Engine for PLSQL.

tePLSQL is a template engine written completly in PLSQL, generate text output (HTML web pages, e-mails, configuration files, source code, etc.) based on templates. Templates are written with embebed Dynamic PLSQL . 

With tePLSQL you should prepare the data to display in your PLSQL packages and do business calculations, and then the template displays that already prepared data. In the template you are focusing on how to present the data, and outside the template you are focusing on what data to present.

Now tePLSQL has the same syntax as the old fashion [Oracle PSP](http://docs.oracle.com/cd/E11882_01/appdev.112/e41502/adfns_psp.htm#ADFNS016) so you do not have to learn any new template language and your PSP will be supported by tePLSQL making some small modifications.

Templates are processed and a single block of PLSQPL code being executed dynamically, as does the Oracle PSP loader.  

The next table list tePLSQL elements that you can use in your templates. 

_**tePLSQPL Elements**_


|Element | Name | Description
|--------|------|------------- 
|`${varName}` | External variable | The variables are defined in a key-value associative array that receives as parameter by the render
|`<%! ... %>` | Declaration block | The declaration for a set of PL/SQL variables that are visible throughout the page, not just within the next BEGIN/END block.
|`<% ... %>` | Code block |A set of PL/SQL statements to be executed when the template is run.
|`<%= ... %>` | Expression block | A single PL/SQL expression
|`\\char` | Escaped character | Escaping reserved words like `<% .. %>` and `q'[]'`
| `!\n` | No new line | This element at the end of a line indicates that a new line is not included in the processed template

The variables are defined in a key-value associative array that receives as parameter by the render. Within the templates reference to ahce variables via `${varName}`.

tePSLQL was created when I noticed that there was no separation between business logic and views in my developments. Furthermore it is very useful in code generators template-based, such as Table APIs.

## Getting started

### Install
Download and compile TEPLSQL.pks and TEPLSQL.pkb. No schema grants are necesary.

### Usage

#### Basic Example
With Text template.
```plsql
    DECLARE
       p_template   VARCHAR2 (32000);
       p_vars       teplsql.t_assoc_array;
    BEGIN
       p_template  :=q'[
       <%/* Using variables */%>!\n
       Hi ${FullName}!
              
       <%/* Using expressions */%>!\n
       Today <%= TO_CHAR(SYSDATE, 'DD-MM-YYYY') %> is a great day!
       
       <% --Using external variable in the query loop
       FOR c1 IN (SELECT username FROM all_users WHERE username = UPPER('${username}'))
       LOOP %>!\n
       Username: <%= c1.username %>
       <% END LOOP; %>!\n
       
       <%/* Escaping chars */%>!\n
       This is the tePLSQL code block syntax <\\% ... %\\>
       
       <%/* Regards */%>!\n
       Bye <%=UPPER('${username}')%>.
       ]';

       --Key-value variables.
       p_vars ('FullName') := 'Oscar Salvador Magallanes';
       p_vars ('username') := 'sys';

       p_template  := teplsql.render (p_template, p_vars);

       DBMS_OUTPUT.put_line (p_template);
    END;
```

Result: 

```
    Hi Oscar Salvador Magallanes!
    
    Today 08-09-2015 is a great day!
    
    Username: SYS
    
    This is the tePLSQL code block syntax <% ... %>
    
    Bye SYS.

    PL/SQL procedure successfully completed.
    Elapsed: 00:00:00.02
```


#### HTML Example

```plsql
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
      <%for i in ${initValue} .. ${lastValue}
        loop %>
            <%= i %> <br>        
        <% end loop;%>
      <h1> Print the Odd numbers of sequence </h1>
      <br>    
       <% /*You can insert PLSQL comments as always*/ 
        for i in ${initValue} .. ${lastValue}
        loop
            if mod(i,2) <> 0 
            then %>
            <%= i %> <br>
         <% end if;        
        end loop; %>
      </body>
    </html>]';

       --Key-value variables.
       p_vars ('title') := 'Number sequence';
       p_vars ('initValue') := 5;
       p_vars ('lastValue') := 20;

       p_template  := teplsql.render (p_template, p_vars);

       DBMS_OUTPUT.put_line (p_template);
    END;
```

Result: 
```html
    <!DOCTYPE html>
    <html>
      <head>
        <title>Number sequence</title>
      </head>
      <body>
      <h1> Print Sequence numbers </h1>
      <br>
      5 <br>        
        6 <br>        
        7 <br>        
        8 <br>        
        9 <br>        
        10 <br>        
        11 <br>        
        12 <br>        
        13 <br>        
        14 <br>        
        15 <br>        
        16 <br>        
        17 <br>        
        18 <br>        
        19 <br>        
        20 <br>        
        
      <h1> Print the Odd numbers of sequence </h1>
      <br>    
       5 <br>
         7 <br>
         9 <br>
         11 <br>
         13 <br>
         15 <br>
         17 <br>
         19 <br>
         
      </body>
    </html>  
    PL/SQL procedure successfully completed.
    Elapsed: 00:00:00.02
```


#### Declaration and instructions

```plsql
    DECLARE
       p_template   CLOB;
       p_vars       teplsql.t_assoc_array;
    BEGIN
       p_template  := 
       q'[<%! lang_name VARCHAR2(10) := 'PL/SQL';
           l_random_number pls_integer := ROUND(DBMS_RANDOM.VALUE (1, 9));
          %> 
            The 'sequence' is used in scripting language: <%=lang_name %>
            
            The result of the operation ${someInValue} * <%= l_random_number %> is <%= ${someInValue} * l_random_number %>
        ]';

       --Key-value variables.   
       p_vars ('someInValue') := 5;   

       p_template  := teplsql.render (p_template, p_vars);

       DBMS_OUTPUT.put_line (p_template);
    END;
```

Result:

        The 'sequence' is used in scripting language: PL/SQL
        
        The result of the operation 5 * 7 is 35

## Contributing

If you have ideas, get in touch directly.

Please inser at the bottom of your commit message the following line using your name and e-mail address .

    Signed-off-by: Your Name <you@example.org>

This can be automatically added to pull requests by committing with:

    git commit --signoff

## License
Copyright 2015 Oscar Salvador Magallanes 

tePLSQL is under MIT license. 
