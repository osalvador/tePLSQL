/* Formatted on 13/07/2015 13:42:05 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY teplsql
AS
   g_buffer   CLOB;
   g_parser   BOOLEAN := FALSE;

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

   FUNCTION render (p_template IN CLOB, p_vars IN t_assoc_array)
      RETURN CLOB
   AS
      l_start        NUMBER;
      l_end          NUMBER;
      l_result       CLOB;
      l_source       CLOB;
      l_dyn_sql      CLOB;
      l_out          CLOB := EMPTY_CLOB;

      ln_cursor      NUMBER;
      ln_result      NUMBER;

      --error control
      v_ind          NUMBER := 1;
      v_error_desc   VARCHAR2 (32000);
   BEGIN
      --init
      l_source    := p_template;
      l_result    := p_template;

      --Bind the variables
      bind_vars (l_source, p_vars);

      --Parse <% %> tags, done once
      IF NOT g_parser
      THEN
         parse (l_source);
         g_parser    := TRUE;
      END IF;

      l_start     := DBMS_LOB.INSTR (l_source, '<%');
      l_end       := DBMS_LOB.INSTR (l_source, '%>');

      IF (NVL (l_start, 0) > 0)
      THEN
         DBMS_LOB.createtemporary (l_result, FALSE, DBMS_LOB.call);

         IF l_start > 1
         THEN
            DBMS_LOB.COPY (l_result
                         , l_source
                         , l_start - 1
                         , 1
                         , 1);
         END IF;

         --Get DynPLSQL in the template         
         l_dyn_sql   := DBMS_LOB.SUBSTR (l_source, (l_end) - (l_start + 3), l_start + 3);

         IF l_dyn_sql IS NOT NULL
         THEN
            -- BEGIN / END
            l_dyn_sql   := 'BEGIN ' || l_dyn_sql || 'END;';

            --Uncomment for DEBUG DynPLSQL
            --DBMS_OUTPUT.put_line ('l_dyn_sql = ' || l_dyn_sql);

            --Exec DynSQL
            ln_cursor   := DBMS_SQL.open_cursor;

            BEGIN
               DBMS_SQL.parse (ln_cursor, l_dyn_sql, DBMS_SQL.native);
               ln_result   := DBMS_SQL.execute (ln_cursor);
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_ind       := DBMS_SQL.last_error_position;
                  v_error_desc := 'Before this sentence [' || SUBSTR (l_dyn_sql, v_ind, 60) || '...] (' || v_ind || ') ';
                  --Print error
                  PRINT ('#tePLSQL Inline Render Error');
                  PRINT (CHR (10));
                  PRINT (SQLERRM);
                  PRINT (CHR (10));
                  PRINT (v_error_desc);
                  PRINT (CHR (10));
                  PRINT (DBMS_XMLGEN.CONVERT (l_dyn_sql, 0));
                  PRINT (CHR (10));
                  PRINT ('##Error BackTrace ');
                  PRINT (DBMS_UTILITY.format_error_backtrace ());
            END;

            DBMS_SQL.close_cursor (ln_cursor);
         END IF;

         --Get and clean buffer
         l_out       := g_buffer;
         g_buffer    := NULL;

         --Only if is not null
         --Append buffer into result
         IF LENGTH (l_out) > 0
         THEN
            DBMS_LOB.COPY (l_result
                         , l_out
                         , DBMS_LOB.getlength (l_out)
                         , DBMS_LOB.getlength (l_result) + 1
                         , 1);
         END IF;

         --Append the rest of template into result
         DBMS_LOB.COPY (l_result
                      , l_source
                      , DBMS_LOB.getlength (l_source)
                      , DBMS_LOB.getlength (l_result) + 1
                      , l_end + 2);
      END IF;

      --Recursive render function,
      IF NVL (DBMS_LOB.INSTR (l_result, '<%'), 0) > 0
      THEN
         RETURN teplsql.render (l_result, p_vars);
      END IF;

      --Bind all variables
      bind_vars (l_result, p_vars);
      --Null all variables not binded
      l_result    := REGEXP_REPLACE (l_result, '\$\{\S*\}', '');

      RETURN l_result;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_ind       := DBMS_SQL.last_error_position;
         v_error_desc :=
            SUBSTR (SQLERRM, 1, 100) || ' before ' || SUBSTR (l_dyn_sql, v_ind, 60) || ' (' || v_ind || ') ';
         raise_application_error (-20001, SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
   END render;
END teplsql;