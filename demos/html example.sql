set timing on;
set serveroutput on;

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
        <%for i in ${initValue} .. ${lastValue} loop %>
        <%= i %><br>
        <% end loop;%>
        <h1> Print the Odd numbers of sequence </h1>
        <br>    
        <% /*You can insert PLSQL comments as always*/ 
        for i in ${initValue} .. ${lastValue}
        loop 
            if mod(i,2) <> 0 
            then %>
        <%= i %><br>
        <% end if; 
        end loop; %>
      </body>
    </html>]';

   --Key-value variables.
   p_vars ('title') := 'Number sequence';
   p_vars ('initValue') := 5;
   p_vars ('lastValue') := 20;

   p_template  := teplsql.render (p_vars, p_template);

   DBMS_OUTPUT.put_line (p_template);
END;