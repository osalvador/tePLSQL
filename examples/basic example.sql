set timing on; 

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
    END LOOP;%>]';

   --Key-value variables. 
   p_vars ('FullName') := 'Oscar Salvador Magallanes';   
   p_vars ('username') := 'SYS';

   p_template  := teplsql.render (p_template,p_vars);

   DBMS_OUTPUT.put_line (p_template);
END;


