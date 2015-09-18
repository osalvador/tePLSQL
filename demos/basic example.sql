set timing on; 
set serveroutput on;

DECLARE
   p_template   VARCHAR2 (32000);
   p_vars       teplsql.t_assoc_array;
BEGIN
   p_template  :=
      q'[<%/* Using variables */%>
       Hi ${FullName}!

       <%/* Using expressions */%>
       Today <%= TO_CHAR(SYSDATE, 'DD-MM-YYYY') %> is a great day!
              
       <% --Using external variable in the query loop
          for c1 in (select username, user_id from all_users where username = upper('${username}')) loop %>          
       Username: <%= c1.username %>, ID:<%= c1.user_id %>.
       <% end loop; %>       
       
       <%/* Escaping chars */%>       
       This is the tePLSQL code block syntax <\\% ... %\\>
              
       <%/* Regards */%>
       Bye <%=UPPER('${username}')%>.]';

   --Key-value variables.
   p_vars ('FullName') := 'Oscar Salvador Magallanes';
   p_vars ('username') := 'test';

   p_template  := teplsql.render (p_vars, p_template);

   DBMS_OUTPUT.put_line (p_template);
END;
