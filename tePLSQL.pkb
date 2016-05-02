create or replace PACKAGE BODY teplsql
AS
  /** A TYPE used to define a request for a template  */
  type t_include_parameters is record ( template_name TE_TEMPLATES.NAME%TYPE
                                      , object_name   varchar2(64)
                                      , object_type   varchar2(64)
                                      , schema        varchar2(64) );
                                  
   null_include_parameters t_include_parameters;
   
   -- various system options
   g_max_includes   int := 50;

   -- run time global variables
   g_buffer         CLOB;
   
   /**
   * Decodes the properties of the "<%@ include() %>" directive.
   * 
   * @param   p_str         Input string found between parentheses of an "<%@ include() %>" directive
   * @return                A record type containing the individual components
   */
   FUNCTION decode_include_parameters (p_str IN VARCHAR2)
      RETURN t_include_parameters
   IS
      TYPE array_t IS TABLE OF te_templates.name%TYPE;

      l_string_tt   array_t;
      l_ret         t_include_parameters := null_include_parameters;
   BEGIN
      IF LENGTH (p_str) > 0
      THEN
             SELECT   REGEXP_REPLACE (REGEXP_SUBSTR (p_str
                                                   , '[^,]+'
                                                   , 1
                                                   , LEVEL), '\s', '')
                         text
               BULK   COLLECT
               INTO   l_string_tt
               FROM   DUAL
         CONNECT BY   REGEXP_SUBSTR (p_str
                                   , '[^,]+'
                                   , 1
                                   , LEVEL) IS NOT NULL;

         --populate variables
         IF l_string_tt.EXISTS (1)
         THEN
            l_ret.template_name := l_string_tt (1);
         END IF;

         IF l_string_tt.EXISTS (2)
         THEN
            l_ret.object_name := l_string_tt (2);
         END IF;

         IF l_string_tt.EXISTS (3)
         THEN
            l_ret.object_type := l_string_tt (3);
         END IF;

         IF l_string_tt.EXISTS (4)
         THEN
            l_ret.schema := l_string_tt (4);
         END IF;
      END IF;

      RETURN l_ret;
   END decode_include_parameters;

   PROCEDURE output_clob (p_clob IN CLOB)
   IS
      v_offset       PLS_INTEGER := 1;
      v_new_line     PLS_INTEGER;
      /**
      * Since 10gR2 Oracle increase the limit of DBMS_OUTPUT to 32767
      */
      $if DBMS_DB_VERSION.ver_le_10_1  $then
        v_chunk_size   PLS_INTEGER := 255;
      $else
        v_chunk_size   PLS_INTEGER := 32767;
      $end
   BEGIN
      DBMS_OUTPUT.enable (1000000);

      LOOP
         EXIT WHEN v_offset > DBMS_LOB.getlength (p_clob);

         DBMS_OUTPUT.put (DBMS_LOB.SUBSTR (p_clob, v_chunk_size, v_offset));
         v_offset    := v_offset + v_chunk_size;
      END LOOP;

      -- flush, inserts a new line at the end
      DBMS_OUTPUT.new_line;
   END output_clob;

   /**
   * Receives the template directive key-value data separated by commas
   * and assign this key-values to the associative array
   *
   * @param  p_directive      the key-value data template directive
   * @param  p_vars           the associative array
   */
   PROCEDURE set_template_directive (p_directive IN CLOB, p_vars IN OUT NOCOPY t_assoc_array)
   AS
      l_key         VARCHAR2 (256);
      l_value       VARCHAR2 (256);
      l_directive   VARCHAR2 (32767);
   BEGIN
      l_directive := REGEXP_REPLACE (p_directive, '\s', '');

      FOR c1 IN (    SELECT   REGEXP_REPLACE (REGEXP_SUBSTR (l_directive
                                                           , '[^,]+'
                                                           , 1
                                                           , LEVEL), '\s', '')
                                 text
                       FROM   DUAL
                 CONNECT BY   REGEXP_SUBSTR (l_directive
                                           , '[^,]+'
                                           , 1
                                           , LEVEL) IS NOT NULL)
      LOOP
         l_key       := SUBSTR (c1.text, 1, INSTR (c1.text, '=') - 1);
         l_value     := SUBSTR (c1.text, INSTR (c1.text, '=') + 1);
         p_vars ('template_' || l_key) := l_value;
      END LOOP;
   END set_template_directive;

   /**
   * Retrieves template from TE_TEMPLATES that was defined by the input.
   *  
   * @param   p_inc        Properties used to define which code to extract
   * @return               Returns the code representing the requested template name or EMBPTY_CLO() if not found.
   */
   FUNCTION get_template_by_table (p_inc t_include_parameters)
      RETURN CLOB
   AS
      l_template   CLOB;
   BEGIN
      SELECT   template
        INTO   l_template
        FROM   te_templates
       WHERE   UPPER (name) = UPPER (p_inc.template_name);

      RETURN l_template;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_template  := EMPTY_CLOB ();
   END get_template_by_table;
   
   /**
   * Retrieves code from DB Object defined by the input.
   * 
   * @param   p_inc         Properties used to define which code to extract
   * @return                Returns the code reperesnting the requested template
   */
   FUNCTION get_template_by_obj (p_inc t_include_parameters)
      RETURN CLOB
   IS
      l_result       CLOB;
      l_object_ddl   CLOB;
      l_template     CLOB;
      l_tmp          CLOB;
      i              PLS_INTEGER := 1;
      l_found        PLS_INTEGER := 0;
   BEGIN
      --Search the template in other Oracle Object

      --Get package source DDL
      l_object_ddl :=
         DBMS_METADATA.get_ddl (NVL (UPPER (p_inc.object_type), 'PACKAGE')
                              , UPPER (p_inc.object_name)
                              , UPPER (p_inc.schema));

      --If p_template_name is null get all templates from the object
      --else get only this template.
      IF p_inc.template_name IS NOT NULL
      THEN
         LOOP
            l_tmp       :=
               REGEXP_SUBSTR (l_object_ddl
                            , '<%@ template([^%>].*?)%>'
                            , 1
                            , i
                            , 'n');

            l_found     := INSTR (l_tmp, 'name=' || p_inc.template_name);

            EXIT WHEN LENGTH (l_tmp) = 0 OR l_found <> 0;
            i           := i + 1;
         END LOOP;
      ELSE
         l_found     := 0;
      END IF;

      -- i has the occurrence of the substr where the template is
      l_tmp       := NULL;

      LOOP
         --Get Template from the object
         $IF DBMS_DB_VERSION.ver_le_10
         $THEN
            l_tmp       :=
               REGEXP_REPLACE (REGEXP_REPLACE (REGEXP_SUBSTR (l_object_ddl
                                                            ,    '\$if[[:blank:]]+false[[:blank:]]+\$then'
                                                              || CHR (10)
                                                              || '([^\$end].*?)\$end'
                                                            , 1
                                                            , i
                                                            , 'n')
                                             , '\$if[[:blank:]]+false[[:blank:]]+\$then\s*' || CHR (10)
                                             , ''
                                             , 1
                                             , 1)
                             , '\$end'
                             , ''
                             , 1
                             , INSTR ('$end', 1, -1));
         $ELSE
            l_tmp       :=
               REGEXP_SUBSTR (l_object_ddl
                            , '\$if[[:blank:]]+false[[:blank:]]+\$then\s*' || CHR (10) || '([^\$end].*?)\$end'
                            , 1
                            , i
                            , 'n'
                            , 1);
         $END

         l_template  := l_template || l_tmp;
         EXIT WHEN LENGTH (l_tmp) = 0 OR l_found <> 0;
         i           := i + 1;
      END LOOP;

      RETURN l_template;
   END get_template_by_obj;

   /**
   *  Retrieves the template based on the input.
   *  This code is responsible for deciding where the template is stored.
   *  
   *  @param   p_inc         Properties used to define which code to extract
   *  @return                Returns the code reperesnting the requested template
   */
   FUNCTION get_template (p_inc t_include_parameters)
      RETURN CLOB
   IS
      l_inc        t_include_parameters := null_include_parameters;
      l_template   CLOB;
   BEGIN
      --Force Defaults
      l_inc.template_name := p_inc.template_name;
      l_inc.object_name := NVL (p_inc.object_name, 'TE_TEMPLATES');
      l_inc.object_type := NVL (p_inc.object_type, 'PACKAGE');
      l_inc.schema := p_inc.schema;

      -- Decision tree for deciding which method to use to retrieve the code
      IF l_inc.template_name IS NOT NULL AND l_inc.object_name = 'TE_TEMPLATES'
      THEN
         l_template  := get_template_by_table (l_inc);
      ELSE
         l_template  := get_template_by_obj (l_inc);
      END IF;

      RETURN l_template;
   END get_template;


   /**
   * Receives the name of the object, usually a package,
   * which contains an embedded template and return the template.
   *
   * This has been refactored with "get_template()"
   *
   * @param  p_template_name    the name of the template
   * @param  p_object_name      the name of the object (usually the name of the package)
   * @param  p_object_type      the type of the object (PACKAGE, PROCEDURE, FUNCTION...)
   * @param  p_schema           the schema of the object
   * @return                    the template.
   */
    FUNCTION include (p_template_name   IN VARCHAR2 DEFAULT NULL
                    , p_object_name     IN VARCHAR2 DEFAULT 'TE_TEMPLATES'
                    , p_object_type     IN VARCHAR2 DEFAULT 'PACKAGE'
                    , p_schema          IN VARCHAR2 DEFAULT NULL )
       RETURN CLOB
    AS
       l_result       CLOB;
       l_object_ddl   CLOB;
       l_template     CLOB;
       l_tmp          CLOB;
       i              PLS_INTEGER := 1;
       l_found        PLS_INTEGER := 0;
       l_object_name     VARCHAR2 (64);
       l_template_name   VARCHAR2 (64);
       l_object_type     VARCHAR2 (64);
       l_schema          VARCHAR2 (64);
    BEGIN

        --Force Defaults
        l_template_name := p_template_name;
        l_object_name := NVL(p_object_name,'TE_TEMPLATES');
        l_object_type := NVL(p_object_type,'PACKAGE');
        l_schema := p_schema;

       --Search for the template in the table TE_TEMPLATES
       IF  l_template_name IS NOT NULL
       AND l_object_name = 'TE_TEMPLATES'
       THEN
          BEGIN
              SELECT   template
                INTO   l_template
                FROM   te_templates
               WHERE   UPPER(name) = UPPER (l_template_name);
          EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
            l_template := EMPTY_CLOB();
          END;

           RETURN l_template;

       ELSE
          --Search the template in other Oracle Object

          --Get package source DDL
          l_object_ddl :=
             DBMS_METADATA.get_ddl (NVL (UPPER (l_object_type), 'PACKAGE'), UPPER (l_object_name), UPPER (l_schema));

          --If p_template_name is null get all templates from the object
          --else get only this template.
          IF l_template_name IS NOT NULL
          THEN
             LOOP
                l_tmp       :=
                   REGEXP_SUBSTR (l_object_ddl
                                , '<%@ template([^%>].*?)%>'
                                , 1
                                , i
                                , 'n');

                l_found     := INSTR (l_tmp, 'name=' || l_template_name);

                EXIT WHEN LENGTH (l_tmp) = 0 OR l_found <> 0;
                i           := i + 1;
             END LOOP;
          ELSE
             l_found     := 0;
          END IF;

          -- i has the occurrence of the substr where the template is
          l_tmp       := NULL;

          LOOP
             --Get Template from the object
             $IF DBMS_DB_VERSION.ver_le_10
             $THEN
                l_tmp       :=
                   REGEXP_REPLACE (REGEXP_REPLACE (REGEXP_SUBSTR (l_object_ddl
                                                                , '\$if[[:blank:]]+false[[:blank:]]+\$then' || CHR (10) || '([^\$end].*?)\$end'
                                                                , 1
                                                                , i
                                                                , 'n')
                                                 , '\$if[[:blank:]]+false[[:blank:]]+\$then\s*' || CHR (10)
                                                 , ''
                                                 , 1
                                                 , 1)
                                 , '\$end'
                                 , ''
                                 , 1
                                 , INSTR ('$end', 1, -1));
             $ELSE
                l_tmp       :=
                   REGEXP_SUBSTR (l_object_ddl
                                , '\$if[[:blank:]]+false[[:blank:]]+\$then\s*' || CHR (10) || '([^\$end].*?)\$end'
                                , 1
                                , i
                                , 'n'
                                , 1);
             $END

             l_template  := l_template || l_tmp;
             EXIT WHEN LENGTH (l_tmp) = 0 OR l_found <> 0;
             i           := i + 1;
          END LOOP;

          RETURN l_template;
       END IF;
    END include;

   /**
   * Bind associative array variables in the template
   *
   * @param  p_template      the template
   * @param  p_vars        the associative array
   */
   PROCEDURE bind_vars (p_template IN OUT NOCOPY CLOB, p_vars IN t_assoc_array)
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF p_vars.COUNT () <> 0
      THEN
         l_key       := p_vars.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            p_template    := REPLACE (p_template, '${' || l_key || '}', TO_CLOB (p_vars (l_key)));
            l_key       := p_vars.NEXT (l_key);
         END LOOP;
      END IF;
   END bind_vars;

   /**
   * Parse template marks
   *
   * @param  p_template      the template
   * @param  p_vars        the associative array
   */
   PROCEDURE parse (p_template IN CLOB, p_vars IN t_assoc_array DEFAULT null_assoc_array)
   AS
      l_open_count    PLS_INTEGER;
      l_close_count   PLS_INTEGER;
      l_template_name VARCHAR2(300);
   BEGIN
      $if dbms_db_version.ver_le_10 $then
          /**
          *  ATTENTION, these instructions are very slow and penalize template processing time.
          *  If performance is critical to your system, you should disable the parser only for BD <= 10g
          */
          l_open_count :=
             NVL (LENGTH (REGEXP_REPLACE (p_template
                                        , '(<)%|.'
                                        , '\1'
                                        , 1
                                        , 0
                                        , 'n')), 0);

          l_close_count :=
             NVL (LENGTH (REGEXP_REPLACE (p_template
                                        , '(%)>|.'
                                        , '\1'
                                        , 1
                                        , 0
                                        , 'n')), 0);
      $else
          l_open_count := regexp_count (p_template, '<\%');
          l_close_count := regexp_count (p_template, '\%>');
      $end


      IF l_open_count <> l_close_count
      THEN
         IF p_vars.exists('template_name')
         THEN
           l_template_name := ' ' || p_vars('template_name');
         END IF;

         raise_application_error (-20001
                                ,    '##Parser Exception processing the template'||l_template_name
                                  || '. One or more tags (<% %>) are not closed: '
                                  || l_open_count
                                  || ' <> '
                                  || l_close_count
                                  || CHR (10));
      END IF;
   END parse;

   /**
   * Interprets the received template and convert it into executable plsql
   *
   * @param  p_template    the template
   * @param  p_vars        the associative array
   */
   PROCEDURE interpret (p_template IN OUT NOCOPY CLOB, p_vars IN t_assoc_array DEFAULT null_assoc_array)
   AS
      l_vars       t_assoc_array := p_vars;
      l_declare    CLOB;
      l_tmp        CLOB;
      i            PLS_INTEGER := 0;
   BEGIN
      --Template directive
      $if dbms_db_version.ver_le_10 $then
          l_tmp       :=
             REPLACE (REPLACE (REGEXP_SUBSTR (p_template
                                            , '<%@ template([^%>].*?)\s*%>'
                                            , 1
                                            , 1
                                            , 'n'), '<%@ template', ''), '%>', '');
      $else
          l_tmp       :=
             REGEXP_SUBSTR (p_template
                          , '<%@ template([^%>].*?)\s*%>'
                          , 1
                          , 1
                          , 'n'
                          , 1);
      $end

      --Set template directive variables into var associative array
      set_template_directive (l_tmp, l_vars);

      --Bind the variables into template
      bind_vars (p_template, l_vars);

      --Null all variables not binded
      p_template    := REGEXP_REPLACE (p_template, '\$\{\S*\}', '');

      --Parse <% %> tags
      parse (p_template, l_vars);

      --Dos to Unix
      p_template  :=
         REGEXP_REPLACE (p_template
                       , CHR(13)||CHR(10)
                       , CHR(10)
                       , 1,0,'nm');

      --Delete all template directives
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '<%@ template([^%>].*?)\s*%>[[:blank:]]*\s$?'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Escaped chars except \\n
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '\\\\([^n])'
                       , ']'');tePLSQL.p(q''[\1]'');tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');


      --New lines.
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '(\\\\n)'
                       , CHR (10) --|| ']'');tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');


      --Delete the line breaks for lines ending in %>[blanks]CHR(10)
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '(%>[[:blank:]]*?' || CHR (10) || ')'
                       , '%>'
                       , 1
                       , 0
                       , '');

      --Delete new lines with !\n
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '([[:blank:]]*\!\\n[[:blank:]]*' || CHR (10) || '?[[:blank:]]*)'
                       , ''
                       , 1
                       , 0
                       , 'm');

      -- Delete all blanks before <% in the beginning of each line
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '(^[[:blank:]]*<%)'
                       , '<%'
                       , 1
                       , 0
                       , 'm');

      --Merge all declaration blocks into a single block
      l_tmp       := NULL;

      LOOP
         i           := i + 1;
          $if dbms_db_version.ver_le_10 $then
             l_tmp       :=
                REPLACE (REPLACE (REGEXP_SUBSTR (p_template
                                               , '<%!([^%>].*?)%>'
                                               , 1
                                               , i
                                               , 'n'), '<%!', ''), '%>', '');
         $else
             l_tmp       :=
                REGEXP_SUBSTR (p_template
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
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '<%!([^%>].*?)%>'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Expresison directive
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '<%=([^%>].*?)%>'
                       , ']'');tePLSQL.p(\1);tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');

      --Code blocks directive
      --p_template  :=
      --   REGEXP_REPLACE (p_template
      --                 , '<%([^%>].*?)%>'
      --                 , ']''); \1 tePLSQL.p(q''['
      --                , 1
      --                 , 0
      --                 , 'n');

      p_template  := 'DECLARE ' || l_declare || ' BEGIN tePLSQL.p(q''[' || p_template || ']''); END;';

   END interpret;

   /**
   * Search for include directives, includes and evaluates the specified templates.
   * Nested include are allowed
   *
   * @param  p_template    the template
   * @param  p_vars        the associative array
   */
   PROCEDURE get_includes (p_template IN OUT NOCOPY CLOB, p_vars IN t_assoc_array DEFAULT null_assoc_array )
    AS
       l_tmp             CLOB;
       l_result          CLOB;

       l_str_tmp         VARCHAR2 (64);
       
       l_inc t_include_parameters;

       TYPE array_t IS TABLE OF VARCHAR2 (64);

       l_strig_tt        array_t;
       l_object_name     VARCHAR2 (64);
       l_template_name   VARCHAR2 (64);
       l_object_type     VARCHAR2 (64);
       l_schema          VARCHAR2 (64);

       l_start           PLS_INTEGER := 0;
       l_end             PLS_INTEGER := 0;
       l_number_includes PLS_INTEGER := 0;
    BEGIN
       /*
       --Pseudocode
       while there includes
       do
           find include directive
           extract parameters (decode_include_parameters)
           get include (get_template)
           interpret template
           concatenate result template into p_template
       done
       */
       WHILE REGEXP_INSTR (p_template, '<%@ include\((.*?)\)\s*%>') <> 0
       LOOP
          --Init
          l_str_tmp   := NULL;
          l_object_name := NULL;
          l_template_name := NULL;
          l_object_type := NULL;
          l_schema    := NULL;
          l_tmp       := NULL;
          l_start     := 0;
          l_end       := 0;

          --get include directive
          $if dbms_db_version.ver_le_10 $then
          l_str_tmp   :=
             REGEXP_REPLACE (REGEXP_REPLACE (REGEXP_SUBSTR (p_template
                          , '<%@ include\((.*?)\)\s*%>'
                          , 1
                          , 1
                          , 'n'),'<%@ include\(',''),'\)\s*%>','');

          $else
          l_str_tmp   :=
             REGEXP_SUBSTR (p_template
                          , '<%@ include\((.*?)\)\s*%>'
                          , 1
                          , 1
                          , 'n'
                          , 1);
          $end

          IF LENGTH (l_str_tmp) > 0
          THEN

             --Bind the variables into include() parameters
             bind_vars (l_str_tmp, p_vars);

             -- translate the string
             l_inc := decode_include_parameters(l_str_tmp);
 
             --get included template
             l_tmp       := get_template( l_inc );

             --Interpret the template
             interpret (l_tmp, p_vars);

             l_tmp := ']'');'|| l_tmp ||' tePLSQL.p(q''[';

             --Start and End of the expression
             l_start     :=
                REGEXP_INSTR (p_template
                            , '<%@ include\((.*?)\)\s*%>'
                            , 1
                            , 1
                            , 0
                            , 'n');

             l_end       :=
                REGEXP_INSTR (p_template
                            , '<%@ include\((.*?)\)\s*%>'
                            , 1
                            , 1
                            , 1
                            , 'n');

             --concatenate result template into first template
             IF (NVL (l_start, 0) > 0)
             THEN
                DBMS_LOB.createtemporary (l_result, FALSE, DBMS_LOB.call);

                IF l_start > 1
                THEN
                   DBMS_LOB.COPY (l_result
                                , p_template
                                , l_start - 1
                                , 1
                                , 1);
                END IF;

                IF LENGTH (l_tmp) > 0
                THEN
                   DBMS_LOB.COPY (l_result
                                , l_tmp
                                , DBMS_LOB.getlength (l_tmp)
                                , DBMS_LOB.getlength (l_result) +1
                                , 1);
                END IF;

                --Adding the rest of the source to the result variable
                IF l_end <= DBMS_LOB.getlength (p_template)
                THEN

                DBMS_LOB.COPY (l_result
                             , p_template
                             , DBMS_LOB.getlength (p_template)
                             , DBMS_LOB.getlength (l_result)+1
                             , l_end);

                END IF;
             END IF;

             p_template  := l_result;

             DBMS_LOB.freetemporary (l_result);

          END IF;

          l_number_includes := l_number_includes +1;
          
          IF l_number_includes >= G_MAX_INCLUDES
          THEN
            raise_application_error (-20001, 'Too much include directive in the template, Recursive include?');
          END IF;

       END LOOP;
    END get_includes;

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

   FUNCTION render (p_vars             IN            t_assoc_array DEFAULT null_assoc_array
                  , p_template         IN            CLOB
                  , p_error_template      OUT NOCOPY CLOB)
      RETURN CLOB
   AS
    l_template   CLOB := p_template;
    l_length pls_integer;
   BEGIN
      --Clear buffer
      g_buffer    := NULL;

      --Parse <% %> tags
      --parse (l_template);

      --Get Includes
      get_includes(l_template, p_vars);

      --Interpret the template
      interpret(l_template, p_vars);

      --Code blocks directive
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<%([^%>].*?)%>'
                       , ']''); \1 tePLSQL.p(q''['
                       , 1
                       , 0
                       , 'n');

      --DBMS_OUTPUT.put_line (l_template);

      --Execute the template
      $if dbms_db_version.ver_le_10 $then
          --10g
          DECLARE
             v_upperbound   NUMBER;
             v_cur          INTEGER;
             v_sql          DBMS_SQL.varchar2a;
             v_ret          NUMBER;
          BEGIN
             v_upperbound := CEIL (DBMS_LOB.getlength (l_template) / 32767);

             FOR i IN 1 .. v_upperbound
             LOOP
                v_sql (i)   := DBMS_LOB.SUBSTR (l_template, -- clob statement
                                                  32767, -- amount
                                                  ( (i - 1) * 32767) + 1);
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
          END;

      $else
          -- 11g
          EXECUTE IMMEDIATE l_template;
      $end

      l_template  := g_buffer;
      g_buffer    := NULL;

      RETURN l_template;

   EXCEPTION
     WHEN OTHERS
     THEN
        --Trim buffer
        l_length := DBMS_LOB.getlength (g_buffer);
        IF l_length > 500
        THEN
            l_length := 500;
        END IF;
        g_buffer := DBMS_LOB.SUBSTR (g_buffer, l_length, DBMS_LOB.getlength (g_buffer) - (l_length - 1));

        --Print error
        PRINT ('### tePLSQL Render Error ###');
        PRINT (CHR (10));
        PRINT (SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
        PRINT (CHR (10));
        PRINT ('### Processed template ###');
        PRINT (CHR (10));
        PRINT (l_template);

        p_error_template := g_buffer;
        RAISE;         
   END render;

   FUNCTION render (p_vars IN t_assoc_array DEFAULT null_assoc_array, p_template IN CLOB)
      RETURN CLOB
   AS
      l_error_template      CLOB;
      l_rendered_template   CLOB;
   BEGIN
      l_rendered_template := render (p_vars, p_template, l_error_template);
      RETURN l_rendered_template;
   END render;

   FUNCTION process (p_vars            IN t_assoc_array DEFAULT null_assoc_array
                   , p_template_name   IN VARCHAR2 DEFAULT NULL
                   , p_object_name     IN VARCHAR2 DEFAULT 'TE_TEMPLATES'
                   , p_object_type     IN VARCHAR2 DEFAULT 'PACKAGE'
                   , p_schema          IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB
   AS
      l_result       CLOB;
      l_template     CLOB;
      l_inc          t_include_parameters := null_include_parameters;
   BEGIN
      --Get template
      --l_template := include(p_template_name,p_object_name,p_object_type,p_schema);
      l_inc.template_name := p_template_name;
      l_inc.object_name   := p_object_name;
      l_inc.object_type   := p_object_type;
      l_inc.schema        := p_schema;
      
      l_template := get_template( l_inc );

      -- verify that we found a template
      IF LENGTH (l_template) = 0
      THEN
         IF p_template_name IS NOT NULL
         THEN
            raise_application_error (-20002
                                   , 'Template ' || p_template_name || ' not found in object ' || UPPER (p_object_name));
         ELSE
            raise_application_error (-20002
                                   , 'The object ' || p_object_name || ' not has a template inside the "$if false $then"');
         END IF;
      END IF;

      --Render template
      l_result    := render (p_vars,l_template);
      RETURN l_result;
   END process;
END teplsql;
/
