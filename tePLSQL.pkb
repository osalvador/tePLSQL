/* Formatted on 08/09/2015 16:32:54 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY teplsql
AS
   g_buffer   CLOB;

   PROCEDURE bind_vars (p_source IN OUT NOCOPY CLOB, p_vars IN t_assoc_array)
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF p_vars.COUNT () <> 0
      THEN
         l_key       := p_vars.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            p_source    := REPLACE (p_source, '${' || l_key || '}', TO_CLOB (p_vars (l_key)));
            l_key       := p_vars.NEXT (l_key);
         END LOOP;
      END IF;
   END bind_vars;

   /*Parse template marks */
   PROCEDURE parse (p_source IN CLOB)
   AS
      l_open_count    PLS_INTEGER;
      l_close_count   PLS_INTEGER;
   BEGIN

    $if dbms_db_version.ver_le_10 $then
       l_open_count :=
         NVL (LENGTH (REGEXP_REPLACE (p_source
                                    , '(<)%|.'
                                    , '\1'
                                    , 1
                                    , 0
                                    , 'n')), 0);

      l_close_count :=
         NVL (LENGTH (REGEXP_REPLACE (p_source
                                    , '(%)>|.'
                                    , '\1'
                                    , 1
                                    , 0
                                    , 'n')), 0); 
     $else
       l_open_count := regexp_count (p_source, '<\%');
       l_close_count := regexp_count (p_source, '\%>');
     $end
      
      

      IF l_open_count <> l_close_count
      THEN
         raise_application_error (-20001
                                ,    '##Parser Exception: '
                                  || 'One or more tags (<% %>) are not closed: '
                                  || l_open_count
                                  || ' <> '
                                  || l_close_count
                                  || CHR (10));
      END IF;
   END parse;

   PROCEDURE PRINT (p_data IN CLOB)
   AS
   BEGIN
      g_buffer    := g_buffer || p_data;
   END PRINT;

   PROCEDURE PRINT (p_data IN VARCHAR2)
   AS
   BEGIN
      g_buffer    := g_buffer || p_data;
   END PRINT;

   PROCEDURE PRINT (p_data IN NUMBER)
   AS
   BEGIN
      g_buffer    := g_buffer || TO_CHAR (p_data);
   END PRINT;

   PROCEDURE p (p_data IN CLOB)
   AS
   BEGIN
      g_buffer    := g_buffer || p_data;
   END p;

   PROCEDURE p (p_data IN VARCHAR2)
   AS
   BEGIN
      g_buffer    := g_buffer || p_data;
   END p;

   PROCEDURE p (p_data IN NUMBER)
   AS
   BEGIN
      g_buffer    := g_buffer || TO_CHAR (p_data);
   END p;

   FUNCTION render (p_template IN CLOB, p_vars IN t_assoc_array)
      RETURN CLOB
   AS
      l_template   CLOB := p_template;
      l_declare    CLOB;
      l_tmp        CLOB;
      i            PLS_INTEGER := 0;
   BEGIN
      --Clear buffer
      g_buffer    := NULL;

      --Bind the variables
      bind_vars (l_template, p_vars);

      --Parse <% %> tags, done once
      parse (l_template);

      --Delete new lines with !\n
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '(!\\n' || CHR (10) || ')'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Merge all declaration blocks into a single block
      LOOP
         i           := i + 1;
         $if dbms_db_version.ver_le_10 $then
         l_tmp       :=
            REPLACE (REPLACE (REGEXP_SUBSTR (l_template
                                           , '<%!([^%>].*?)%>'
                                           , 1
                                           , i
                                           , 'n'), '<%!', ''), '%>', ''); 
         $else
         l_tmp       :=
            REGEXP_SUBSTR (l_template
                         , '<%!([^%>].*?)%>'
                         , 1
                         , i
                         , 'n'
                         , 1);
         $end
         
         l_declare   := l_declare || l_tmp;
         EXIT WHEN LENGTH (l_tmp) = 0;
      END LOOP;

      --Delete declaration blocks from template
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<%!([^%>].*?)%>'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Expresison directive
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<%=([^%>].*?)%>'
                       , ']'');tePLSQL.p(\1);tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');

      --Code blocks directive
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<%([^%>].*?)%>'
                       , ']''); \1 tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');

      --Escaped chars
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '\\\\(.)'
                       , ']'');tePLSQL.p(q''[\1]'');tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');

      l_template  := 'DECLARE ' || l_declare || ' BEGIN tePLSQL.p(q''[' || l_template || ' ]''); END;';

      --DBMS_OUTPUT.put_line (l_template);
     $if dbms_db_version.ver_le_10 $then
     --10g
     DECLARE
         v_upperbound   NUMBER;
         v_cur          INTEGER;
         v_sql          DBMS_SQL.varchar2s;
         v_ret          NUMBER;
      BEGIN
         v_upperbound := CEIL (DBMS_LOB.getlength (l_template) / 256);

         FOR i IN 1 .. v_upperbound
         LOOP
            v_sql (i)   := DBMS_LOB.SUBSTR (l_template, -- clob statement
                                                       256, -- amount
                                                            ( (i - 1) * 256) + 1);
         END LOOP;

         v_cur       := DBMS_SQL.open_cursor;
         -- parse sql statement
         DBMS_SQL.parse (v_cur
                       , v_sql
                       , 1
                       , v_upperbound
                       , FALSE
                       , DBMS_SQL.native);
         -- execute
         v_ret       := DBMS_SQL.execute (v_cur);
      EXCEPTION
         WHEN OTHERS
         THEN
            --Print error
            PRINT ('### tePLSQL Render Error ###');
            PRINT (CHR (10));
            PRINT (SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
            PRINT (CHR (10));
            PRINT ('### Processed template ###');
            PRINT (CHR (10));
            PRINT (l_template);
      END;     
 
     $else
     -- 11g 
      BEGIN
         EXECUTE IMMEDIATE l_template;
      EXCEPTION
         WHEN OTHERS
         THEN
            --Print error
            PRINT ('### tePLSQL Render Error ###');
            PRINT (CHR (10));
            PRINT (SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
            PRINT (CHR (10));
            PRINT ('### Processed template ###');
            PRINT (CHR (10));
            PRINT (l_template);
      END;
      $end

      l_template  := g_buffer;
      g_buffer    := NULL;

      RETURN l_template;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error (-20001, SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
   END render;
END teplsql;
/