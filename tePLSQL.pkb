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
      l_open_count := regexp_count (p_source, '<\%');

      l_close_count := regexp_count (p_source, '\%>');

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
      l_chr_tmp    VARCHAR2 (32767);
      i            PLS_INTEGER := 0;
   BEGIN
      --Bind the variables
      bind_vars (l_template, p_vars);

      --Parse <% %> tags, done once
      parse (l_template);

      --Merge all declaration blocks into a single block
      LOOP
         i           := i + 1;

         l_tmp       :=
            REGEXP_SUBSTR (l_template
                         , '<%!([^%>].*?)%>'
                         , 1
                         , i
                         , 'n'
                         , 1);
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
      /*l_template  :=
         REGEXP_REPLACE (l_template
                       , '\\(.)'
                       , ']'');tePLSQL.p(q''[\1]'');tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');*/

      --tePLSQL.print with null or one white space
      --l_template  := REGEXP_REPLACE (l_template, 'tePLSQL.p\(''(\s){0,1}''\);', '');


      l_template  := 'DECLARE ' || l_declare || ' BEGIN tePLSQL.p(q''[' || l_template || ' ]''); END;';

      --DBMS_OUTPUT.put_line (l_template);

      BEGIN
         EXECUTE IMMEDIATE l_template;
      EXCEPTION
         WHEN OTHERS
         THEN
            --Print error
            PRINT ('#tePLSQL Inline Render Error');
            PRINT (CHR (10));
            PRINT (SQLERRM);
            PRINT (CHR (10));
            PRINT (l_template);
            PRINT (CHR (10));
            PRINT ('##Error BackTrace ');
            PRINT (DBMS_UTILITY.format_error_backtrace ());
      END;

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