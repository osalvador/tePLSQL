create or replace PACKAGE BODY teplsql
AS
  /** A TYPE used to define a request for a template  */
  type t_include_parameters is record ( template_name TE_TEMPLATES.NAME%TYPE
                                      , object_name   varchar2(64)
                                      , object_type   varchar2(64)
                                      , schema        varchar2(64)
                                      , indent        int );

   null_include_parameters t_include_parameters;

   -- various system default values
   g_max_includes_default        constant int := 50;
   g_globbing_mode_default       constant t_template_variable_value := g_globbing_mode_off;
   g_globbing_separator_default  constant t_template_variable_value := chr(10);
   g_render_mode_default         constant t_template_variable_value := g_render_mode_normal;
   g_indent_string_default       constant t_template_variable_value := '    ';

   -- various system options
   g_max_includes        int := g_max_includes_default;
   g_globbing_mode       t_template_variable_value := g_globbing_mode_default;
   g_globbing_separator  t_template_variable_value := g_globbing_separator_default;
   g_render_mode         t_template_variable_value := g_render_mode_default;
   g_indent_string       t_template_variable_value := g_indent_string_default;

   -- run time global variables
   g_buffer          CLOB;
   g_indention_level int := 1;
   g_max_indention_level constant int := 20;
   
   type t_indentable_clob is varray(20) of clob;
   g_buffer2     t_indentable_clob := new t_indentable_clob();
   
   only_hierarch_tags_complete exception;
   only_fetch_complete         exception;

   /**
   * Resets all of the system options to default values
   *
   * @param   p_vars       This is the Associative Array that contains system options
   */
   procedure reset_system_defaults
   as
   begin
      g_max_includes        := g_max_includes_default;
      g_globbing_mode       := g_globbing_mode_default;
      g_globbing_separator  := g_globbing_separator_default;
      g_render_mode         := g_render_mode_default;
      g_indent_string       := g_indent_string_default;
   end reset_system_defaults;

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

         IF l_string_tt.EXISTS (5)
         THEN
            l_ret.indent := l_string_tt (5);
         END IF;
      END IF;

      RETURN l_ret;
   END decode_include_parameters;

   /**
   * Process all parameters that adjust the tePLSQL engine
   * 
   * @param   p_vars         the template's arguments and engine properties.
   */
   PROCEDURE process_engine_parameters( p_vars IN t_assoc_array DEFAULT null_assoc_array)
   IS
      l_key   t_template_variable_name;
      l_value t_template_variable_value;

      invalid_parameter_value EXCEPTION;
   BEGIN
      l_key := p_vars.first;
      WHILE( l_key is not null )
      LOOP
         l_value := p_vars(l_key);

         CASE l_key
            WHEN g_set_max_includes THEN
               -- test that the value is a number and the number is >= 1
               IF NOT regexp_like( l_value, '^[[:digit:]]+$')
               THEN
                 raise invalid_parameter_value;
               END IF;

               g_max_includes := to_number( l_value );

               IF g_max_includes < 1 or g_max_includes IS NULL
               THEN
                  raise invalid_parameter_value;
               END IF;
            WHEN g_set_globbing_separator THEN
               g_globbing_separator := l_value;
            WHEN g_set_globbing_mode THEN
               -- assert the value is valid
               IF l_value not in (g_globbing_mode_off, g_globbing_mode_on, g_globbing_mode_regexp,g_globbing_mode_like)
               THEN
                  raise invalid_parameter_value;
               END IF;

               g_globbing_mode := l_value;
             WHEN g_set_render_mode THEN
                IF l_value in ( g_render_mode_hierarch_tags_only, g_render_mode_fetch_only )
                THEN
                    g_render_mode := l_value;
                ELSE
                    g_render_mode := g_render_mode_default;
                end if;
              WHEN g_set_indention_string THEN
                g_indent_string := l_value;
            ELSE
               NULL;
         END CASE;

         l_key := p_vars.next( l_key );
      END LOOP;
   EXCEPTION
      WHEN invalid_parameter_value THEN
         raise_application_error( -20010, 'Parameter "' || l_key || '" has an invalid value of "' || l_value || '"');
   END process_engine_parameters;

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
      l_regexp     varchar2(32767);
   BEGIN
      CASE g_globbing_mode
         WHEN g_globbing_mode_off THEN
            SELECT   t.template
              INTO   l_template
            FROM   te_templates t
            WHERE   UPPER (t.name) = UPPER (p_inc.template_name);
         WHEN g_globbing_mode_like THEN
            FOR curr IN (
               SELECT   t.template
                 INTO   l_template
               FROM   te_templates t
               WHERE   UPPER (t.name) like UPPER (p_inc.template_name)
               ORDER BY t.name
              )
           LOOP
              IF l_template IS NULL
              THEN
                 l_template := curr.template;
              ELSE
                 l_template  := l_template || g_globbing_separator || curr.template;
              END IF;
           END LOOP;
         WHEN g_globbing_mode_regexp THEN
            FOR curr IN (
               SELECT   t.template
                 INTO   l_template
               FROM   te_templates t
               WHERE   regexp_like(t.name, p_inc.template_name)
               ORDER BY t.name
              )
           LOOP
              IF l_template IS NULL
              THEN
                 l_template := curr.template;
              ELSE
                 l_template  := l_template || g_globbing_separator || curr.template;
              END IF;
           END LOOP;
         WHEN g_globbing_mode_on THEN
            l_regexp := regexp_replace( p_inc.template_name, '([.(){}\])', '\\\1');
            l_regexp := '^' || regexp_replace( l_regexp, '\*', '[^.]+' ) || '$';

            FOR curr IN (
               SELECT   t.template
                 INTO   l_template
               FROM   te_templates t
               WHERE   regexp_like(t.name, l_regexp)
               ORDER BY t.name
              )
           LOOP
              IF l_template IS NULL
              THEN
                 l_template := curr.template;
              ELSE
                 l_template  := l_template || g_globbing_separator || curr.template;
              END IF;
           END LOOP;
         ELSE
           raise no_data_found;
      END CASE;

      IF l_template IS NULL
      THEN
        raise no_data_found;
      END IF;

      RETURN l_template;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_template  := EMPTY_CLOB ();
         RETURN l_template;
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

    /*
     * merges template into TE_TEMPLATES or a GTT/PTT
     */
    procedure set_template( name         in te_templates.name%type
                            ,template    in te_templates.template%type
                            ,description in te_templates.description%type default null
                            ,use_gtt     in varchar2                      default null )
    as
    begin
        case use_gtt
            when 'GTT' then
                raise no_data_found;
            when 'PTT' then
                raise no_data_found;
            else
                merge into te_templates a
                using (select set_template.template   as template
                            ,set_template.name        as name
                            ,set_template.description as description
                        from dual) b
                on (a.name = b.name)
                when matched then update
                    set a.template=b.template, a.description = nvl(b.description,a.description)
                when not matched then insert ( name, template )
                    values (b.name, b.template);
         end case;
    end set_template;
            

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
      l_pkey  VARCHAR2 (256);
      l_value te_templates.name%type;
      l_render_all_tags boolean := true;
      
      procedure replace_vars( i_key in varchar2, i_value in varchar2 )
      as
      begin
        p_template := REPLACE (p_template, '${' || i_key || '}', TO_CLOB ( i_value ));
      end;
   BEGIN
      if g_render_mode = g_render_mode_fetch_only
      then
        raise only_fetch_complete;
      end if;

      IF p_vars.COUNT () <> 0
      THEN
         l_key       := p_vars.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;

            case
                when l_key in ( 'object_name', 'name' ) then
                    -- always replace certian vars
                    replace_vars( l_key, p_vars( l_key ) );
                when l_key = 'this' then
                    -- special handling of ${this} and ${super} vars
                    replace_vars( l_key, p_vars(l_key) );

                    -- render up to 10 parents deep
                    l_value := p_vars( 'this' );
                    l_pkey  := 'super';
                    for i in 1 .. 10
                    loop
                        l_value    := rtrim( regexp_substr( l_value, '^.+\.' ), '.' );
                        replace_vars( l_pkey, l_value );
                        l_pkey := l_pkey || '.super';
                    end loop;
                when g_render_mode not in ( g_render_mode_hierarch_tags_only )
                then
                    -- replace other vars based on G_RENDER_MODE
                    replace_vars( l_key, p_vars( l_key ) );
                else
                    null;
            end case;
            
            l_key       := p_vars.NEXT (l_key);
         END LOOP;
      END IF;
      
      if g_render_mode in ( g_render_mode_hierarch_tags_only )
      then
        raise only_hierarch_tags_complete;
      end if;
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
      
      if g_render_mode = g_render_mode_fetch_only
      then
          --Delete all template directives
          p_template  :=
             REGEXP_REPLACE (p_template
                           , '<%@ template([^%>].*?)\s*%>[[:blank:]]*\s$?'
                           , ''
                           , 1
                           , 0
                           , 'n');

        raise only_fetch_complete;
      end if;

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

       l_str_tmp         VARCHAR2 (32767);

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

             l_tmp := ']'');'
                    || case when l_inc.indent > 0 then chr(10) || 'teplsql.begin_indent;' || chr(10) end
                    ||  l_tmp 
                    || case when l_inc.indent > 0 then chr(10) || 'teplsql.end_indent;' || chr(10) end
                    ||' tePLSQL.p(q''[';

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
    
   procedure begin_indent( n in int default null )
   as
   begin
      g_indention_level := g_indention_level + 1;
      if g_indention_level > g_max_indention_level
      then
        raise_application_error( -20005, 'To many indentions' );
      end if;

      g_buffer2.extend;

   end begin_indent;
   
   procedure end_indent
   as
   begin
        -- indent buffer results
        g_buffer2( g_indention_level ) :=
            regexp_replace( g_buffer2( g_indention_level ) , '^'
                            ,g_indent_string, 1, 0, 'm' );

        -- indention level decrement
        g_indention_level := greatest( g_indention_level - 1, 1);
        
        -- append the upper indetion results to the lower one
        g_buffer2( g_indention_level ) := g_buffer2( g_indention_level ) || g_buffer2( g_indention_level + 1 );
        g_buffer2( g_indention_level + 1 ) := null; -- and set the upper one to NULL
        g_buffer2.trim;
   end end_indent;
   PROCEDURE PRINT (p_data IN CLOB)
   AS
   BEGIN
      p(p_data);
--      g_buffer    := g_buffer || p_data;
   END PRINT;

   PROCEDURE PRINT (p_data IN VARCHAR2)
   AS
   BEGIN
      p(p_data);
--      g_buffer    := g_buffer || p_data;
   END PRINT;

   PROCEDURE PRINT (p_data IN NUMBER)
   AS
   BEGIN
      p(p_data);
--      g_buffer    := g_buffer || TO_CHAR (p_data);
   END PRINT;

   PROCEDURE p (p_data IN CLOB)
   AS
   BEGIN
      if g_buffer2.count < 1
      then
        g_buffer2.extend;
      end if;
      
      g_buffer    := g_buffer || p_data;
      g_buffer2( g_indention_level )  := g_buffer2( g_indention_level ) || p_data;
   END p;

   PROCEDURE p (p_data IN VARCHAR2)
   AS
   BEGIN
      if g_buffer2.count < 1
      then
        g_buffer2.extend;
      end if;
      
      g_buffer    := g_buffer || p_data;
      g_buffer2( g_indention_level )  := g_buffer2( g_indention_level ) || p_data;
   END p;

   PROCEDURE p (p_data IN NUMBER)
   AS
   BEGIN
      if g_buffer2.count < 1
      then
        g_buffer2.extend;
      end if;
      
      g_buffer    := g_buffer || TO_CHAR (p_data);
      g_buffer2( g_indention_level )  := g_buffer2( g_indention_level ) || TO_CHAR (p_data);
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

      --Set engine properties
      reset_system_defaults;
      process_engine_parameters(p_vars);
      
      --Parse <% %> tags
      --parse (l_template);

      --Get Includes
      IF g_render_mode in ( g_render_mode_normal )
      THEN
        get_includes(l_template, p_vars);
      END IF;

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
      l_template  := g_buffer2(1);
      g_buffer    := NULL;

      RETURN l_template;

   EXCEPTION
     when only_fetch_complete then
        return l_template;
     when only_hierarch_tags_complete then
        return l_template;
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
   EXCEPTION
     when only_fetch_complete then
        return l_template;
   END process;

    function copy_helper_template( to_base_name in varchar2
                                  ,from_base_name in varchar2
                                  ,object_type in varchar2
                                  ,object_name in varchar2
                                  ,use_gtt in varchar2 default null )
                            return varchar2
    as
    
      l_vars            teplsql.t_assoc_array;
      
      l_template        CLOB;
    begin
        -- to be corrected by #43
--        select a.object_type_id
--            into copy_helper_template.object_type_id
--        from te_skeleton_objects a
--        where a.skeleton_class = copy_helper_template.helper_class
--          and a.object_type  = copy_helper_template.object_type;
        
        -- fetch a BLOCK render hiearchal tags only
        l_vars('this')        := to_base_name || '.' || object_type || '.' || object_name;
        l_vars('object_name') := object_name;
        
        l_vars( g_set_render_mode ) := g_render_mode_hierarch_tags_only;

        -- clear buffers    
        l_template := NULL;
    
       -- loop matching templates (to be fixed by #43)
        for curr in (   select a.name template_name
                            ,a.description
                            ,ltrim(regexp_substr( a.name, '\.[^.]+$' ),'.') fragment_name
                        from te_templates a
                        where regexp_like( a.name, '^' || nvl(from_base_name, 'teplsql.skeleton.default' )
                                        || '\.' || object_type || '\.[^.]+$' )
                    )
        loop
            l_template := process(p_vars =>  l_vars, p_template_name => curr.template_name );
            
            set_template( l_vars('this') || '.' || curr.fragment_name
                        ,l_template, curr.description, use_gtt );
        end loop;
    
        return l_vars('this');

  END copy_helper_template;

    function build_code_from_xml( xml_build in xmltype, to_base_name in varchar2, use_gtt in varchar2 default null ) return varchar2
    as
        object_name      varchar2(500);
        this_object_name varchar2(500);
        clob_buff        clob;
        
        p_vars teplsql.t_assoc_array;
        result_clob clob;
        err_clob   clob;
    begin
        g_buffer2   := new t_indentable_clob();

        /*
            1. loop over XML objects
               2. object_name := copy skeleton
               3. loop <blocks/block>
                  4. get new template <block>
                  5. replace tags
                  6. merge template with that in table
               7. last_child := build_code_from_xml( 'subObjects' )
            8. return last object_name
        */
        -- parse XML
        <<step1>>
        for curr in (
                    with parse_xml as (
                        select b.object_type, b.base_name, b.object_name, b.modifications, b.children
                        from xmltable( '/extends'
                            passing xml_build
                            columns
                                object_type     varchar2(500) path '/extends/@object_type'
                                ,base_name   varchar2(500) path '/extends/@base_name'
                                ,object_name    varchar2(500) path '/extends/@object_name'
                                ,modifications  xmltype       path '/extends/block'
                                ,children        xmltype       path '/extends/extends'
                            ) b
                    )
                    select *
                    from parse_xml
                )
        loop
            -- STEP 2
            this_object_name := copy_helper_template( to_base_name
                                  ,nvl( curr.base_name, 'teplsql.helper.default' )
                                  ,curr.object_type
                                  ,coalesce(curr.object_name, 'rng$' || dbms_random.string( 'X', '12' ) )
                                  ,use_gtt );
    
            <<step3>>
            for mcur in ( select * 
                         from xmltable( '/block'
                                    passing curr.modifications
                                    columns
                                        fragment_name varchar2(50) path '/block/@fragment_name',
                                        fragment_code clob         path '/block'
                                ) b
                            )
            loop
    
                -- STEP 4 - get new template
                clob_buff := mcur.fragment_code;
    
                -- STEP 5 - render TAGS
                p_vars( g_set_render_mode ) := g_render_mode_hierarch_tags_only;
                p_vars( 'this' ) := this_object_name;
                
                result_clob := render( p_vars, clob_buff, err_clob );
                
                -- STEP 6
                set_template( this_object_name || '.' || mcur.fragment_name, result_clob );
    
            end loop;
            
            object_name := build_code_from_xml( curr.children, this_object_name );
        end loop;
        
        return this_object_name;
    end build_code_from_xml;

    function convert_blocks( p_clob in clob ) return clob
    as
        block_tag_clob clob;
        block_att_clob clob;
        block_txt_clob clob;
        block_final_clob clob;
        
        first_extends_pos int;
        last_extends_pos  int;
        cnt_extends       int;
        extends_clob      clob;
        
        first_block_pos   int;
        last_block_pos    int;
        cnt_blocks        int;
        
        anti_infinite_loop int := 0;
    begin
        if not regexp_like(p_clob, '<%@ *block[^>]*%>(.*?)<%@ *enblock *%>','n')
        then
            return p_clob;
        end if;
        
        -- preserve the <extends> block of text
        cnt_extends       := regexp_count(p_clob, '<extends[^>]*>',1,'n');
        if cnt_extends > 0
        then
            first_extends_pos := regexp_instr(p_clob, '<extends[^>]*>',1,1,0 ,'n');
            last_extends_pos  := regexp_instr(p_clob, '</extends>',1,cnt_extends,1 ,'n');
            extends_clob := substr( p_clob, first_extends_pos, last_extends_pos - first_extends_pos );
        else
            extends_clob := null;
        end if;
        
        -- extract out <block> tags
        cnt_blocks   := regexp_count(p_clob, '<%@ *block[^>]*%>',1,'n');
        if cnt_blocks > 0
        then
            first_block_pos := regexp_instr( p_clob, '<%@ *block[^>]*%>',1,1,1,'n');
            last_block_pos := regexp_instr( p_clob, '<%@ *enblock *%>',1,cnt_blocks,0,'n');
            block_final_clob := substr( p_clob, first_block_pos, last_block_pos - first_block_pos );
        else
            block_final_clob := null;
        end if;
        
        block_final_clob := p_clob;
        
        -- LOOP over all <block> tags
        while ( regexp_like( block_final_clob,'<%@ *block([^>]*)%>(.*?)<%@ *enblock *%>','n')
                and anti_infinite_loop <= 25 )
        loop
            anti_infinite_loop := anti_infinite_loop + 1;
            -- find <block> of text
            block_tag_clob     := regexp_substr( block_final_clob,'<%@ *block([^>]*)%>(.*?)<%@ *enblock *%>',1,1,'n');
            block_att_clob     := regexp_replace( block_tag_clob,'<%@ *block([^>]*)%>(.*)<%@ *enblock ?%>', '\1',1,1,'n');
            
            -- convert text to XML
            select xmlelement("block", regexp_replace( block_tag_clob,'<%@ *block([^>]*)%>(.*)<%@ *enblock *%>', '\2',1,1,'n') ).getclobval()
                into block_txt_clob
            from dual;
            
            -- add attributes back to XML tag
            block_tag_clob := regexp_replace( block_txt_clob, '^<block>', '<block' || block_att_clob || '>' );
            
            -- replace text
            block_final_clob :=  regexp_replace( block_final_clob,'<%@ *block([^>]*)%>(.*?)<%@ *enblock *%>', block_tag_clob, 1,1,'n');
        end loop;
        
        return  block_final_clob || extends_clob;
        
    end convert_blocks;

    function convert_extends( p_clob in clob ) return clob
    as
        l_clob       clob;
        c_clob clob;
        
        extends_clob clob;
        extends_att  clob;

        start_txt_pos int;
        end_txt_pos   int;
        start_tag_pos int;
        end_tag_pos   int;
        cnt           int;
        
        anti_infinite_loop int := 1;
    begin
        l_clob := p_clob;
        
        while( anti_infinite_loop < 100 and regexp_like(l_clob, '<%@ *extends([^>]*?)%>.*<%@ *enextends *%>','n' ) )
        loop
            anti_infinite_loop := anti_infinite_loop + 1;
            if regexp_like(l_clob, '<%@ *extends([^>]*?)%>.*<%@ *enextends *%>','n' )
            then
                cnt            := regexp_count(l_clob, '<%@ *?extends([^>]*?)%>',1,'n');
                -- dbms_output.put_line( anti_infinite_loop || ' =>  ' || regexp_substr( p_clob, '<%@ *extends([^>]*?)%>', 1, cnt, 'n' ) );
    
                start_txt_pos  := regexp_instr(l_clob, '<%@ *extends([^>]*?)%>',1,cnt,1 ,'n'); -- grab last <extends>
                end_txt_pos    := regexp_instr(l_clob, '<%@ *enextends *%>',start_txt_pos,1,0,'n'); -- grab first </extends> (after last <extends>)
    
                start_tag_pos  := regexp_instr(l_clob, '<%@ *extends([^>]*?)%>',1,cnt,0 ,'n');
                end_tag_pos    := regexp_instr(l_clob, '<%@ *enextends *%>',start_txt_pos,1,1,'n');
                
                -- get the attributes
                extends_att := regexp_replace( regexp_substr( l_clob, '<%@ *extends([^>]*?)%>', regexp_instr(l_clob, '<%@ *extends([^>]*?)%>',1,cnt,0 ,'n') )
                                                ,'<%@ *?extends([^>]*?)%>', '\1');
                -- and adjust them for XML
                -- TODO
                -- dbms_output.put_line( '  attributes= ~' || extends_att || '~' );
        
                -- calculate the replacement text
                extends_clob := to_clob( '<extends ' || extends_att || '>' )
                                || convert_blocks( substr( l_clob, start_txt_pos, end_txt_pos - start_txt_pos ) )
                                || to_clob( '</extends>' );
                                
                -- replace found-tag with extends_clob
                if start_tag_pos = 1
                then
                    c_clob := extends_clob; -- '---'; --extends_clob;
                else
                    c_clob := substr( l_clob, 1, start_tag_pos -1) -- pre <extends>
                            || extends_clob                        -- replacement text
                            || substr( l_clob, end_tag_pos );      -- post </extends>
                end if;
                
                l_clob := c_clob;
            else
                null;
            end if;
        end loop;
    
        return l_clob;

    end convert_extends;
    
    procedure validate_build_template( template_clob in clob )
    as
        cnt_extends   int;
        cnt_enextends int;
        cnt_block     int;
        cnt_enblock   int;
    begin
        cnt_extends   := regexp_count(template_clob, '<%@ *extends([^>]*?)%>',1,'n');
        cnt_enextends := regexp_count(template_clob, '<%@ *enextends *%>',1,'n');
        cnt_block     := regexp_count(template_clob, '<%@ *block([^>]*?)%>',1,'n');
        cnt_enblock   := regexp_count(template_clob, '<%@ *enblock([^>]*?)%>',1,'n');
        
        if nvl(cnt_extends,0) <> nvl(cnt_enextends,0)
        then
            raise_application_error( -20005, 'Mismatched <%@ extends %> tag. ' || cnt_extends || ' vs ' || cnt_enextends );
        elsif nvl(cnt_block,0)<> nvl(cnt_enblock,0)
        then
            raise_application_error( -20005, 'Mismatched <%@ block %> tag. ' || cnt_block || ' vs ' || cnt_enblock );
        end if;
    end validate_build_template;

END teplsql;
/
