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