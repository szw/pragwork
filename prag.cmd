@setlocal enableextensions & python -x %~f0 %* & goto :EOF
#!/usr/bin/env python
# encoding: utf-8
# The MIT License

# Pragwork 1.0
# Prag Generator 1.0
# Author: Szymon Wrozynski
# Copyright (c) 2009-2011 Szymon Wrozynski (http://wrozynski.com)
# 
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

import os
import sys
import struct
import re

__prag_version__ = '1.0'
__author__ = 'Copyright (c) 2009-2011 Szymon Wrozynski'
__pragwork_version__ = '1.0'
__license__ = 'Licensed under the MIT License'

# Field class (for Model and Scaffolding) ####################################

class Field(object):
    def __init__(self, declaration):
        parts = declaration.split(':')
        if len(parts) != 2: error("Wrong field declaration: " + declaration)
        self.name = ensure_ident(parts[0], True)
        if parts[1].startswith('nullable '):
            parts[1] = parts[1][9:]
            self.__is_nullable = True
        else:
            self.__is_nullable = False
        if parts[1] in ('bool', 'int', 'float', 'string'):
            self.type = parts[1]
            self.__is_text = False
        elif parts[1] == 'text':
            self.type = 'string'
            self.__is_text = True
        else:
            error("Unknown type: " + parts[1])
        
    def is_nullable(self): return self.__is_nullable
    
    def is_bool(self): return self.type == 'bool'
        
    def is_int(self): return self.type == 'int'
    
    def is_float(self): return self.type == 'float'
    
    def is_string(self): return self.type == 'string'
        
    def is_text(self): return self.__is_text
    
    def is_id(self): return self.is_int() and self.name.endswith('_id')
    
    def declaration(self):
        decl = self.name + ':'
        if self.__is_nullable:
            decl += 'nullable '
        if self.__is_text:
            decl += 'text'
        else:
            decl += self.type
        return decl

# Globals

STRIP_PHPDOC = False
SSL = False
EXT = ''
ASTERISK_USED = False
WRITE_MSG = None
THE_SAME_WRITE_MSG = False

# Basic functions ############################################################

def read(path):
    try:
        f = open(path, 'r')
        text = f.read()
        f.close()
        return text
    except IOError as (errno, strerror):
        error("Cannot find or read " + path)

def write(path, text, asterisk=False):
    try:
        f = open(path, 'w')
        f.write(text)
        f.close()
        msg = "Writing " + path
        global WRITE_MSG, THE_SAME_WRITE_MSG, ASTERISK_USED
        if asterisk:
            ASTERISK_USED = True
            msg += ' *'
        THE_SAME_WRITE_MSG = msg == WRITE_MSG
        if THE_SAME_WRITE_MSG:
            print '.',
        else:
            if WRITE_MSG is not None: print
            WRITE_MSG = msg
            print msg,
    except IOError as (errno, strerror):
        if WRITE_MSG is not None: print
        error("Cannot write " + path + ". Are you in the project directory?")
        
def write_binary(path, binary):
    try:
        binfile = open(path, 'wb')
        for num in binary:
            data = struct.pack('b', num)
            binfile.write(data)
        binfile.close()
        global WRITE_MSG
        if WRITE_MSG is not None: print
        WRITE_MSG = "Writing " + path
        print WRITE_MSG,
    except IOError as (errno, strerror):
        error("Cannot write " + path)

def error(msg):
    print "ERROR: " + msg + "\n"
    sys.exit(1)
    
def check_file_exists(path):
    if not os.path.isfile(path):
        error('Cannot found ' + path \
            + ' file. Are you in the project directory?')
            
def check_dir_exists(path):
    if not os.path.isdir(path):
        error('Cannot found ' + path \
            + ' directory. Are you in the project directory?')

def ensure_ident(ident, strict=False):
    if strict:
        pattern = r'^[a-z]+[a-z0-9_]*$'
    else:
        pattern = r'^[a-z]+[a-z0-9_\\]*$'
    
    if not re.match(pattern, ident):
        error("Incorrect identifier: " + ident)
    
    return ident

# Various helper functions ###################################################

def __make_app_dirs(*dirs):
    path = 'app'
    check_dir_exists(path)
    for d in dirs:
        path = os.path.join(path, d)
        if not os.path.isdir(path): os.mkdir(path)
    return path

def __make_ns_dirs(path, ns):
    if len(ns) == 0: return
    for part in ns.split('\\'):
        path = os.path.join(path, part)
        try:
            if not os.path.isdir(path): os.mkdir(path)
        except OSError as (errno, strerror):
            error('Cannot create ' + path \
                + '. Are you in the project directory?')
            
def __pluralize(text):
    plural_keys = [ # order matters!!!
        r'(quiz)$',
        r'^(ox)$',
        r'([m|l])ouse$',
        r'(matr|vert|ind)ix$',
        r'(matr|vert|ind)ex$',
        r'(x|ch|ss|sh)$',
        r'([^aeiouy]|qu)y$',
        r'(hive)$',
        r'(?:([^f])fe|([lr])f)$',
        r'(shea|lea|loa|thie)f$',
        r'sis$',
        r'([ti])um$',
        r'(tomat|potat|ech|her|vet)o$',
        r'(bu)s$',
        r'(alias)$',
        r'(octop)us$',
        r'(ax|test)is$',
        r'(us)$',
        r's$',
        r'$'
    ]
    plural = {
        r'(quiz)$': r"\1zes",
        r'^(ox)$': r"\1en",
        r'([m|l])ouse$': r"\1ice",
        r'(matr|vert|ind)ix$': r"\1ices",
        r'(matr|vert|ind)ex$': r"\1ices",
        r'(x|ch|ss|sh)$': r"\1es",
        r'([^aeiouy]|qu)y$': r"\1ies",
        r'(hive)$': r"\1s",
        r'(?:([^f])fe|([lr])f)$': r"\1\2ves",
        r'(shea|lea|loa|thie)f$': r"\1ves",
        r'sis$': r"ses",
        r'([ti])um$': r"\1a",
        r'(tomat|potat|ech|her|vet)o$': r"\1oes",
        r'(bu)s$': r"\1ses",
        r'(alias)$': r"\1es",
        r'(octop)us$': r"\1i",
        r'(ax|test)is$': r"\1es",
        r'(us)$': r"\1es",
        r's$': r"s",
        r'$': r"s"
    }
    irregular = {
        'move': 'moves',
        'foot': 'feet',
        'goose': 'geese',
        'sex': 'sexes',
        'child': 'children',
        'man': 'men',
        'tooth': 'teeth',
        'person': 'people'
    }
    uncountable = ['sheep', 'fish', 'deer', 'series', 'species', 'money',
        'rice', 'information', 'equipment']
    if text.lower() in uncountable:
        return text
    for pattern in irregular:
        if re.search(pattern, text, re.I):
            return re.sub(pattern, irregular[pattern], text.lower())
    for pattern in plural_keys:
        if re.search(pattern, text, re.I):
            return re.sub(pattern, plural[pattern], text.lower())
    return text

def __camelize(name, separator='_'):
    return name.title().replace(separator, '')
    
def __uncamelize(name, separator='_'):
    result = ''
    prev = ''
    for l in name:
        if l.isupper() and prev not in '_\\':
            result += separator
        result += l.lower()
        prev = l
    return result
    
def __get_ns_and_name(name):
    rpos = name.rfind('\\')
    if rpos > -1: 
        return (name[:rpos], name[rpos + 1:])
    return ('', name)

def __strip_phpdoc(text):
    if STRIP_PHPDOC:
        comment_start = text.find('/**')
        if comment_start > 0:
            comment_end = text.find('*/', comment_start)
            if comment_end > 0:
                return __strip_phpdoc(text[:comment_start] 
                    + text[comment_end + 2:])
    return text

# Main generator functions ###################################################

def new_actions_with_methods(full_controller_sn, actions_with_methods,
    prepend_comment):
    ams = []
    for entry in actions_with_methods:
        if entry in ('GET', 'POST', 'PUT', 'DELETE'):
            if len(ams) == 0: 
                error('An action should be specified before the ' + entry \
                    + ' method')
            if not entry in ams[-1]['methods']:
                ams[-1]['methods'].append(entry)
        else:
            ams.append({'action': entry, 'methods': []})
    for am in ams:
        if len(am['methods']) == 0:
            methods = 'GET'
        else:
            methods = ' '.join(am['methods'])
        new_action(full_controller_sn, am['action'], methods, prepend_comment)

def new_action(full_controller_sn, action, methods, prepend_comment):
    path = os.path.join('app', 'Controllers', 
        __camelize(full_controller_sn).replace('\\', os.path.sep) \
        + 'Controller.php')
    check_file_exists(path)
    controller_text = read(path)
    if re.search(r"\s*public\s+function\s+"+ action + r"\s*\(\s*\)\s*\{",
        controller_text) is not None: return
    mapping = full_controller_sn.replace('_', '-').replace('\\', '/') + '/' \
        + action.replace('_', '-')
    new_route(full_controller_sn, action, methods, mapping, prepend_comment)
    first_part = controller_text[:controller_text.rindex('}')]
    new_controller_text = first_part + os.linesep + '    # ' + methods + ' /' \
        + mapping + EXT + os.linesep + '    public function ' +  action + '()' \
        + os.linesep + '    {}' + os.linesep + '}' + os.linesep + '?>'
    write(path, new_controller_text)
    new_view(full_controller_sn, action)

def new_route(full_controller_sn, action, methods, mapping, prepend_comment):
    path = os.path.join('config', 'routes.php')
    check_file_exists(path)
    routes_text = read(path)
    first_entry = routes_text == R'''<?php
$ROUTES = array(
);
?>'''  
    if re.search(r"\s*'controller'\s*=>\s*'" 
        + __camelize(full_controller_sn).replace('\\', '\\\\')
        + r"'\s*,\s*'action'\s*=>\s*'" + action + "'", routes_text) is not None:
        return
    
    if prepend_comment[0] is not None and not first_entry:
        comment = os.linesep + "    # " + prepend_comment[0] + os.linesep
        prepend_comment[0] = None
    else:
        comment = ""
    
    routes_text = routes_text[:routes_text.rindex(os.linesep + ');' \
        + os.linesep + '?>')]
    
    if SSL or (len(EXT) > 0):
        asterisk = True
    else:
        asterisk = False
    
    if SSL:
        ssl_line = ',' + os.linesep + "        'ssl' => true"
    else:
        ssl_line = ''
    
    if first_entry:
        routes_text += os.linesep + "    # Root"
        mapping_line = ''
    else:
        routes_text += ','
        mapping_line = os.linesep + "        '/" + mapping + EXT + "',"
    
    routes_text += os.linesep + comment + "    array(" + mapping_line \
        + os.linesep + "        'controller' => '" \
        + __camelize(full_controller_sn) + "'," \
        + os.linesep + "        'action' => '" + action + "'," \
        + os.linesep + "        'methods' => '" + methods + "'" + ssl_line \
        + os.linesep + "    )" + os.linesep + ');' + os.linesep + '?>';
    
    write(path, routes_text, asterisk)

def new_view(full_controller_sn, action):
    dir_path = __make_app_dirs('views')
    full_ns = __camelize(full_controller_sn)
    __make_ns_dirs(dir_path, full_ns)
    dirs = full_ns.replace('\\', os.path.sep)
    path = os.path.join(dir_path, dirs, action + '.php')
    if os.path.isfile(path): return
    place = os.path.join('app', 'views', dirs, action + '.php')
    write(path, '<h1>%s\%s</h1>\n\n<p>Find me in %s</p>' % (
        __camelize(full_controller_sn), action, place))

def new_controller(full_controller_sn, actions_with_methods, prepend_comment):
    path = __make_app_dirs('Controllers')
    ns, cont = __get_ns_and_name(full_controller_sn)
    __make_ns_dirs(path, __camelize(ns))
    path = os.path.join(path, __camelize(full_controller_sn).replace('\\', 
        os.path.sep) + 'Controller.php')
    
    if len(ns) > 0:
        ns_clause = '\\' + __camelize(ns)
    else:
        ns_clause = ''
    
    if len(actions_with_methods) == 0:
        abstract = 'abstract '
    else:
        abstract = ''
    
    if len(ns_clause) > 0:
        use_app_cont = 'use Controllers\ApplicationController;' + os.linesep
    else:
        use_app_cont = ''
    
    text = '<?php' + os.linesep + 'namespace Controllers' \
        + ns_clause + ';' + os.linesep + use_app_cont + os.linesep \
        + abstract + 'class ' + __camelize(cont) \
        + 'Controller extends ApplicationController' \
        + os.linesep + '{}' + os.linesep + "?>"
    write(path, text)
    new_helper(ns, cont)
    new_actions_with_methods(full_controller_sn, actions_with_methods, 
        prepend_comment)

def new_helper(namespace_sn, controller_sn):
    path = __make_app_dirs('helpers')
    camelized_ns = __camelize(namespace_sn)
    __make_ns_dirs(path, camelized_ns)    
    path = os.path.join(path, camelized_ns.replace('\\', os.path.sep),
        __camelize(controller_sn) + 'Helper.php')
    write(path, '')

# Help printing function #####################################################
        
def help():
    print '''USAGE:

  prag work name
  
    - Generates a new project.
    

  prag help[|h]
  
    - Prints this information.


Commands available in the project directory:

  prag [ssl] [.ext] controller[|c] name
  prag [ssl] [.ext] controller[|c] namespace\\\\name action_1 [action_2] ...
  prag [ssl] [.ext] controller[|c] name action_1 [GET POST PUT DELETE] ...
  
    - Generates a new controller with given actions and HTTP methods 
      or adds new actions to the existing one. This command also adds 
      the default routes to "routes.php" file and creates the default 
      view templates. The 4 HTTP methods are allowed: GET, POST, PUT, DELETE.
      They should be passed in upper case and follow the action. 
      If no HTTP method follows the action then the GET method is assumed.
      
      This command may be prepended with the "ssl" particle. It causes 
      all generated routes to have the "ssl" option set to "true".
      
      Also, this command may be prepended with an extension starting with a dot.
      The extension will be appended to all generated routes.
      
      Examples: 
      prag .html controller my_controller get_post GET POST post_only POST
      prag c my_controller get_post GET POST post_only POST
      
  
  prag [ssl] [.ext] scaffold[|s][!] entity field_1:type [field_2:type] ...
  
    - Generates a scaffolding around a given model using ActiveRecord module. 
      This command creates a controller, view templates, model class, 
      and routing entries for CRUD actions. 
      
      The Pragwork uses 5 predefined field types: "bool", "float", "int", 
      "string", and "text". Each type can be prepended with the keyword 
      "nullable" if it is allowed to hold a null value. The field name
      and type are separated with a colon.
      
      If the field type is an "int" and its name ends with "_id" then 
      the "INT UNSIGNED" is used within the SQL generated code. This is 
      because of an assumption that the field acts as a foreign key in 
      the relationship between tables.
      
      To overwrite existing files, add an exclamation mark (!) to the command.
      
      This command may be prepended with the "ssl" particle. It causes 
      all generated routes to have the "ssl" option set to "true".
      
      Also, this command may be prepended with an extension starting with a dot.
      The extension will be appended to all generated routes.
      
      Examples: 
      prag scaffold person name:string last_name:string age:int
      prag s! person name:string last_name:string age:int
  
  prag model[|m][!] entity field_1:type [field_2:type] ...
  
    - Creates (or overwrites) model class for the given entity. 
      Generates the SQL code if needed. Follows exactly the same 
      syntax as the "scaffold" command.
      
      To overwrite existing files, add an exclamation mark (!) to the command.

      
  prag form[|f][!] entity field_1:type [field_2:type] ...
  
    - Creates a tableless model class used as a plain model without 
      a database connection. It is especially useful within forms because of 
      the ActiveRecord validation features. Also, this command generates the 
      corresponding form partial template.
      The command follows exactly the same syntax as the "scaffold" command.
      
      To overwrite existing files, add an exclamation mark (!) to the command.
      
      Examples:
      prag form! login name:string password:string
      prag f login name:string password:string
      
      
  prag localize[|l][!] [locale_code] [locale_code_2] ...
  
    - Creates localization files according to specified locale codes. Also, this
      command appends stub entries based on possible keys found in the code 
      to the localization files. 
      
      If no locale codes were specified all available locales are evaluated.
      
      To overwrite existing files, add an exclamation mark (!) to the command.
      
      Examples:
      prag localize!
      prag l en pl

  prag update [nodoc]
  
    - Updates modules of the current project to Pragwork %s.
      The optional "nodoc" parameter causes writing modules without
      PHPDoc comments. That makes some modules significantly smaller and 
      therefore they can be loaded a bit faster.''' % (__pragwork_version__)

# Localization functions

def __make_locale_file(locale):
    path = os.path.join('locales', locale + '.php')
    write(path, R'''<?php
$LOCALE = array(
    '%s'
);
?>''' % (locale, ))    

def __add_locale_stub(locale, key, prepend_comment, value='null'):
    path = os.path.join('locales', locale + '.php')
    
    if (key[0] == '"') and not "'" in key: 
        key = "'" + key[1:-1] + "'"
    
    locale_text = read(path)
    
    if key in re.findall(r"""\s*('[^'\\]+'|"[^"\\]+")\s*=>""", locale_text):
        return
    
    if prepend_comment[0] is not None:
        comment = os.linesep + "    # " + prepend_comment[0] + os.linesep
        prepend_comment[0] = None
    else:
        comment = ""
    
    first_part = locale_text[:locale_text.rindex(os.linesep + ');' \
        + os.linesep + '?>')]
    new_locale_text = first_part + ',' + os.linesep + comment + "    " + key \
        + " => " + value + os.linesep + ');' + os.linesep + '?>'
    write(path, new_locale_text)

def __find_locale_keys_in_dir(locale, directory, prepend_comment):
    for entry in os.listdir(directory):
        entry = os.path.join(directory, entry)
        if os.path.isdir(entry): 
            __find_locale_keys_in_dir(locale, entry, prepend_comment)
        else:
            keys = re.findall(
                r"""[^\w$][tT]\s*\(\s*('[^'\\]+'|"[^"\\]+")\s*\)""",
                read(entry)
            )
            for key in keys: 
                __add_locale_stub(locale, key, prepend_comment)

def __find_model_validation_messages_in_dir(locale, directory, keys):
    for entry in os.listdir(directory):
        entry = os.path.join(directory, entry)
        if os.path.isdir(entry): 
            __find_model_validation_messages_in_dir(locale, entry, keys)
        else:
            text = read(entry)
            keys += [k[1] for k in re.findall(
r"""\s*('message'|"message"|'wrong_length'|"wrong_length"|'too_long'|"too_long"| 'too_short'|"too_short")\s*=>\s*('[^'\\]+'|"[^"\\]+")""", text)]
            keys += [k[1] for k in re.findall(
r"""\$this\s*->\s*errors\s*->\s*add\s*\(\s*('\w+'|"\w+")\s*,\s*('[^'\\]+'|"[^"\\]+")\s*\)""", text)]

def __find_model_validation_messages(locale, prepend_comment):
    keys = [
        "'is not included in the list'",
 	    "'is reserved'",
  	    "'is invalid'",
  	    '"can\'t be empty"',
  	    '"can\'t be blank"',
  	    "'is too long (maximum is %d characters)'",
  	    "'is too short (minimum is %d characters)'",
  	    "'is the wrong length (should be %d characters)'",
  	    "'is not a number'",
  	    "'must be greater than %d'",
  	    "'must be equal to %d'",
  	    "'must be less than %d'",
  	    "'must be odd'",
  	    "'must be even'",
	    "'must be unique'",
  	    "'must be less than or equal to %d'",
  	    "'must be greater than or equal to %d'"
  	]
    path = os.path.join('app', 'Models')
    if os.path.isdir(path): 
        __find_model_validation_messages_in_dir(locale, path, keys)
    for key in keys:
        __add_locale_stub(locale, key, prepend_comment)

def __find_model_fields_in_dir(locale, directory, keys):
    for entry in os.listdir(directory):
        entry = os.path.join(directory, entry)
        if os.path.isdir(entry): 
            __find_model_fields_in_dir(locale, entry, keys)
        else:
            text = read(entry)
            keys += re.findall(r"\s*public\s+\$(\w+)\s*[=;]", text)
            for k in re.findall(r"\s*public\s+function\s+set_(\w+)\s*\(", text):
                if re.search(r"\s*public\s+function\s+get_" +k+ r"\s*\(", text):
                    keys.append(k)

def __find_model_fields(locale, prepend_comment):
    keys = []
    path = os.path.join('app', 'Models')
    if os.path.isdir(path): 
        __find_model_fields_in_dir(locale, path, keys)
    for key in keys:
        __add_locale_stub(locale, "'" + key + "'", prepend_comment,
            "'" + key.replace('_', ' ').capitalize() + "'")

def __find_model_fields_in_sql(locale, prepend_comment):
    path = os.path.join('sql', 'schema.sql')
    check_file_exists(path)
    attributes = re.findall(r"\s+(\w+)\s*:\s*[a-zA-Z]+", read(path))
    if len(attributes) > 0:
        __add_locale_stub(locale, "'id'", prepend_comment, "'Id'")
        for attr in attributes:
            attr = __uncamelize(attr)
            __add_locale_stub(locale, "'" + attr + "'", prepend_comment,
                "'" + attr.replace('_', ' ').capitalize() + "'")
        __add_locale_stub(locale, "'created_at'",prepend_comment,"'Created at'")
        __add_locale_stub(locale, "'updated_at'",prepend_comment,"'Updated at'")
    
def find_locale_keys_and_create_locale(locale, overwrite):
    check_dir_exists('locales')
    check_dir_exists('app')
    check_dir_exists('config')
    check_dir_exists('errors')
    
    path = os.path.join('locales', locale + '.php')
    if overwrite and os.path.isfile(path): os.remove(path)
    if not os.path.isfile(path): __make_locale_file(locale)
    
    comment = ['Fields']
    __find_model_fields_in_sql(locale, comment)
    __find_model_fields(locale, comment)
    comment = ['Configuration entries']
    __find_locale_keys_in_dir(locale, 'config', comment)
    comment = ['Model validation messages']
    __find_model_validation_messages(locale, comment)
    comment = ['Messages']
    __find_locale_keys_in_dir(locale, 'errors', comment)
    __find_locale_keys_in_dir(locale, 'app', comment)

# Scaffolding functions ######################################################

def make_scaffolding_controller(full_singular_sn, fields, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    
    controller_path = __make_app_dirs('Controllers')
    __make_ns_dirs(controller_path, ns_camel)
    controller_path = os.path.join(controller_path, 
        ns_camel.replace('\\', os.path.sep), plural_camel + 'Controller.php')
    
    helper_path = __make_app_dirs('helpers')
    __make_ns_dirs(helper_path, ns_camel)
    helper_path = os.path.join(helper_path, 
        ns_camel.replace('\\', os.path.sep), plural_camel + 'Helper.php')
        
    if overwrite or not os.path.isfile(helper_path): write(helper_path, '')
    
    if not overwrite and os.path.isfile(controller_path): return
    
    if len(ns_camel) > 0:
        mapping_part = ns.replace('_', '-').replace('\\', '/') \
            + '/' + plural.replace('_', '-')
        ns_clause = '\\' + ns_camel
        use_app_cont = 'use Controllers\ApplicationController;' + os.linesep
    else:
        mapping_part = plural.replace('_', '-')
        use_app_cont = ''
        ns_clause = ''
    
    controller_text = R'''<?php
namespace Controllers%s;
%suse Models\%s;

class %sController extends ApplicationController
{
    static $layout = '%s';
''' % (ns_clause, use_app_cont, singular_camel, plural_camel, 
        '\\'.join([x for x in [ns_camel, plural] if len(x) > 0]))
    
    index_pattern = 'GET /' + mapping_part + EXT
    controller_text += R'''
    # %s
    public function index()
    {
        $this->%s = %s::all();
    }
''' % (index_pattern, plural, singular_camel)

    add_pattern = 'GET /' + mapping_part + '/add' + EXT
    controller_text += R'''
    # %s
    public function add()
    {
        $this->%s = new %s;
    }
''' % (add_pattern, singular, singular_camel)
        
    create_pattern = 'POST /' + mapping_part + '/add' + EXT
    controller_text += R'''
    # %s
    public function create()
    {
        $this->%s = new %s($this->params);
        
        if ($this->%s->save())
            $this->redirect_to(array(
                'action' => 'index', 
                'notice' => '%s was successfully created.'
            ));
        
        $this->render('add');
    }
''' % (create_pattern, singular, singular_camel, singular, 
        singular.replace('_', ' ').capitalize())
    
    show_pattern = 'GET /' + mapping_part + '/:id' + EXT
    controller_text += R'''
    # %s
    public function show()
    {
        $this->%s = %s::find($this->params->id);
    }
''' % (show_pattern, singular, singular_camel)
    
    edit_pattern = 'GET /' + mapping_part + '/:id/edit' + EXT
    controller_text += R'''
    # %s
    public function edit()
    {
        $this->%s = %s::find($this->params->id);
    }
''' % (edit_pattern, singular, singular_camel)
    
    update_pattern = 'POST PUT /' + mapping_part + '/:id' + EXT
    controller_text += R'''
    # %s
    public function update()
    {
        $this->%s = %s::find($this->params->id);
        
        if ($this->%s->update_attributes($this->params))
            $this->redirect_to(array(
                'action' => 'show', 
                'params' => $this->%s->id,
                'notice' => '%s was successfully updated.'
            ));

        $this->render('edit');
    }
''' % (update_pattern, singular, singular_camel, singular, singular, 
        singular.replace('_', ' ').capitalize())
    
    delete_pattern = 'POST DELETE /' + mapping_part + '/:id/delete' + EXT
    controller_text += R'''
    # %s
    public function delete()
    {
        $%s = %s::find($this->params->id);
        $%s->delete();
        $this->redirect_to(array(
            'action' => 'index',
            'notice' => '%s was successfully deleted.'
        ));
    }
}
?>''' % (delete_pattern, singular, singular_camel, singular,
            singular.replace('_', ' ').capitalize())
        
    write(controller_path, controller_text)

def make_scaffolding_routes(full_singular_sn):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
        
    if len(ns) > 0:
        full_cont_sn = ns + '\\' + plural
        mapping_part = ns.replace('_', '-').replace('\\', '/') \
            + '/' + plural.replace('_', '-')
    else:
        full_cont_sn = plural
        mapping_part = plural.replace('_', '-')
    
    pc = ['Controller ' + __camelize(full_cont_sn)]
    new_route(full_cont_sn, 'index', 'GET', mapping_part, pc)
    new_route(full_cont_sn, 'create', 'POST', mapping_part + '/add', pc)
    new_route(full_cont_sn, 'add', 'GET', mapping_part + '/add', pc)
    new_route(full_cont_sn, 'update', 'POST PUT', mapping_part + '/:id', pc)
    new_route(full_cont_sn, 'edit', 'GET', mapping_part + '/:id/edit', pc)
    new_route(full_cont_sn,'delete','POST DELETE',mapping_part+'/:id/delete',pc)
    new_route(full_cont_sn, 'show', 'GET', mapping_part + '/:id', pc)

def add_sql_table(full_singular_sn, fields):
    path = os.path.join('sql', 'schema.sql')
    check_file_exists(path)
    ns, singular = __get_ns_and_name(full_singular_sn)
    table_name = __pluralize(singular)
    sql_text = read(path)
    if ('CREATE TABLE ' + table_name) in sql_text: return
    declarations = []
    sql_code = '\nDROP TABLE IF EXISTS ' + table_name \
        + ';\nCREATE TABLE ' + table_name \
        + ' (\n    id INT UNSIGNED NOT NULL AUTO_INCREMENT,\n'
    for f in fields:
        sql_code += '    ' + f.name
        declarations.append(f.declaration())
        if f.is_int():
            sql_code += ' INT'
            if f.is_id(): sql_code += ' UNSIGNED'
        elif f.is_float(): sql_code += ' DECIMAL(10,2)'
        elif f.is_bool(): sql_code += ' TINYINT(1)'
        elif f.is_text(): sql_code += ' TEXT'
        else: sql_code += ' VARCHAR(255)'
        if not f.is_nullable(): sql_code += ' NOT NULL'
        sql_code += ',\n'
    sql_code += '    created_at DATETIME,\n    updated_at DATETIME,\n    ' \
        + 'PRIMARY KEY (id)\n) ENGINE=MYISAM DEFAULT ' \
        + 'CHARACTER SET=utf8 COLLATE=utf8_general_ci;\n'
    write(path, sql_text + '\n-- prag model ' + singular + ' ' \
        + ' '.join(declarations) + sql_code)
    
def add_sql_data_reset(full_singular_sn):
    ns, singular = __get_ns_and_name(full_singular_sn)
    table_name = __pluralize(singular)
    path = os.path.join('sql', 'data.sql')
    check_file_exists(path)
    text = read(path)
    if ('TRUNCATE ' + table_name + ';') in text: return
    text += '\nTRUNCATE ' + table_name + ';'
    write(path, text)

def new_model(full_singular_sn, fields, overwrite, tableless=False):
    ns, singular = __get_ns_and_name(full_singular_sn)
    singular_camel = __camelize(singular)
    path = os.path.join(__make_app_dirs('Models'), 
        singular_camel + '.php')
    
    if not overwrite and os.path.isfile(path): return
    
    validates_presence = []
    validates_numericality = []
    validates_inclusion = []
    for f in fields:
        if not f.is_nullable():
            validates_presence.append("'" + f.name + "'")
        if f.is_int() or f.is_float():
            validates_numericality.append("'" + f.name + "'")
        if f.is_bool():
            validates_inclusion.append("'" + f.name + "'")
    
    validations = []
    
    if len(validates_presence) == 1:
        validations.append("static $validates_presence_of = " 
            + validates_presence[0] + ';')
    elif len(validates_presence) > 1:
        one_line = "static $validates_presence_of = array(" \
            + ", ".join(validates_presence) + ");"
        if len(one_line) <= 76:
            validations.append(one_line);
        else:
            validations.append("static $validates_presence_of = array("
                + os.linesep + '        '  
                + (',' + os.linesep + '        ').join(validates_presence) 
                + os.linesep + '    );')
    
    if len(validates_numericality) == 1:
        validations.append("static $validates_numericality_of = " 
            + validates_numericality[0] + ';')
    elif len(validates_numericality) > 1:
        one_line = "static $validates_numericality_of = array(" \
            + ", ".join(validates_numericality) + ");"
        if len(one_line) <= 76:
            validations.append(one_line);
        else:
            validations.append("static $validates_numericality_of = array(" 
                + os.linesep + '        ' + (',' 
                + os.linesep + '        ').join(validates_numericality) 
                + os.linesep + '    );')
    
    if len(validates_inclusion) > 0:
        validates_inclusion.append("'in' => array(0, 1)")
        one_line = "static $validates_inclusion_of = array(" \
            + ", ".join(validates_inclusion) + ");"
        if len(one_line) <= 76:
            validations.append(one_line)
        else:
            validations.append("static $validates_inclusion_of = array("
                + os.linesep + '        '
                + (',' + os.linesep + '        ').join(validates_inclusion) 
                + os.linesep + '    );')
    
    validations_str = os.linesep + '    ' + (os.linesep + os.linesep \
        + '    ').join(validations) + os.linesep;
    
    if tableless:
        attrs = os.linesep + (os.linesep).join(
            ["    public $" + f.name + ";" for f in fields]
        ) + os.linesep
        model_class = "TablelessModel"
    else:
        model_class = "Model"
        attrs = ''
        add_sql_table(full_singular_sn, fields)
        add_sql_data_reset(full_singular_sn)
    
    write(path, R'''<?php
namespace Models;
modules('activerecord');

class %s extends \ActiveRecord\%s
{%s%s}
?>''' % (singular_camel, model_class, attrs, validations_str))

def make_scaffolding_form(full_singular_sn, fields, overwrite, scaffold=True):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    if scaffold:
        path = os.path.join('app', 'views', ns_camel.replace('\\', os.path.sep), 
            plural_camel, 'form.part.php')
        button_name = 'Save'
    else:
        if ns_camel == '': 
            path = os.path.join('app', 'views', 'shared')
        else:
            path= os.path.join('app','views',ns_camel.replace('\\',os.path.sep))        
        path = os.path.join(path, singular + '_form.part.php')
        button_name = 'Send'
    
    if not overwrite and os.path.isfile(path): return
        
    inputs = ''
    required = ''
    for f in fields:
        inputs += os.linesep + '    <div class="field">' + os.linesep 
        if f.is_bool():
            inputs += "        <?php echo $f->check_box('" + f.name + "') ?>"\
                + os.linesep + "        <?php echo $f->label('" + f.name \
                + "') ?>" + os.linesep
        else:
            if f.is_nullable():
                suffix = ''
            else:
                suffix = ' *'
                if required == '': 
                    required = os.linesep + os.linesep \
                        + '<p><small>* Fields required</small></p>'
            inputs += "        <?php echo $f->label('" + f.name + "') ?>" \
                + suffix + "<br />" + os.linesep
            if f.is_text():
                inputs += "        <?php echo $f->text_area('" \
                    + f.name + "', array('rows' => 10, 'cols' => 80)) ?>" \
                    + os.linesep
            elif f.is_float() or f.is_int():
                inputs += "        <?php echo $f->text_field('" \
                    + f.name + "', array('size' => 10)) ?>" + os.linesep
            else:
                inputs += "        <?php echo $f->text_field('" \
                    + f.name + "', array('size' => 60)) ?>" + os.linesep
        inputs += "        <?php echo $f->error_messages('" + f.name \
            + "', array('wrap_in' => 'p', 'class' => 'error')) ?>" \
            + os.linesep + '    </div>' + os.linesep               
    write(path, 
R'''<?php echo form_for($this->%s, $options, function($f) { ?>
%s
    <div class="actions">
        <?php echo $f->submit('%s') ?>
    </div>

<?php }) ?>%s''' % (singular, inputs, button_name, required))

def make_scaffolding_edit(full_singular_sn, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    full_name_camel = '\\'.join([x for x in [ns_camel, plural_camel] if len(x) > 0])
    path = os.path.join('app', 'views', 
        full_name_camel.replace('\\', os.path.sep), 'edit.php')
    
    if not overwrite and os.path.isfile(path): return
        
    write(path, R'''<h1>Edit %s</h1>

<?php echo $this->render(array('form', 'options' => array('update', 'params' => $this->%s->id))) ?>

<p>Updated at: <?php echo $this->%s->updated_at->format('Y-m-d H:i:s') ?></p>

<nav>
    <?php echo link_to('Show', array('show', 'params' => $this->%s->id)) ?> |
    <?php echo button_to('Delete', array('delete', 'params' => $this->%s->id, 'confirm' => 'Are you sure?')) ?> |        
    <?php echo link_to('Back to index', 'index') ?>
</nav>''' % (singular.replace('_', ' ').title(), singular, singular, singular, 
    singular))
    
def make_scaffolding_add(full_singular_sn, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    full_name_camel = '\\'.join([x for x in [ns_camel, plural_camel] if len(x) > 0])
    
    path = os.path.join('app', 'views', 
        full_name_camel.replace('\\', os.path.sep), 'add.php')
    
    if not overwrite and os.path.isfile(path): return
    
    write(path, R'''<h1>New %s</h1>

<?php echo $this->render(array('form', 'options' => 'create')) ?>

<nav><?php echo link_to('Back to index', 'index') ?></nav>''' % (
    singular.replace('_', ' ').title(), ))

def make_scaffolding_index(full_singular_sn, fields, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    full_name_camel = \
        '\\'.join([x for x in [ns_camel, plural_camel] if len(x) > 0])
    
    path = os.path.join('app', 'views', 
        full_name_camel.replace('\\', os.path.sep), 'index.php')
    
    if not overwrite and os.path.isfile(path): return
    
    headers = ""
    data = ""
    
    for f in fields:
        headers += "        <th>" + f.name.replace('_', ' ').capitalize() \
            + "</th>" + os.linesep
        if f.is_bool():
            data += "            <td class=\"bool\"><?php echo $" \
                + plural[0] + "->" + f.name + " ? 'Yes' : 'No' ?></td>" \
                + os.linesep
        elif f.is_float() or f.is_int():
            data += "            <td class=\"numeric\"><?php echo $" \
                + plural[0] + "->" + f.name + " ?></td>" + os.linesep
        else:
            data += "            <td><?php echo $" + plural[0] + "->" \
                + f.name + " ?></td>" + os.linesep
    write(path, R'''<h1>%s</h1>

<table>
    <tr>
%s        <th colspan="3" />
    </tr>

    <?php foreach ($this->%s as $%s): ?>
        <tr>
%s            <td><?php echo link_to('Show', array('show', 'params' => $%s->id)) ?></td>
            <td><?php echo link_to('Edit', array('edit', 'params' => $%s->id)) ?></td>
            <td><?php echo button_to('Delete', array('delete', 'params' => $%s->id, 'confirm' => 'Are you sure?')) ?></td>
        </tr>
    <?php endforeach ?>
</table>
<br />
<nav><?php echo link_to('Add the new %s', 'add') ?></nav>''' % (
    plural.replace('_', ' ').title(), headers, plural, plural[0], data, 
    plural[0], plural[0], plural[0], singular.replace('_', ' ')))

def make_scaffolding_show(full_singular_sn, fields, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular);
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    full_name_camel = '\\'.join([x for x in [ns_camel, plural_camel] if len(x) > 0])
    
    path = os.path.join('app', 'views', 
        full_name_camel.replace('\\', os.path.sep), 'show.php')
    
    if not overwrite and os.path.isfile(path): return
    
    data = ''
    for f in fields:
        screen_name = f.name.replace('_', ' ').capitalize()
        if f.is_bool():
            data += "<p><strong>" + screen_name \
                + "</strong>: <?php echo $this->" + singular \
                + "->" + f.name + " ? 'Yes' : 'No' ?></p>"
        else:
            data += "<p><strong>" + screen_name \
            + "</strong>: <?php echo $this->" + singular \
            + "->" + f.name + " ?></p>"
        data += os.linesep + os.linesep
    write(path, R'''<h1>%s</h1>

%s<br />

<p>Updated at: <?php echo $this->%s->updated_at->format('Y-m-d H:i:s') ?></p>

<nav>
    <?php echo link_to('Edit', array('edit', 'params' => $this->%s->id)) ?> | 
    <?php echo button_to('Delete', array('delete', 'params' => $this->%s->id, 'confirm' => 'Are you sure?')) ?> | 
    <?php echo link_to('Back to index', 'index') ?>
</nav>''' % (singular.replace('_', ' ').title(), data, singular,
        singular, singular))

def make_scaffolding_layout(full_singular_sn, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    full_name = '\\'.join([x for x in [ns_camel, plural] if len(x) > 0])
    
    path = os.path.join('app', 'views', 'layouts', 
        full_name.replace('\\', os.path.sep) + ".php")
    
    if not overwrite and os.path.isfile(path): return
    
    write(path, R'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <?php echo stylesheet_link_tag('scaffold.css') ?>
    <title>%s</title>
    <!--[if lt IE 9]>
    <?php echo javascript_include_tag(
        'http://html5shiv.googlecode.com/svn/trunk/html5.js'
    ) ?>
    <![endif]-->
</head>
<body>
    <?php if (flash('notice')): ?>
        <aside class="notice"><?php echo flash('notice') ?></aside>
    <?php endif ?>
    <section>
        <?php echo $this->yield() ?>
    </section>
</body>
</html>''' % (plural.replace('_', ' ').title(), ))

def make_scaffolding_templates(full_singular_sn, fields, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    plural = __pluralize(singular)
    ns_camel = __camelize(ns)
    plural_camel = __camelize(plural)
    singular_camel = __camelize(singular)
    full_name_camel = '\\'.join([x for x in [ns_camel, plural_camel] if len(x) > 0])
    
    __make_ns_dirs(__make_app_dirs('views'), full_name_camel)
    __make_ns_dirs(__make_app_dirs('views', 'layouts'), ns_camel)
    
    make_scaffolding_layout(full_singular_sn, overwrite)
    make_scaffolding_form(full_singular_sn, fields, overwrite)
    make_scaffolding_index(full_singular_sn, fields, overwrite)
    make_scaffolding_show(full_singular_sn, fields, overwrite)
    make_scaffolding_edit(full_singular_sn, overwrite)
    make_scaffolding_add(full_singular_sn, overwrite)

def new_scaffolding(full_singular_sn, fields, overwrite):
    make_scaffolding_routes(full_singular_sn)
    make_scaffolding_controller(full_singular_sn, fields, overwrite)
    new_model(full_singular_sn, fields, overwrite)
    make_scaffolding_templates(full_singular_sn, fields, overwrite)

def new_form(full_singular_sn, fields, overwrite):
    ns, singular = __get_ns_and_name(full_singular_sn)
    ns_camel = __camelize(ns)
    if ns_camel == '': 
        __make_app_dirs('views', 'shared')
    else:
        __make_ns_dirs(__make_app_dirs('views'), ns_camel)
    new_model(full_singular_sn, fields, overwrite, True)
    make_scaffolding_form(full_singular_sn, fields, overwrite, False)

# New work functions ######################################################
    
def new_work(work):
    if os.path.isdir(work): error("Directory " + work + " already exists")
    os.mkdir(work)
    os.mkdir(os.path.join(work, 'app'))
    os.mkdir(os.path.join(work, 'app', 'Controllers'))
    os.mkdir(os.path.join(work, 'app', 'Models'))
    os.mkdir(os.path.join(work, 'modules'))
    os.mkdir(os.path.join(work, 'config'))
    os.mkdir(os.path.join(work, 'sql'))
    os.mkdir(os.path.join(work, 'app', 'helpers'))
    os.mkdir(os.path.join(work, 'temp'))
    os.mkdir(os.path.join(work, 'app', 'views'))
    os.mkdir(os.path.join(work, 'app', 'views', 'layouts'))
    os.mkdir(os.path.join(work, 'locales'))
    os.mkdir(os.path.join(work, 'errors'))
    os.mkdir(os.path.join(work, 'public'))
    os.mkdir(os.path.join(work, 'public', 'images'))
    os.mkdir(os.path.join(work, 'public', 'stylesheets'))
    os.mkdir(os.path.join(work, 'public', 'javascripts'))
    make_modules(work)
    make_controllers(work)
    make_config(work)
    make_db(work)
    make_helpers(work)
    make_errors(work)
    make_public(work)
    make_images(work)

def make_images(work):
    pragwork = [-119, 80, 78, 71, 13, 10, 26, 10, 0, 0, 
    0, 13, 73, 72, 68, 82, 0, 0, 0, -75, 
    0, 0, 0, 40, 8, 6, 0, 0, 0, -72, 
    -85, -69, 52, 0, 0, 0, 4, 115, 66, 73, 
    84, 8, 8, 8, 8, 124, 8, 100, -120, 0, 
    0, 0, 9, 112, 72, 89, 115, 0, 0, 17, 
    -36, 0, 0, 17, -36, 1, 126, 89, 30, -34, 
    0, 0, 0, 25, 116, 69, 88, 116, 83, 111, 
    102, 116, 119, 97, 114, 101, 0, 119, 119, 119, 
    46, 105, 110, 107, 115, 99, 97, 112, 101, 46, 
    111, 114, 103, -101, -18, 60, 26, 0, 0, 21, 
    -50, 73, 68, 65, 84, 120, -100, -19, 93, 121, 
    120, -101, -59, -103, -1, 125, -110, 108, -39, -78, 
    78, -53, -78, 100, 75, 114, -20, 56, -66, -19, 
    36, -50, 65, 78, -110, 52, 16, 72, 2, 116, 
    -95, 109, 90, 54, 105, -77, -95, -108, -93, 71, 
    22, -78, 7, -35, 2, 33, -80, 93, 40, 100, 
    123, -80, -19, -61, 66, -39, 18, -102, -106, 64, 
    57, 66, 32, 28, 105, -46, -112, 3, 114, -112, 
    -61, 87, 46, 59, -66, -49, 72, -14, 37, -55, 
    -78, 36, -53, -106, -26, -37, 63, 100, -53, -110, 
    102, 62, -55, 78, -13, 60, -95, -44, -65, -25, 
    -103, 63, -66, 111, 126, -13, -50, 59, 51, -17, 
    55, -13, -50, 59, 35, -101, -29, 121, 30, 57, 
    -9, -4, 33, 31, -64, -77, 98, 17, -73, 34, 
    64, 120, 13, -90, 48, -123, -65, 33, -120, 69, 
    -100, 61, 64, -8, 35, 0, -2, -93, -27, -43, 
    -115, -11, 92, -10, -90, -99, -7, 28, -121, 106, 
    -98, 71, -14, -11, 86, 110, 10, 83, -8, 107, 
    -64, 113, -16, -14, 60, 102, -117, 0, 60, 59, 
    101, -48, 83, -8, 50, 96, -44, -114, -97, -107, 
    -116, -70, 28, -41, 91, -97, 47, 21, -44, 41, 
    82, -20, -40, -78, -14, 122, -85, -15, 119, -127, 
    65, -17, 8, 126, -71, -89, 26, -43, -51, -67, 
    0, 0, -79, -120, 91, 33, -103, -14, -95, -81, 
    61, 36, 98, 14, -27, -71, -70, -21, -83, -58, 
    -33, 21, 54, -2, -30, 32, 0, 32, 64, 120, 
    -115, -24, 58, -21, 50, -123, 41, -4, -43, -112, 
    39, 39, 68, 60, 75, -82, -109, 30, 127, 83, 
    80, -54, 18, 81, 96, 82, -61, -88, -107, 67, 
    45, -105, -94, -77, 119, 16, -83, -74, 1, -76, 
    117, -69, 48, -30, 39, 20, -97, -29, -72, -21, 
    -96, 101, 108, -44, 117, -40, -47, 100, 113, -94, 
    -75, -37, 5, -103, 84, -126, 28, -67, 18, 69, 
    89, 26, -24, -43, -78, -21, -83, -38, 53, -121, 
    -96, 81, -1, -49, -125, 55, 98, 81, -95, -127, 
    -103, -25, 29, -10, -93, -37, -31, 69, -73, -61, 
    11, -101, -61, -125, -102, -26, 94, -20, 59, -37, 
    -114, 97, 127, 64, -80, -94, -1, 88, 55, 23, 
    95, 91, 50, -99, -103, 55, 52, 28, -128, -51, 
    -31, -127, -43, -18, -127, -91, -33, -125, -117, 109, 
    125, 113, -27, 9, -31, -25, -33, 91, -126, 101, 
    -91, -103, -44, -5, 61, 39, -102, -15, -77, -73, 
    42, 38, 37, 107, -10, -12, 52, 108, 90, 85, 
    -124, -43, 115, -77, 32, 77, 16, 83, -7, 1, 
    -62, -93, -83, -37, -123, 63, 30, -70, -116, 63, 
    29, -83, -57, -48, 112, 80, -33, 17, 63, -63, 
    -94, 127, 121, 7, -2, 0, 109, -16, -69, 30, 
    -71, 5, -7, 70, 117, -60, -69, -97, -4, -2, 
    36, 14, 86, 117, 68, -68, 19, -117, 68, 56, 
    -12, -20, -99, -112, 73, 35, -121, 104, -35, 51, 
    127, 70, -85, 109, -128, -110, -5, -60, -6, 27, 
    112, -57, -126, -20, -120, 119, -124, -25, -15, -10, 
    103, -115, -40, 113, -96, 22, -11, 93, 14, -86, 
    -116, 88, -60, -31, -26, 114, 51, 30, 88, 83, 
    18, -45, 93, 122, -24, -91, -49, 112, -94, -42, 
    -62, -52, 75, 73, 74, -128, 65, 35, 67, 70, 
    106, 10, -12, -102, 100, -52, -99, -111, -114, -107, 
    -77, 76, 16, -117, -124, 63, -20, -91, -1, -74, 
    27, -66, 17, 122, 108, -9, 110, -69, 13, 25, 
    -87, 41, -95, -25, -113, -49, -76, 97, -37, 107, 
    -89, -104, 50, -74, -36, 53, 27, -21, 87, -28, 
    51, -13, 4, -115, 90, 37, 75, -124, 78, 37, 
    28, 20, -55, -46, 41, 34, -98, -97, 88, 63, 
    -124, -73, 62, 107, -60, 107, -121, 46, -93, -85, 
    -49, 77, -15, -27, -55, 9, 49, -27, -103, 117, 
    -14, -120, -25, 109, 27, 124, -8, -45, -47, 6, 
    -20, 58, -52, -106, -57, -126, 88, -60, -31, -106, 
    57, 102, 40, -110, 19, -87, -68, -43, -13, -78, 
    38, 108, -44, 98, 17, -121, 45, 119, -51, -58, 
    -9, 111, 43, -123, 40, -58, -84, 43, 22, 113, 
    -104, 110, 80, 98, -37, -6, -7, -8, -31, -19, 
    101, 120, 121, -33, 69, -20, 58, 124, 25, 18, 
    49, 7, 85, -118, 20, -105, 59, -19, 84, -103, 
    102, -21, 0, 101, -44, 71, -49, 95, 65, -17, 
    -64, 16, -59, -83, 105, -18, -59, -94, -94, -15, 
    -119, -123, -25, -127, 115, 45, 125, -52, -113, 61, 
    -57, -96, -116, 120, -10, -8, -4, -40, -4, -30, 
    -89, 56, 84, -45, 41, -88, 127, -128, -16, -40, 
    95, -47, -114, -125, 85, 29, 120, -4, -18, 121, 
    -40, -76, -86, -120, -55, 115, -72, 125, 76, -3, 
    0, -96, 119, 96, 8, 109, -35, -82, -80, 55, 
    23, 97, -48, -56, -80, -31, 43, -7, -72, 123, 
    121, 62, -46, -108, 73, 84, -103, 30, -25, 16, 
    -77, 13, -31, 1, 11, 127, -128, 96, -5, 59, 
    -107, -52, 122, 115, 12, 74, -84, 91, 58, 67, 
    -80, 93, -41, -52, -89, 78, 85, 36, -31, -63, 
    -75, -91, -8, -24, -87, 59, 48, 35, 83, -11, 
    87, -53, -45, -56, -91, -8, -2, 109, -91, -8, 
    -13, 79, -65, -118, -30, -84, -44, 9, -107, -103, 
    51, 67, -57, 52, 104, 32, -8, 17, 102, -21, 
    -107, -52, -68, 112, -120, 69, 28, 94, -4, -47, 
    10, -4, -16, -10, -78, -104, 6, 29, -115, 52, 
    101, 18, 30, -3, -42, 92, 20, -103, -125, -5, 
    -18, -46, 105, 108, -99, -93, 103, 89, 75, -65, 
    27, -106, 126, -10, 71, 91, -47, -40, 19, -15, 
    108, -75, -69, -103, -58, 32, 17, -117, 80, 16, 
    -10, -95, -8, 3, 4, -33, -7, -7, 95, 98, 
    26, 116, 56, 2, -124, -57, 83, -81, -97, -63, 
    11, 31, -98, -97, 16, 63, 30, -84, 118, 15, 
    126, -15, 110, 53, -42, 62, -15, 1, -38, 123, 
    92, -15, 11, 48, -80, -21, 112, 125, -44, -57, 
    50, -114, -1, -4, -10, 2, 36, 72, -124, 77, 
    87, 48, -121, -25, 121, 16, 66, 38, -99, 20, 
    -55, 18, -68, -70, 101, 37, -12, -22, -28, 40, 
    121, -109, -105, 69, 8, -127, 76, 42, -58, -114, 
    -121, -65, 2, 115, -102, 92, 64, -45, 113, -36, 
    88, -110, 25, 83, -42, -78, -110, -116, -72, 50, 
    -74, -83, -97, -113, -101, 102, 25, -81, 74, -41, 
    119, -113, 55, -123, 12, -79, 56, -117, 29, 84, 
    106, -75, 13, 68, -108, 57, 91, -33, 45, -88, 
    75, 69, 99, 119, 4, -105, -27, 118, 0, 64, 
    -66, 81, 5, -79, 8, 33, -34, -49, -34, -86, 
    64, 101, -44, 7, 49, 17, -4, 106, 79, 53, 
    78, 95, -74, 82, -19, -70, 90, -12, 56, -67, 
    -40, -8, -13, -125, -24, 113, 120, 38, 36, 111, 
    44, -33, -27, -15, -31, -41, 123, -49, 49, 57, 
    107, -26, 101, 97, 113, -111, 62, 82, 71, 62, 
    50, 36, 29, -45, -88, -81, 54, 101, 104, 100, 
    120, 121, -13, -118, 40, 121, 87, 47, 51, 77, 
    -103, -124, 87, -73, -84, -116, -7, 117, 2, -64, 
    -78, -46, -116, -104, 114, 110, 44, -115, 109, -44, 
    101, -39, 90, -84, 95, -111, 39, 88, -66, -86, 
    -87, 7, 123, 78, 52, -29, 100, -83, 21, 87, 
    -6, -36, 8, 16, 18, -54, 115, 15, -115, -32, 
    -71, 119, 42, 67, -78, -124, -115, -38, 21, 33, 
    -13, 108, -93, -80, 81, 87, 53, -10, -128, -112, 
    113, -82, -112, 81, -105, 100, -91, -122, 56, 77, 
    22, 39, 118, 28, -88, 21, -108, 57, 45, 93, 
    1, -91, -116, -67, -102, 5, 8, -113, 39, 119, 
    -99, 97, -74, -3, 106, -47, -42, -19, -62, 125, 
    -65, 57, 18, 37, -117, 45, 111, -52, 70, 94, 
    -34, 119, 9, -3, 46, -38, -19, 72, -106, 74, 
    -16, -24, 55, -25, -46, -70, 69, -23, 39, -24, 
    83, -109, -47, -103, 58, 26, -1, -73, -65, 22, 
    -57, 47, 89, 81, -110, -91, 65, 89, -74, 22, 
    11, 11, -45, -95, 78, -111, 82, -68, 34, -77, 
    26, 51, 115, -76, 56, -41, -46, 55, -86, 48, 
    91, -34, 123, -97, -73, 98, -41, -31, 122, -56, 
    -92, 18, 76, 75, 87, 96, -61, -118, 60, 20, 
    -104, -44, 20, 47, 75, -105, -126, -27, -91, -103, 
    56, 88, -51, 94, 82, -75, -118, 36, 20, -103, 
    -44, 49, 103, -126, 27, -14, -45, -111, 40, 17, 
    97, -104, 17, -79, 0, -128, 7, -41, 20, 51, 
    -53, -5, 3, 4, -1, -4, -37, -29, 84, -35, 
    26, -71, 20, -73, -51, -97, -122, -69, 22, -27, 
    96, 127, 101, 7, -70, 29, -34, 80, 94, -95, 
    81, 5, -114, -93, -6, 27, 109, -35, -82, -120, 
    58, 42, 26, -124, -115, -38, -23, 25, 70, -29, 
    21, 7, 114, 51, -126, 110, 83, -101, -115, -67, 
    28, 23, -101, 53, 33, -103, -69, -113, 53, 49, 
    57, 115, 114, -45, -16, -29, 117, -27, 40, -97, 
    -98, 6, -33, 72, 0, -97, 84, 119, -31, -119, 
    93, 103, 48, -32, 25, -114, -32, -43, 118, -40, 
    113, -95, -75, 79, -16, -93, 12, -57, 125, -73, 
    22, 97, 85, -71, 9, 46, -17, 8, -102, -83, 
    3, -40, -7, 73, 61, 58, 123, 7, 41, 94, 
    77, 115, 47, -50, -75, -12, 10, -70, 100, 99, 
    -32, 121, 2, -101, -61, -125, 87, -2, -62, -2, 
    40, 127, 112, 91, 9, -12, -22, 36, 106, -116, 
    -94, -97, 5, -115, -102, 23, 88, 42, -38, -69, 
    93, 56, 81, 107, -59, -119, 90, 43, 0, 32, 
    75, 39, -57, 27, -113, -36, 4, -83, -126, -34, 
    16, 44, 43, -55, -120, 107, -44, -42, 126, 55, 
    106, 70, 57, 39, -21, 108, 120, -9, 68, 51, 
    -10, 110, 93, -115, 108, -67, -126, -30, -82, -100, 
    41, 108, -44, 75, -118, -11, -32, 121, 66, 25, 
    81, 56, -92, 18, 14, -13, -14, 116, 56, 81, 
    107, -93, -14, 102, 100, 40, -79, 114, 102, 38, 
    83, -57, 23, 62, -68, -64, -84, -41, 62, -24, 
    -61, 107, -121, -21, -15, -38, -31, 122, 42, 47, 
    57, 81, -116, 44, -99, -126, -14, 11, 109, 14, 
    15, 60, -66, 17, 36, 37, -120, -31, -11, -7, 
    81, -41, 73, 71, 37, -62, 81, -47, -40, -115, 
    28, 125, -48, -11, 106, 21, -16, 49, 11, 77, 
    -86, -48, 50, -4, -34, -25, 45, 84, 126, -94, 
    68, -124, 103, 55, 45, 64, -106, 78, 14, 66, 
    8, 18, -60, 28, 86, -49, 53, -63, -26, -16, 
    -32, 103, 111, 87, 81, -4, -73, -113, 53, 97, 
    -21, -35, 115, 66, -49, 66, 51, -75, 81, -101, 
    -126, -103, -39, 65, 67, 93, 82, -92, -57, 109, 
    -13, -78, -80, -10, -55, -113, -31, 112, 15, 83, 
    -36, 67, 53, 93, 40, 54, -45, -109, 85, 56, 
    8, 33, -8, -51, -34, -117, -16, -6, -4, 84, 
    94, -114, 94, -127, 77, 43, -13, -103, -29, 19, 
    -83, 95, 12, -9, -125, -19, 46, 68, -93, -67, 
    103, 16, -5, 43, 58, -104, 92, -125, 38, 57, 
    76, 30, 123, 73, -113, -58, -80, -97, -32, -3, 
    83, -83, 2, 110, -115, 112, -12, 100, 105, -79, 
    97, 66, -82, -52, -46, 98, 118, -104, -14, -66, 
    -43, 69, 0, 104, 126, 109, -121, 29, 47, -19, 
    -69, 36, 88, 47, -77, -17, 70, -37, 91, -100, 
    69, 15, 34, -49, 3, 29, 61, 65, 23, -92, 
    -70, -91, 15, -15, -82, 40, 84, 53, -11, -122, 
    116, 105, -17, -95, 103, 65, 17, -57, -95, -64, 
    -88, 2, -49, -13, 56, 126, -55, 10, 91, -40, 
    106, 49, -122, -69, -105, -27, -62, -100, -106, 66, 
    -75, 109, -3, -14, 92, 24, 52, 116, -100, -6, 
    -125, -45, 109, -16, -115, 4, -30, -70, 30, -47, 
    -14, 52, -14, 68, -36, 52, -53, -56, -28, 118, 
    -10, 14, -58, -107, -41, 98, 27, -64, -37, -57, 
    -102, -103, 121, 91, -17, -98, 3, -119, -104, -101, 
    -112, 29, -119, -64, 19, -80, -110, -48, -58, -114, 
    103, 112, 27, -82, 56, -104, 92, 101, -78, 36, 
    -66, 60, 66, -53, -77, -10, -69, -103, 92, -107, 
    44, -127, -87, 43, 7, -126, 69, -123, -23, 20, 
    -1, -56, -71, 46, -22, -35, -110, -94, 116, -86, 
    -68, -104, -29, 113, -21, 108, -10, -26, 112, -41, 
    -31, 122, 4, 2, 1, 102, -67, -79, 18, 33, 
    4, 69, 70, 21, 51, -81, -59, 26, -36, 44, 
    86, 54, 116, -57, -107, 83, -39, 52, -66, 89, 
    108, -17, 118, 82, -7, -45, -46, 101, -112, 38, 
    -120, 64, 8, -63, 71, -89, 91, -103, 50, -54, 
    -89, 107, -103, 109, 19, 113, 64, -39, 52, 53, 
    -59, 31, 112, 15, -31, -45, 11, -29, 125, -57, 
    26, 115, -95, 49, 77, 87, 73, -103, -36, 94, 
    -25, -8, 102, 81, -88, -83, -49, -65, 119, -114, 
    -39, -41, -73, -106, 27, -79, 32, 95, 23, 115, 
    -109, 30, -50, -105, -16, -124, 125, -64, 65, 72, 
    -128, 61, -43, -109, 0, -94, -53, -88, 101, 9, 
    76, 110, -45, 21, 71, -120, 43, -28, -50, 16, 
    -122, 60, -125, 90, -54, -28, 90, -6, -35, 20, 
    23, 0, -118, -89, -91, 82, 58, -16, 60, -16, 
    -30, -57, -25, -79, -76, 88, 31, -63, -99, -82, 
    87, 32, 93, 41, -123, -51, -31, 9, -67, -45, 
    107, 82, 66, -47, -125, -120, -74, -14, -64, -47, 
    115, -99, -52, 58, 99, -127, 31, -19, -69, 66, 
    -93, -110, 89, -74, -51, -26, 4, 33, 25, -88, 
    104, -76, 81, -7, -118, -28, 4, -72, -68, 35, 
    -95, -25, 22, -117, 3, 118, -41, 16, 8, -49, 
    99, -48, -29, -93, 100, 21, 25, 85, 33, -67, 
    -101, -83, 14, 102, 125, -71, 122, -71, -32, 94, 
    99, -122, 65, -114, 3, -116, 50, -83, 86, 39, 
    -56, -24, -58, -102, 53, -26, -63, -9, -12, -104, 
    118, -37, -39, 99, -92, 87, -115, -113, 105, 80, 
    30, -83, -49, -7, 22, 58, 98, -109, -100, 40, 
    -63, -65, 127, -83, 44, 110, -44, 36, -68, 78, 
    9, -49, 56, -11, 2, 0, 18, 16, 48, -62, 
    0, 65, 116, -103, 57, -71, 90, 38, -9, 66, 
    75, 111, -120, 43, 36, -113, 39, -111, -14, 56, 
    14, 88, 94, -102, -63, -28, -74, -39, -100, 84, 
    -35, 0, -80, -92, 32, -99, -30, 55, 90, -100, 
    -88, 110, -24, -127, -51, -18, -90, 14, 125, -106, 
    20, -90, 99, -9, -15, -15, 101, -50, -84, 77, 
    97, -42, 87, -37, 97, -121, 77, 32, -122, 28, 
    19, -93, 109, -51, 55, -86, -104, -6, -74, 90, 
    7, -32, 15, 4, 80, -35, -40, 19, -111, 47, 
    -30, 56, 44, -52, 79, -57, -127, -54, -15, -45, 
    69, 30, 64, 85, 83, 55, 84, 50, 41, 83, 
    86, 97, -104, 81, 95, -23, 25, 100, 114, 50, 
    83, 101, -126, 70, -111, -87, -111, 49, -53, 88, 
    -6, -36, -29, 70, -56, 24, 115, -128, 30, -45, 
    97, 63, -63, -79, 11, 87, -104, -36, 108, -99, 
    60, -82, 60, 22, 30, 88, 93, 8, -99, -110, 
    -34, 28, -122, 35, -38, -122, 4, 103, 106, 33, 
    -1, -121, -113, -6, 42, 86, -107, -101, 49, 63, 
    79, -57, -28, -98, 111, -23, 25, -97, -87, 121, 
    18, 87, 30, -57, 1, 15, -84, 45, 69, -95, 
    73, -51, -28, 126, 82, -43, -63, -100, 5, 22, 
    23, -21, 41, -2, -103, -53, -63, 89, -80, -94, 
    -95, 27, -73, -50, -51, -94, -8, -17, 124, -42, 
    16, 122, 54, -89, -55, -104, -11, -75, 88, -99, 
    -109, -98, -91, -127, -47, -43, -121, -25, -95, 78, 
    73, -124, 94, 37, -123, -43, -18, -119, -56, 111, 
    -77, 57, -47, -40, -27, -128, -53, 29, 25, -74, 
    50, -92, -55, 49, 35, 67, -127, -3, 81, 117, 
    86, 53, -10, 96, -70, -127, 61, -21, 23, -104, 
    -126, -2, -76, 63, 64, -48, 99, 119, -45, -2, 
    -91, -120, 11, -7, -94, 44, 72, 19, 68, 76, 
    -71, -106, -66, -63, 80, -103, -24, 49, 31, 67, 
    -8, -104, -6, 3, 4, -37, -33, -86, -60, -107, 
    94, 122, 51, -53, 113, -64, -78, -78, -116, 48, 
    121, -20, -103, 58, 26, 57, 6, 37, -66, -77, 
    50, 63, 110, 72, -111, -25, -93, 102, 106, 8, 
    25, -75, -128, -69, -16, -35, 91, 10, 97, -44, 
    38, -61, 57, 56, -116, -78, 28, 45, 86, -50, 
    54, 51, 121, 39, 47, 89, 96, 9, 107, -32, 
    -40, -110, 28, -115, -101, -53, 77, 16, 115, 60, 
    8, 15, -36, 80, -88, 71, 113, 86, 42, -109, 
    119, -87, -67, 31, -89, 107, -81, 80, -17, 21, 
    -78, 68, -108, 77, -93, -53, -100, -87, -77, 0, 
    36, -128, -77, -105, -83, 88, 85, 110, -118, -56, 
    91, -112, -97, 14, 49, 72, 104, -109, 102, -42, 
    -78, 103, 50, 75, -17, 32, -124, -6, 39, 38, 
    -62, -38, 90, 100, 82, -63, -38, 23, 57, -48, 
    -106, 94, 23, -102, -82, 56, 40, -39, -71, 122, 
    57, -90, 27, 20, -44, -5, -6, -114, 62, -56, 
    18, 68, 76, 93, 10, 70, 103, 106, 107, -65, 
    27, 36, 64, 71, 13, -92, 9, -110, -104, -77, 
    92, -94, 24, 76, -71, -42, 62, 87, -124, -69, 
    -64, -30, -68, 117, -28, 50, -70, 122, 7, -32, 
    27, 14, -32, -60, 37, 11, 90, -84, -20, 56, 
    -6, -78, -103, 70, -104, -45, -62, 86, 67, 18, 
    0, 38, 96, -44, 63, -7, 102, 57, 68, 28, 
    -19, 22, 70, -125, 16, 18, -95, -33, -92, 125, 
    106, -125, 38, 25, -1, 116, 115, 97, -24, -103, 
    21, 70, 27, -12, -114, -32, -119, -99, 39, 34, 
    -66, 30, -95, -45, 36, -93, 86, -122, 111, -33, 
    84, 16, -87, 96, 20, 124, 35, 1, 60, -13, 
    -6, 41, -26, 108, 113, 67, -98, 14, 0, 15, 
    18, 21, 69, -88, -72, 108, 5, 79, 2, 56, 
    123, -39, 66, -55, -108, 73, -59, 40, -99, -90, 
    65, 117, -45, -88, 15, -57, -77, 117, 115, 123, 
    125, -126, 51, -11, 63, 126, -91, 0, 75, 25, 
    23, -89, 94, 120, -65, 6, -74, -47, 19, 52, 
    32, 120, -38, 119, -88, -86, 45, -126, 99, -21, 
    31, 68, 103, -49, 0, 37, -69, -56, -84, 10, 
    -82, 82, 81, -17, 91, 44, 14, 24, -75, 50, 
    -22, 125, -90, 54, 5, -14, 36, 73, -40, -90, 
    -101, -27, -9, 114, -109, -14, 71, -57, -53, 5, 
    34, -116, -102, -59, -87, 107, -17, 69, 93, 123, 
    -81, -96, 108, 32, 120, -61, -15, -95, 59, 103, 
    70, -18, 119, 38, 48, 83, -117, 68, 28, 18, 
    -60, -79, 117, 23, 106, -61, -92, -35, -113, -119, 
    -32, -71, 55, 79, 83, -77, -109, -112, -5, 17, 
    15, -124, -25, -15, -40, 43, -57, 80, -45, 72, 
    -57, -106, 1, 96, -47, 104, 40, 47, 28, -83, 
    -74, 1, -12, 56, -126, -31, -81, -122, -50, 62, 
    56, 6, -121, -96, -118, 58, 32, 90, 92, 108, 
    64, 85, 67, 48, -42, -34, -43, 59, -64, -44, 
    77, -111, -100, 32, 104, -44, 57, 6, 5, 22, 
    23, -45, 39, -108, -81, 29, -68, 4, 107, 127, 
    32, 36, -81, -48, 76, 27, -87, 119, 40, -128, 
    -38, -74, 94, -22, 125, -95, 89, -125, -116, 84, 
    25, -108, -55, 18, 56, -35, -29, -101, -62, 14, 
    -101, 3, -42, 12, 5, -51, 15, 115, -45, 116, 
    -86, 36, 112, 60, 125, 100, 60, -28, -117, -35, 
    -17, 67, -66, 17, 102, 27, -45, 85, 73, -29, 
    -18, 2, -49, 54, -4, 120, -112, 38, -120, -15, 
    -4, -9, -105, 33, 91, -81, -116, -48, 65, -56, 
    -99, 9, 71, -128, 0, -113, -68, 124, 20, 111, 
    62, 126, 59, -44, 114, -6, 112, 47, 28, 60, 
    -31, -93, -35, 15, -10, -105, 32, -28, 126, -60, 
    -126, 99, -48, -121, 103, -33, 56, -115, 3, 103, 
    91, -81, -119, -68, -102, -90, 30, 108, 127, -13, 
    12, 106, -37, -6, 4, 57, -117, -118, 12, -108, 
    -36, 118, -101, 51, -30, -12, -86, -43, -30, 68, 
    -39, -12, 52, -86, -36, 11, 123, -126, -27, -70, 
    -94, 78, -7, -58, -96, -110, 73, 4, -105, 73, 
    -95, -10, -16, -124, 0, 97, 121, -7, 70, 53, 
    83, 70, 85, -67, -115, 122, 95, 104, 10, -98, 
    12, 22, -103, -44, -8, 60, -20, -86, 103, -128, 
    0, -43, 13, 52, -65, 32, -20, 4, 85, -60, 
    1, 105, 10, 41, -70, 29, -111, -2, 59, 33, 
    -128, 111, -40, 47, 120, -59, -64, -21, 27, 97, 
    -22, 23, 126, 114, 55, -42, -90, -55, -32, -58, 
    -103, 38, -4, -21, -70, 121, -56, 74, 87, -48, 
    -3, 52, 65, 121, -74, -66, 65, 60, -6, -69, 
    79, -15, -101, -51, 55, 33, -42, -35, -78, 104, 
    -3, 38, -19, 126, 48, -71, 60, -113, 67, 85, 
    -19, 120, -18, -11, 83, -52, 51, -5, -96, -68, 
    -55, 25, -75, 63, 64, -16, -44, -50, 99, 104, 
    -79, 56, 5, 57, -71, -103, 106, -24, 84, -12, 
    -50, 120, 113, 113, 6, 53, -117, 70, 115, 10, 
    76, 26, -88, 83, 18, 96, 119, 13, -95, -85, 
    -57, -55, -44, -83, 40, 43, 85, 112, 70, 17, 
    106, 79, 112, -39, 30, -17, 59, -99, 42, 41, 
    84, 79, 56, -84, 125, -111, -2, -89, 86, -103, 
    12, -83, 50, 24, -10, 42, 48, -85, 113, -14, 
    98, -28, 9, 102, -113, -99, 62, 120, 41, -120, 
    -70, 22, -96, 87, 39, -63, -42, 79, 111, -44, 
    58, -70, -99, -56, 54, -80, 111, 78, -74, -37, 
    -40, 97, -64, -16, -120, -125, -112, -5, 33, 4, 
    101, -118, 20, 91, 55, 44, 64, -86, 64, -44, 
    98, 50, -14, -114, -97, -17, -64, 43, 31, -41, 
    -32, -69, 107, -54, 4, 57, -47, 97, -31, 73, 
    -69, 31, 47, -66, 95, -123, 86, -85, 19, -77, 
    114, -45, 97, -77, -69, 81, -37, -42, -121, -38, 
    -74, 62, 120, 124, 35, 12, 41, 17, 45, 97, 
    -54, -5, -8, -13, 38, 44, 41, 51, 81, -18, 
    -127, 88, -60, -31, -71, -5, -105, 97, -29, 51, 
    31, 50, -113, 77, 1, 96, 97, 17, -19, 122, 
    76, 6, 11, 10, -11, -40, 119, -86, 25, 93, 
    61, 108, -9, 35, 43, 93, -127, 76, -83, 12, 
    93, -116, -21, -109, 60, -119, 21, -51, -119, -52, 
    43, 48, -87, 113, -14, 98, 87, 76, 93, 10, 
    -51, -22, 48, -105, 69, 51, -95, 65, 47, 48, 
    107, 34, -22, -55, 74, -105, -93, -90, -47, 74, 
    -15, 26, 58, -5, 49, 77, -32, -38, 109, 67, 
    71, 31, -77, 46, -109, 78, 30, 55, -6, -15, 
    -115, -27, 5, -40, 123, -68, -111, -70, 14, -21, 
    116, 121, -16, -29, -105, 15, -29, -91, 45, -73, 
    66, -60, -8, -79, -128, -112, 81, 47, 46, 49, 
    -30, 4, -93, -97, -2, -9, -67, 10, -52, -54, 
    -43, 97, 78, -98, -98, -54, 3, 70, 109, 53, 
    76, -98, 8, 99, 59, -37, -88, 52, -74, -68, 
    70, -89, 126, -89, 27, 7, -49, 52, -31, 23, 
    127, 58, -119, -41, -10, -97, 67, 69, 93, 23, 
    60, -34, 33, -90, -116, -16, 68, 2, 1, -90, 
    60, 107, -65, 11, -37, 118, 28, 101, -26, 101, 
    -21, -107, 120, -4, -37, -117, 4, 101, 46, 42, 
    -50, -120, 121, -54, 20, 47, 45, 42, -54, 0, 
    72, 0, -125, 110, 47, -86, 27, -24, 43, -105, 
    -124, 16, -36, 50, 55, 75, -96, 127, -40, -19, 
    9, -75, 55, -20, 93, -127, 81, 29, -73, 127, 
    10, 71, 47, 37, 17, 66, 80, 104, -42, -60, 
    -27, 107, -27, -119, -48, -56, -91, 17, -11, -84, 
    -102, 59, -115, -55, -83, -86, -73, 48, 117, -11, 
    13, -5, 113, -95, -55, 70, -15, -107, 73, 98, 
    44, 12, -21, 91, 33, 29, 102, 100, -86, -16, 
    -16, -41, -25, 48, -13, 42, 106, -69, -16, -21, 
    -35, 103, 98, -10, 81, 116, 122, -24, -21, 115, 
    97, 78, 75, -95, 109, -57, -17, -57, 79, 94, 
    58, 20, 113, 42, 25, 75, -90, 104, -20, -85, 
    -119, 78, 99, 75, 104, 116, 26, -5, 106, 39, 
    -97, -124, -113, -55, 63, -83, 106, -59, 27, 7, 
    47, 48, -13, 111, -98, 59, 13, -21, 86, 20, 
    80, -14, -92, 18, 14, 51, 115, 99, 31, -99, 
    -58, 75, 55, 20, 101, 0, 124, 80, -34, 31, 
    -2, 92, -61, -28, -36, -69, 118, 22, 10, 70, 
    35, 18, 19, 105, 15, 33, -76, -63, -25, -101, 
    89, -27, 35, 83, 65, -104, 81, 27, 82, 83, 
    -96, 72, -106, -60, -31, -85, -87, -70, -25, 23, 
    26, -112, -90, -108, 82, -36, -35, -121, 47, -95, 
    -51, 74, 95, 101, 120, -13, -109, 11, -24, -18, 
    119, 81, -4, 91, -25, -25, 64, 34, -30, -88, 
    54, -79, -6, -32, -21, -53, 11, -80, 124, -106, 
    -119, -103, -1, -121, 125, -43, 56, 84, -47, -62, 
    24, 115, -74, 60, 105, -126, 8, -37, 54, 45, 
    1, 7, -102, -45, 99, 119, -31, -15, -105, 15, 
    -63, -49, -104, 28, -93, -71, -94, -48, 114, 73, 
    37, -95, 75, 65, 66, -4, 56, 73, -24, -110, 
    -47, 104, -2, -81, -33, 58, -123, -70, -74, 94, 
    38, -25, -95, 111, -52, 71, 73, 118, 90, -124, 
    -68, 57, -7, 122, 36, -120, 69, 20, -41, -18, 
    -14, -30, -11, -65, 92, -96, -110, -37, 59, 76, 
    113, -43, 114, 41, -14, 77, -87, -32, 9, -63, 
    -47, -54, 86, -76, -37, -100, 20, 71, 34, -26, 
    -16, -12, -3, 43, -80, -88, 56, 19, 18, 17, 
    38, -48, 30, -98, -54, -49, 27, -83, 35, 86, 
    42, -52, -46, 70, -108, 41, 48, 105, 98, -14, 
    -13, 76, -87, 84, -35, 28, -128, 53, 11, 114, 
    41, -82, 111, 120, 4, 79, -66, 114, 20, -25, 
    26, 109, -32, 121, 30, -66, 97, 63, 14, -100, 
    110, -62, -17, 62, -88, 100, -54, -66, 125, -15, 
    12, 118, -101, 4, -58, -12, -15, -115, 75, -96, 
    87, -53, -104, -100, 39, 119, 28, 65, -101, -43, 
    -63, 28, 115, -106, -68, -46, 28, 29, 54, -34, 
    82, -54, -52, 63, 117, -79, 19, -81, 124, 80, 
    21, -45, -114, 120, 66, 38, 127, -8, 34, 20, 
    -120, -113, 7, -31, -69, 36, -63, -91, 99, 120, 
    56, -128, -57, 94, 58, -120, -99, 91, -17, 68, 
    -78, 52, -14, 39, -17, 34, 14, 120, -26, -2, 
    21, -40, -8, -45, 61, 112, -116, 110, -72, 22, 
    22, -79, -81, -119, -98, 60, -33, -127, 95, -67, 
    113, -100, 122, 111, -42, -55, -79, -72, -52, 76, 
    -67, 95, 88, -100, -127, -70, 22, 27, 8, -128, 
    93, -5, 107, -16, -56, -122, 37, 20, 39, 83, 
    43, -57, 47, 55, -81, -126, -37, 59, -126, -86, 
    6, 11, -110, 18, 37, -104, 97, 100, 31, 18, 
    -123, -69, 31, -31, -27, 83, -92, 34, -72, -67, 
    -20, 125, 71, -86, 50, 25, -38, -88, 77, 85, 
    -127, 57, 21, -89, 47, 118, 48, -7, 64, 112, 
    -93, -53, -86, 127, -19, -62, 92, -20, -4, -88, 
    -110, 122, 127, -82, -31, 10, -18, 125, -26, 61, 
    -104, -46, -107, 112, 14, 14, -63, -27, -95, -81, 
    -121, 2, 64, -66, 89, -117, -68, 104, -39, 2, 
    99, 62, 54, -90, 41, 73, 9, -8, -23, -9, 
    -106, -31, -63, -19, 31, 33, 16, -91, -109, -37, 
    29, -64, -113, 95, 56, -128, 87, 30, -3, 7, 
    36, 37, 6, 111, 58, 11, -39, -48, -104, -68, 
    123, 111, -97, -115, -29, -25, -38, 80, -33, 78, 
    71, -67, 126, -9, -2, 89, -52, -52, -43, 97, 
    94, 97, 102, 88, -71, -56, -61, -105, 73, -69, 
    31, -79, -106, -113, -85, 113, 63, -62, -105, -74, 
    54, 75, 63, -98, -5, -29, 103, 76, 94, -102, 
    42, 25, 79, -35, -69, 28, -36, 104, -52, 116, 
    65, 49, -5, -89, 91, -107, 117, -99, -52, -6, 
    43, -22, -24, 27, 123, -124, 16, 44, 40, -50, 
    12, 113, 62, -4, -84, 14, -115, 29, 125, -126, 
    -19, 78, -106, -118, -79, -72, -44, -124, 57, -7, 
    6, 40, 83, 18, 39, -20, 126, -16, 60, 65, 
    -98, 81, 35, -40, 55, -31, -82, -57, 88, 42, 
    48, 11, -13, 121, 18, 64, 30, -93, 12, 33, 
    4, -26, 116, 5, -66, 117, 83, -79, 96, -71, 
    14, -85, 29, 3, -125, 94, 102, 30, 7, -126, 
    45, 119, 47, -120, 57, 70, 66, 99, 90, -110, 
    -93, -61, 125, 119, -52, 102, -14, 26, 59, 122, 
    -15, -12, -17, -57, -9, 77, -62, 54, 23, -52, 
    23, 113, -64, 19, -9, 44, 67, -126, 24, 20, 
    39, 16, -16, 99, -21, 111, 15, -94, -57, 62, 
    40, 104, -109, -126, 70, 29, -37, 93, -72, 58, 
    -93, 22, -106, 57, -50, -5, -8, 120, 29, -10, 
    -99, -84, 103, -14, -26, 21, 102, -94, 108, -70, 
    14, -103, -38, 20, 24, 117, 10, 38, -89, -94, 
    -82, -117, 89, 127, 101, 93, 39, -109, 95, -110, 
    -93, 67, -118, 84, 12, -98, 4, 48, -28, -13, 
    -31, -31, 95, 125, 8, 91, -1, -96, -80, -82, 
    -15, -46, 88, -1, 68, -67, -49, -117, 97, -92, 
    5, 102, -38, -107, -56, -49, -46, 10, -14, -27, 
    73, 18, 24, 82, -27, -126, 58, -4, -32, 107, 
    -13, 81, -110, -109, 54, -23, 49, -70, -17, -114, 
    57, -104, -103, -85, -97, -60, -104, 71, -114, -23, 
    -122, -43, 51, 49, -81, -48, -64, -28, -18, 63, 
    121, 25, -19, 99, 110, -120, -96, 14, -29, -78, 
    114, 50, -44, 120, -16, -50, -71, 76, 94, -97, 
    99, 16, -17, 125, 90, 27, -27, 18, -121, 25, 
    -75, 96, -76, 66, 96, -74, -118, -73, 43, -97, 
    108, 52, -123, 103, 112, -73, -17, 60, -126, 54, 
    -117, -99, -55, -25, 64, 4, 103, -23, 30, -5, 
    32, -38, -81, -12, 49, -21, -81, 107, -74, -63, 
    -19, -11, 49, -28, 1, 115, 11, 12, 33, 94, 
    119, -33, 0, -18, 127, 122, 55, -50, 94, -22, 
    16, -20, -125, 88, 73, -88, -1, -14, 77, -87, 
    -126, 125, -109, -97, 69, -33, 119, -50, -48, -54, 
    -95, 72, -110, -80, -7, 38, -10, 44, 29, 62, 
    -45, 61, -1, -16, 26, 44, 41, 53, 77, 104, 
    108, 68, 32, 120, -8, 91, 11, -15, -99, 53, 
    -77, 38, 53, -26, -47, 99, 10, -98, -57, -42, 
    123, 86, 32, 85, -98, -56, -28, -113, 109, -14, 
    38, 106, 115, -21, 86, -106, -94, 60, 79, -49, 
    -28, 6, -4, -2, 48, 27, -118, -108, 41, 17, 
    58, -125, 31, 24, -12, -94, -105, 17, -16, -9, 
    -6, -122, 49, -111, 27, 86, -47, 112, 121, -122, 
    -104, -14, 60, 30, 31, 37, -49, -29, -11, 97, 
    -21, 75, -5, -79, 125, -13, 26, -22, -49, 20, 
    12, 15, -113, 32, 63, 75, -53, -108, 117, -30, 
    92, -69, -96, 110, 126, 66, 112, -94, -90, 21, 
    -77, -14, -24, -93, -19, -94, 108, 29, -114, -100, 
    109, 10, 61, 91, 123, 7, -80, -7, -65, -33, 
    -57, -38, 37, -123, -8, -22, -78, 34, -108, 76, 
    103, -57, 71, -57, -48, 106, -79, -29, -13, -13, 
    -19, 56, 121, -82, 29, 53, 13, 22, 40, 83, 
    -24, -5, -32, -7, 102, 45, 52, 2, -57, -67, 
    121, 102, -10, -43, -35, -14, 124, 3, -50, 51, 
    -30, -50, 101, -71, -12, 85, -37, 104, 72, 19, 
    -60, 120, -26, -121, -73, -32, -93, 99, 117, 120, 
    -5, -32, 121, 52, 119, -11, 83, 28, -111, -120, 
    -61, -46, -39, -39, -40, -80, 122, 54, 74, -90, 
    -21, 5, 101, -54, -109, 19, -104, -70, 39, 74, 
    68, 84, 25, -115, 34, 9, -113, -35, -77, 2, 
    -1, -75, -29, 112, -16, 66, 122, 24, 56, 4, 
    127, -46, -105, -86, 72, -62, -16, 8, 125, -10, 
    48, -106, 31, -114, -57, -18, 89, -127, 31, 109, 
    127, 31, -66, -31, 72, 126, 82, -126, 56, -60, 
    13, 25, -10, -104, 28, -19, -94, -51, 83, 127, 
    -14, 52, 14, -116, -23, 42, 76, 55, -90, 66, 
    -81, -107, 67, 37, 79, -122, 115, -48, -117, 62, 
    -89, 7, -3, 78, 15, 44, 61, 46, 116, 71, 
    125, 96, -87, 74, 25, -10, 62, -65, -23, -6, 
    40, 43, -128, -90, -114, 62, -76, 89, -19, -24, 
    -76, 57, -111, 44, 77, -128, -39, -96, -58, 12, 
    -77, 22, 105, -22, -108, -8, -123, -65, -32, -72, 
    -40, 100, -61, 3, 79, -17, 14, 61, 11, -98, 
    40, 78, 97, 28, -99, -42, 126, 116, 90, -23, 
    -103, 78, 8, 99, -101, -98, 47, 18, 114, -116, 
    26, -28, 24, -23, 95, -120, 127, -47, -12, -68, 
    26, -124, -36, -40, 81, 8, -122, -12, -90, 112, 
    -11, -8, 34, 26, -11, -105, 25, -82, 65, 111, 
    68, 72, 79, 34, 2, 111, 15, 16, 50, -11, 
    55, -86, -81, 33, 70, 70, -122, 81, 121, 73, 
    56, -58, 60, -123, 107, 7, -9, -48, 48, 118, 
    -18, 61, 29, -102, -87, -59, 34, -111, -99, 83, 
    -105, 127, -9, 93, 0, 119, 93, 95, -43, -90, 
    48, -123, 107, -122, 61, -100, 122, -10, -90, -87, 
    127, 100, 52, -123, 47, 5, 66, -1, -56, -56, 
    94, -11, 106, 61, -49, 99, 54, -128, 61, 98, 
    17, 71, -1, -19, -39, 41, 76, -31, 11, -114, 
    81, -69, -35, -61, -13, -104, 109, -81, 122, -75, 
    -2, -1, 1, 22, -9, 24, -72, -101, -107, 6, 
    -25, 0, 0, 0, 0, 73, 69, 78, 68, -82, 66, 96, -126]
    
    pragwork_small = [-119, 80, 78, 71, 13, 10, 26, 10, 0, 0, 
    0, 13, 73, 72, 68, 82, 0, 0, 0, 72, 
    0, 0, 0, 16, 8, 6, 0, 0, 0, -75, 
    48, 57, -35, 0, 0, 0, 4, 115, 66, 73, 
    84, 8, 8, 8, 8, 124, 8, 100, -120, 0, 
    0, 0, 9, 112, 72, 89, 115, 0, 0, 13, 
    -41, 0, 0, 13, -41, 1, 66, 40, -101, 120, 
    0, 0, 0, 25, 116, 69, 88, 116, 83, 111, 
    102, 116, 119, 97, 114, 101, 0, 119, 119, 119, 
    46, 105, 110, 107, 115, 99, 97, 112, 101, 46, 
    111, 114, 103, -101, -18, 60, 26, 0, 0, 6, 
    -127, 73, 68, 65, 84, 88, -123, -19, -104, 89, 
    108, -100, 87, 21, -57, 127, -25, 126, 51, 99, 
    -41, 65, 73, 83, 55, -42, -52, -73, 56, 113, 
    -110, 66, 66, -51, -94, -42, -95, -111, 17, 89, 
    68, 90, -47, 86, 125, 8, 60, 84, -118, 42, 
    -88, -60, -114, 10, 20, 42, 33, 120, -128, -120, 
    45, -86, -24, 67, 64, 68, 21, 37, 47, 72, 
    -88, 79, 44, 21, -120, 82, -89, 69, 81, -94, 
    84, -20, -119, 67, 73, -29, 58, -87, 19, 51, 
    51, -33, -25, -63, -114, -107, -91, 77, -30, -39, 
    -18, -31, 97, -18, -25, 124, 76, 98, 81, -119, 
    -121, -66, -28, 72, -106, -49, 57, -1, 123, -42, 
    123, -65, -69, -116, -108, 74, -91, -57, 69, -28, 
    -37, -64, 114, 110, 82, -106, 46, -87, -22, 110, 
    -15, 125, -1, 2, -80, -30, -19, -50, 6, -8, 
    -76, -86, 86, -33, -18, 36, 82, 18, -111, -121, 
    -127, -99, 57, -82, 53, 103, 30, 56, -25, -8, 
    -37, -128, 85, 93, 54, 89, -68, 31, -72, 125, 
    9, -33, 117, 96, -38, -15, 17, -48, 119, -125, 
    -32, 39, 84, -11, 31, -64, 90, -32, 46, -96, 
    -57, 90, 27, 27, 99, -90, 61, -49, -69, 84, 
    46, -105, -109, 32, 8, -6, -128, 65, 17, -79, 
    -43, 106, -11, 20, 64, 20, 69, 119, 88, 107, 
    61, -32, 92, 28, -57, -25, 0, 74, -91, -46, 
    42, -49, -13, -74, -74, -37, -19, -109, 51, 51, 
    51, 39, -45, 24, -21, -42, -83, 91, -79, -80, 
    -80, 80, 2, -56, -25, -13, 23, -89, -89, -89, 
    103, -78, 57, -108, 74, -91, 85, -58, -104, 126, 
    99, 76, -85, 82, -87, -68, -98, -58, 3, 48, 
    -58, -52, -74, -37, 109, 68, -28, 81, -109, -79, 
    -39, 23, -57, -15, 6, -9, 55, 0, 108, 80, 
    -43, -49, 0, -81, -34, 0, 95, -91, -86, -17, 
    22, -111, -49, 1, -109, 93, -11, -1, 38, 29, 
    39, 34, -5, -69, 26, 115, 6, -40, 88, -83, 
    86, -33, 19, -57, -15, 35, 113, 28, -113, -26, 
    -13, -7, 33, -32, -128, 49, -26, 105, 96, -94, 
    -43, 106, 61, 11, -96, -86, -113, 0, 19, -86, 
    58, 89, 44, 22, 7, -94, 40, -70, -59, 90, 
    59, 9, 76, -120, -56, -57, 0, -62, 48, -36, 
    107, -116, -7, -73, -86, -2, -62, 24, -13, 106, 
    16, 4, 127, 95, -67, 122, -11, 74, -128, 122, 
    -67, -66, 19, -104, 0, 38, -102, -51, 102, 18, 
    4, -63, -103, 32, 8, 126, 22, 69, -47, 61, 
    -82, 9, 79, 0, 19, -42, -38, -105, 93, 122, 
    79, -70, -15, -57, 69, 100, 101, -102, 115, -74, 
    65, 105, 17, 38, -118, -94, -37, -30, 56, -98, 
    76, -110, 100, -65, -25, 121, -9, 1, 23, -77, 
    -8, -64, -64, 64, 49, 73, -110, -119, 106, -75, 
    -6, 12, 112, 31, 112, 41, -29, 98, 44, 101, 
    -84, -75, 99, 25, -3, -91, 70, -93, -15, -63, 
    56, -114, 95, -117, -94, -24, -106, 32, 8, 118, 
    4, 65, 112, -69, -120, -100, 7, 54, -118, -56, 
    49, -25, 127, -67, -5, 63, -102, 26, 122, -98, 
    55, -38, 106, -75, -42, 2, 2, -48, 110, -73, 
    -113, -7, -66, -1, 101, 85, 125, -36, -115, -3, 
    27, 112, 25, -72, -69, -39, 108, -2, -70, -69, 
    38, 32, 1, -122, -128, 79, 88, 107, -57, 124, 
    -33, 95, -99, 5, -117, -59, -30, 16, -16, 89, 
    55, 49, 79, -107, -53, -27, -87, 37, 27, -76, 
    102, -51, -102, -27, -42, -38, -7, 48, 12, 127, 
    14, 80, 46, -105, 19, 17, -7, 99, 22, -49, 
    -25, -13, 51, 97, 24, -2, 18, 32, -114, -29, 
    50, -80, -120, 27, 99, 94, -52, 20, 118, 24, 
    88, 112, -30, 51, -77, -77, -77, -75, -111, -111, 
    -111, -68, -101, -75, -105, -128, -39, 70, -93, 49, 
    69, 103, 105, -113, -69, 113, -63, -48, -48, 80, 
    47, -80, -40, 32, 96, -44, 24, -77, -34, -15, 
    -83, 92, 46, 119, 66, 68, -66, -24, -28, 31, 
    84, -85, -43, 15, -120, -56, 14, -41, -84, 109, 
    81, 20, -67, 55, 91, 83, -95, 80, -72, 83, 
    85, 71, -100, 120, -85, 49, -26, -2, 44, -18, 
    121, -34, 119, -127, 2, -16, 47, -49, -13, -10, 
    100, -79, -21, 26, -108, -110, -86, -34, -101, -31, 
    103, 111, -128, -65, 47, 35, 94, 112, -55, -99, 
    -88, 84, 42, 113, 24, -122, -3, 97, 24, -66, 
    -65, 82, -87, 92, 5, 14, 3, 24, 99, 126, 
    5, -112, 36, -55, 102, 58, -5, 14, 116, 86, 
    -124, -17, 108, -113, -91, -70, -123, -123, -123, 123, 
    -128, 59, -72, -42, -36, -47, 116, 101, -47, -7, 
    44, 6, -127, 117, -50, -18, 37, -128, 106, -75, 
    -6, 103, -32, 77, 0, 107, -19, 3, -35, -7, 
    -118, -56, 4, -48, 112, -71, -33, -102, -127, 86, 
    2, -69, -100, -2, 43, 46, -25, 69, -70, -82, 
    65, -115, 70, -93, 1, 28, 17, -111, -81, 59, 
    -57, 2, 108, 78, -15, -85, 87, -81, 54, -127, 
    -125, -64, 87, 29, 110, -128, 29, 46, -64, -104, 
    75, 112, 11, -80, 61, -85, 3, 78, -69, 70, 
    109, -22, -114, -23, 108, -50, -32, 26, -19, 121, 
    -34, 46, -89, 62, 2, -76, -127, -69, -127, 119, 
    58, -35, 49, 17, 9, 50, -90, -107, 110, 94, 
    85, -41, 100, 125, -73, 90, -83, 81, 96, 31, 
    -99, 85, 2, 112, 32, 3, 23, -24, 76, -44, 
    -117, 73, -110, 60, -41, -99, 87, -82, 91, 17, 
    -57, -15, 21, 96, 75, 42, -5, -66, -1, 4, 
    -16, -82, 84, -82, -43, 106, -105, -127, 15, 3, 
    12, 15, 15, 23, 124, -33, 127, -102, 107, 39, 
    -38, 1, 0, 99, -52, 86, -105, -28, 94, 17, 
    121, 1, -40, -101, -53, -27, -84, 27, -77, 120, 
    -86, 25, 99, 30, 108, -75, 90, 39, -115, 49, 
    -97, 119, -123, 29, 23, -111, 109, -86, -70, -43, 
    -55, 127, 49, -58, -108, 84, 117, 88, 85, 63, 
    -28, 116, -29, -99, 57, 123, -21, 100, -83, 125, 
    -34, -79, 42, 34, -69, -85, -43, -22, 120, 16, 
    4, 15, 119, 13, -53, -117, -120, 81, 85, -101, 
    85, 94, -73, -126, 70, 70, 70, -14, -66, -17, 
    111, -119, -94, -24, 1, -73, 15, 61, -107, -59, 
    -121, -121, -121, 11, -59, 98, 113, 25, -64, -7, 
    -13, -25, 63, 2, 124, -46, 65, 87, -6, -6, 
    -6, -114, 0, -76, 90, -83, 61, -98, -25, 125, 
    1, 32, -114, -29, 73, 96, -70, -39, 108, -82, 
    113, 5, -2, 51, -11, -91, -86, -55, -52, -52, 
    -52, 52, 112, -34, -87, -46, -49, 108, 113, -75, 
    88, 107, 83, -35, -58, 84, -89, -86, 113, 38, 
    -91, -88, -101, 23, -111, -23, -82, -78, 82, -1, 
    -29, 113, 28, -17, -23, -62, -22, 64, 11, -40, 
    -18, -5, -2, 55, -69, -80, -21, 27, 52, 63, 
    63, -65, 76, 68, 14, 91, 107, -97, 119, 71, 
    -19, 127, -47, -27, -53, -105, -5, 60, -49, -37, 
    7, 16, -57, -15, 111, -127, -3, 0, -86, 122, 
    -24, -12, -23, -45, 117, -128, 90, -83, 54, 91, 
    46, -105, -109, -44, 70, 85, -57, -84, -75, -9, 
    3, -12, -10, -10, 30, 2, -106, -70, 16, 46, 
    -18, 67, -82, -48, -93, 34, 114, 52, -125, 107, 
    -77, -39, 60, -98, 36, -55, 41, 96, -54, -7, 
    -66, 23, 32, 12, -61, -51, -64, 59, 0, -116, 
    49, -65, -49, 58, 85, -43, 79, 1, 22, -72, 
    43, 8, -126, -17, 116, -59, -68, 0, 124, -49, 
    -15, -33, 10, -61, 112, 123, 22, 92, 114, -109, 
    -2, 31, -12, 104, 16, 4, -69, 0, 10, -123, 
    -62, -105, -128, 113, 17, 57, 0, 80, 44, 22, 
    7, -126, 32, -72, 26, 4, -63, 66, -87, 84, 
    -38, -28, 10, 29, 19, -111, -57, -118, -59, -30, 
    -78, -87, -87, -87, -117, -67, -67, -67, -61, 34, 
    -14, 80, -67, 94, -97, -54, 58, 85, -43, -15, 
    -116, 120, -50, -99, -112, -39, 6, -67, 62, 55, 
    55, -9, -122, 118, -24, -57, 78, -9, -75, 48, 
    12, -1, -86, -86, 127, 112, 62, 14, 85, 42, 
    -107, 87, -78, 126, 123, 122, 122, 14, -118, -56, 
    -109, 14, -1, 70, 24, -122, 15, 102, -15, 36, 
    73, -66, -17, -30, 24, 85, 125, -74, 88, 44, 
    14, -4, -65, 13, 2, -8, -55, -32, -32, -32, 
    -70, -77, 103, -49, 46, -120, -56, 79, 69, 100, 
    12, 32, -105, -53, 109, 3, 122, -127, 30, 99, 
    -52, 118, -128, 70, -93, 113, 16, 88, -27, 121, 
    -34, -31, -63, -63, 65, 127, 106, 106, -22, 98, 
    -75, 90, -3, -35, -36, -36, -36, 27, 35, 35, 
    35, 121, 58, 55, 119, 106, -75, -38, 36, 112, 
    -59, -7, 63, 6, -48, 110, -73, -113, -45, -103, 
    -3, 69, -99, 43, -22, 71, 34, -14, 67, 87, 
    -12, 38, 96, 25, 112, 52, -97, -49, 127, -12, 
    70, -55, -58, 113, -68, 27, -8, 19, 32, -86, 
    -6, 88, 22, 83, -43, -106, -75, -10, -29, 116, 
    62, -73, 82, 46, -105, -37, -103, 98, -30, -5, 
    -66, 58, 62, 125, 74, 24, 58, 71, 108, 55, 
    -35, 8, 79, 117, 43, -72, 118, -103, -52, 62, 
    67, 46, 2, 53, -57, -81, 5, -14, 116, 78, 
    -91, 87, -24, -36, 90, 55, 0, 119, 2, 61, 
    -64, -58, 56, -114, 95, 43, 22, -117, 107, 61, 
    -49, 43, 52, -101, -51, 11, -77, -77, -77, 53, 
    -128, 40, -118, -42, 91, 107, 115, -42, -38, -7, 
    -103, -103, -103, -71, 108, 82, 111, -27, -87, -111, 
    36, -55, 41, 85, -75, -3, -3, -3, -53, 123, 
    123, 123, 125, 17, 121, -77, -35, 110, -41, -77, 
    79, 13, -128, 32, 8, 34, 96, 89, -95, 80, 
    -88, -43, -21, -11, -51, 34, -14, -62, -51, -57, 
    -22, 18, -108, 62, 86, -27, -26, -49, 29, 75, 
    -46, 37, 85, -35, -3, 31, 88, -34, -19, 102, 
    -86, 113, 3, -63, 0, 0, 0, 0, 73, 69, 
    78, 68, -82, 66, 96, -126]
    
    favicon = [0, 0, 1, 0, 1, 0, 16, 16, 0, 0, 
    1, 0, 32, 0, 104, 4, 0, 0, 22, 0, 
    0, 0, 40, 0, 0, 0, 16, 0, 0, 0, 
    32, 0, 0, 0, 1, 0, 32, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 112, 71, 44, -124, 100, 54, 23, -6, 
    96, 48, 16, -1, 96, 48, 16, -1, 96, 48, 
    16, -1, 96, 48, 16, -1, 96, 48, 16, -1, 
    96, 48, 16, -1, 96, 48, 16, -1, 96, 48, 
    16, -1, 96, 48, 16, -1, 96, 48, 16, -1, 
    96, 48, 16, -1, 96, 48, 16, -1, 100, 54, 
    23, -6, 112, 71, 44, -124, 103, 57, 24, -6, 
    99, 51, 17, -1, 99, 51, 17, -1, 99, 51, 
    17, -1, 99, 51, 17, -1, 99, 51, 17, -1, 
    99, 51, 17, -1, 99, 51, 17, -1, 99, 51, 
    17, -1, 99, 51, 17, -1, 99, 51, 17, -1, 
    99, 51, 17, -1, 99, 51, 17, -1, 99, 51, 
    17, -1, 99, 51, 17, -1, 103, 57, 24, -6, 
    106, 56, 19, -1, 106, 56, 19, -1, 106, 56, 
    19, -1, 106, 56, 19, -1, 113, 67, 32, -1, 
    121, 79, 48, -1, 121, 79, 47, -1, 106, 56, 
    19, -1, 106, 56, 19, -1, 106, 56, 19, -1, 
    106, 56, 19, -1, 106, 56, 19, -1, 106, 56, 
    19, -1, 106, 56, 19, -1, 106, 56, 19, -1, 
    106, 56, 19, -1, 113, 61, 20, -1, 113, 61, 
    20, -1, 113, 61, 20, -1, 113, 61, 20, -1, 
    -97, -125, 109, -1, -45, -45, -45, -1, -48, -50, 
    -51, -1, 113, 61, 20, -1, 113, 61, 20, -1, 
    113, 61, 20, -1, 113, 61, 20, -1, 113, 61, 
    20, -1, 113, 61, 20, -1, 113, 61, 20, -1, 
    113, 61, 20, -1, 113, 61, 20, -1, 120, 66, 
    22, -1, 120, 66, 22, -1, 120, 66, 22, -1, 
    120, 66, 22, -1, -92, -120, 112, -1, -41, -41, 
    -41, -1, -44, -46, -47, -1, 120, 66, 22, -1, 
    120, 66, 22, -1, 120, 66, 22, -1, 120, 66, 
    22, -1, 120, 66, 22, -1, 120, 66, 22, -1, 
    120, 66, 22, -1, 120, 66, 22, -1, 120, 66, 
    22, -1, 127, 71, 24, -1, 127, 71, 24, -1, 
    127, 71, 24, -1, 127, 71, 24, -1, -86, -116, 
    115, -1, -37, -37, -37, -1, -40, -42, -43, -1, 
    127, 71, 24, -1, 127, 71, 24, -1, 127, 71, 
    24, -1, 127, 71, 24, -1, 127, 71, 24, -1, 
    127, 71, 24, -1, 127, 71, 24, -1, 127, 71, 
    24, -1, 127, 71, 24, -1, -123, 76, 25, -1, 
    -123, 76, 25, -1, -123, 76, 25, -1, -123, 76, 
    25, -1, -81, -111, 117, -1, -33, -33, -33, -1, 
    -34, -34, -35, -1, -56, -70, -83, -1, -58, -75, 
    -89, -1, -89, -125, 100, -1, -123, 76, 25, -1, 
    -123, 76, 25, -1, -123, 76, 25, -1, -123, 76, 
    25, -1, -123, 76, 25, -1, -123, 76, 25, -1, 
    -116, 81, 27, -1, -116, 81, 27, -1, -116, 81, 
    27, -1, -116, 81, 27, -1, -75, -107, 120, -1, 
    -29, -29, -29, -1, -29, -29, -29, -1, -29, -29, 
    -29, -1, -29, -29, -29, -1, -29, -29, -29, -1, 
    -66, -91, -114, -1, -116, 81, 27, -1, -116, 81, 
    27, -1, -116, 81, 27, -1, -116, 81, 27, -1, 
    -116, 81, 27, -1, -109, 86, 29, -1, -109, 86, 
    29, -1, -109, 86, 29, -1, -109, 86, 29, -1, 
    -70, -102, 123, -1, -25, -25, -25, -1, -27, -28, 
    -29, -1, -89, 121, 77, -1, -59, -83, -106, -1, 
    -25, -25, -25, -1, -25, -25, -25, -1, -94, 112, 
    65, -1, -109, 86, 29, -1, -109, 86, 29, -1, 
    -109, 86, 29, -1, -109, 86, 29, -1, -102, 91, 
    30, -1, -102, 91, 30, -1, -102, 91, 30, -1, 
    -102, 91, 30, -1, -64, -98, 126, -1, -21, -21, 
    -21, -1, -24, -26, -27, -1, -102, 91, 30, -1, 
    -97, 100, 43, -1, -21, -21, -21, -1, -21, -21, 
    -21, -1, -69, -107, 113, -1, -102, 91, 30, -1, 
    -102, 91, 30, -1, -102, 91, 30, -1, -102, 91, 
    30, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -59, -93, 
    -127, -1, -17, -17, -17, -1, -19, -21, -23, -1, 
    -95, 96, 32, -1, -69, -113, 100, -1, -17, -17, 
    -17, -1, -17, -17, -17, -1, -70, -115, 98, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -57, -91, -126, -1, -13, -13, -13, -1, 
    -13, -14, -14, -1, -19, -24, -29, -1, -13, -13, 
    -13, -1, -13, -13, -13, -1, -20, -26, -31, -1, 
    -89, 107, 48, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -55, -90, -124, -1, 
    -9, -9, -9, -1, -9, -9, -9, -1, -9, -9, 
    -9, -1, -21, -31, -40, -1, -42, -68, -92, -1, 
    -79, 124, 72, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -89, 107, 47, -1, -81, 120, 65, -1, -81, 120, 
    65, -1, -87, 109, 51, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -92, 102, 
    41, -6, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -92, 102, 
    41, -6, -82, 120, 66, -124, -92, 102, 41, -6, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -95, 96, 
    32, -1, -95, 96, 32, -1, -95, 96, 32, -1, 
    -95, 96, 32, -1, -95, 96, 32, -1, -92, 102, 
    41, -6, -82, 120, 66, -124, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    
    path_public = os.path.join(work, 'public')
    write_binary(os.path.join(path_public, 'favicon.ico'), favicon)
    path_img = os.path.join(path_public, 'images')
    write_binary(os.path.join(path_img, 'pragwork.png'), pragwork)
    write_binary(os.path.join(path_img, 'pragwork_small.png'), pragwork_small)

def make_public(work):
    path = os.path.join(work, 'public')
    write(os.path.join(path, '.htaccess'),
R'''RewriteEngine on

RewriteCond %{REQUEST_URI} \..+$
RewriteCond %{REQUEST_URI} !\.html$
RewriteRule .* - [L]

RewriteRule ^$ index.html [QSA]
RewriteRule ^([^.]+)/$ $1.html [QSA]
RewriteRule ^([^.]+)$ $1.html [QSA]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ index.php [QSA,L]

php_flag magic_quotes_gpc off
php_flag register_globals off''')
    write(os.path.join(path, 'robots.txt'), 
R'''# Uncomment these lines to disallow spiders read the site:
# User-Agent: *
# Disallow: /
''')
    write(os.path.join(path, 'index.html'), R'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <style type="text/css" media="screen">
        article, footer, header {
            display: block;
        }

        body {
            width: 920px;
            font-size: 100%%;
            margin: 0 auto;
            font-family: Helvetica, Arial, sans-serif;
            color: #1a1a1a;
            line-height: 130%%;
        }

        p {
            font-size: 1em;
        }

        h1 {
            font-size: 2em;
            font-weight: bold;
            line-height: 1.5em;
        }

        h2 {
            font-size: 1.2em;
            font-weight: bold;
            line-height: 1.2em;
        }

        img {
            border: none;
        }

        small {
            font-size: 0.75em;
        }

        a:link {
            color: #2060a1;
            text-decoration: underline;
        }

        a:visited {
            color: #2060a1;
            text-decoration: none;
        }

        a:hover {
            color: #d40000;
            text-decoration: none;
        }

        header {
            height: 60px;
        }

        .pragwork-logo {
            margin-top: 15px;
            display: block;
            float: left;
        }

        .pragwork-small-logo {
            text-align: center;
        }

        .info {
            font-size: 0.75em;
            padding-top: 15px;
            padding-bottom: 5px;
        }

        article {
            clear: both;
        }

        footer {
            text-align: center;
            margin-top: 20px;
            border-top: 1px solid #2060a1;
        }
    </style>
    <title>Welcome to %s</title>
</head>
<body>
<header>
    <a href="http://pragwork.com">
    <img src="/images/pragwork.png" class="pragwork-logo" />
    </a>
</header>
<article>
<h1>Welcome to %s!</h1>
<h2>Pragwork works! Thank you for choosing Pragwork %s &mdash; the pragmatic PHP web framework</h2>

<p>Pragwork is a pragmatic web framework for PHP 5.3+ inspired by the ideas of <a href="http://rubyonrails.org">Ruby on Rails</a>. The framework supports <a href="http://en.wikipedia.org/wiki/Model-view-controller">MVC</a> and <a href="http://en.wikipedia.org/wiki/RESTful">RESTful</a> approaches. It uses the <a href="http://www.phpactiverecord.org">PHP ActiveRecord</a> library for <a href="http://en.wikipedia.org/wiki/Object-relational_mapping">O/R mapping</a>. Pragwork has also the internal support for localization, <a href="http://en.wikipedia.org/wiki/AJAX">AJAX</a>, <a href="http://textile.thresholdstate.com">Textile</a>, <a href="http://michelf.com/projects/php-markdown">Markdown</a>, <a href="http://phpmailer.worxware.com">PHP Mailer</a>, and more. And all of that is slightly mixed with a rationale philosophy utilizing the best sides of PHP along with the common sense of making software.</p>

<p>Pragwork is the technology created by <a href="http://pragwork.com/en/about-author-and-contributors#szymon">Szymon Wrozynski</a> &mdash; a freelance software developer from Poland. Currently, Pragwork is free, open source software in continuous development, publicly available under the <a href="http://pragwork.com/en/license">MIT license</a>. Pragwork requires a web server (PHP 5.3, URL rewriting) and a database server. The console generator you have used (<strong>Prag</strong>) requires a Python interpreter.</p>

<p>For further information, FAQ, and tutorials please visit the Pragwork website at <a href="http://pragwork.com">http://pragwork.com</a>.</p>

<p>I hope you do enjoy pragworking!</p>

<p>Good luck with your projects!</p>

<p>Szymon Wrozynski</p>
</article>
<footer>
<div class="info">
    Pragwork %s &copy; 2009-2011 <a href="http://pragwork.com/en/about-author-and-contributors#szymon">Szymon Wrozynski</a><br />
<small>"Pragwork" and the Pragwork logo are trademarks of Szymon Wrozynski. All rights reserved</small>
</div>
<a href="http://pragwork.com"><img src="/images/pragwork_small.png" class="pragwork-small-logo" /></a>
</footer>
</body>
</html>''' % (work.title(), work.title(), __pragwork_version__, __pragwork_version__))
    write(os.path.join(path, 'index.php'), R'''<?php
# %s SETTINGS
const LIVE = false;

const APPLICATION_PATH = '%s';
const SERVER_PATH = null;
const HTTP_PORT = null;
const SSL_PORT = null;

const IMAGES_PATH = '/images';
const JAVASCRIPTS_PATH = '/javascripts';
const STYLESHEETS_PATH = '/stylesheets';

const LOCALIZATION = false;
const SESSION = true;
const CACHE = false;

date_default_timezone_set('Europe/Warsaw');

# Start request processing ##################################################### 

define('MODULES', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'modules'
    . DIRECTORY_SEPARATOR);
require MODULES . 'application.php';

Application\start();
?>''' % (work.upper(), os.path.join(os.getcwd(), work)))
    write(os.path.join(path, 'stylesheets', 'scaffold.css'), 
R'''body {
    width: 920px;
    font-size: 100%;
    line-height: 130%;
    margin: 0 auto;
    font-family: Helvetica, Arial, sans-serif;
    color: #1a1a1a;
    padding-bottom: 50px;
}

article, aside, canvas, details, figcaption, figure, footer, header, 
hgroup, menu, nav, section, summary {
    display: block;
}

h1 {
    font-size: 2em;
    font-weight: bold;
    line-height: 1.5em;
}

h2 {
    font-size: 1.2em;
    font-weight: bold;
    line-height: 1.2em;
}

img {
    border: none;
}

small {
    font-size: 0.8em;
}

/* LINKS */

a:link {
    color: #2060a1;
    text-decoration: underline;
}

a:visited {
    color: #2060a1;
    text-decoration: none;
}

a:hover {
    color: #d40000;
    text-decoration: none;
}

/* TABLES */

table {
    border: 1px solid #1a1a1a;
    border-collapse: collapse;
}

td, th {
   border: 1px solid #1a1a1a;
   padding: 5px;
   vertical-align: middle;
   font-size: 0.9em;
}

th {
    color: white;
    font-weight: bold;
    background-color: #2060a1;
    text-align: left;
    padding-left: 20px;
    padding-right: 20px;
    padding-top: 10px;
}

.numeric {
    text-align: right;
}

.bool {
    text-align: center;
}

/* FORMS */

label {
    font-weight: bold;
    vertical-align: text-top;
}

form div {
    margin-top: 20px;
    margin-bottom: 30px;
}

div.field input {
    font-size: 0.9em;
    border: 1px solid #cecece;
    padding: 2px;
}

div.field textarea {
    padding: 2px;
    border: 1px solid #cecece;
    font-size: 1em;
}

div.actions input {
    font-size: 1em;
}

form p.error {
    margin-top: 0;
    margin-bottom: 0;
    font-size: 0.8em;
    line-height: 1.5em;
    font-weight: bold;
    color: #d40000;
}

/* MISC */

.notice {
    margin-top: 20px;
    padding-top: 10px;
    padding-bottom: 10px;
    background-color: #2060a1;
    text-align: center;
    color: white;
    font-size: 1em;
    font-weight: bold;
}

.button-to {
    display: inline;
}

.button-to input {
    font-size: 0.8em;
}''')

def make_errors(work):
    path = os.path.join(work, 'errors')
    write(os.path.join(path, '403.php'), 
R'''<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>
            403 Forbidden
        </title>
    </head>
    <body>
        <h1>
            Forbidden
        </h1>
        <p>
            You don't have permission to access <?php echo $_SERVER['REQUEST_URI'] ?> on this server.
        </p>
        <hr />
        <address>Pragwork %s <?php echo $_SERVER['SERVER_SOFTWARE'] ?> Server at <?php echo $_SERVER['SERVER_NAME'] ?> Port <?php echo $_SERVER['SERVER_PORT'] ?></address>
    </body>
</html>''' % (__pragwork_version__,))
    write(os.path.join(path, '404.php'), 
R'''<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>
            404 Not found
        </title>
    </head>
    <body>
        <h1>
            Not found
        </h1>
        <p>
            The requested URL <?php echo $_SERVER['REQUEST_URI'] ?> was not found on this server.
        </p>
        <hr />
        <address>Pragwork %s <?php echo $_SERVER['SERVER_SOFTWARE'] ?> Server at <?php echo $_SERVER['SERVER_NAME'] ?> Port <?php echo $_SERVER['SERVER_PORT'] ?></address>
    </body>
</html>''' % (__pragwork_version__,))
    write(os.path.join(path, '405.php'), 
R'''<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>
            405 Method Not Allowed
        </title>
    </head>
    <body>
        <h1>
            Method Not Allowed
        </h1>
        <p>
            The requested method <?php echo $_SERVER['REQUEST_METHOD'] ?> is not allowed for the URL <?php echo $_SERVER['REQUEST_URI'] ?>.
        </p>
        <hr />
        <address>Pragwork %s <?php echo $_SERVER['SERVER_SOFTWARE'] ?> Server at <?php echo $_SERVER['SERVER_NAME'] ?> Port <?php echo $_SERVER['SERVER_PORT'] ?></address>
    </body>
</html>''' % (__pragwork_version__,))
    
    write(os.path.join(path, '500.php'), 
R'''<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>
            500 Internal server error
        </title>
    </head>
    <body>
        <h1>
            Internal server error
        </h1>
        <p>
            We are sorry but your request cannot be completed due to server errors. This incident has been logged and reported to the site administrator.
        </p>
        <p>
            Thank you for understanding.
        </p>
        <hr />
        <address>Pragwork %s <?php echo $_SERVER['SERVER_SOFTWARE'] ?> Server at <?php echo $_SERVER['SERVER_NAME'] ?> Port <?php echo $_SERVER['SERVER_PORT'] ?></address>
    </body>
</html>''' % (__pragwork_version__,))

def make_controllers(work):
    path = os.path.join(work, 'app', 'Controllers')
    write(os.path.join(path, 'ApplicationController.php'), R'''<?php
namespace Controllers;
modules('tags');

abstract class ApplicationController extends \Application\Controller
{}
?>''')
    
def make_config(work):
    path = os.path.join(work, 'config')
    write(os.path.join(path, 'routes.php'), R'''<?php
$ROUTES = array(
);
?>''')
    write(os.path.join(path, 'activerecord.php'), R'''<?php
ActiveRecord\Config::initialize(function($cfg) 
{
    $cfg->set_connections(array(
        'development' => 'mysql://%s:secret@localhost/%s?charset=utf8',
        'production' => 'mysql://%s:secret@localhost/%s?charset=utf8'
    ));
    $cfg->set_default_connection('development');
});
?>''' % (work, work, work, work))

def make_db(work):
    path = os.path.join(work, 'sql')
    write(os.path.join(path, 'schema.sql'), 
R'''SET CHARSET utf8;
DROP DATABASE IF EXISTS %s;
CREATE DATABASE %s CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL ON %s.* to '%s'@'localhost';
SET PASSWORD FOR '%s'@'localhost' = PASSWORD('secret');
USE %s;
''' % (work, work, work, work, work, work))
    write(os.path.join(path, 'data.sql'), 'USE %s;' % (work, ))
    
def make_helpers(work):
    write(os.path.join(work, 'app', 'helpers', 'ApplicationHelper.php'), '')

def make_modules(work):
    make_activerecord_module(work)
    make_application_module(work)
    make_image_module(work)
    make_mailer_module(work)
    make_lightopenid_module(work)
    make_paginate_module(work)
    make_tags_module(work)
    make_textile_module(work)
    make_markdown_module(work)

def make_markdown_module(work):
    write(os.path.join(work, 'modules', 'markdown.php'), R'''<?php
/**
 * Markdown Extra Module 1.0 for Pragwork %s
 *
 * @copyright Copyright (c) 2004-2009 Michel Fortin (PHP Markdown),
 *            Copyright (c) 2004-2006 John Gruber (Original Markdown), 
 *            %s (Module)
 * @license BSD
 * @version %s
 * @package Markdown
 */

#
# Markdown Extra  -  A text-to-HTML conversion tool for web writers
#
# PHP Markdown & Extra
# Copyright (c) 2004-2009 Michel Fortin  
# <http://michelf.com/projects/php-markdown/>
#
# Original Markdown
# Copyright (c) 2004-2006 John Gruber  
# <http://daringfireball.net/projects/markdown/>
#
# Code updates to PHP 5.3.3 and Pragwork standards 
# by (c) 2010 Szymon Wrozynski
''' % (__pragwork_version__, __author__, __pragwork_version__) 
    + __strip_phpdoc(R'''
define( 'MARKDOWN_VERSION',  "1.0.1n" ); # Sat 10 Oct 2009
define( 'MARKDOWNEXTRA_VERSION',  "1.2.4" ); # Sat 10 Oct 2009

#
# Global default settings:
#

# Change to ">" for HTML output
@define( 'MARKDOWN_EMPTY_ELEMENT_SUFFIX',  " />");

# Define the width of a tab for code blocks.
@define( 'MARKDOWN_TAB_WIDTH',     4 );

# Optional title attribute for footnote links and backlinks.
@define( 'MARKDOWN_FN_LINK_TITLE',         "" );
@define( 'MARKDOWN_FN_BACKLINK_TITLE',     "" );

# Optional class attribute for footnote links and backlinks.
@define( 'MARKDOWN_FN_LINK_CLASS',         "" );
@define( 'MARKDOWN_FN_BACKLINK_CLASS',     "" );


### Standard Function Interface ###

@define( 'MARKDOWN_PARSER_CLASS',  'MarkdownExtra_Parser' );

function markdown($text) {
#
# Initialize the parser and return the result of its transform method.
#
	# Setup static parser variable.
	static $parser;
	if (!isset($parser)) {
		$parser_class = MARKDOWN_PARSER_CLASS;
		$parser = new $parser_class;
	}

	# Transform text using parser.
	return $parser->transform($text);
}

#
# Markdown Parser Class
#

class Markdown_Parser {

	# Regex to match balanced [brackets].
	# Needed to insert a maximum bracked depth while converting to PHP.
	protected $nested_brackets_depth = 6;
	protected $nested_brackets_re;
	
	protected $nested_url_parenthesis_depth = 4;
	protected $nested_url_parenthesis_re;

	# Table of hash values for escaped characters:
	protected $escape_chars = '\`*_{}[]()>#+-.!';
	protected $escape_chars_re;

	# Change to ">" for HTML output.
	protected $empty_element_suffix = MARKDOWN_EMPTY_ELEMENT_SUFFIX;
	protected $tab_width = MARKDOWN_TAB_WIDTH;
	
	# Change to `true` to disallow markup or entities.
	protected $no_markup = false;
	protected $no_entities = false;
	
	# Predefined urls and titles for reference links and images.
	protected $predef_urls = array();
	protected $predef_titles = array();


	function __construct() {
	#
	# Constructor function. Initialize appropriate member variables.
	#
		$this->_initDetab();
		$this->prepareItalicsAndBold();
	
		$this->nested_brackets_re = 
			str_repeat('(?>[^\[\]]+|\[', $this->nested_brackets_depth).
			str_repeat('\])*', $this->nested_brackets_depth);
	
		$this->nested_url_parenthesis_re = 
			str_repeat('(?>[^()\s]+|\(', $this->nested_url_parenthesis_depth).
			str_repeat('(?>\)))*', $this->nested_url_parenthesis_depth);
		
		$this->escape_chars_re = '['.preg_quote($this->escape_chars).']';
		
		# Sort document, block, and span gamut in ascendent priority order.
		asort($this->document_gamut);
		asort($this->block_gamut);
		asort($this->span_gamut);
	}


	# Internal hashes used during transformation.
	protected $urls = array();
	protected $titles = array();
	protected $html_hashes = array();
	
	# Status flag to avoid invalid nesting.
	protected $in_anchor = false;
	
	
	function setup() {
	#
	# Called before the transformation process starts to setup parser 
	# states.
	#
		# Clear global hashes.
		$this->urls = $this->predef_urls;
		$this->titles = $this->predef_titles;
		$this->html_hashes = array();
		
		$in_anchor = false;
	}
	
	function teardown() {
	#
	# Called after the transformation process to clear any variable 
	# which may be taking up memory unnecessarly.
	#
		$this->urls = array();
		$this->titles = array();
		$this->html_hashes = array();
	}


	function transform($text) {
	#
	# Main function. Performs some preprocessing on the input text
	# and pass it through the document gamut.
	#
		$this->setup();
	
		# Remove UTF-8 BOM and marker character in input, if present.
		$text = preg_replace('{^\xEF\xBB\xBF|\x1A}', '', $text);

		# Standardize line endings:
		#   DOS to Unix and Mac to Unix
		$text = preg_replace('{\r\n?}', "\n", $text);

		# Make sure $text ends with a couple of newlines:
		$text .= "\n\n";

		# Convert all tabs to spaces.
		$text = $this->detab($text);

		# Turn block-level HTML blocks into hash entries
		$text = $this->hashHTMLBlocks($text);

		# Strip any lines consisting only of spaces and tabs.
		# This makes subsequent regexen easier to write, because we can
		# match consecutive blank lines with /\n+/ instead of something
		# contorted like /[ ]*\n+/ .
		$text = preg_replace('/^[ ]+$/m', '', $text);

		# Run document gamut methods.
		foreach ($this->document_gamut as $method => $priority) {
			$text = $this->$method($text);
		}
		
		$this->teardown();

		return $text . "\n";
	}
	
	protected $document_gamut = array(
		# Strip link definitions, store in hashes.
		"stripLinkDefinitions" => 20,
		
		"runBasicBlockGamut"   => 30,
		);


	function stripLinkDefinitions($text) {
	#
	# Strips link definitions from text, stores the URLs and titles in
	# hash references.
	#
		$less_than_tab = $this->tab_width - 1;

		# Link defs are in the form: ^[id]: url "optional title"
		$text = preg_replace_callback('{
							^[ ]{0,'.$less_than_tab.'}\[(.+)\][ ]?:	# id = $1
							  [ ]*
							  \n?				# maybe *one* newline
							  [ ]*
							(?:
							  <(.+?)>			# url = $2
							|
							  (\S+?)			# url = $3
							)
							  [ ]*
							  \n?				# maybe one newline
							  [ ]*
							(?:
								(?<=\s)			# lookbehind for whitespace
								["(]
								(.*?)			# title = $4
								[")]
								[ ]*
							)?	# title is optional
							(?:\n+|\Z)
			}xm',
			array(&$this, '_stripLinkDefinitions_callback'),
			$text);
		return $text;
	}
	function _stripLinkDefinitions_callback($matches) {
		$link_id = strtolower($matches[1]);
		$url = $matches[2] == '' ? $matches[3] : $matches[2];
		$this->urls[$link_id] = $url;
		$this->titles[$link_id] =& $matches[4];
		return ''; # String that will replace the block
	}


	function hashHTMLBlocks($text) {
		if ($this->no_markup)  return $text;

		$less_than_tab = $this->tab_width - 1;

		# Hashify HTML blocks:
		# We only want to do this for block-level HTML tags, such as headers,
		# lists, and tables. That's because we still want to wrap <p>s around
		# "paragraphs" that are wrapped in non-block-level tags, such as anchors,
		# phrase emphasis, and spans. The list of tags we're looking for is
		# hard-coded:
		#
		# *  List "a" is made of tags which can be both inline or block-level.
		#    These will be treated block-level when the start tag is alone on 
		#    its line, otherwise they're not matched here and will be taken as 
		#    inline later.
		# *  List "b" is made of tags which are always block-level;
		#
		$block_tags_a_re = 'ins|del';
		$block_tags_b_re = 'p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|address|'.
						   'script|noscript|form|fieldset|iframe|math';

		# Regular expression for the content of a block tag.
		$nested_tags_level = 4;
		$attr = '
			(?>				# optional tag attributes
			  \s			# starts with whitespace
			  (?>
				[^>"/]+		# text outside quotes
			  |
				/+(?!>)		# slash not followed by ">"
			  |
				"[^"]*"		# text inside double quotes (tolerate ">")
			  |
				\'[^\']*\'	# text inside single quotes (tolerate ">")
			  )*
			)?	
			';
		$content =
			str_repeat('
				(?>
				  [^<]+			# content without tag
				|
				  <\2			# nested opening tag
					'.$attr.'	# attributes
					(?>
					  />
					|
					  >', $nested_tags_level).	# end of opening tag
					  '.*?'.					# last level nested tag content
			str_repeat('
					  </\2\s*>	# closing nested tag
					)
				  |				
					<(?!/\2\s*>	# other tags with a different name
				  )
				)*',
				$nested_tags_level);
		$content2 = str_replace('\2', '\3', $content);

		# First, look for nested blocks, e.g.:
		# 	<div>
		# 		<div>
		# 		tags for inner block must be indented.
		# 		</div>
		# 	</div>
		#
		# The outermost tags must start at the left margin for this to match, and
		# the inner nested divs must be indented.
		# We need to do this before the next, more liberal match, because the next
		# match will start at the first `<div>` and stop at the first `</div>`.
		$text = preg_replace_callback('{(?>
			(?>
				(?<=\n\n)		# Starting after a blank line
				|				# or
				\A\n?			# the beginning of the doc
			)
			(						# save in $1

			  # Match from `\n<tag>` to `</tag>\n`, handling nested tags 
			  # in between.
					
						[ ]{0,'.$less_than_tab.'}
						<('.$block_tags_b_re.')# start tag = $2
						'.$attr.'>			# attributes followed by > and \n
						'.$content.'		# content, support nesting
						</\2>				# the matching end tag
						[ ]*				# trailing spaces/tabs
						(?=\n+|\Z)	# followed by a newline or end of document

			| # Special version for tags of group a.

						[ ]{0,'.$less_than_tab.'}
						<('.$block_tags_a_re.')# start tag = $3
						'.$attr.'>[ ]*\n	# attributes followed by >
						'.$content2.'		# content, support nesting
						</\3>				# the matching end tag
						[ ]*				# trailing spaces/tabs
						(?=\n+|\Z)	# followed by a newline or end of document
					
			| # Special case just for <hr />. It was easier to make a special 
			  # case than to make the other regex more complicated.
			
						[ ]{0,'.$less_than_tab.'}
						<(hr)				# start tag = $2
						'.$attr.'			# attributes
						/?>					# the matching end tag
						[ ]*
						(?=\n{2,}|\Z)		# followed by a blank line or end of document
			
			| # Special case for standalone HTML comments:
			
					[ ]{0,'.$less_than_tab.'}
					(?s:
						<!-- .*? -->
					)
					[ ]*
					(?=\n{2,}|\Z)		# followed by a blank line or end of document
			
			| # PHP and ASP-style processor instructions (<? and <%)
			
					[ ]{0,'.$less_than_tab.'}
					(?s:
						<([?%])			# $2
						.*?
						\2>
					)
					[ ]*
					(?=\n{2,}|\Z)		# followed by a blank line or end of document
					
			)
			)}Sxmi',
			array(&$this, '_hashHTMLBlocks_callback'),
			$text);

		return $text;
	}
	function _hashHTMLBlocks_callback($matches) {
		$text = $matches[1];
		$key  = $this->hashBlock($text);
		return "\n\n$key\n\n";
	}
	
	
	function hashPart($text, $boundary = 'X') {
	#
	# Called whenever a tag must be hashed when a function insert an atomic 
	# element in the text stream. Passing $text to through this function gives
	# a unique text-token which will be reverted back when calling unhash.
	#
	# The $boundary argument specify what character should be used to surround
	# the token. By convension, "B" is used for block elements that needs not
	# to be wrapped into paragraph tags at the end, ":" is used for elements
	# that are word separators and "X" is used in the general case.
	#
		# Swap back any tag hash found in $text so we do not have to `unhash`
		# multiple times at the end.
		$text = $this->unhash($text);
		
		# Then hash the block.
		static $i = 0;
		$key = "$boundary\x1A" . ++$i . $boundary;
		$this->html_hashes[$key] = $text;
		return $key; # String that will replace the tag.
	}


	function hashBlock($text) {
	#
	# Shortcut function for hashPart with block-level boundaries.
	#
		return $this->hashPart($text, 'B');
	}


	protected $block_gamut = array(
	#
	# These are all the transformations that form block-level
	# tags like paragraphs, headers, and list items.
	#
		"doHeaders"         => 10,
		"doHorizontalRules" => 20,
		
		"doLists"           => 40,
		"doCodeBlocks"      => 50,
		"doBlockQuotes"     => 60,
		);

	function runBlockGamut($text) {
	#
	# Run block gamut tranformations.
	#
		# We need to escape raw HTML in Markdown source before doing anything 
		# else. This need to be done for each block, and not only at the 
		# begining in the Markdown function since hashed blocks can be part of
		# list items and could have been indented. Indented blocks would have 
		# been seen as a code block in a previous pass of hashHTMLBlocks.
		$text = $this->hashHTMLBlocks($text);
		
		return $this->runBasicBlockGamut($text);
	}
	
	function runBasicBlockGamut($text) {
	#
	# Run block gamut tranformations, without hashing HTML blocks. This is 
	# useful when HTML blocks are known to be already hashed, like in the first
	# whole-document pass.
	#
		foreach ($this->block_gamut as $method => $priority) {
			$text = $this->$method($text);
		}
		
		# Finally form paragraph and restore hashed blocks.
		$text = $this->formParagraphs($text);

		return $text;
	}
	
	
	function doHorizontalRules($text) {
		# Do Horizontal Rules:
		return preg_replace(
			'{
				^[ ]{0,3}	# Leading space
				([-*_])		# $1: First marker
				(?>			# Repeated marker group
					[ ]{0,2}	# Zero, one, or two spaces.
					\1			# Marker character
				){2,}		# Group repeated at least twice
				[ ]*		# Tailing spaces
				$			# End of line.
			}mx',
			"\n".$this->hashBlock("<hr$this->empty_element_suffix")."\n", 
			$text);
	}


	protected $span_gamut = array(
	#
	# These are all the transformations that occur *within* block-level
	# tags like paragraphs, headers, and list items.
	#
		# Process character escapes, code spans, and inline HTML
		# in one shot.
		"parseSpan"           => -30,

		# Process anchor and image tags. Images must come first,
		# because ![foo][f] looks like an anchor.
		"doImages"            =>  10,
		"doAnchors"           =>  20,
		
		# Make links out of things like `<http://example.com/>`
		# Must come after doAnchors, because you can use < and >
		# delimiters in inline links like [this](<url>).
		"doAutoLinks"         =>  30,
		"encodeAmpsAndAngles" =>  40,

		"doItalicsAndBold"    =>  50,
		"doHardBreaks"        =>  60,
		);

	function runSpanGamut($text) {
	#
	# Run span gamut tranformations.
	#
		foreach ($this->span_gamut as $method => $priority) {
			$text = $this->$method($text);
		}

		return $text;
	}
	
	
	function doHardBreaks($text) {
		# Do hard breaks:
		return preg_replace_callback('/ {2,}\n/', 
			array(&$this, '_doHardBreaks_callback'), $text);
	}
	function _doHardBreaks_callback($matches) {
		return $this->hashPart("<br$this->empty_element_suffix\n");
	}


	function doAnchors($text) {
	#
	# Turn Markdown link shortcuts into XHTML <a> tags.
	#
		if ($this->in_anchor) return $text;
		$this->in_anchor = true;
		
		#
		# First, handle reference-style links: [link text] [id]
		#
		$text = preg_replace_callback('{
			(					# wrap whole match in $1
			  \[
				('.$this->nested_brackets_re.')	# link text = $2
			  \]

			  [ ]?				# one optional space
			  (?:\n[ ]*)?		# one optional newline followed by spaces

			  \[
				(.*?)		# id = $3
			  \]
			)
			}xs',
			array(&$this, '_doAnchors_reference_callback'), $text);

		#
		# Next, inline-style links: [link text](url "optional title")
		#
		$text = preg_replace_callback('{
			(				# wrap whole match in $1
			  \[
				('.$this->nested_brackets_re.')	# link text = $2
			  \]
			  \(			# literal paren
				[ \n]*
				(?:
					<(.+?)>	# href = $3
				|
					('.$this->nested_url_parenthesis_re.')	# href = $4
				)
				[ \n]*
				(			# $5
				  ([\'"])	# quote char = $6
				  (.*?)		# Title = $7
				  \6		# matching quote
				  [ \n]*	# ignore any spaces/tabs between closing quote and )
				)?			# title is optional
			  \)
			)
			}xs',
			array(&$this, '_doAnchors_inline_callback'), $text);

		#
		# Last, handle reference-style shortcuts: [link text]
		# These must come last in case you've also got [link text][1]
		# or [link text](/foo)
		#
		$text = preg_replace_callback('{
			(					# wrap whole match in $1
			  \[
				([^\[\]]+)		# link text = $2; can\'t contain [ or ]
			  \]
			)
			}xs',
			array(&$this, '_doAnchors_reference_callback'), $text);

		$this->in_anchor = false;
		return $text;
	}
	function _doAnchors_reference_callback($matches) {
		$whole_match =  $matches[1];
		$link_text   =  $matches[2];
		$link_id     =& $matches[3];

		if ($link_id == "") {
			# for shortcut links like [this][] or [this].
			$link_id = $link_text;
		}
		
		# lower-case and turn embedded newlines into spaces
		$link_id = strtolower($link_id);
		$link_id = preg_replace('{[ ]?\n}', ' ', $link_id);

		if (isset($this->urls[$link_id])) {
			$url = $this->urls[$link_id];
			$url = $this->encodeAttribute($url);
			
			$result = "<a href=\"$url\"";
			if ( isset( $this->titles[$link_id] ) ) {
				$title = $this->titles[$link_id];
				$title = $this->encodeAttribute($title);
				$result .=  " title=\"$title\"";
			}
		
			$link_text = $this->runSpanGamut($link_text);
			$result .= ">$link_text</a>";
			$result = $this->hashPart($result);
		}
		else {
			$result = $whole_match;
		}
		return $result;
	}
	function _doAnchors_inline_callback($matches) {
		$whole_match	=  $matches[1];
		$link_text		=  $this->runSpanGamut($matches[2]);
		$url			=  $matches[3] == '' ? $matches[4] : $matches[3];
		$title			=& $matches[7];

		$url = $this->encodeAttribute($url);

		$result = "<a href=\"$url\"";
		if (isset($title)) {
			$title = $this->encodeAttribute($title);
			$result .=  " title=\"$title\"";
		}
		
		$link_text = $this->runSpanGamut($link_text);
		$result .= ">$link_text</a>";

		return $this->hashPart($result);
	}


	function doImages($text) {
	#
	# Turn Markdown image shortcuts into <img> tags.
	#
		#
		# First, handle reference-style labeled images: ![alt text][id]
		#
		$text = preg_replace_callback('{
			(				# wrap whole match in $1
			  !\[
				('.$this->nested_brackets_re.')		# alt text = $2
			  \]

			  [ ]?				# one optional space
			  (?:\n[ ]*)?		# one optional newline followed by spaces

			  \[
				(.*?)		# id = $3
			  \]

			)
			}xs', 
			array(&$this, '_doImages_reference_callback'), $text);

		#
		# Next, handle inline images:  ![alt text](url "optional title")
		# Don't forget: encode * and _
		#
		$text = preg_replace_callback('{
			(				# wrap whole match in $1
			  !\[
				('.$this->nested_brackets_re.')		# alt text = $2
			  \]
			  \s?			# One optional whitespace character
			  \(			# literal paren
				[ \n]*
				(?:
					<(\S*)>	# src url = $3
				|
					('.$this->nested_url_parenthesis_re.')	# src url = $4
				)
				[ \n]*
				(			# $5
				  ([\'"])	# quote char = $6
				  (.*?)		# title = $7
				  \6		# matching quote
				  [ \n]*
				)?			# title is optional
			  \)
			)
			}xs',
			array(&$this, '_doImages_inline_callback'), $text);

		return $text;
	}
	function _doImages_reference_callback($matches) {
		$whole_match = $matches[1];
		$alt_text    = $matches[2];
		$link_id     = strtolower($matches[3]);

		if ($link_id == "") {
			$link_id = strtolower($alt_text); # for shortcut links like ![this][].
		}

		$alt_text = $this->encodeAttribute($alt_text);
		if (isset($this->urls[$link_id])) {
			$url = $this->encodeAttribute($this->urls[$link_id]);
			$result = "<img src=\"$url\" alt=\"$alt_text\"";
			if (isset($this->titles[$link_id])) {
				$title = $this->titles[$link_id];
				$title = $this->encodeAttribute($title);
				$result .=  " title=\"$title\"";
			}
			$result .= $this->empty_element_suffix;
			$result = $this->hashPart($result);
		}
		else {
			# If there's no such link ID, leave intact:
			$result = $whole_match;
		}

		return $result;
	}
	function _doImages_inline_callback($matches) {
		$whole_match	= $matches[1];
		$alt_text		= $matches[2];
		$url			= $matches[3] == '' ? $matches[4] : $matches[3];
		$title			=& $matches[7];

		$alt_text = $this->encodeAttribute($alt_text);
		$url = $this->encodeAttribute($url);
		$result = "<img src=\"$url\" alt=\"$alt_text\"";
		if (isset($title)) {
			$title = $this->encodeAttribute($title);
			$result .=  " title=\"$title\""; # $title already quoted
		}
		$result .= $this->empty_element_suffix;

		return $this->hashPart($result);
	}


	function doHeaders($text) {
		# Setext-style headers:
		#	  Header 1
		#	  ========
		#  
		#	  Header 2
		#	  --------
		#
		$text = preg_replace_callback('{ ^(.+?)[ ]*\n(=+|-+)[ ]*\n+ }mx',
			array(&$this, '_doHeaders_callback_setext'), $text);

		# atx-style headers:
		#	# Header 1
		#	## Header 2
		#	## Header 2 with closing hashes ##
		#	...
		#	###### Header 6
		#
		$text = preg_replace_callback('{
				^(\#{1,6})	# $1 = string of #\'s
				[ ]*
				(.+?)		# $2 = Header text
				[ ]*
				\#*			# optional closing #\'s (not counted)
				\n+
			}xm',
			array(&$this, '_doHeaders_callback_atx'), $text);

		return $text;
	}
	function _doHeaders_callback_setext($matches) {
		# Terrible hack to check we haven't found an empty list item.
		if ($matches[2] == '-' && preg_match('{^-(?: |$)}', $matches[1]))
			return $matches[0];
		
		$level = $matches[2]{0} == '=' ? 1 : 2;
		$block = "<h$level>".$this->runSpanGamut($matches[1])."</h$level>";
		return "\n" . $this->hashBlock($block) . "\n\n";
	}
	function _doHeaders_callback_atx($matches) {
		$level = strlen($matches[1]);
		$block = "<h$level>".$this->runSpanGamut($matches[2])."</h$level>";
		return "\n" . $this->hashBlock($block) . "\n\n";
	}


	function doLists($text) {
	#
	# Form HTML ordered (numbered) and unordered (bulleted) lists.
	#
		$less_than_tab = $this->tab_width - 1;

		# Re-usable patterns to match list item bullets and number markers:
		$marker_ul_re  = '[*+-]';
		$marker_ol_re  = '\d+[.]';
		$marker_any_re = "(?:$marker_ul_re|$marker_ol_re)";

		$markers_relist = array(
			$marker_ul_re => $marker_ol_re,
			$marker_ol_re => $marker_ul_re,
			);

		foreach ($markers_relist as $marker_re => $other_marker_re) {
			# Re-usable pattern to match any entirel ul or ol list:
			$whole_list_re = '
				(								# $1 = whole list
				  (								# $2
					([ ]{0,'.$less_than_tab.'})	# $3 = number of spaces
					('.$marker_re.')			# $4 = first list item marker
					[ ]+
				  )
				  (?s:.+?)
				  (								# $5
					  \z
					|
					  \n{2,}
					  (?=\S)
					  (?!						# Negative lookahead for another list item marker
						[ ]*
						'.$marker_re.'[ ]+
					  )
					|
					  (?=						# Lookahead for another kind of list
					    \n
						\3						# Must have the same indentation
						'.$other_marker_re.'[ ]+
					  )
				  )
				)
			'; // mx
			
			# We use a different prefix before nested lists than top-level lists.
			# See extended comment in _ProcessListItems().
		
			if ($this->list_level) {
				$text = preg_replace_callback('{
						^
						'.$whole_list_re.'
					}mx',
					array(&$this, '_doLists_callback'), $text);
			}
			else {
				$text = preg_replace_callback('{
						(?:(?<=\n)\n|\A\n?) # Must eat the newline
						'.$whole_list_re.'
					}mx',
					array(&$this, '_doLists_callback'), $text);
			}
		}

		return $text;
	}
	function _doLists_callback($matches) {
		# Re-usable patterns to match list item bullets and number markers:
		$marker_ul_re  = '[*+-]';
		$marker_ol_re  = '\d+[.]';
		$marker_any_re = "(?:$marker_ul_re|$marker_ol_re)";
		
		$list = $matches[1];
		$list_type = preg_match("/$marker_ul_re/", $matches[4]) ? "ul" : "ol";
		
		$marker_any_re = ( $list_type == "ul" ? $marker_ul_re : $marker_ol_re );
		
		$list .= "\n";
		$result = $this->processListItems($list, $marker_any_re);
		
		$result = $this->hashBlock("<$list_type>\n" . $result . "</$list_type>");
		return "\n". $result ."\n\n";
	}

	protected $list_level = 0;

	function processListItems($list_str, $marker_any_re) {
	#
	#	Process the contents of a single ordered or unordered list, splitting it
	#	into individual list items.
	#
		# The $this->list_level global keeps track of when we're inside a list.
		# Each time we enter a list, we increment it; when we leave a list,
		# we decrement. If it's zero, we're not in a list anymore.
		#
		# We do this because when we're not inside a list, we want to treat
		# something like this:
		#
		#		I recommend upgrading to version
		#		8. Oops, now this line is treated
		#		as a sub-list.
		#
		# As a single paragraph, despite the fact that the second line starts
		# with a digit-period-space sequence.
		#
		# Whereas when we're inside a list (or sub-list), that line will be
		# treated as the start of a sub-list. What a kludge, huh? This is
		# an aspect of Markdown's syntax that's hard to parse perfectly
		# without resorting to mind-reading. Perhaps the solution is to
		# change the syntax rules such that sub-lists must start with a
		# starting cardinal number; e.g. "1." or "a.".
		
		$this->list_level++;

		# trim trailing blank lines:
		$list_str = preg_replace("/\n{2,}\\z/", "\n", $list_str);

		$list_str = preg_replace_callback('{
			(\n)?							# leading line = $1
			(^[ ]*)							# leading whitespace = $2
			('.$marker_any_re.'				# list marker and space = $3
				(?:[ ]+|(?=\n))	# space only required if item is not empty
			)
			((?s:.*?))						# list item text   = $4
			(?:(\n+(?=\n))|\n)				# tailing blank line = $5
			(?= \n* (\z | \2 ('.$marker_any_re.') (?:[ ]+|(?=\n))))
			}xm',
			array(&$this, '_processListItems_callback'), $list_str);

		$this->list_level--;
		return $list_str;
	}
	function _processListItems_callback($matches) {
		$item = $matches[4];
		$leading_line =& $matches[1];
		$leading_space =& $matches[2];
		$marker_space = $matches[3];
		$tailing_blank_line =& $matches[5];

		if ($leading_line || $tailing_blank_line || 
			preg_match('/\n{2,}/', $item))
		{
			# Replace marker with the appropriate whitespace indentation
			$item = $leading_space . str_repeat(' ', strlen($marker_space)) . $item;
			$item = $this->runBlockGamut($this->outdent($item)."\n");
		}
		else {
			# Recursion for sub-lists:
			$item = $this->doLists($this->outdent($item));
			$item = preg_replace('/\n+$/', '', $item);
			$item = $this->runSpanGamut($item);
		}

		return "<li>" . $item . "</li>\n";
	}


	function doCodeBlocks($text) {
	#
	#	Process Markdown `<pre><code>` blocks.
	#
		$text = preg_replace_callback('{
				(?:\n\n|\A\n?)
				(	            # $1 = the code block -- one or more lines, starting with a space/tab
				  (?>
					[ ]{'.$this->tab_width.'}  # Lines must start with a tab or a tab-width of spaces
					.*\n+
				  )+
				)
				((?=^[ ]{0,'.$this->tab_width.'}\S)|\Z)	# Lookahead for non-space at line-start, or end of doc
			}xm',
			array(&$this, '_doCodeBlocks_callback'), $text);

		return $text;
	}
	function _doCodeBlocks_callback($matches) {
		$codeblock = $matches[1];

		$codeblock = $this->outdent($codeblock);
		$codeblock = htmlspecialchars($codeblock, ENT_NOQUOTES);

		# trim leading newlines and trailing newlines
		$codeblock = preg_replace('/\A\n+|\n+\z/', '', $codeblock);

		$codeblock = "<pre><code>$codeblock\n</code></pre>";
		return "\n\n".$this->hashBlock($codeblock)."\n\n";
	}


	function makeCodeSpan($code) {
	#
	# Create a code span markup for $code. Called from handleSpanToken.
	#
		$code = htmlspecialchars(trim($code), ENT_NOQUOTES);
		return $this->hashPart("<code>$code</code>");
	}


	protected $em_relist = array(
		''  => '(?:(?<!\*)\*(?!\*)|(?<!_)_(?!_))(?=\S|$)(?![.,:;]\s)',
		'*' => '(?<=\S|^)(?<!\*)\*(?!\*)',
		'_' => '(?<=\S|^)(?<!_)_(?!_)',
		);
	protected $strong_relist = array(
		''   => '(?:(?<!\*)\*\*(?!\*)|(?<!_)__(?!_))(?=\S|$)(?![.,:;]\s)',
		'**' => '(?<=\S|^)(?<!\*)\*\*(?!\*)',
		'__' => '(?<=\S|^)(?<!_)__(?!_)',
		);
	protected $em_strong_relist = array(
		''    => '(?:(?<!\*)\*\*\*(?!\*)|(?<!_)___(?!_))(?=\S|$)(?![.,:;]\s)',
		'***' => '(?<=\S|^)(?<!\*)\*\*\*(?!\*)',
		'___' => '(?<=\S|^)(?<!_)___(?!_)',
		);
	protected $em_strong_prepared_relist;
	
	function prepareItalicsAndBold() {
	#
	# Prepare regular expressions for searching emphasis tokens in any
	# context.
	#
		foreach ($this->em_relist as $em => $em_re) {
			foreach ($this->strong_relist as $strong => $strong_re) {
				# Construct list of allowed token expressions.
				$token_relist = array();
				if (isset($this->em_strong_relist["$em$strong"])) {
					$token_relist[] = $this->em_strong_relist["$em$strong"];
				}
				$token_relist[] = $em_re;
				$token_relist[] = $strong_re;
				
				# Construct master expression from list.
				$token_re = '{('. implode('|', $token_relist) .')}';
				$this->em_strong_prepared_relist["$em$strong"] = $token_re;
			}
		}
	}
	
	function doItalicsAndBold($text) {
		$token_stack = array('');
		$text_stack = array('');
		$em = '';
		$strong = '';
		$tree_char_em = false;
		
		while (1) {
			#
			# Get prepared regular expression for seraching emphasis tokens
			# in current context.
			#
			$token_re = $this->em_strong_prepared_relist["$em$strong"];
			
			#
			# Each loop iteration search for the next emphasis token. 
			# Each token is then passed to handleSpanToken.
			#
			$parts = preg_split($token_re, $text, 2, PREG_SPLIT_DELIM_CAPTURE);
			$text_stack[0] .= $parts[0];
			$token =& $parts[1];
			$text =& $parts[2];
			
			if (empty($token)) {
				# Reached end of text span: empty stack without emitting.
				# any more emphasis.
				while ($token_stack[0]) {
					$text_stack[1] .= array_shift($token_stack);
					$text_stack[0] .= array_shift($text_stack);
				}
				break;
			}
			
			$token_len = strlen($token);
			if ($tree_char_em) {
				# Reached closing marker while inside a three-char emphasis.
				if ($token_len == 3) {
					# Three-char closing marker, close em and strong.
					array_shift($token_stack);
					$span = array_shift($text_stack);
					$span = $this->runSpanGamut($span);
					$span = "<strong><em>$span</em></strong>";
					$text_stack[0] .= $this->hashPart($span);
					$em = '';
					$strong = '';
				} else {
					# Other closing marker: close one em or strong and
					# change current token state to match the other
					$token_stack[0] = str_repeat($token{0}, 3-$token_len);
					$tag = $token_len == 2 ? "strong" : "em";
					$span = $text_stack[0];
					$span = $this->runSpanGamut($span);
					$span = "<$tag>$span</$tag>";
					$text_stack[0] = $this->hashPart($span);
					$$tag = ''; # $$tag stands for $em or $strong
				}
				$tree_char_em = false;
			} else if ($token_len == 3) {
				if ($em) {
					# Reached closing marker for both em and strong.
					# Closing strong marker:
					for ($i = 0; $i < 2; ++$i) {
						$shifted_token = array_shift($token_stack);
						$tag = strlen($shifted_token) == 2 ? "strong" : "em";
						$span = array_shift($text_stack);
						$span = $this->runSpanGamut($span);
						$span = "<$tag>$span</$tag>";
						$text_stack[0] .= $this->hashPart($span);
						$$tag = ''; # $$tag stands for $em or $strong
					}
				} else {
					# Reached opening three-char emphasis marker. Push on token 
					# stack; will be handled by the special condition above.
					$em = $token{0};
					$strong = "$em$em";
					array_unshift($token_stack, $token);
					array_unshift($text_stack, '');
					$tree_char_em = true;
				}
			} else if ($token_len == 2) {
				if ($strong) {
					# Unwind any dangling emphasis marker:
					if (strlen($token_stack[0]) == 1) {
						$text_stack[1] .= array_shift($token_stack);
						$text_stack[0] .= array_shift($text_stack);
					}
					# Closing strong marker:
					array_shift($token_stack);
					$span = array_shift($text_stack);
					$span = $this->runSpanGamut($span);
					$span = "<strong>$span</strong>";
					$text_stack[0] .= $this->hashPart($span);
					$strong = '';
				} else {
					array_unshift($token_stack, $token);
					array_unshift($text_stack, '');
					$strong = $token;
				}
			} else {
				# Here $token_len == 1
				if ($em) {
					if (strlen($token_stack[0]) == 1) {
						# Closing emphasis marker:
						array_shift($token_stack);
						$span = array_shift($text_stack);
						$span = $this->runSpanGamut($span);
						$span = "<em>$span</em>";
						$text_stack[0] .= $this->hashPart($span);
						$em = '';
					} else {
						$text_stack[0] .= $token;
					}
				} else {
					array_unshift($token_stack, $token);
					array_unshift($text_stack, '');
					$em = $token;
				}
			}
		}
		return $text_stack[0];
	}


	function doBlockQuotes($text) {
		$text = preg_replace_callback('/
			  (								# Wrap whole match in $1
				(?>
				  ^[ ]*>[ ]?			# ">" at the start of a line
					.+\n					# rest of the first line
				  (.+\n)*					# subsequent consecutive lines
				  \n*						# blanks
				)+
			  )
			/xm',
			array(&$this, '_doBlockQuotes_callback'), $text);

		return $text;
	}
	function _doBlockQuotes_callback($matches) {
		$bq = $matches[1];
		# trim one level of quoting - trim whitespace-only lines
		$bq = preg_replace('/^[ ]*>[ ]?|^[ ]+$/m', '', $bq);
		$bq = $this->runBlockGamut($bq);		# recurse

		$bq = preg_replace('/^/m', "  ", $bq);
		# These leading spaces cause problem with <pre> content, 
		# so we need to fix that:
		$bq = preg_replace_callback('{(\s*<pre>.+?</pre>)}sx', 
			array(&$this, '_doBlockQuotes_callback2'), $bq);

		return "\n". $this->hashBlock("<blockquote>\n$bq\n</blockquote>")."\n\n";
	}
	function _doBlockQuotes_callback2($matches) {
		$pre = $matches[1];
		$pre = preg_replace('/^  /m', '', $pre);
		return $pre;
	}


	function formParagraphs($text) {
	#
	#	Params:
	#		$text - string to process with html <p> tags
	#
		# Strip leading and trailing lines:
		$text = preg_replace('/\A\n+|\n+\z/', '', $text);

		$grafs = preg_split('/\n{2,}/', $text, -1, PREG_SPLIT_NO_EMPTY);

		#
		# Wrap <p> tags and unhashify HTML blocks
		#
		foreach ($grafs as $key => $value) {
			if (!preg_match('/^B\x1A[0-9]+B$/', $value)) {
				# Is a paragraph.
				$value = $this->runSpanGamut($value);
				$value = preg_replace('/^([ ]*)/', "<p>", $value);
				$value .= "</p>";
				$grafs[$key] = $this->unhash($value);
			}
			else {
				# Is a block.
				# Modify elements of @grafs in-place...
				$graf = $value;
				$block = $this->html_hashes[$graf];
				$graf = $block;
//				if (preg_match('{
//					\A
//					(							# $1 = <div> tag
//					  <div  \s+
//					  [^>]*
//					  \b
//					  markdown\s*=\s*  ([\'"])	#	$2 = attr quote char
//					  1
//					  \2
//					  [^>]*
//					  >
//					)
//					(							# $3 = contents
//					.*
//					)
//					(</div>)					# $4 = closing tag
//					\z
//					}xs', $block, $matches))
//				{
//					list(, $div_open, , $div_content, $div_close) = $matches;
//
//					# We can't call Markdown(), because that resets the hash;
//					# that initialization code should be pulled into its own sub, though.
//					$div_content = $this->hashHTMLBlocks($div_content);
//					
//					# Run document gamut methods on the content.
//					foreach ($this->document_gamut as $method => $priority) {
//						$div_content = $this->$method($div_content);
//					}
//
//					$div_open = preg_replace(
//						'{\smarkdown\s*=\s*([\'"]).+?\1}', '', $div_open);
//
//					$graf = $div_open . "\n" . $div_content . "\n" . $div_close;
//				}
				$grafs[$key] = $graf;
			}
		}

		return implode("\n\n", $grafs);
	}


	function encodeAttribute($text) {
	#
	# Encode text for a double-quoted HTML attribute. This function
	# is *not* suitable for attributes enclosed in single quotes.
	#
		$text = $this->encodeAmpsAndAngles($text);
		$text = str_replace('"', '&quot;', $text);
		return $text;
	}
	
	
	function encodeAmpsAndAngles($text) {
	#
	# Smart processing for ampersands and angle brackets that need to 
	# be encoded. Valid character entities are left alone unless the
	# no-entities mode is set.
	#
		if ($this->no_entities) {
			$text = str_replace('&', '&amp;', $text);
		} else {
			# Ampersand-encoding based entirely on Nat Irons's Amputator
			# MT plugin: <http://bumppo.net/projects/amputator/>
			$text = preg_replace('/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/', 
								'&amp;', $text);;
		}
		# Encode remaining <'s
		$text = str_replace('<', '&lt;', $text);

		return $text;
	}


	function doAutoLinks($text) {
		$text = preg_replace_callback('{<((https?|ftp|dict):[^\'">\s]+)>}i', 
			array(&$this, '_doAutoLinks_url_callback'), $text);

		# Email addresses: <address@domain.foo>
		$text = preg_replace_callback('{
			<
			(?:mailto:)?
			(
				(?:
					[-!#$%&\'*+/=?^_`.{|}~\w\x80-\xFF]+
				|
					".*?"
				)
				\@
				(?:
					[-a-z0-9\x80-\xFF]+(\.[-a-z0-9\x80-\xFF]+)*\.[a-z]+
				|
					\[[\d.a-fA-F:]+\]	# IPv4 & IPv6
				)
			)
			>
			}xi',
			array(&$this, '_doAutoLinks_email_callback'), $text);

		return $text;
	}
	function _doAutoLinks_url_callback($matches) {
		$url = $this->encodeAttribute($matches[1]);
		$link = "<a href=\"$url\">$url</a>";
		return $this->hashPart($link);
	}
	function _doAutoLinks_email_callback($matches) {
		$address = $matches[1];
		$link = $this->encodeEmailAddress($address);
		return $this->hashPart($link);
	}


	function encodeEmailAddress($addr) {
	#
	#	Input: an email address, e.g. "foo@example.com"
	#
	#	Output: the email address as a mailto link, with each character
	#		of the address encoded as either a decimal or hex entity, in
	#		the hopes of foiling most address harvesting spam bots. E.g.:
	#
	#	  <p><a href="&#109;&#x61;&#105;&#x6c;&#116;&#x6f;&#58;&#x66;o&#111;
	#        &#x40;&#101;&#x78;&#97;&#x6d;&#112;&#x6c;&#101;&#46;&#x63;&#111;
	#        &#x6d;">&#x66;o&#111;&#x40;&#101;&#x78;&#97;&#x6d;&#112;&#x6c;
	#        &#101;&#46;&#x63;&#111;&#x6d;</a></p>
	#
	#	Based by a filter by Matthew Wickline, posted to BBEdit-Talk.
	#   With some optimizations by Milian Wolff.
	#
		$addr = "mailto:" . $addr;
		$chars = preg_split('/(?<!^)(?!$)/', $addr);
		$seed = (int)abs(crc32($addr) / strlen($addr)); # Deterministic seed.
		
		foreach ($chars as $key => $char) {
			$ord = ord($char);
			# Ignore non-ascii chars.
			if ($ord < 128) {
				$r = ($seed * (1 + $key)) % 100; # Pseudo-random function.
				# roughly 10% raw, 45% hex, 45% dec
				# '@' *must* be encoded. I insist.
				if ($r > 90 && $char != '@') /* do nothing */;
				else if ($r < 45) $chars[$key] = '&#x'.dechex($ord).';';
				else              $chars[$key] = '&#'.$ord.';';
			}
		}
		
		$addr = implode('', $chars);
		$text = implode('', array_slice($chars, 7)); # text without `mailto:`
		$addr = "<a href=\"$addr\">$text</a>";

		return $addr;
	}


	function parseSpan($str) {
	#
	# Take the string $str and parse it into tokens, hashing embeded HTML,
	# escaped characters and handling code spans.
	#
		$output = '';
		
		$span_re = '{
				(
					\\\\'.$this->escape_chars_re.'
				|
					(?<![`\\\\])
					`+						# code span marker
			'.( $this->no_markup ? '' : '
				|
					<!--    .*?     -->		# comment
				|
					<\?.*?\?> | <%.*?%>		# processing instruction
				|
					<[/!$]?[-a-zA-Z0-9:_]+	# regular tags
					(?>
						\s
						(?>[^"\'>]+|"[^"]*"|\'[^\']*\')*
					)?
					>
			').'
				)
				}xs';

		while (1) {
			#
			# Each loop iteration seach for either the next tag, the next 
			# openning code span marker, or the next escaped character. 
			# Each token is then passed to handleSpanToken.
			#
			$parts = preg_split($span_re, $str, 2, PREG_SPLIT_DELIM_CAPTURE);
			
			# Create token from text preceding tag.
			if ($parts[0] != "") {
				$output .= $parts[0];
			}
			
			# Check if we reach the end.
			if (isset($parts[1])) {
				$output .= $this->handleSpanToken($parts[1], $parts[2]);
				$str = $parts[2];
			}
			else {
				break;
			}
		}
		
		return $output;
	}
	
	
	function handleSpanToken($token, &$str) {
	#
	# Handle $token provided by parseSpan by determining its nature and 
	# returning the corresponding value that should replace it.
	#
		switch ($token{0}) {
			case "\\":
				return $this->hashPart("&#". ord($token{1}). ";");
			case "`":
				# Search for end marker in remaining text.
				if (preg_match('/^(.*?[^`])'.preg_quote($token).'(?!`)(.*)$/sm', 
					$str, $matches))
				{
					$str = $matches[2];
					$codespan = $this->makeCodeSpan($matches[1]);
					return $this->hashPart($codespan);
				}
				return $token; // return as text since no ending marker found.
			default:
				return $this->hashPart($token);
		}
	}


	function outdent($text) {
	#
	# Remove one level of line-leading tabs or spaces
	#
		return preg_replace('/^(\t|[ ]{1,'.$this->tab_width.'})/m', '', $text);
	}


	# String length function for detab. `_initDetab` will create a function to 
	# hanlde UTF-8 if the default function does not exist.
	protected $utf8_strlen = 'mb_strlen';
	
	function detab($text) {
	#
	# Replace tabs with the appropriate amount of space.
	#
		# For each line we separate the line in blocks delemited by
		# tab characters. Then we reconstruct every line by adding the 
		# appropriate number of space between each blocks.
		
		$text = preg_replace_callback('/^.*\t.*$/m',
			array(&$this, '_detab_callback'), $text);

		return $text;
	}
	function _detab_callback($matches) {
		$line = $matches[0];
		$strlen = $this->utf8_strlen; # strlen function for UTF-8.
		
		# Split in blocks.
		$blocks = explode("\t", $line);
		# Add each blocks to the line.
		$line = $blocks[0];
		unset($blocks[0]); # Do not add first block twice.
		foreach ($blocks as $block) {
			# Calculate amount of space, insert spaces, insert block.
			$amount = $this->tab_width - 
				$strlen($line, 'UTF-8') % $this->tab_width;
			$line .= str_repeat(" ", $amount) . $block;
		}
		return $line;
	}
	function _initDetab() {
	#
	# Check for the availability of the function in the `utf8_strlen` property
	# (initially `mb_strlen`). If the function is not available, create a 
	# function that will loosely count the number of UTF-8 characters with a
	# regular expression.
	#
		if (function_exists($this->utf8_strlen)) return;
		$this->utf8_strlen = create_function('$text', 'return preg_match_all(
			"/[\\\\x00-\\\\xBF]|[\\\\xC0-\\\\xFF][\\\\x80-\\\\xBF]*/", 
			$text, $m);');
	}


	function unhash($text) {
	#
	# Swap back in all the tags hashed by _HashHTMLBlocks.
	#
		return preg_replace_callback('/(.)\x1A[0-9]+\1/', 
			array(&$this, '_unhash_callback'), $text);
	}
	function _unhash_callback($matches) {
		return $this->html_hashes[$matches[0]];
	}

}


#
# Markdown Extra Parser Class
#

class MarkdownExtra_Parser extends Markdown_Parser {

	# Prefix for footnote ids.
	protected $fn_id_prefix = "";
	
	# Optional title attribute for footnote links and backlinks.
	protected $fn_link_title = MARKDOWN_FN_LINK_TITLE;
	protected $fn_backlink_title = MARKDOWN_FN_BACKLINK_TITLE;
	
	# Optional class attribute for footnote links and backlinks.
	protected $fn_link_class = MARKDOWN_FN_LINK_CLASS;
	protected $fn_backlink_class = MARKDOWN_FN_BACKLINK_CLASS;
	
	# Predefined abbreviations.
	protected $predef_abbr = array();


	function __construct() {
	#
	# Constructor function. Initialize the parser object.
	#
		# Add extra escapable characters before parent constructor 
		# initialize the table.
		$this->escape_chars .= ':|';
		
		# Insert extra document, block, and span transformations. 
		# Parent constructor will do the sorting.
		$this->document_gamut += array(
			"doFencedCodeBlocks" => 5,
			"stripFootnotes"     => 15,
			"stripAbbreviations" => 25,
			"appendFootnotes"    => 50,
			);
		$this->block_gamut += array(
			"doFencedCodeBlocks" => 5,
			"doTables"           => 15,
			"doDefLists"         => 45,
			);
		$this->span_gamut += array(
			"doFootnotes"        => 5,
			"doAbbreviations"    => 70,
			);
		
		parent::__construct();
	}
	
	
	# Extra variables used during extra transformations.
	protected $footnotes = array();
	protected $footnotes_ordered = array();
	protected $abbr_desciptions = array();
	protected $abbr_word_re = '';
	
	# Give the current footnote number.
	protected $footnote_counter = 1;
	
	
	function setup() {
	#
	# Setting up Extra-specific variables.
	#
		parent::setup();
		
		$this->footnotes = array();
		$this->footnotes_ordered = array();
		$this->abbr_desciptions = array();
		$this->abbr_word_re = '';
		$this->footnote_counter = 1;
		
		foreach ($this->predef_abbr as $abbr_word => $abbr_desc) {
			if ($this->abbr_word_re)
				$this->abbr_word_re .= '|';
			$this->abbr_word_re .= preg_quote($abbr_word);
			$this->abbr_desciptions[$abbr_word] = trim($abbr_desc);
		}
	}
	
	function teardown() {
	#
	# Clearing Extra-specific variables.
	#
		$this->footnotes = array();
		$this->footnotes_ordered = array();
		$this->abbr_desciptions = array();
		$this->abbr_word_re = '';
		
		parent::teardown();
	}
	
	
	### HTML Block Parser ###
	
	# Tags that are always treated as block tags:
	protected $block_tags_re = 'p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|address|form|fieldset|iframe|hr|legend';
	
	# Tags treated as block tags only if the opening tag is alone on it's line:
	protected $context_block_tags_re = 'script|noscript|math|ins|del';
	
	# Tags where markdown="1" default to span mode:
	protected $contain_span_tags_re = 'p|h[1-6]|li|dd|dt|td|th|legend|address';
	
	# Tags which must not have their contents modified, no matter where 
	# they appear:
	protected $clean_tags_re = 'script|math';
	
	# Tags that do not need to be closed.
	protected $auto_close_tags_re = 'hr|img';
	

	function hashHTMLBlocks($text) {
	#
	# Hashify HTML Blocks and "clean tags".
	#
	# We only want to do this for block-level HTML tags, such as headers,
	# lists, and tables. That's because we still want to wrap <p>s around
	# "paragraphs" that are wrapped in non-block-level tags, such as anchors,
	# phrase emphasis, and spans. The list of tags we're looking for is
	# hard-coded.
	#
	# This works by calling _HashHTMLBlocks_InMarkdown, which then calls
	# _HashHTMLBlocks_InHTML when it encounter block tags. When the markdown="1" 
	# attribute is found whitin a tag, _HashHTMLBlocks_InHTML calls back
	#  _HashHTMLBlocks_InMarkdown to handle the Markdown syntax within the tag.
	# These two functions are calling each other. It's recursive!
	#
		#
		# Call the HTML-in-Markdown hasher.
		#
		list($text, ) = $this->_hashHTMLBlocks_inMarkdown($text);
		
		return $text;
	}
	function _hashHTMLBlocks_inMarkdown($text, $indent = 0, 
										$enclosing_tag_re = '', $span = false)
	{
	#
	# Parse markdown text, calling _HashHTMLBlocks_InHTML for block tags.
	#
	# *   $indent is the number of space to be ignored when checking for code 
	#     blocks. This is important because if we don't take the indent into 
	#     account, something like this (which looks right) won't work as expected:
	#
	#     <div>
	#         <div markdown="1">
	#         Hello World.  <-- Is this a Markdown code block or text?
	#         </div>  <-- Is this a Markdown code block or a real tag?
	#     <div>
	#
	#     If you don't like this, just don't indent the tag on which
	#     you apply the markdown="1" attribute.
	#
	# *   If $enclosing_tag_re is not empty, stops at the first unmatched closing 
	#     tag with that name. Nested tags supported.
	#
	# *   If $span is true, text inside must treated as span. So any double 
	#     newline will be replaced by a single newline so that it does not create 
	#     paragraphs.
	#
	# Returns an array of that form: ( processed text , remaining text )
	#
		if ($text === '') return array('', '');

		# Regex to check for the presense of newlines around a block tag.
		$newline_before_re = '/(?:^\n?|\n\n)*$/';
		$newline_after_re = 
			'{
				^						# Start of text following the tag.
				(?>[ ]*<!--.*?-->)?		# Optional comment.
				[ ]*\n					# Must be followed by newline.
			}xs';
		
		# Regex to match any tag.
		$block_tag_re =
			'{
				(					# $2: Capture hole tag.
					</?					# Any opening or closing tag.
						(?>				# Tag name.
							'.$this->block_tags_re.'			|
							'.$this->context_block_tags_re.'	|
							'.$this->clean_tags_re.'        	|
							(?!\s)'.$enclosing_tag_re.'
						)
						(?:
							(?=[\s"\'/a-zA-Z0-9])	# Allowed characters after tag name.
							(?>
								".*?"		|	# Double quotes (can contain `>`)
								\'.*?\'   	|	# Single quotes (can contain `>`)
								.+?				# Anything but quotes and `>`.
							)*?
						)?
					>					# End of tag.
				|
					<!--    .*?     -->	# HTML Comment
				|
					<\?.*?\?> | <%.*?%>	# Processing instruction
				|
					<!\[CDATA\[.*?\]\]>	# CData Block
				|
					# Code span marker
					`+
				'. ( !$span ? ' # If not in span.
				|
					# Indented code block
					(?: ^[ ]*\n | ^ | \n[ ]*\n )
					[ ]{'.($indent+4).'}[^\n]* \n
					(?>
						(?: [ ]{'.($indent+4).'}[^\n]* | [ ]* ) \n
					)*
				|
					# Fenced code block marker
					(?> ^ | \n )
					[ ]{'.($indent).'}~~~+[ ]*\n
				' : '' ). ' # End (if not is span).
				)
			}xs';

		
		$depth = 0;		# Current depth inside the tag tree.
		$parsed = "";	# Parsed text that will be returned.

		#
		# Loop through every tag until we find the closing tag of the parent
		# or loop until reaching the end of text if no parent tag specified.
		#
		do {
			#
			# Split the text using the first $tag_match pattern found.
			# Text before  pattern will be first in the array, text after
			# pattern will be at the end, and between will be any catches made 
			# by the pattern.
			#
			$parts = preg_split($block_tag_re, $text, 2, 
								PREG_SPLIT_DELIM_CAPTURE);
			
			# If in Markdown span mode, add a empty-string span-level hash 
			# after each newline to prevent triggering any block element.
			if ($span) {
				$void = $this->hashPart("", ':');
				$newline = "$void\n";
				$parts[0] = $void . str_replace("\n", $newline, $parts[0]) . $void;
			}
			
			$parsed .= $parts[0]; # Text before current tag.
			
			# If end of $text has been reached. Stop loop.
			if (count($parts) < 3) {
				$text = "";
				break;
			}
			
			$tag  = $parts[1]; # Tag to handle.
			$text = $parts[2]; # Remaining text after current tag.
			$tag_re = preg_quote($tag); # For use in a regular expression.
			
			#
			# Check for: Code span marker
			#
			if ($tag{0} == "`") {
				# Find corresponding end marker.
				$tag_re = preg_quote($tag);
				if (preg_match('{^(?>.+?|\n(?!\n))*?(?<!`)'.$tag_re.'(?!`)}',
					$text, $matches))
				{
					# End marker found: pass text unchanged until marker.
					$parsed .= $tag . $matches[0];
					$text = substr($text, strlen($matches[0]));
				}
				else {
					# Unmatched marker: just skip it.
					$parsed .= $tag;
				}
			}
			#
			# Check for: Indented code block.
			#
			else if ($tag{0} == "\n" || $tag{0} == " ") {
				# Indented code block: pass it unchanged, will be handled 
				# later.
				$parsed .= $tag;
			}
			#
			# Check for: Fenced code block marker.
			#
			else if ($tag{0} == "~") {
				# Fenced code block marker: find matching end marker.
				$tag_re = preg_quote(trim($tag));
				if (preg_match('{^(?>.*\n)+?'.$tag_re.' *\n}', $text, 
					$matches)) 
				{
					# End marker found: pass text unchanged until marker.
					$parsed .= $tag . $matches[0];
					$text = substr($text, strlen($matches[0]));
				}
				else {
					# No end marker: just skip it.
					$parsed .= $tag;
				}
			}
			#
			# Check for: Opening Block level tag or
			#            Opening Context Block tag (like ins and del) 
			#               used as a block tag (tag is alone on it's line).
			#
			else if (preg_match('{^<(?:'.$this->block_tags_re.')\b}', $tag) ||
				(	preg_match('{^<(?:'.$this->context_block_tags_re.')\b}', $tag) &&
					preg_match($newline_before_re, $parsed) &&
					preg_match($newline_after_re, $text)	)
				)
			{
				# Need to parse tag and following text using the HTML parser.
				list($block_text, $text) = 
					$this->_hashHTMLBlocks_inHTML($tag . $text, "hashBlock", true);
				
				# Make sure it stays outside of any paragraph by adding newlines.
				$parsed .= "\n\n$block_text\n\n";
			}
			#
			# Check for: Clean tag (like script, math)
			#            HTML Comments, processing instructions.
			#
			else if (preg_match('{^<(?:'.$this->clean_tags_re.')\b}', $tag) ||
				$tag{1} == '!' || $tag{1} == '?')
			{
				# Need to parse tag and following text using the HTML parser.
				# (don't check for markdown attribute)
				list($block_text, $text) = 
					$this->_hashHTMLBlocks_inHTML($tag . $text, "hashClean", false);
				
				$parsed .= $block_text;
			}
			#
			# Check for: Tag with same name as enclosing tag.
			#
			else if ($enclosing_tag_re !== '' &&
				# Same name as enclosing tag.
				preg_match('{^</?(?:'.$enclosing_tag_re.')\b}', $tag))
			{
				#
				# Increase/decrease nested tag count.
				#
				if ($tag{1} == '/')						$depth--;
				else if ($tag{strlen($tag)-2} != '/')	$depth++;

				if ($depth < 0) {
					#
					# Going out of parent element. Clean up and break so we
					# return to the calling function.
					#
					$text = $tag . $text;
					break;
				}
				
				$parsed .= $tag;
			}
			else {
				$parsed .= $tag;
			}
		} while ($depth >= 0);
		
		return array($parsed, $text);
	}
	function _hashHTMLBlocks_inHTML($text, $hash_method, $md_attr) {
	#
	# Parse HTML, calling _HashHTMLBlocks_InMarkdown for block tags.
	#
	# *   Calls $hash_method to convert any blocks.
	# *   Stops when the first opening tag closes.
	# *   $md_attr indicate if the use of the `markdown="1"` attribute is allowed.
	#     (it is not inside clean tags)
	#
	# Returns an array of that form: ( processed text , remaining text )
	#
		if ($text === '') return array('', '');
		
		# Regex to match `markdown` attribute inside of a tag.
		$markdown_attr_re = '
			{
				\s*			# Eat whitespace before the `markdown` attribute
				markdown
				\s*=\s*
				(?>
					(["\'])		# $1: quote delimiter		
					(.*?)		# $2: attribute value
					\1			# matching delimiter	
				|
					([^\s>]*)	# $3: unquoted attribute value
				)
				()				# $4: make $3 always defined (avoid warnings)
			}xs';
		
		# Regex to match any tag.
		$tag_re = '{
				(					# $2: Capture hole tag.
					</?					# Any opening or closing tag.
						[\w:$]+			# Tag name.
						(?:
							(?=[\s"\'/a-zA-Z0-9])	# Allowed characters after tag name.
							(?>
								".*?"		|	# Double quotes (can contain `>`)
								\'.*?\'   	|	# Single quotes (can contain `>`)
								.+?				# Anything but quotes and `>`.
							)*?
						)?
					>					# End of tag.
				|
					<!--    .*?     -->	# HTML Comment
				|
					<\?.*?\?> | <%.*?%>	# Processing instruction
				|
					<!\[CDATA\[.*?\]\]>	# CData Block
				)
			}xs';
		
		$original_text = $text;		# Save original text in case of faliure.
		
		$depth		= 0;	# Current depth inside the tag tree.
		$block_text	= "";	# Temporary text holder for current text.
		$parsed		= "";	# Parsed text that will be returned.

		#
		# Get the name of the starting tag.
		# (This pattern makes $base_tag_name_re safe without quoting.)
		#
		if (preg_match('/^<([\w:$]*)\b/', $text, $matches))
			$base_tag_name_re = $matches[1];

		#
		# Loop through every tag until we find the corresponding closing tag.
		#
		do {
			#
			# Split the text using the first $tag_match pattern found.
			# Text before  pattern will be first in the array, text after
			# pattern will be at the end, and between will be any catches made 
			# by the pattern.
			#
			$parts = preg_split($tag_re, $text, 2, PREG_SPLIT_DELIM_CAPTURE);
			
			if (count($parts) < 3) {
				#
				# End of $text reached with unbalenced tag(s).
				# In that case, we return original text unchanged and pass the
				# first character as filtered to prevent an infinite loop in the 
				# parent function.
				#
				return array($original_text{0}, substr($original_text, 1));
			}
			
			$block_text .= $parts[0]; # Text before current tag.
			$tag         = $parts[1]; # Tag to handle.
			$text        = $parts[2]; # Remaining text after current tag.
			
			#
			# Check for: Auto-close tag (like <hr/>)
			#			 Comments and Processing Instructions.
			#
			if (preg_match('{^</?(?:'.$this->auto_close_tags_re.')\b}', $tag) ||
				$tag{1} == '!' || $tag{1} == '?')
			{
				# Just add the tag to the block as if it was text.
				$block_text .= $tag;
			}
			else {
				#
				# Increase/decrease nested tag count. Only do so if
				# the tag's name match base tag's.
				#
				if (preg_match('{^</?'.$base_tag_name_re.'\b}', $tag)) {
					if ($tag{1} == '/')						$depth--;
					else if ($tag{strlen($tag)-2} != '/')	$depth++;
				}
				
				#
				# Check for `markdown="1"` attribute and handle it.
				#
				if ($md_attr && 
					preg_match($markdown_attr_re, $tag, $attr_m) &&
					preg_match('/^1|block|span$/', $attr_m[2] . $attr_m[3]))
				{
					# Remove `markdown` attribute from opening tag.
					$tag = preg_replace($markdown_attr_re, '', $tag);
					
					# Check if text inside this tag must be parsed in span mode.
					$this->mode = $attr_m[2] . $attr_m[3];
					$span_mode = $this->mode == 'span' || $this->mode != 'block' &&
						preg_match('{^<(?:'.$this->contain_span_tags_re.')\b}', $tag);
					
					# Calculate indent before tag.
					if (preg_match('/(?:^|\n)( *?)(?! ).*?$/', $block_text, $matches)) {
						$strlen = $this->utf8_strlen;
						$indent = $strlen($matches[1], 'UTF-8');
					} else {
						$indent = 0;
					}
					
					# End preceding block with this tag.
					$block_text .= $tag;
					$parsed .= $this->$hash_method($block_text);
					
					# Get enclosing tag name for the ParseMarkdown function.
					# (This pattern makes $tag_name_re safe without quoting.)
					preg_match('/^<([\w:$]*)\b/', $tag, $matches);
					$tag_name_re = $matches[1];
					
					# Parse the content using the HTML-in-Markdown parser.
					list ($block_text, $text)
						= $this->_hashHTMLBlocks_inMarkdown($text, $indent, 
							$tag_name_re, $span_mode);
					
					# Outdent markdown text.
					if ($indent > 0) {
						$block_text = preg_replace("/^[ ]{1,$indent}/m", "", 
													$block_text);
					}
					
					# Append tag content to parsed text.
					if (!$span_mode)	$parsed .= "\n\n$block_text\n\n";
					else				$parsed .= "$block_text";
					
					# Start over a new block.
					$block_text = "";
				}
				else $block_text .= $tag;
			}
			
		} while ($depth > 0);
		
		#
		# Hash last block text that wasn't processed inside the loop.
		#
		$parsed .= $this->$hash_method($block_text);
		
		return array($parsed, $text);
	}


	function hashClean($text) {
	#
	# Called whenever a tag must be hashed when a function insert a "clean" tag
	# in $text, it pass through this function and is automaticaly escaped, 
	# blocking invalid nested overlap.
	#
		return $this->hashPart($text, 'C');
	}


	function doHeaders($text) {
	#
	# Redefined to add id attribute support.
	#
		# Setext-style headers:
		#	  Header 1  {#header1}
		#	  ========
		#  
		#	  Header 2  {#header2}
		#	  --------
		#
		$text = preg_replace_callback(
			'{
				(^.+?)								# $1: Header text
				(?:[ ]+\{\#([-_:a-zA-Z0-9]+)\})?	# $2: Id attribute
				[ ]*\n(=+|-+)[ ]*\n+				# $3: Header footer
			}mx',
			array(&$this, '_doHeaders_callback_setext'), $text);

		# atx-style headers:
		#	# Header 1        {#header1}
		#	## Header 2       {#header2}
		#	## Header 2 with closing hashes ##  {#header3}
		#	...
		#	###### Header 6   {#header2}
		#
		$text = preg_replace_callback('{
				^(\#{1,6})	# $1 = string of #\'s
				[ ]*
				(.+?)		# $2 = Header text
				[ ]*
				\#*			# optional closing #\'s (not counted)
				(?:[ ]+\{\#([-_:a-zA-Z0-9]+)\})? # id attribute
				[ ]*
				\n+
			}xm',
			array(&$this, '_doHeaders_callback_atx'), $text);

		return $text;
	}
	function _doHeaders_attr($attr) {
		if (empty($attr))  return "";
		return " id=\"$attr\"";
	}
	function _doHeaders_callback_setext($matches) {
		if ($matches[3] == '-' && preg_match('{^- }', $matches[1]))
			return $matches[0];
		$level = $matches[3]{0} == '=' ? 1 : 2;
		$attr  = $this->_doHeaders_attr($id =& $matches[2]);
		$block = "<h$level$attr>".$this->runSpanGamut($matches[1])."</h$level>";
		return "\n" . $this->hashBlock($block) . "\n\n";
	}
	function _doHeaders_callback_atx($matches) {
		$level = strlen($matches[1]);
		$attr  = $this->_doHeaders_attr($id =& $matches[3]);
		$block = "<h$level$attr>".$this->runSpanGamut($matches[2])."</h$level>";
		return "\n" . $this->hashBlock($block) . "\n\n";
	}


	function doTables($text) {
	#
	# Form HTML tables.
	#
		$less_than_tab = $this->tab_width - 1;
		#
		# Find tables with leading pipe.
		#
		#	| Header 1 | Header 2
		#	| -------- | --------
		#	| Cell 1   | Cell 2
		#	| Cell 3   | Cell 4
		#
		$text = preg_replace_callback('
			{
				^							# Start of a line
				[ ]{0,'.$less_than_tab.'}	# Allowed whitespace.
				[|]							# Optional leading pipe (present)
				(.+) \n						# $1: Header row (at least one pipe)
				
				[ ]{0,'.$less_than_tab.'}	# Allowed whitespace.
				[|] ([ ]*[-:]+[-| :]*) \n	# $2: Header underline
				
				(							# $3: Cells
					(?>
						[ ]*				# Allowed whitespace.
						[|] .* \n			# Row content.
					)*
				)
				(?=\n|\Z)					# Stop at final double newline.
			}xm',
			array(&$this, '_doTable_leadingPipe_callback'), $text);
		
		#
		# Find tables without leading pipe.
		#
		#	Header 1 | Header 2
		#	-------- | --------
		#	Cell 1   | Cell 2
		#	Cell 3   | Cell 4
		#
		$text = preg_replace_callback('
			{
				^							# Start of a line
				[ ]{0,'.$less_than_tab.'}	# Allowed whitespace.
				(\S.*[|].*) \n				# $1: Header row (at least one pipe)
				
				[ ]{0,'.$less_than_tab.'}	# Allowed whitespace.
				([-:]+[ ]*[|][-| :]*) \n	# $2: Header underline
				
				(							# $3: Cells
					(?>
						.* [|] .* \n		# Row content
					)*
				)
				(?=\n|\Z)					# Stop at final double newline.
			}xm',
			array(&$this, '_DoTable_callback'), $text);

		return $text;
	}
	function _doTable_leadingPipe_callback($matches) {
		$head		= $matches[1];
		$underline	= $matches[2];
		$content	= $matches[3];
		
		# Remove leading pipe for each row.
		$content	= preg_replace('/^ *[|]/m', '', $content);
		
		return $this->_doTable_callback(array($matches[0], $head, $underline, $content));
	}
	function _doTable_callback($matches) {
		$head		= $matches[1];
		$underline	= $matches[2];
		$content	= $matches[3];

		# Remove any tailing pipes for each line.
		$head		= preg_replace('/[|] *$/m', '', $head);
		$underline	= preg_replace('/[|] *$/m', '', $underline);
		$content	= preg_replace('/[|] *$/m', '', $content);
		
		# Reading alignement from header underline.
		$separators	= preg_split('/ *[|] */', $underline);
		foreach ($separators as $n => $s) {
			if (preg_match('/^ *-+: *$/', $s))		$attr[$n] = ' align="right"';
			else if (preg_match('/^ *:-+: *$/', $s))$attr[$n] = ' align="center"';
			else if (preg_match('/^ *:-+ *$/', $s))	$attr[$n] = ' align="left"';
			else									$attr[$n] = '';
		}
		
		# Parsing span elements, including code spans, character escapes, 
		# and inline HTML tags, so that pipes inside those gets ignored.
		$head		= $this->parseSpan($head);
		$headers	= preg_split('/ *[|] */', $head);
		$col_count	= count($headers);
		
		# Write column headers.
		$text = "<table>\n";
		$text .= "<thead>\n";
		$text .= "<tr>\n";
		foreach ($headers as $n => $header)
			$text .= "  <th$attr[$n]>".$this->runSpanGamut(trim($header))."</th>\n";
		$text .= "</tr>\n";
		$text .= "</thead>\n";
		
		# Split content by row.
		$rows = explode("\n", trim($content, "\n"));
		
		$text .= "<tbody>\n";
		foreach ($rows as $row) {
			# Parsing span elements, including code spans, character escapes, 
			# and inline HTML tags, so that pipes inside those gets ignored.
			$row = $this->parseSpan($row);
			
			# Split row by cell.
			$row_cells = preg_split('/ *[|] */', $row, $col_count);
			$row_cells = array_pad($row_cells, $col_count, '');
			
			$text .= "<tr>\n";
			foreach ($row_cells as $n => $cell)
				$text .= "  <td$attr[$n]>".$this->runSpanGamut(trim($cell))."</td>\n";
			$text .= "</tr>\n";
		}
		$text .= "</tbody>\n";
		$text .= "</table>";
		
		return $this->hashBlock($text) . "\n";
	}

	
	function doDefLists($text) {
	#
	# Form HTML definition lists.
	#
		$less_than_tab = $this->tab_width - 1;

		# Re-usable pattern to match any entire dl list:
		$whole_list_re = '(?>
			(								# $1 = whole list
			  (								# $2
				[ ]{0,'.$less_than_tab.'}
				((?>.*\S.*\n)+)				# $3 = defined term
				\n?
				[ ]{0,'.$less_than_tab.'}:[ ]+ # colon starting definition
			  )
			  (?s:.+?)
			  (								# $4
				  \z
				|
				  \n{2,}
				  (?=\S)
				  (?!						# Negative lookahead for another term
					[ ]{0,'.$less_than_tab.'}
					(?: \S.*\n )+?			# defined term
					\n?
					[ ]{0,'.$less_than_tab.'}:[ ]+ # colon starting definition
				  )
				  (?!						# Negative lookahead for another definition
					[ ]{0,'.$less_than_tab.'}:[ ]+ # colon starting definition
				  )
			  )
			)
		)'; // mx

		$text = preg_replace_callback('{
				(?>\A\n?|(?<=\n\n))
				'.$whole_list_re.'
			}mx',
			array(&$this, '_doDefLists_callback'), $text);

		return $text;
	}
	function _doDefLists_callback($matches) {
		# Re-usable patterns to match list item bullets and number markers:
		$list = $matches[1];
		
		# Turn double returns into triple returns, so that we can make a
		# paragraph for the last item in a list, if necessary:
		$result = trim($this->processDefListItems($list));
		$result = "<dl>\n" . $result . "\n</dl>";
		return $this->hashBlock($result) . "\n\n";
	}


	function processDefListItems($list_str) {
	#
	#	Process the contents of a single definition list, splitting it
	#	into individual term and definition list items.
	#
		$less_than_tab = $this->tab_width - 1;
		
		# trim trailing blank lines:
		$list_str = preg_replace("/\n{2,}\\z/", "\n", $list_str);

		# Process definition terms.
		$list_str = preg_replace_callback('{
			(?>\A\n?|\n\n+)					# leading line
			(								# definition terms = $1
				[ ]{0,'.$less_than_tab.'}	# leading whitespace
				(?![:][ ]|[ ])				# negative lookahead for a definition 
											#   mark (colon) or more whitespace.
				(?> \S.* \n)+?				# actual term (not whitespace).	
			)			
			(?=\n?[ ]{0,3}:[ ])				# lookahead for following line feed 
											#   with a definition mark.
			}xm',
			array(&$this, '_processDefListItems_callback_dt'), $list_str);

		# Process actual definitions.
		$list_str = preg_replace_callback('{
			\n(\n+)?						# leading line = $1
			(								# marker space = $2
				[ ]{0,'.$less_than_tab.'}	# whitespace before colon
				[:][ ]+						# definition mark (colon)
			)
			((?s:.+?))						# definition text = $3
			(?= \n+ 						# stop at next definition mark,
				(?:							# next term or end of text
					[ ]{0,'.$less_than_tab.'} [:][ ]	|
					<dt> | \z
				)						
			)					
			}xm',
			array(&$this, '_processDefListItems_callback_dd'), $list_str);

		return $list_str;
	}
	function _processDefListItems_callback_dt($matches) {
		$terms = explode("\n", trim($matches[1]));
		$text = '';
		foreach ($terms as $term) {
			$term = $this->runSpanGamut(trim($term));
			$text .= "\n<dt>" . $term . "</dt>";
		}
		return $text . "\n";
	}
	function _processDefListItems_callback_dd($matches) {
		$leading_line	= $matches[1];
		$marker_space	= $matches[2];
		$def			= $matches[3];

		if ($leading_line || preg_match('/\n{2,}/', $def)) {
			# Replace marker with the appropriate whitespace indentation
			$def = str_repeat(' ', strlen($marker_space)) . $def;
			$def = $this->runBlockGamut($this->outdent($def . "\n\n"));
			$def = "\n". $def ."\n";
		}
		else {
			$def = rtrim($def);
			$def = $this->runSpanGamut($this->outdent($def));
		}

		return "\n<dd>" . $def . "</dd>\n";
	}


	function doFencedCodeBlocks($text) {
	#
	# Adding the fenced code block syntax to regular Markdown:
	#
	# ~~~
	# Code block
	# ~~~
	#
		$less_than_tab = $this->tab_width;
		
		$text = preg_replace_callback('{
				(?:\n|\A)
				# 1: Opening marker
				(
					~{3,} # Marker: three tilde or more.
				)
				[ ]* \n # Whitespace and newline following marker.
				
				# 2: Content
				(
					(?>
						(?!\1 [ ]* \n)	# Not a closing marker.
						.*\n+
					)+
				)
				
				# Closing marker.
				\1 [ ]* \n
			}xm',
			array(&$this, '_doFencedCodeBlocks_callback'), $text);

		return $text;
	}
	function _doFencedCodeBlocks_callback($matches) {
		$codeblock = $matches[2];
		$codeblock = htmlspecialchars($codeblock, ENT_NOQUOTES);
		$codeblock = preg_replace_callback('/^\n+/',
			array(&$this, '_doFencedCodeBlocks_newlines'), $codeblock);
		$codeblock = "<pre><code>$codeblock</code></pre>";
		return "\n\n".$this->hashBlock($codeblock)."\n\n";
	}
	function _doFencedCodeBlocks_newlines($matches) {
		return str_repeat("<br$this->empty_element_suffix", 
			strlen($matches[0]));
	}


	#
	# Redefining emphasis markers so that emphasis by underscore does not
	# work in the middle of a word.
	#
	protected $em_relist = array(
		''  => '(?:(?<!\*)\*(?!\*)|(?<![a-zA-Z0-9_])_(?!_))(?=\S|$)(?![.,:;]\s)',
		'*' => '(?<=\S|^)(?<!\*)\*(?!\*)',
		'_' => '(?<=\S|^)(?<!_)_(?![a-zA-Z0-9_])',
		);
	protected $strong_relist = array(
		''   => '(?:(?<!\*)\*\*(?!\*)|(?<![a-zA-Z0-9_])__(?!_))(?=\S|$)(?![.,:;]\s)',
		'**' => '(?<=\S|^)(?<!\*)\*\*(?!\*)',
		'__' => '(?<=\S|^)(?<!_)__(?![a-zA-Z0-9_])',
		);
	protected $em_strong_relist = array(
		''    => '(?:(?<!\*)\*\*\*(?!\*)|(?<![a-zA-Z0-9_])___(?!_))(?=\S|$)(?![.,:;]\s)',
		'***' => '(?<=\S|^)(?<!\*)\*\*\*(?!\*)',
		'___' => '(?<=\S|^)(?<!_)___(?![a-zA-Z0-9_])',
		);


	function formParagraphs($text) {
	#
	#	Params:
	#		$text - string to process with html <p> tags
	#
		# Strip leading and trailing lines:
		$text = preg_replace('/\A\n+|\n+\z/', '', $text);
		
		$grafs = preg_split('/\n{2,}/', $text, -1, PREG_SPLIT_NO_EMPTY);

		#
		# Wrap <p> tags and unhashify HTML blocks
		#
		foreach ($grafs as $key => $value) {
			$value = trim($this->runSpanGamut($value));
			
			# Check if this should be enclosed in a paragraph.
			# Clean tag hashes & block tag hashes are left alone.
			$is_p = !preg_match('/^B\x1A[0-9]+B|^C\x1A[0-9]+C$/', $value);
			
			if ($is_p) {
				$value = "<p>$value</p>";
			}
			$grafs[$key] = $value;
		}
		
		# Join grafs in one text, then unhash HTML tags. 
		$text = implode("\n\n", $grafs);
		
		# Finish by removing any tag hashes still present in $text.
		$text = $this->unhash($text);
		
		return $text;
	}
	
	
	### Footnotes
	
	function stripFootnotes($text) {
	#
	# Strips link definitions from text, stores the URLs and titles in
	# hash references.
	#
		$less_than_tab = $this->tab_width - 1;

		# Link defs are in the form: [^id]: url "optional title"
		$text = preg_replace_callback('{
			^[ ]{0,'.$less_than_tab.'}\[\^(.+?)\][ ]?:	# note_id = $1
			  [ ]*
			  \n?					# maybe *one* newline
			(						# text = $2 (no blank lines allowed)
				(?:					
					.+				# actual text
				|
					\n				# newlines but 
					(?!\[\^.+?\]:\s)# negative lookahead for footnote marker.
					(?!\n+[ ]{0,3}\S)# ensure line is not blank and followed 
									# by non-indented content
				)*
			)		
			}xm',
			array(&$this, '_stripFootnotes_callback'),
			$text);
		return $text;
	}
	function _stripFootnotes_callback($matches) {
		$note_id = $this->fn_id_prefix . $matches[1];
		$this->footnotes[$note_id] = $this->outdent($matches[2]);
		return ''; # String that will replace the block
	}


	function doFootnotes($text) {
	#
	# Replace footnote references in $text [^id] with a special text-token 
	# which will be replaced by the actual footnote marker in appendFootnotes.
	#
		if (!$this->in_anchor) {
			$text = preg_replace('{\[\^(.+?)\]}', "F\x1Afn:\\1\x1A:", $text);
		}
		return $text;
	}

	
	function appendFootnotes($text) {
	#
	# Append footnote list to text.
	#
		$text = preg_replace_callback('{F\x1Afn:(.*?)\x1A:}', 
			array(&$this, '_appendFootnotes_callback'), $text);
	
		if (!empty($this->footnotes_ordered)) {
			$text .= "\n\n";
			$text .= "<div class=\"footnotes\">\n";
			$text .= "<hr". $this->empty_element_suffix ."\n";
			$text .= "<ol>\n\n";
			
			$attr = " rev=\"footnote\"";
			if ($this->fn_backlink_class != "") {
				$class = $this->fn_backlink_class;
				$class = $this->encodeAttribute($class);
				$attr .= " class=\"$class\"";
			}
			if ($this->fn_backlink_title != "") {
				$title = $this->fn_backlink_title;
				$title = $this->encodeAttribute($title);
				$attr .= " title=\"$title\"";
			}
			$num = 0;
			
			while (!empty($this->footnotes_ordered)) {
				$footnote = reset($this->footnotes_ordered);
				$note_id = key($this->footnotes_ordered);
				unset($this->footnotes_ordered[$note_id]);
				
				$footnote .= "\n"; # Need to append newline before parsing.
				$footnote = $this->runBlockGamut("$footnote\n");				
				$footnote = preg_replace_callback('{F\x1Afn:(.*?)\x1A:}', 
					array(&$this, '_appendFootnotes_callback'), $footnote);
				
				$attr = str_replace("%%", ++$num, $attr);
				$note_id = $this->encodeAttribute($note_id);
				
				# Add backlink to last paragraph; create new paragraph if needed.
				$backlink = "<a href=\"#fnref:$note_id\"$attr>&#8617;</a>";
				if (preg_match('{</p>$}', $footnote)) {
					$footnote = substr($footnote, 0, -4) . "&#160;$backlink</p>";
				} else {
					$footnote .= "\n\n<p>$backlink</p>";
				}
				
				$text .= "<li id=\"fn:$note_id\">\n";
				$text .= $footnote . "\n";
				$text .= "</li>\n\n";
			}
			
			$text .= "</ol>\n";
			$text .= "</div>";
		}
		return $text;
	}
	function _appendFootnotes_callback($matches) {
		$node_id = $this->fn_id_prefix . $matches[1];
		
		# Create footnote marker only if it has a corresponding footnote *and*
		# the footnote hasn't been used by another marker.
		if (isset($this->footnotes[$node_id])) {
			# Transfert footnote content to the ordered list.
			$this->footnotes_ordered[$node_id] = $this->footnotes[$node_id];
			unset($this->footnotes[$node_id]);
			
			$num = $this->footnote_counter++;
			$attr = " rel=\"footnote\"";
			if ($this->fn_link_class != "") {
				$class = $this->fn_link_class;
				$class = $this->encodeAttribute($class);
				$attr .= " class=\"$class\"";
			}
			if ($this->fn_link_title != "") {
				$title = $this->fn_link_title;
				$title = $this->encodeAttribute($title);
				$attr .= " title=\"$title\"";
			}
			
			$attr = str_replace("%%", $num, $attr);
			$node_id = $this->encodeAttribute($node_id);
			
			return
				"<sup id=\"fnref:$node_id\">".
				"<a href=\"#fn:$node_id\"$attr>$num</a>".
				"</sup>";
		}
		
		return "[^".$matches[1]."]";
	}
		
	
	### Abbreviations ###
	
	function stripAbbreviations($text) {
	#
	# Strips abbreviations from text, stores titles in hash references.
	#
		$less_than_tab = $this->tab_width - 1;

		# Link defs are in the form: [id]*: url "optional title"
		$text = preg_replace_callback('{
			^[ ]{0,'.$less_than_tab.'}\*\[(.+?)\][ ]?:	# abbr_id = $1
			(.*)					# text = $2 (no blank lines allowed)	
			}xm',
			array(&$this, '_stripAbbreviations_callback'),
			$text);
		return $text;
	}
	function _stripAbbreviations_callback($matches) {
		$abbr_word = $matches[1];
		$abbr_desc = $matches[2];
		if ($this->abbr_word_re)
			$this->abbr_word_re .= '|';
		$this->abbr_word_re .= preg_quote($abbr_word);
		$this->abbr_desciptions[$abbr_word] = trim($abbr_desc);
		return ''; # String that will replace the block
	}
	
	
	function doAbbreviations($text) {
	#
	# Find defined abbreviations in text and wrap them in <abbr> elements.
	#
		if ($this->abbr_word_re) {
			// cannot use the /x modifier because abbr_word_re may 
			// contain significant spaces:
			$text = preg_replace_callback('{'.
				'(?<![\w\x1A])'.
				'(?:'.$this->abbr_word_re.')'.
				'(?![\w\x1A])'.
				'}', 
				array(&$this, '_doAbbreviations_callback'), $text);
		}
		return $text;
	}
	function _doAbbreviations_callback($matches) {
		$abbr = $matches[0];
		if (isset($this->abbr_desciptions[$abbr])) {
			$desc = $this->abbr_desciptions[$abbr];
			if (empty($desc)) {
				return $this->hashPart("<abbr>$abbr</abbr>");
			} else {
				$desc = $this->encodeAttribute($desc);
				return $this->hashPart("<abbr title=\"$desc\">$abbr</abbr>");
			}
		} else {
			return $matches[0];
		}
	}

}


/*

PHP Markdown Extra
==================

Description
-----------

This is a PHP port of the original Markdown formatter written in Perl 
by John Gruber. This special "Extra" version of PHP Markdown features 
further enhancements to the syntax for making additional constructs 
such as tables and definition list.

Markdown is a text-to-HTML filter; it translates an easy-to-read /
easy-to-write structured text format into HTML. Markdown's text format
is most similar to that of plain text email, and supports features such
as headers, *emphasis*, code blocks, blockquotes, and links.

Markdown's syntax is designed not as a generic markup language, but
specifically to serve as a front-end to (X)HTML. You can use span-level
HTML tags anywhere in a Markdown document, and you can use block level
HTML tags (like <div> and <table> as well).

For more information about Markdown's syntax, see:

<http://daringfireball.net/projects/markdown/>


Bugs
----

To file bug reports please send email to:

<michel.fortin@michelf.com>

Please include with your report: (1) the example input; (2) the output you
expected; (3) the output Markdown actually produced.


Version History
--------------- 

See the readme file for detailed release notes for this version.


Copyright and License
---------------------

PHP Markdown & Extra  
Copyright (c) 2004-2009 Michel Fortin  
<http://michelf.com/>  
All rights reserved.

Based on Markdown  
Copyright (c) 2003-2006 John Gruber   
<http://daringfireball.net/>   
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

*	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

*	Neither the name "Markdown" nor the names of its contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

This software is provided by the copyright holders and contributors "as
is" and any express or implied warranties, including, but not limited
to, the implied warranties of merchantability and fitness for a
particular purpose are disclaimed. In no event shall the copyright owner
or contributors be liable for any direct, indirect, incidental, special,
exemplary, or consequential damages (including, but not limited to,
procurement of substitute goods or services; loss of use, data, or
profits; or business interruption) however caused and on any theory of
liability, whether in contract, strict liability, or tort (including
negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.

*/
?>'''), STRIP_PHPDOC)

def make_textile_module(work):
    write(os.path.join(work, 'modules', 'textile.php'), R'''<?php
/**
 * Textile Module 1.0 for Pragwork %s
 *
 * @copyright Dean Allen <dean@textism.com> (Textile), %s (Module)
 * @license BSD
 * @version %s
 * @package Textile
 */
''' % (__pragwork_version__, __author__, __pragwork_version__) 
    + __strip_phpdoc(R'''
/*
_____________
T E X T I L E

A Humane Web Text Generator

Version 2.0

Copyright (c) 2003-2004, Dean Allen <dean@textism.com>
All rights reserved.

Thanks to Carlo Zottmann <carlo@g-blog.net> for refactoring
Textile's procedural code into a class framework

Additions and fixes Copyright (c) 2006 Alex Shiels http://thresholdstate.com/

Code updates to PHP 5.3, Pragwork standards and the list 
formating bugfix (provided by Aurelien Antoine (http://ilpleut.be/doku.php)) 
applied by (c) 2009 Szymon Wrozynski

Image fixes by (c) 2010 Szymon Wrozynski

_____________
L I C E N S E

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name Textile nor the names of its contributors may be used to
  endorse or promote products derived from this software without specific
  prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

/**
_________
U S A G E

Block modifier syntax:

    Header: h(1-6).
    Paragraphs beginning with 'hn. ' (where n is 1-6) are wrapped in header tags.
    Example: h1. Header... -> <h1>Header...</h1>

    Paragraph: p. (also applied by default)
    Example: p. Text -> <p>Text</p>

    Blockquote: bq.
    Example: bq. Block quotation... -> <blockquote>Block quotation...</blockquote>

    Blockquote with citation: bq.:http://citation.url
    Example: bq.:http://textism.com/ Text...
    ->  <blockquote cite="http://textism.com">Text...</blockquote>

    Footnote: fn(1-100).
    Example: fn1. Footnote... -> <p id="fn1">Footnote...</p>

    Numeric list: #, ##
    Consecutive paragraphs beginning with # are wrapped in ordered list tags.
    Example: <ol><li>ordered list</li></ol>

    Bulleted list: *, **
    Consecutive paragraphs beginning with * are wrapped in unordered list tags.
    Example: <ul><li>unordered list</li></ul>

Phrase modifier syntax:

           _emphasis_   ->   <em>emphasis</em>
           __italic__   ->   <i>italic</i>
             *strong*   ->   <strong>strong</strong>
             **bold**   ->   <b>bold</b>
         ??citation??   ->   <cite>citation</cite>
       -deleted text-   ->   <del>deleted</del>
      +inserted text+   ->   <ins>inserted</ins>
        ^superscript^   ->   <sup>superscript</sup>
          ~subscript~   ->   <sub>subscript</sub>
               @code@   ->   <code>computer code</code>
          %(bob)span%   ->   <span class="bob">span</span>

        ==notextile==   ->   leave text alone (do not format)

       "linktext":url   ->   <a href="url">linktext</a>
 "linktext(title)":url  ->   <a href="url" title="title">linktext</a>

           !imageurl!   ->   <img src="imageurl" />
  !imageurl(alt text)!  ->   <img src="imageurl" alt="alt text" />
    !imageurl!:linkurl  ->   <a href="linkurl"><img src="imageurl" /></a>

ABC(Always Be Closing)  ->   <acronym title="Always Be Closing">ABC</acronym>


Table syntax:

    Simple tables:

        |a|simple|table|row|
        |And|Another|table|row|

        |_. A|_. table|_. header|_.row|
        |A|simple|table|row|

    Tables with attributes:

        table{border:1px solid black}.
        {background:#ddd;color:red}. |{}| | | |


Applying Attributes:

    Most anywhere Textile code is used, attributes such as arbitrary css style,
    css classes, and ids can be applied. The syntax is fairly consistent.

    The following characters quickly alter the alignment of block elements:

        <  ->  left align    ex. p<. left-aligned para
        >  ->  right align       h3>. right-aligned header 3
        =  ->  centred           h4=. centred header 4
        <> ->  justified         p<>. justified paragraph

    These will change vertical alignment in table cells:

        ^  ->  top         ex. |^. top-aligned table cell|
        -  ->  middle          |-. middle aligned|
        ~  ->  bottom          |~. bottom aligned cell|

    Plain (parentheses) inserted between block syntax and the closing dot-space
    indicate classes and ids:

        p(hector). paragraph -> <p class="hector">paragraph</p>

        p(#fluid). paragraph -> <p id="fluid">paragraph</p>

        (classes and ids can be combined)
        p(hector#fluid). paragraph -> <p class="hector" id="fluid">paragraph</p>

    Curly {brackets} insert arbitrary css style

        p{line-height:18px}. paragraph -> <p style="line-height:18px">paragraph</p>

        h3{color:red}. header 3 -> <h3 style="color:red">header 3</h3>

    Square [brackets] insert language attributes

        p[no]. paragraph -> <p lang="no">paragraph</p>

        %[fr]phrase% -> <span lang="fr">phrase</span>

    Usually Textile block element syntax requires a dot and space before the block
    begins, but since lists don't, they can be styled just using braces

        #{color:blue} one  ->  <ol style="color:blue">
        # big                   <li>one</li>
        # list                  <li>big</li>
                                <li>list</li>
                               </ol>

    Using the span tag to style a phrase

        It goes like this, %{color:red}the fourth the fifth%
              -> It goes like this, <span style="color:red">the fourth the fifth</span>

*/

// define these before including this file to override the standard glyphs
@define('txt_quote_single_open',  '&#8216;');
@define('txt_quote_single_close', '&#8217;');
@define('txt_quote_double_open',  '&#8220;');
@define('txt_quote_double_close', '&#8221;');
@define('txt_apostrophe',         '&#8217;');
@define('txt_prime',              '&#8242;');
@define('txt_prime_double',       '&#8243;');
@define('txt_ellipsis',           '&#8230;');
@define('txt_emdash',             '&#8212;');
@define('txt_endash',             '&#8211;');
@define('txt_dimension',          '&#215;');
@define('txt_trademark',          '&#8482;');
@define('txt_registered',         '&#174;');
@define('txt_copyright',          '&#169;');

function textile($text, $lite='', $encode='', $noimage='', $strict='', $rel='')
{
    static $tex;
    if (!isset($tex))
        $tex = new Textile;
    
    return $tex->textileThis($text, $lite, $encode, $noimage, $strict, $rel);
}

class Textile
{
    private $_hlgn;
    private $_vlgn;
    private $_clas;
    private $_lnge;
    private $_styl;
    private $_cspn;
    private $_rspn;
    private $_a;
    private $_s;
    private $_c;
    private $_pnct;
    private $_rel;
    private $_fn;
    
    private $_shelf = array();
    private $_restricted = false;
    private $_noimage = false;
    private $_lite = false;
    private $_url_schemes = array();
    private $_glyph = array();
    private $_hu = '';
    
    private $_ver = '2.0.0';
    private $_rev = '$Rev: 216 $';

    public function __construct()
    {
        $this->_hlgn = "(?:\<(?!>)|(?<!<)\>|\<\>|\=|[()]+(?! ))";
        $this->_vlgn = "[\-^~]";
        $this->_clas = "(?:\([^)]+\))";
        $this->_lnge = "(?:\[[^]]+\])";
        $this->_styl = "(?:\{[^}]+\})";
        $this->_cspn = "(?:\\\\\d+)";
        $this->_rspn = "(?:\/\d+)";
        $this->_a = "(?:{$this->_hlgn}|{$this->_vlgn})*";
        $this->_s = "(?:{$this->_cspn}|{$this->_rspn})*";
        $this->_c = "(?:{$this->_clas}|{$this->_styl}|{$this->_lnge}|{$this->_hlgn})*";

        $this->_pnct = '[\!"#\$%&\'()\*\+,\-\./:;<=>\?@\[\\\]\^_`{\|}\~]';
        $this->_urlch = '[\w"$\-_.+!*\'(),";\/?:@=&%#{}|\\^~\[\]`]';

        $this->_url_schemes = array('http','https','ftp','mailto');

        $this->_btag = array('bq', 'bc', 'notextile', 'pre', 'h[1-6]', 'fn\d+', 'p');

        $this->_glyph = array(
           'quote_single_open'  => txt_quote_single_open,
           'quote_single_close' => txt_quote_single_close,
           'quote_double_open'  => txt_quote_double_open,
           'quote_double_close' => txt_quote_double_close,
           'apostrophe'         => txt_apostrophe,
           'prime'              => txt_prime,
           'prime_double'       => txt_prime_double,
           'ellipsis'           => txt_ellipsis,
           'emdash'             => txt_emdash,
           'endash'             => txt_endash,
           'dimension'          => txt_dimension,
           'trademark'          => txt_trademark,
           'registered'         => txt_registered,
           'copyright'          => txt_copyright,
        );

        if (defined('hu')) {
            $this->_hu = hu;
        }
    }

    public function textileThis($text, $lite='', $encode='', $noimage='', $strict='', $rel='')
    {
        if ($rel) {
            $this->_rel = ' rel="'.$rel.'" ';
        }
        $this->_lite = $lite;
        $this->_noimage = $noimage;

        if ($encode) {
            $text = $this->_incomingEntities($text);
            $text = str_replace("x%x%", "&#38;", $text);
            return $text;
        } else {
            if(!$strict) {
                $text = $this->_cleanWhiteSpace($text);
            }

            $text = $this->_getRefs($text);

            if (!$lite) {
                $text = $this->_block($text);
            }

            $text = $this->_retrieve($text);

                // just to be tidy
            $text = str_replace("<br />", "<br />\n", $text);

            return $text;
        }
    }

// -------------------------------------------------------------
    public function textileRestricted($text, $lite=1, $noimage=1, $rel='nofollow')
    {
        $this->_restricted = true;
        $this->_lite = $lite;
        $this->_noimage = $noimage;
        if ($rel)
           $this->_rel = ' rel="'.$rel.'" ';

            // escape any raw html
            $text = $this->_encode_html($text, 0);

            $text = $this->_cleanWhiteSpace($text);
            $text = $this->_getRefs($text);

            if ($lite) {
                $text = $this->_blockLite($text);
            }
            else {
                $text = $this->_block($text);
            }

            $text = $this->_retrieve($text);

                // just to be tidy
            $text = str_replace("<br />", "<br />\n", $text);

            return $text;
    }

    private function _pba($in, $element='') // "parse block attributes"
    {
        $style = '';
        $class = '';
        $lang = '';
        $colspan = '';
        $rowspan = '';
        $id = '';
        $atts = '';

        if (!empty($in)) {
            $matched = $in;
            if ($element == 'td') {
                if (preg_match("/\\\\(\d+)/", $matched, $csp)) $colspan = $csp[1];
                if (preg_match("/\/(\d+)/", $matched, $rsp)) $rowspan = $rsp[1];
            }

            if ($element == 'td' or $element == 'tr') {
                if (preg_match("/($this->_vlgn)/", $matched, $vert))
                    $style[] = "vertical-align:" . $this->_vAlign($vert[1]) . ";";
            }

            if (preg_match("/\{([^}]*)\}/", $matched, $sty)) {
                $style[] = rtrim($sty[1], ';') . ';';
                $matched = str_replace($sty[0], '', $matched);
            }

            if (preg_match("/\[([^]]+)\]/U", $matched, $lng)) {
                $lang = $lng[1];
                $matched = str_replace($lng[0], '', $matched);
            }

            if (preg_match("/\(([^()]+)\)/U", $matched, $cls)) {
                $class = $cls[1];
                $matched = str_replace($cls[0], '', $matched);
            }

            if (preg_match("/([(]+)/", $matched, $pl)) {
                $style[] = "padding-left:" . strlen($pl[1]) . "em;";
                $matched = str_replace($pl[0], '', $matched);
            }

            if (preg_match("/([)]+)/", $matched, $pr)) {
                // $this->_dump($pr);
                $style[] = "padding-right:" . strlen($pr[1]) . "em;";
                $matched = str_replace($pr[0], '', $matched);
            }

            if (preg_match("/($this->_hlgn)/", $matched, $horiz))
                $style[] = "text-align:" . $this->_hAlign($horiz[1]) . ";";

            if (preg_match("/^(.*)#(.*)$/", $class, $ids)) {
                $id = $ids[2];
                $class = $ids[1];
            }

            if ($this->_restricted) {
                return ($lang)    ? ' lang="'    . $lang            .'"':'';
            }

            return join('',array(
                ($style)   ? ' style="'   . join("", $style) .'"':'',
                ($class)   ? ' class="'   . $class           .'"':'',
                ($lang)    ? ' lang="'    . $lang            .'"':'',
                ($id)      ? ' id="'      . $id              .'"':'',
                ($colspan) ? ' colspan="' . $colspan         .'"':'',
                ($rowspan) ? ' rowspan="' . $rowspan         .'"':''
            ));
        }
        return '';
    }

    private function _hasRawText($text)
    {
        // checks whether the text has text not already enclosed by a block tag
        $r = trim(preg_replace('@<(p|blockquote|div|form|table|ul|ol|pre|h\d)[^>]*?>.*</\1>@s', '', trim($text)));
        $r = trim(preg_replace('@<(hr|br)[^>]*?/>@', '', $r));
        return '' != $r;
    }

    private function _table($text)
    {
        $text = $text . "\n\n";
        return preg_replace_callback("/^(?:table(_?{$this->_s}{$this->_a}{$this->_c})\. ?\n)?^({$this->_a}{$this->_c}\.? ?\|.*\|)\n\n/smU",
           array(&$this, "_fTable"), $text);
    }

    private function _fTable($matches)
    {
        $tatts = $this->_pba($matches[1], 'table');

        foreach(preg_split("/\|$/m", $matches[2], -1, PREG_SPLIT_NO_EMPTY) as $row) {
            if (preg_match("/^($this->_a$this->_c\. )(.*)/m", ltrim($row), $rmtch)) {
                $ratts = $this->_pba($rmtch[1], 'tr');
                $row = $rmtch[2];
            } else $ratts = '';

                $cells = array();
            foreach(explode("|", $row) as $cell) {
                $ctyp = "d";
                if (preg_match("/^_/", $cell)) $ctyp = "h";
                if (preg_match("/^(_?$this->_s$this->_a$this->_c\. )(.*)/", $cell, $cmtch)) {
                    $catts = $this->_pba($cmtch[1], 'td');
                    $cell = $cmtch[2];
                } else $catts = '';

                $cell = $this->_graf($this->_span($cell));

                if (trim($cell) != '')
                    $cells[] = "\t\t\t<t$ctyp$catts>$cell</t$ctyp>";
            }
            $rows[] = "\t\t<tr$ratts>\n" . join("\n", $cells) . ($cells ? "\n" : "") . "\t\t</tr>";
            unset($cells, $catts);
        }
        return "\t<table$tatts>\n" . join("\n", $rows) . "\n\t</table>\n\n";
    }

    private function _lists($text)
    {
        return preg_replace_callback("/^([#*]+$this->_c .*)$(?![^#*])/smU", array(&$this, "_fList"), $text);
    }

    private function _fList($m)
    {
        $text = explode("\n", $m[0]);
        $i = 0;
        $nbrline = count($text);
        while($i < $nbrline) {
            $line = $text[$i];
            $i++;
            if($i == $nbrline) {
                $nextline='';
            } else {
                $nextline = $text[$i];
            }
            if (preg_match("/^([#*]+)($this->_a$this->_c) (.*)$/s", $line, $m)) {
                list(, $tl, $atts, $content) = $m;
                $nl = '';
                if (preg_match("/^([#*]+)\s.*/", $nextline, $nm))
                	$nl = $nm[1];
                if (!isset($lists[$tl])) {
                    $lists[$tl] = true;
                    $atts = $this->_pba($atts);
                    $line = "\t<" . $this->_lT($tl) . "l$atts>\n\t\t<li>" . $this->_graf($content);
                } else {
                    $line = "\t\t<li>" . $this->_graf($content);
                }

                if(strlen($nl) <= strlen($tl)) $line .= "</li>";
                foreach(array_reverse($lists) as $k => $v) {
                    if(strlen($k) > strlen($nl)) {
                        $line .= "\n\t</" . $this->_lT($k) . "l>";
                        if(strlen($k) > 1)
                            $line .= "</li>";
                        unset($lists[$k]);
                    }
                }
            }
            $out[] = $line;
        }
        return join("\n", $out);
    }

    private function _lT($in)
    {
        return preg_match("/^#+/", $in) ? 'o' : 'u';
    }

    private function _doPBr($in)
    {
        return preg_replace_callback('@<(p)([^>]*?)>(.*)(</\1>)@s', array(&$this, '_doBr'), $in);
    }

    private function _doBr($m)
    {
        $content = preg_replace("@(.+)(?<!<br>|<br />)\n(?![#*\s|])@", '$1<br />', $m[3]);
        return '<'.$m[1].$m[2].'>'.$content.$m[4];
    }

    private function _block($text)
    {
        $find = $this->_btag;
        $tre = join('|', $find);

        $text = explode("\n\n", $text);

        $tag = 'p';
        $atts = $cite = $graf = $ext  = '';

        foreach($text as $line) {
            $anon = 0;
            if (preg_match("/^($tre)($this->_a$this->_c)\.(\.?)(?::(\S+))? (.*)$/s", $line, $m)) {
                // last block was extended, so close it
                if ($ext)
                    $out[count($out)-1] .= $c1;
                // new block
                list(,$tag,$atts,$ext,$cite,$graf) = $m;
                list($o1, $o2, $content, $c2, $c1) = $this->_fBlock(array(0,$tag,$atts,$ext,$cite,$graf));

                // leave off c1 if this block is extended, we'll close it at the start of the next block
                if ($ext)
                    $line = $o1.$o2.$content.$c2;
                else
                    $line = $o1.$o2.$content.$c2.$c1;
            }
            else {
                // anonymous block
                $anon = 1;
                if ($ext or !preg_match('/^ /', $line)) {
                    list($o1, $o2, $content, $c2, $c1) = $this->_fBlock(array(0,$tag,$atts,$ext,$cite,$line));
                    // skip $o1/$c1 because this is part of a continuing extended block
                    if ($tag == 'p' and !$this->_hasRawText($content)) {
                        $line = $content;
                    }
                    else {
                        $line = $o2.$content.$c2;
                    }
                }
                else {
                   $line = $this->_graf($line);
                }
            }

            $line = $this->_doPBr($line);
            $line = preg_replace('/<br>/', '<br />', $line);

            if ($ext and $anon)
                $out[count($out)-1] .= "\n".$line;
            else
                $out[] = $line;

            if (!$ext) {
                $tag = 'p';
                $atts = '';
                $cite = '';
                $graf = '';
            }
        }
        if ($ext) $out[count($out)-1] .= $c1;
        return join("\n\n", $out);
    }

    private function _fBlock($m)
    {
        // $this->_dump($m);
        list(, $tag, $atts, $ext, $cite, $content) = $m;
        $atts = $this->_pba($atts);

        $o1 = $o2 = $c2 = $c1 = '';

        if (preg_match("/fn(\d+)/", $tag, $fns)) {
            $tag = 'p';
            $fnid = empty($this->_fn[$fns[1]]) ? $fns[1] : $this->_fn[$fns[1]];
            $atts .= ' id="fn' . $fnid . '"';
            if (strpos($atts, 'class=') === false)
                $atts .= ' class="footnote"';
            $content = '<sup>' . $fns[1] . '</sup> ' . $content;
        }

        if ($tag == "bq") {
            $cite = $this->_checkRefs($cite);
            $cite = ($cite != '') ? ' cite="' . $cite . '"' : '';
            $o1 = "\t<blockquote$cite$atts>\n";
            $o2 = "\t\t<p$atts>";
            $c2 = "</p>";
            $c1 = "\n\t</blockquote>";
        }
        elseif ($tag == 'bc') {
            $o1 = "<pre$atts>";
            $o2 = "<code$atts>";
            $c2 = "</code>";
            $c1 = "</pre>";
            $content = $this->_shelve($this->_encode_html(rtrim($content, "\n")."\n"));
        }
        elseif ($tag == 'notextile') {
            $content = $this->_shelve($content);
            $o1 = $o2 = '';
            $c1 = $c2 = '';
        }
        elseif ($tag == 'pre') {
            $content = $this->_shelve($this->_encode_html(rtrim($content, "\n")."\n"));
            $o1 = "<pre$atts>";
            $o2 = $c2 = '';
            $c1 = "</pre>";
        }
        else {
            $o2 = "\t<$tag$atts>";
            $c2 = "</$tag>";
          }

        $content = $this->_graf($content);

        return array($o1, $o2, $content, $c2, $c1);
    }

    private function _graf($text)
    {
        // handle normal paragraph text
        if (!$this->_lite) {
            $text = $this->_noTextile($text);
            $text = $this->_code($text);
        }

        $text = $this->_links($text);
        if (!$this->_noimage)
            $text = $this->_image($text);

        if (!$this->_lite) {
            $text = $this->_lists($text);
            $text = $this->_table($text);
        }

        $text = $this->_span($text);
        $text = $this->_footnoteRef($text);
        $text = $this->_glyphs($text);
        return rtrim($text, "\n");
    }

    private function _span($text)
    {
        $qtags = array('\*\*','\*','\?\?','-','__','_','%','\+','~','\^');
        $pnct = ".,\"'?!;:";

        foreach($qtags as $f) {
            $text = preg_replace_callback("/
                (?:^|(?<=[\s>$pnct])|([{[]))
                ($f)(?!$f)
                ({$this->_c})
                (?::(\S+))?
                ([^\s$f]+|\S[^$f\n]*[^\s$f\n])
                ([$pnct]*)
                $f
                (?:$|([\]}])|(?=[[:punct:]]{1,2}|\s))
            /x", array(&$this, "_fSpan"), $text);
        }
        return $text;
    }

    private function _fSpan($m)
    {
        $qtags = array(
            '*'  => 'strong',
            '**' => 'b',
            '??' => 'cite',
            '_'  => 'em',
            '__' => 'i',
            '-'  => 'del',
            '%'  => 'span',
            '+'  => 'ins',
            '~'  => 'sub',
            '^'  => 'sup',
        );

        list(,, $tag, $atts, $cite, $content, $end) = $m;
        $tag = $qtags[$tag];
        $atts = $this->_pba($atts);
        $atts .= ($cite != '') ? 'cite="' . $cite . '"' : '';

        $out = "<$tag$atts>$content$end</$tag>";

//      $this->_dump($out);

        return $out;

    }

    private function _links($text)
    {
        return preg_replace_callback('/
            (?:^|(?<=[\s>.$pnct\(])|([{[])) # $pre
            "                            # start
            (' . $this->_c . ')           # $atts
            ([^"]+)                      # $text
            \s?
            (?:\(([^)]+)\)(?="))?        # $title
            ":
            ('.$this->_urlch.'+)          # $url
            (\/)?                        # $slash
            ([^\w\/;]*)                  # $post
            (?:([\]}])|(?=\s|$|\)))
        /Ux', array(&$this, "_fLink"), $text);
    }

    private function _fLink($m)
    {
        list(, $pre, $atts, $text, $title, $url, $slash, $post) = $m;

        $url = $this->_checkRefs($url);

        $atts = $this->_pba($atts);
        $atts .= ($title != '') ? ' title="' . $this->_encode_html($title) . '"' : '';

        if (!$this->_noimage)
            $text = $this->_image($text);

        $text = $this->_span($text);
        $text = $this->_glyphs($text);

        $url = $this->_relURL($url);

        $out = '<a href="' . $this->_encode_html($url . $slash) . '"' . $atts . $this->_rel . '>' . $text . '</a>' . $post;

        // $this->_dump($out);
        return $this->_shelve($out);

    }

    private function _getRefs($text)
    {
        return preg_replace_callback("/(?<=^|\s)\[(.+)\]((?:http:\/\/|\/)\S+)(?=\s|$)/U",
            array(&$this, "_refs"), $text);
    }

    private function _refs($m)
    {
        list(, $flag, $url) = $m;
        $this->_urlrefs[$flag] = $url;
        return '';
    }

    private function _checkRefs($text)
    {
        return (isset($this->_urlrefs[$text])) ? $this->_urlrefs[$text] : $text;
    }

    private function _relURL($url)
    {
        $parts = parse_url($url);
        if ((empty($parts['scheme']) or @$parts['scheme'] == 'http') and
             empty($parts['host']) and
             preg_match('/^\w/', @$parts['path']))
            $url = $this->_hu.$url;
        if ($this->_restricted and !empty($parts['scheme']) and
              !in_array($parts['scheme'], $this->_url_schemes))
            return '#';
        return $url;
    }

    private function _image($text)
    {
        return preg_replace_callback("/
            (?:[[{])?          # pre
            \!                 # opening !
            (\<|\=|\>)??       # optional alignment atts
            ($this->_c)         # optional style,class atts
            (?:\. )?           # optional dot-space
            ([^\s(!]+)         # presume this is the src
            \s?                # optional space
            (?:\(([^\)]+)\))?  # optional title
            \!                 # closing
            (?::(\S+))?        # optional href
            (?:[\]}]|(?=\s|$)) # lookahead: space or end of string
        /Ux", array(&$this, "_fImage"), $text);
    }

    private function _fImage($m)
    {
        list(, $algn, $atts, $url) = $m;
        $atts  = $this->_pba($atts);
        $atts .= ($algn != '')  ? ' align="' . $this->_iAlign($algn) . '"' : '';
        $atts .= (isset($m[4])) ? ' title="' . $m[4] . '"' : '';
        $atts .= (isset($m[4])) ? ' alt="'   . $m[4] . '"' : ' alt=""';
        $size = (file_exists($url) && is_file($url)) ? @getimagesize($url) : null;
        if ($size) $atts .= " $size[3]";

        $href = (isset($m[5])) ? $this->_checkRefs($m[5]) : '';
        $url = $this->_checkRefs($url);

        $url = $this->_relURL($url);

        $out = array(
            ($href) ? '<a href="' . $href . '">' : '',
            '<img src="' . $url . '"' . $atts . ' />',
            ($href) ? '</a>' : ''
        );

        return join('',$out);
    }

    private function _code($text)
    {
        $text = $this->_doSpecial($text, '<code>', '</code>', '_fCode');
        $text = $this->_doSpecial($text, '@', '@', '_fCode');
        $text = $this->_doSpecial($text, '<pre>', '</pre>', '_fPre');
        return $text;
    }

    private function _fCode($m)
    {
      @list(, $before, $text, $after) = $m;
      if ($this->_restricted)
          // $text is already escaped
            return $before.$this->_shelve('<code>'.$text.'</code>').$after;
      else
            return $before.$this->_shelve('<code>'.$this->_encode_html($text).'</code>').$after;
    }

    private function _fPre($m)
    {
      @list(, $before, $text, $after) = $m;
      if ($this->_restricted)
          // $text is already escaped
            return $before.'<pre>'.$this->_shelve($text).'</pre>'.$after;
      else
            return $before.'<pre>'.$this->_shelve($this->_encode_html($text)).'</pre>'.$after;
    }

    private function _shelve($val)
    {
        $i = uniqid(rand());
        $this->_shelf[$i] = $val;
        return $i;
    }

    private function _retrieve($text)
    {
        if (is_array($this->_shelf))
            do {
                $old = $text;
                $text = strtr($text, $this->_shelf);
             } while ($text != $old);

        return $text;
    }


// NOTE: deprecated
    private function _incomingEntities($text)
    {
        return preg_replace("/&(?![#a-z0-9]+;)/i", "x%x%", $text);
    }

// NOTE: deprecated
    private function _encodeEntities($text)
    {
        return (function_exists('mb_encode_numericentity'))
        ?    $this->_encode_high($text)
        :    htmlentities($text, ENT_NOQUOTES, "utf-8");
    }

// NOTE: deprecated
    private function _fixEntities($text)
    {
        /*  de-entify any remaining angle brackets or ampersands */
        return str_replace(array("&gt;", "&lt;", "&amp;"),
            array(">", "<", "&"), $text);
    }

    private function _cleanWhiteSpace($text)
    {
        $out = str_replace("\r\n", "\n", $text);
        $out = preg_replace("/\n{3,}/", "\n\n", $out);
        $out = preg_replace("/\n *\n/", "\n\n", $out);
        $out = preg_replace('/"$/', "\" ", $out);
        return $out;
    }

    private function _doSpecial($text, $start, $end, $method='_fSpecial')
    {
      return preg_replace_callback('/(^|\s|[[({>])'.preg_quote($start, '/').'(.*?)'.preg_quote($end, '/').'(\s|$|[\])}])?/ms',
            array(&$this, $method), $text);
    }

    private function _fSpecial($m)
    {
        // A special block like notextile or code
      @list(, $before, $text, $after) = $m;
        return $before.$this->_shelve($this->_encode_html($text)).$after;
    }

    private function _noTextile($text)
    {
         $text = $this->_doSpecial($text, '<notextile>', '</notextile>', '_fTextile');
         return $this->_doSpecial($text, '==', '==', '_fTextile');

    }

    private function _fTextile($m)
    {
        @list(, $before, $notextile, $after) = $m;
        #$notextile = str_replace(array_keys($modifiers), array_values($modifiers), $notextile);
        return $before.$this->_shelve($notextile).$after;
    }

    private function _footnoteRef($text)
    {
        return preg_replace('/\b\[([0-9]+)\](\s)?/Ue',
            '$this->_footnoteID(\'\1\',\'\2\')', $text);
    }

    private function _footnoteID($id, $t)
    {
        if (empty($this->_fn[$id])) {
            $this->_fn[$id] = uniqid(rand());
        }
        $fnid = $this->_fn[$id];
        return '<sup class="footnote"><a href="#fn'.$fnid.'">'.$id.'</a></sup>'.$t;
    }

    private function _glyphs($text)
    {
        // fix: hackish
        $text = preg_replace('/"\z/', "\" ", $text);
        $pnc = '[[:punct:]]';

        $glyph_search = array(
            '/(\w)\'(\w)/',                                      // apostrophe's
            '/(\s)\'(\d+\w?)\b(?!\')/',                          // back in '88
            '/(\S)\'(?=\s|'.$pnc.'|<|$)/',                       //  single closing
            '/\'/',                                              //  single opening
            '/(\S)\"(?=\s|'.$pnc.'|<|$)/',                       //  double closing
            '/"/',                                               //  double opening
            '/\b([A-Z][A-Z0-9]{2,})\b(?:[(]([^)]*)[)])/',        //  3+ uppercase acronym
            '/\b([A-Z][A-Z\'\-]+[A-Z])(?=[\s.,\)>])/',           //  3+ uppercase
            '/\b( )?\.{3}/',                                     //  ellipsis
            '/(\s?)--(\s?)/',                                    //  em dash
            '/\s-(?:\s|$)/',                                     //  en dash
            '/(\d+)( ?)x( ?)(?=\d+)/',                           //  dimension sign
            '/\b ?[([]TM[])]/i',                                 //  trademark
            '/\b ?[([]R[])]/i',                                  //  registered
            '/\b ?[([]C[])]/i',                                  //  copyright
         );

        extract($this->_glyph, EXTR_PREFIX_ALL, 'txt');

        $glyph_replace = array(
            '$1'.$txt_apostrophe.'$2',           // apostrophe's
            '$1'.$txt_apostrophe.'$2',           // back in '88
            '$1'.$txt_quote_single_close,        //  single closing
            $txt_quote_single_open,              //  single opening
            '$1'.$txt_quote_double_close,        //  double closing
            $txt_quote_double_open,              //  double opening
            '<acronym title="$2">$1</acronym>',  //  3+ uppercase acronym
            '<span class="caps">$1</span>',      //  3+ uppercase
            '$1'.$txt_ellipsis,                  //  ellipsis
            '$1'.$txt_emdash.'$2',               //  em dash
            ' '.$txt_endash.' ',                 //  en dash
            '$1$2'.$txt_dimension.'$3',          //  dimension sign
            $txt_trademark,                      //  trademark
            $txt_registered,                     //  registered
            $txt_copyright,                      //  copyright
         );

         $text = preg_split("/(<.*>)/U", $text, -1, PREG_SPLIT_DELIM_CAPTURE);
         foreach($text as $line) {
             if (!preg_match("/<.*>/", $line)) {
                 $line = preg_replace($glyph_search, $glyph_replace, $line);
             }
              $glyph_out[] = $line;
         }
         return join('', $glyph_out);
    }

    private function _iAlign($in)
    {
        $vals = array(
            '<' => 'left',
            '=' => 'center',
            '>' => 'right');
        return (isset($vals[$in])) ? $vals[$in] : '';
    }

    private function _hAlign($in)
    {
        $vals = array(
            '<'  => 'left',
            '='  => 'center',
            '>'  => 'right',
            '<>' => 'justify');
        return (isset($vals[$in])) ? $vals[$in] : '';
    }

    private function _vAlign($in)
    {
        $vals = array(
            '^' => 'top',
            '-' => 'middle',
            '~' => 'bottom');
        return (isset($vals[$in])) ? $vals[$in] : '';
    }

// NOTE: deprecated
    private function _encode_high($text, $charset = "UTF-8")
    {
        return mb_encode_numericentity($text, $this->_cmap(), $charset);
    }

// NOTE: deprecated
    private function _decode_high($text, $charset = "UTF-8")
    {
        return mb_decode_numericentity($text, $this->_cmap(), $charset);
    }

// NOTE: deprecated
    private function _cmap()
    {
        $f = 0xffff;
        $cmap = array(0x0080, 0xffff, 0, $f);
        return $cmap;
    }

    private function _encode_html($str, $quotes=1)
    {
        $a = array(
            '&' => '&#38;',
            '<' => '&#60;',
            '>' => '&#62;',
        );
        if ($quotes) $a = $a + array(
            "'" => '&#39;',
            '"' => '&#34;',
        );

        return strtr($str, $a);
    }

    private function _textile_popup_help($name, $helpvar, $windowW, $windowH)
    {
        return ' <a target="_blank" href="http://www.textpattern.com/help/?item=' . $helpvar . '" onclick="window.open(this.href, \'popupwindow\', \'width=' . $windowW . ',height=' . $windowH . ',scrollbars,resizable\'); return false;">' . $name . '</a><br />';

        return $out;
    }

// NOTE: deprecated
    private function _txtgps($thing)
    {
        if (isset($_POST[$thing])) {
            if (get_magic_quotes_gpc()) {
                return stripslashes($_POST[$thing]);
            }
            else {
                return $_POST[$thing];
            }
        }
        else {
            return '';
        }
    }

// NOTE: deprecated
    private function _dump()
    {
        foreach (func_get_args() as $a) {
            echo "\n<pre>",(is_array($a)) ? print_r($a) : $a, "</pre>\n";
        }
    }

    private function _blockLite($text)
    {
        $this->_btag = array('bq', 'p');
        return $this->_block($text."\n\n");
    }
}
?>'''), STRIP_PHPDOC)

def make_image_module(work):
    write(os.path.join(work, 'modules', 'image.php'), R'''<?php
/**
 * Image Module 1.0 for Pragwork %s
 *
 * @copyright %s
 * @license %s
 * @version %s
 * @package Image
 */
''' % (__pragwork_version__, __author__, __license__, __pragwork_version__) 
    + __strip_phpdoc(R'''
/**
 * Sends the image from the given path and with the given name optionally. 
 * It is a final action. The request processing will stop after.
 *
 * @param string $file_path Image file path
 * @param string $file_name Optional file name
 * @return bool False if the image cannot be sent
 * @throws {@link \Application\StopException} In order to stop execution
 * @author Szymon Wrozynski
 */
function send_image($file_path, $file_name=null)
{    
    if (is_file($file_path))
    {
        $info = getimagesize($file_path);
        $size = filesize($file_path);
        
        header('Content-Type: ' . $info['mime']);
        header('Content-Disposition: inline; filename="' 
            . (($file_name === null) ? basename($file_path) : $file_name) .'"');
        header('Content-Length: ' . $size);
        
        readfile($file_path);
        throw new \Application\StopException;
    }
    
    return false;
}

/**
 * Creates a thumbnail image from the given image path. The thumbnail file is
 * stored under the $thumb_path. Allowed image formats are: PNG, GIF, and JPG.
 *
 * @param string $file_path Image file path (source)
 * @param string $thumbnail_path Image thumbnail path (target)
 * @param int $max_width Max thumbnail width (in pixels)
 * @param int $max_height Max thumbnail height (in pixels)
 * @param int $jpg_quality Quality of the thumbnail if the file is a JPG one 
 *     (default: 95)
 * @author Szymon Wrozynski (based on the public code found in the Internet)
 */
function save_thumbnail($file_path, $thumbnail_path, $max_width=100,
    $max_height=100, $jpg_quality=95)
{
    $info = getimagesize($file_path);
    
    if (($info[0] <= $max_width) && ($info[1] <= $max_height))
    {
        $w = $info[0];
        $h = $info[1];
    }
    else
    {
        $scale = ($info[0] > $info[1]) 
            ? $info[0] / $max_width : $info[1] / $max_height;
    
        $w = floor($info[0] / $scale);
        $h = floor($info[1] / $scale);
    }
    
    $thumb = imagecreatetruecolor($w, $h);
    $image_type = get_image_type($info['mime']);
    
    if (!$image_type)
        trigger_error('Incorrect image type: ' . $info['mime']);
    elseif ($image_type === 'PNG')
    {
        imagecopyresampled($thumb, imagecreatefrompng($file_path), 
            0, 0, 0, 0, $w, $h, $info[0], $info[1]);
        
        imagepng($thumb, $thumbnail_path);
    }
    elseif ($image_type === 'GIF')
    {
        imagecopyresampled($thumb, imagecreatefromgif($file_path),
            0, 0, 0, 0, $w, $h, $info[0], $info[1]);
        
        imagegif($thumb, $thumbnail_path);
    }
    elseif ($image_type === 'JPG')
    {
        imagecopyresampled($thumb, imagecreatefromjpeg($file_path), 
            0, 0, 0, 0,  $w, $h, $info[0], $info[1]);
            
        imagejpeg($thumb, $thumbnail_path, $jpg_quality);
    }
    
    imagedestroy($thumb);
}

/**
 * Returns the string ('PNG', 'GIF', or 'JPG') with image type based on the MIME
 * information or false if no image was found. Recognized image formats are:
 * PNG, GIF, and JPG.
 *
 * @param string $mime MIME information
 * @return mixed String ('PNG', 'GIF', or 'JPG'), or false
 * @author Szymon Wrozynski
 */
function get_image_type($mime)
{
    if ($mime)
    {
        if (stripos($mime, 'png', 6) !== false)
            return 'PNG';
        elseif (stripos($mime, 'gif', 6) !== false)
            return 'GIF';
        elseif (stripos($mime, 'jp', 6) !== false)
            return 'JPG';
    }
    return false;
}
?>'''), STRIP_PHPDOC);

def make_activerecord_module(work):
    write(os.path.join(work, 'modules', 'activerecord.php'), R'''<?php
/**
 * ActiveRecord Module 1.0 for Pragwork %s
 *
 * @copyright Kien La, Jacques Fuentes (PHP ActiveRecord Library), 
 *            Szymon Wrozynski (the module and additions)
 * @license %s
 * @version %s
 * @package Activerecord
 */
''' % (__pragwork_version__, __license__, __pragwork_version__) 
    + __strip_phpdoc(R'''
/*
Copyright (c) 2009

AUTHORS:
Kien La
Jacques Fuentes

Modifications for Pragwork: Szymon Wrozynski
TablelessModel: Szymon Wrozynski
Some bug fixes: Szymon Wrozynski

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

namespace ActiveRecord;
use Closure;
use PDO;
use PDOException;
use ReflectionClass;
use XmlWriter;
use ActiveRecord\Model;
use IteratorAggregate;
use ArrayIterator;

/**
 * Callbacks allow the programmer to hook into the life cycle of a {@link Model}.
 * 
 * You can control the state of your object by declaring certain methods to be
 * called before or after methods are invoked on your object inside of ActiveRecord.
 * 
 * Valid callbacks are:
 * <ul>
 * <li><b>after_construct:</b> called after a model has been constructed</li>
 * <li><b>before_save:</b> called before a model is saved</li>
 * <li><b>after_save:</b> called after a model is saved</li>
 * <li><b>before_create:</b> called before a NEW model is to be inserted into the database</li>
 * <li><b>after_create:</b> called after a NEW model has been inserted into the database</li>
 * <li><b>before_update:</b> called before an existing model has been saved</li>
 * <li><b>after_update:</b> called after an existing model has been saved</li>
 * <li><b>before_validation:</b> called before running validators</li>
 * <li><b>after_validation:</b> called after running validators</li>
 * <li><b>before_validation_on_create:</b> called before validation on a NEW model being inserted</li>
 * <li><b>after_validation_on_create:</b> called after validation on a NEW model being inserted</li>
 * <li><b>before_validation_on_update:</b> see above except for an existing model being saved</li>
 * <li><b>after_validation_on_update:</b> ...</li>
 * <li><b>before_destroy:</b> called after a model has been deleted</li>
 * <li><b>after_destroy:</b> called after a model has been deleted</li>
 * </ul>
 * 
 * This class isn't meant to be used directly. Callbacks are defined on your model like the example below:
 * 
 * <code>
 * class Person extends ActiveRecord\Model {
 *   static $before_save = array('make_name_uppercase');
 *   static $after_save = array('do_happy_dance');
 *   
 *   public function make_name_uppercase() {
 *     $this->name = strtoupper($this->name);
 *   }
 * 
 *   public function do_happy_dance() {
 *     happy_dance();
 *   }
 * }
 * </code>
 *
 * Available options for callbacks:
 *
 * <ul>
 * <li><b>prepend:</b> puts the callback at the top of the callback chain instead of the bottom</li>
 * </ul>
 *
 * @package ActiveRecord
 * @link http://www.phpactiverecord.org/guides/callbacks
 */
class CallBack
{
	/**
	 * List of available callbacks.
	 *
	 * @var array
	 */
	static protected $VALID_CALLBACKS = array(
		'after_construct',
		'before_save',
		'after_save',
		'before_create',
		'after_create',
		'before_update',
		'after_update',
		'before_validation',
		'after_validation',
		'before_validation_on_create',
		'after_validation_on_create',
		'before_validation_on_update',
		'after_validation_on_update',
		'before_destroy',
		'after_destroy'
	);

	/**
	 * Container for reflection class of given model
	 * 
	 * @var object
	 */
	private $klass;
	
	/**
     * List of public methods of the given model
     * @var array
     */
    private $publicMethods;

	/**
	 * Holds data for registered callbacks.
	 *
	 * @var array
	 */
	private $registry = array();

	/**
	 * Creates a CallBack.
	 *
	 * @param string $model_class_name The name of a {@link Model} class
	 * @return CallBack
	 */
	public function __construct($model_class_name)
	{
		$this->klass = Reflections::instance()->get($model_class_name);

		foreach (static::$VALID_CALLBACKS as $name)
		{
			// look for explicitly defined static callback
			if (($definition = $this->klass->getStaticPropertyValue($name,null)))
			{
			    if ((array) $definition !== $definition)
					$definition = array($definition);

				foreach ($definition as $method_name)
					$this->register($name,$method_name);
			}

			// implicit callbacks that don't need to have a static definition
			// simply define a method named the same as something in $VALID_CALLBACKS
			// and the callback is auto-registered
			elseif ($this->klass->hasMethod($name))
				$this->register($name,$name);
		}
	}

	/**
	 * Returns all the callbacks registered for a callback type.
	 *
	 * @param $name string Name of a callback (see {@link VALID_CALLBACKS $VALID_CALLBACKS})
	 * @return array array of callbacks or null if invalid callback name.
	 */
	public function get_callbacks($name)
	{
		return isset($this->registry[$name]) ? $this->registry[$name] : null;
	}

	/**
	 * Invokes a callback.
	 *
	 * @internal This is the only piece of the CallBack class that carries its own logic for the
	 * model object. For (after|before)_(create|update) callbacks, it will merge with
	 * a generic 'save' callback which is called first for the lease amount of precision.
	 *
	 * @param string $model Model to invoke the callback on.
	 * @param string $name Name of the callback to invoke
	 * @param boolean $must_exist Set to true to raise an exception if the callback does not exist.
	 * @return mixed null if $name was not a valid callback type or false if a method was invoked
	 * that was for a before_* callback and that method returned false. If this happens, execution
	 * of any other callbacks after the offending callback will not occur.
	 */
	public function invoke($model, $name, $must_exist=true)
	{
		if ($must_exist && !array_key_exists($name, $this->registry))
			throw new ActiveRecordException("No callbacks were defined for: $name on " . get_class($model));

		// if it doesn't exist it might be a /(after|before)_(create|update)/ so we still need to run the save
		// callback
		if (!array_key_exists($name, $this->registry))
			$registry = array();
		else
			$registry = $this->registry[$name];

		$first = substr($name,0,6);

		// starts with /(after|before)_(create|update)/
		if (($first == 'after_' || $first == 'before') && (($second = substr($name,7,5)) == 'creat' || $second == 'updat' || $second == 'reate' || $second == 'pdate'))
		{
			$temporal_save = str_replace(array('create', 'update'), 'save', $name);

			if (!isset($this->registry[$temporal_save]))
				$this->registry[$temporal_save] = array();

			$registry = array_merge($this->registry[$temporal_save], $registry ? $registry : array());
		}

		if ($registry)
		{
			foreach ($registry as $method)
			{
				$ret = ($method instanceof Closure ? $method($model) : $model->$method());

				if (false === $ret && $first === 'before')
					return false;
			}
		}
		return true;
	}

    /**
     * Register a new callback.
     *
     * The option array can contain the following parameters:
     * <ul>
     * <li><b>prepend:</b> Add this callback at the beginning of the existing callbacks (true) or at the end (false, default)</li>
     * </ul>
     *
     * @param string $name Name of callback type (see {@link VALID_CALLBACKS $VALID_CALLBACKS})
     * @param mixed $closure_or_method_name Either a closure or the name of a method on the {@link Model}
     * @param array $options Options array
     * @return void
     * @throws ActiveRecordException if invalid callback type or callback method was not found
     */
    public function register($name, $closure_or_method_name=null, 
        $options=array())
    {
        $options = array_merge(array('prepend' => false), $options);

        if (!$closure_or_method_name)
            $closure_or_method_name = $name;

        if (!in_array($name,self::$VALID_CALLBACKS))
            throw new ActiveRecordException("Invalid callback: $name");

        if (!($closure_or_method_name instanceof Closure))
        {
            if (!isset($this->publicMethods))
                $this->publicMethods=get_class_methods($this->klass->getName());

            if (!in_array($closure_or_method_name, $this->publicMethods))
            {
                if ($this->klass->hasMethod($closure_or_method_name))
                {
                    // Method is private or protected
                    throw new ActiveRecordException(
                "Callback methods need to be public (or anonymous closures). " 
                ."Please change the visibility of " . $this->klass->getName() 
                . "->" . $closure_or_method_name . "()");
                }
                else
                {
                    // i'm a dirty ruby programmer
                    throw new ActiveRecordException(
                        "Unknown method for callback: $name" 
                        . (is_string($closure_or_method_name) 
                            ? ": #$closure_or_method_name" 
                            : ""
                        )
                    );
                }
            }
        }

        if (!isset($this->registry[$name]))
            $this->registry[$name] = array();

        if ($options['prepend'])
            array_unshift($this->registry[$name], $closure_or_method_name);
        else
            $this->registry[$name][] = $closure_or_method_name;
    }
}

/**
 * Class for a table column.
 *
 * @package ActiveRecord
 */
class Column
{
	// types for $type
	const STRING	= 1;
	const INTEGER	= 2;
	const DECIMAL	= 3;
	const DATETIME	= 4;
	const DATE		= 5;
	const TIME		= 6;

	/**
	 * Map a type to an column type.
	 * @static
	 * @var array
	 */
	static $TYPE_MAPPING = array(
		'datetime'	=> self::DATETIME,
		'timestamp'	=> self::DATETIME,
		'date'		=> self::DATE,
		'time'		=> self::TIME,

		'int'		=> self::INTEGER,
		'tinyint'	=> self::INTEGER,
		'smallint'	=> self::INTEGER,
		'mediumint'	=> self::INTEGER,
		'bigint'	=> self::INTEGER,

		'float'		=> self::DECIMAL,
		'double'	=> self::DECIMAL,
		'numeric'	=> self::DECIMAL,
		'decimal'	=> self::DECIMAL,
		'dec'		=> self::DECIMAL);

	/**
	 * The true name of this column.
	 * @var string
	 */
	public $name;

	/**
	 * The inflected name of this columns .. hyphens/spaces will be => _.
	 * @var string
	 */
	public $inflected_name;

	/**
	 * The type of this column: STRING, INTEGER, ...
	 * @var integer
	 */
	public $type;

	/**
	 * The raw database specific type.
	 * @var string
	 */
	public $raw_type;

	/**
	 * The maximum length of this column.
	 * @var int
	 */
	public $length;

	/**
	 * True if this column allows null.
	 * @var boolean
	 */
	public $nullable;

	/**
	 * True if this column is a primary key.
	 * @var boolean
	 */
	public $pk;

	/**
	 * The default value of the column.
	 * @var mixed
	 */
	public $default;

	/**
	 * True if this column is set to auto_increment.
	 * @var boolean
	 */
	public $auto_increment;

	/**
	 * Name of the sequence to use for this column if any.
	 * @var boolean
	 */
	public $sequence;

	/**
	 * Casts a value to the column's type.
	 *
	 * @param mixed $value The value to cast
	 * @param Connection $connection The Connection this column belongs to
	 * @return mixed type-casted value
	 */
	public function cast($value, $connection)
	{
		if ($value === null)
			return null;

		switch ($this->type)
		{
			case self::STRING:	return (string)$value;
			case self::INTEGER:	return (int)$value;
			case self::DECIMAL:	return (double)$value;
			case self::DATETIME:
			case self::DATE:
				if (!$value)
					return null;

				if ($value instanceof DateTime)
					return $value;
					
				if ($value instanceof \DateTime)
                    return new DateTime($value->format('Y-m-d H:i:s T'));

				return $connection->string_to_datetime($value);
		}
		return $value;
	}

	/**
	 * Sets the $type member variable.
	 * @return mixed
	 */
	public function map_raw_type()
	{
		if ($this->raw_type == 'integer')
			$this->raw_type = 'int';

		if (array_key_exists($this->raw_type,self::$TYPE_MAPPING))
			$this->type = self::$TYPE_MAPPING[$this->raw_type];
		else
			$this->type = self::STRING;

		return $this->type;
	}
}

/**
 * Manages configuration options for ActiveRecord.
 *
 * <code>
 * ActiveRecord::initialize(function($cfg) {
 *   $cfg->set_model_home('models');
 *   $cfg->set_connections(array(
 *     'development' => 'mysql://user:pass@development.com/awesome_development',
 *     'production' => 'mysql://user:pass@production.com/awesome_production'));
 * });
 * </code>
 *
 * @package ActiveRecord
 */
class Config extends Singleton
{
	/**
	 * Name of the connection to use by default.
	 *
	 * <code>
	 * ActiveRecord\Config::initialize(function($cfg) {
	 *   $cfg->set_model_directory('/your/app/models');
	 *   $cfg->set_connections(array(
	 *     'development' => 'mysql://user:pass@development.com/awesome_development',
	 *     'production' => 'mysql://user:pass@production.com/awesome_production'));
	 * });
	 * </code>
	 *
	 * This is a singleton class so you can retrieve the {@link Singleton} instance by doing:
	 *
	 * <code>
	 * $config = ActiveRecord\Config::instance();
	 * </code>
	 *
	 * @var string
	 */
	private $default_connection = 'development';

	/**
	 * Contains the list of database connection strings.
	 *
	 * @var array
	 */
	private $connections = array();

	/**
	 * Directory for the auto_loading of model classes.
	 *
	 * @see activerecord_autoload
	 * @var string
	 */
	private $model_directory;

	/**
	 * Switch for logging.
	 *
	 * @var bool
	 */
	private $logging = false;

	/**
	 * Contains a Logger object that must impelement a log() method.
	 *
	 * @var object
	 */
	private $logger;
	
	/**
     * The format to serialize DateTime values into.
     *
     * @var string
     */
    private $date_format = \DateTime::ISO8601;

	/**
	 * Allows config initialization using a closure.
	 *
	 * This method is just syntatic sugar.
	 *
	 * <code>
	 * ActiveRecord\Config::initialize(function($cfg) {
     *   $cfg->set_model_directory('/path/to/your/model_directory');
     *   $cfg->set_connections(array(
     *     'development' => 'mysql://username:password@127.0.0.1/database_name'));
	 * });
	 * </code>
	 *
	 * You can also initialize by grabbing the singleton object:
	 *
	 * <code>
	 * $cfg = ActiveRecord\Config::instance();
	 * $cfg->set_model_directory('/path/to/your/model_directory');
	 * $cfg->set_connections(array('development' =>
  	 *   'mysql://username:password@localhost/database_name'));
	 * </code>
	 *
	 * @param Closure $initializer A closure
	 * @return void
	 */
	public static function initialize(Closure $initializer)
	{
		$initializer(parent::instance());
	}

	/**
	 * Sets the list of database connection strings.
	 *
	 * <code>
	 * $config->set_connections(array(
     *     'development' => 'mysql://username:password@127.0.0.1/database_name'));
     * </code>
	 *
	 * @param array $connections Array of connections
	 * @param string $default_connection Optionally specify the default_connection
	 * @return void
	 * @throws ActiveRecord\ConfigException
	 */
	public function set_connections($connections, $default_connection=null)
	{
		if (!is_array($connections))
			throw new ConfigException("Connections must be an array");

		if ($default_connection)
			$this->set_default_connection($default_connection);

		$this->connections = $connections;
	}

	/**
	 * Returns the connection strings array.
	 *
	 * @return array
	 */
	public function get_connections()
	{
		return $this->connections;
	}

	/**
	 * Returns a connection string if found otherwise null.
	 *
	 * @param string $name Name of connection to retrieve
	 * @return string connection info for specified connection name
	 */
	public function get_connection($name)
	{
		if (array_key_exists($name, $this->connections))
			return $this->connections[$name];

		return null;
	}

	/**
	 * Returns the default connection string or null if there is none.
	 *
	 * @return string
	 */
	public function get_default_connection_string()
	{
		return array_key_exists($this->default_connection,$this->connections) ?
			$this->connections[$this->default_connection] : null;
	}

	/**
	 * Returns the name of the default connection.
	 *
	 * @return string
	 */
	public function get_default_connection()
	{
		return $this->default_connection;
	}

	/**
	 * Set the name of the default connection.
	 *
	 * @param string $name Name of a connection in the connections array
	 * @return void
	 */
	public function set_default_connection($name)
	{
		$this->default_connection = $name;
	}

	/**
	 * Sets the directory where models are located.
	 *
	 * @param string $dir Directory path containing your models
	 * @return void
	 * @throws ConfigException if specified directory was not found
	 */
	public function set_model_directory($dir)
	{
		if (!file_exists($dir))
			throw new ConfigException("Invalid or non-existent directory: $dir");

		$this->model_directory = $dir;
	}

	/**
	 * Returns the model directory.
	 *
	 * @return string
	 */
	public function get_model_directory()
	{
		return $this->model_directory;
	}

	/**
	 * Turn on/off logging
	 *
	 * @param boolean $bool
	 * @return void
	 */
	public function set_logging($bool)
	{
		$this->logging = (bool)$bool;
	}

	/**
	 * Sets the logger object for future SQL logging
	 *
	 * @param object $logger
	 * @return void
	 * @throws ConfigException if Logger objecct does not implement public log()
	 */
	public function set_logger($logger)
	{
		$klass = Reflections::instance()->add($logger)->get($logger);

		if (!$klass->getMethod('log') || !$klass->getMethod('log')->isPublic())
			throw new ConfigException("Logger object must implement a public log method");

		$this->logger = $logger;
	}

	/**
	 * Return whether or not logging is on
	 *
	 * @return boolean
	 */
	public function get_logging()
	{
		return $this->logging;
	}

	/**
	 * Returns the logger
	 *
	 * @return object
	 */
	public function get_logger()
	{
		return $this->logger;
	}
	
	/**
     * Returns the date format.
     *
     * @return string
     * DEPRECATED
     */
    public function get_date_format()
    {
        error_log('DEPRECATION WARNING: Config::get_date_format() has been deprecated and will be removed in a future version. Please ActiveRecord\Serialization::$DATETIME_FORMAT instead.');

        return Serialization::$DATETIME_FORMAT;
    }

    /**
     * Sets the date format.
     *
     * Accepts date formats accepted by PHP's date() function.
     *
     * @link http://php.net/manual/en/function.date.php
     * @param string $format
     * DEPRECATED
     */
    public function set_date_format($format)
    {
        error_log('DEPRECATION WARNING: Config::set_date_format() has been deprecated and will be removed in a future version. Please use ActiveRecord\Serialization::$DATETIME_FORMAT instead.');
        Serialization::$DATETIME_FORMAT = $format;
    }
    
    /**
     * Sets the url for the cache server to enable query caching.
     *
     * Only table schema queries are cached at the moment. A general query cache
     * will follow.
     *
     * Example:
     *
     * <code>
     * $config->set_cache("memcached://localhost");
     * $config->set_cache("memcached://localhost",array("expire" => 60));
     * </code>
     *
     * @param string $url Url to your cache server.
     * @param array $options Array of options
     */
    public function set_cache($url, $options=array())
    {
        Cache::initialize($url,$options);
    }
}

/**
 * The base class for database connection adapters.
 *
 * @package ActiveRecord
 */
abstract class Connection
{
	/**
	 * The PDO connection object.
	 * @var mixed
	 */
	public $connection;

	/**
	 * The last query run.
	 * @var string
	 */
	public $last_query;

	/**
	 * Switch for logging.
	 *
	 * @var bool
	 */
	 private $logging = false;

	/**
	 * Contains a Logger object that must impelement a log() method.
	 *
	 * @var object
	 */
	private $logger;

	/**
	 * Default PDO options to set for each connection.
	 * @var array
	 */
	static $PDO_OPTIONS = array(
		PDO::ATTR_CASE				=> PDO::CASE_LOWER,
		PDO::ATTR_ERRMODE			=> PDO::ERRMODE_EXCEPTION,
		PDO::ATTR_ORACLE_NULLS		=> PDO::NULL_NATURAL,
		PDO::ATTR_STRINGIFY_FETCHES	=> false);

	/**
	 * The quote character for stuff like column and field names.
	 * @var string
	 */
	static $QUOTE_CHARACTER = '`';

	/**
	 * Default port.
	 * @var int
	 */
	static $DEFAULT_PORT = 0;

	/**
	 * Retrieve a database connection.
	 *
	 * @param string $connection_string_or_connection_name A database connection string (ex. mysql://user:pass@host[:port]/dbname)
	 *   Everything after the protocol:// part is specific to the connection adapter.
	 *   OR
	 *   A connection name that is set in ActiveRecord\Config
	 *   If null it will use the default connection specified by ActiveRecord\Config->set_default_connection
	 * @return Connection
	 * @see parse_connection_url
	 */
	public static function instance($connection_string_or_connection_name=null)
	{
		$config = Config::instance();

		if (strpos($connection_string_or_connection_name,'://') === false)
		{
			$connection_string = $connection_string_or_connection_name ?
				$config->get_connection($connection_string_or_connection_name) :
				$config->get_default_connection_string();
		}
		else
			$connection_string = $connection_string_or_connection_name;

		if (!$connection_string)
			throw new DatabaseException("Empty connection string");

		$info = static::parse_connection_url($connection_string);
		$fqclass = static::load_adapter_class($info->protocol);

		try {
			$connection = new $fqclass($info);
			$connection->protocol = $info->protocol;
			$connection->logging = $config->get_logging();
			$connection->logger = $connection->logging ? $config->get_logger() : null;
			if (isset($info->charset))
                $connection->set_encoding($info->charset);
		} catch (PDOException $e) {
			throw new DatabaseException($e);
		}
		return $connection;
	}

	/**
	 * Loads the specified class for an adapter.
	 *
	 * @param string $adapter Name of the adapter.
	 * @return string The full name of the class including namespace.
	 */
	private static function load_adapter_class($adapter)
 	{
 		$class = ucwords($adapter) . 'Adapter';
 		$fqclass = 'ActiveRecord\\' . $class;
 		return $fqclass;
 	}

    /**
     * Use this for any adapters that can take connection info in the form below
     * to set the adapters connection info.
     *
     * <code>
     * protocol://username:password@host[:port]/dbname
     * protocol://urlencoded%20username:urlencoded%20password@host[:port]/dbname?decode=true
     * protocol://username:password@unix(/some/file/path)/dbname
     * </code>
     *
     * Sqlite has a special syntax, as it does not need a database name 
     * or user authentication:
     *
     * <code>
 	 * sqlite://file.db
     * sqlite://../relative/path/to/file.db
     * sqlite://unix(/absolute/path/to/file.db)
     * sqlite://windows(c:/absolute/path/to/file.db) // TODO currently not implemented
     * </code>
  	 *
     * @param string $connection_url A connection URL
     * @return object the parsed URL as an object.
     */
    public static function parse_connection_url($connection_url)
    {
        $url = @parse_url($connection_url);

        if (!isset($url['host']))
            throw new DatabaseException(
                'Database host must be specified in the connection string.If you want to specify absolute filenames, use e.g. sqlite://unix(/path/to/file).'
            );

        $info = new \stdClass();
        $info->protocol = $url['scheme'];
        $info->host = $url['host'];
        $info->db = isset($url['path']) ? substr($url['path'],1) : null;
        $info->user = isset($url['user']) ? $url['user'] : null;
        $info->pass = isset($url['pass']) ? $url['pass'] : null;
        
        $allow_blank_db = ($info->protocol == 'sqlite');
        if ($info->host == 'unix(')
        {
            $socket_database = $info->host . '/' . $info->db;
            
            $unix_regex = $allow_blank_db
                ? '/^unix\((.+)\)\/?().*$/'
                : '/^unix\((.+)\)\/(.+)$/';
            
            if (preg_match_all($unix_regex, $socket_database, $matches) > 0)
            {
                $info->host = $matches[1][0];
                $info->db = $matches[2][0];
            }
        }
        
        if ($allow_blank_db && $info->db)
            $info->host .= '/' . $info->db;

        if (isset($url['port']))
            $info->port = $url['port'];

        if (strpos($connection_url,'decode=true') !== false)
        {
            if ($info->user)
            $info->user = urldecode($info->user);

            if ($info->pass)
                $info->pass = urldecode($info->pass);
        }
        
        if (isset($url['query']))
        {
            foreach (explode('/&/',$url['query']) as $pair)
            {
                list($name, $value) = explode('=', $pair);

                if ($name == 'charset')
                    $info->charset = $value;
            }
        }

        return $info;
    }

	/**
	 * Class Connection is a singleton. Access it via instance().
	 *
	 * @param array $info Array containing URL parts
	 * @return Connection
	 */
	protected function __construct($info)
	{
		try
		{
			// unix sockets start with a /
			if ($info->host[0] != '/')
			{
				$host = "host=$info->host";

				if (isset($info->port))
					$host .= ";port=$info->port";
			}
			else
				$host = "unix_socket=$info->host";

			$this->connection = new PDO("$info->protocol:$host;dbname=$info->db",$info->user,$info->pass,static::$PDO_OPTIONS);
		} catch (PDOException $e) {
			throw new DatabaseException($e);
		}
	}

	/**
	 * Retrieves column meta data for the specified table.
	 *
	 * @param string $table Name of a table
	 * @return array An array of {@link Column} objects.
	 */
	public function columns($table)
	{
		$columns = array();
		$sth = $this->query_column_info($table);

		while (($row = $sth->fetch()))
		{
			$c = $this->create_column($row);
			$columns[$c->name] = $c;
		}
		return $columns;
	}

	/**
	 * Escapes quotes in a string.
	 *
	 * @param string $string The string to be quoted.
	 * @return string The string with any quotes in it properly escaped.
	 */
	public function escape($string)
	{
		return $this->connection->quote($string);
	}

	/**
	 * Retrieve the insert id of the last model saved.
	 *
	 * @param string $sequence Optional name of a sequence to use
	 * @return int
	 */
	public function insert_id($sequence=null)
	{
		return $this->connection->lastInsertId($sequence);
	}

	/**
	 * Execute a raw SQL query on the database.
	 *
	 * @param string $sql Raw SQL string to execute.
	 * @param array &$values Optional array of bind values
	 * @return mixed A result set object
	 */
	public function query($sql, &$values=array())
	{
		if ($this->logging)
			$this->logger->log($sql);

		$this->last_query = $sql;

		try {
			if (!($sth = $this->connection->prepare($sql)))
				throw new DatabaseException($this);
		} catch (PDOException $e) {
			throw new DatabaseException($this);
		}

		$sth->setFetchMode(PDO::FETCH_ASSOC);

		try {
			if (!$sth->execute($values))
				throw new DatabaseException($this);
		} catch (PDOException $e) {
			throw new DatabaseException($sth);
		}
		return $sth;
	}

	/**
	 * Execute a query that returns maximum of one row with one field and return it.
	 *
	 * @param string $sql Raw SQL string to execute.
	 * @param array &$values Optional array of values to bind to the query.
	 * @return string
	 */
	public function query_and_fetch_one($sql, &$values=array())
	{
		$sth = $this->query($sql,$values);
		$row = $sth->fetch(PDO::FETCH_NUM);
		return $row[0];
	}

	/**
	 * Execute a raw SQL query and fetch the results.
	 *
	 * @param string $sql Raw SQL string to execute.
	 * @param Closure $handler Closure that will be passed the fetched results.
	 */
	public function query_and_fetch($sql, Closure $handler)
	{
		$sth = $this->query($sql);

		while (($row = $sth->fetch(PDO::FETCH_ASSOC)))
			$handler($row);
	}

	/**
	 * Returns all tables for the current database.
	 *
	 * @return array Array containing table names.
	 */
	public function tables()
	{
		$tables = array();
		$sth = $this->query_for_tables();

		while (($row = $sth->fetch(PDO::FETCH_NUM)))
			$tables[] = $row[0];

		return $tables;
	}

	/**
	 * Starts a transaction.
	 */
	public function transaction()
	{
		if (!$this->connection->beginTransaction())
			throw new DatabaseException($this);
	}

	/**
	 * Commits the current transaction.
	 */
	public function commit()
	{
		if (!$this->connection->commit())
			throw new DatabaseException($this);
	}

	/**
	 * Rollback a transaction.
	 */
	public function rollback()
	{
		if (!$this->connection->rollback())
			throw new DatabaseException($this);
	}

	/**
	 * Tells you if this adapter supports sequences or not.
	 *
	 * @return boolean
	 */
	function supports_sequences() { return false; }

	/**
	 * Return a default sequence name for the specified table.
	 *
	 * @param string $table Name of a table
	 * @param string $column_name Name of column sequence is for
	 * @return string sequence name or null if not supported.
	 */
	public function get_sequence_name($table, $column_name)
	{
		return "{$table}_seq";
	}

	/**
	 * Return SQL for getting the next value in a sequence.
	 *
	 * @param string $sequence_name Name of the sequence
	 * @return string
	 */
	public function next_sequence_value($sequence_name) { return null; }

	/**
	 * Quote a name like table names and field names.
	 *
	 * @param string $string String to quote.
	 * @return string
	 */
	public function quote_name($string)
	{
		return $string[0] === static::$QUOTE_CHARACTER || $string[strlen($string)-1] === static::$QUOTE_CHARACTER ?
			$string : static::$QUOTE_CHARACTER . $string . static::$QUOTE_CHARACTER;
	}
	
	/**
     * Return a date time formatted into the database's date format.
     *
     * @param DateTime $datetime The DateTime object
     * @return string
     */
    public function date_to_string($datetime)
    {
        return $datetime->format('Y-m-d');
    }

	/**
	 * Return a date time formatted into the database's datetime format.
	 *
	 * @param DateTime $datetime The DateTime object
	 * @return string
	 */
	public function datetime_to_string($datetime)
	{
		return $datetime->format('Y-m-d H:i:s T');
	}

	/**
	 * Converts a string representation of a datetime into a DateTime object.
	 *
	 * @param string $string A datetime in the form accepted by date_create()
	 * @return DateTime
	 */
	public function string_to_datetime($string)
	{
		$date = date_create($string);
		$errors = \DateTime::getLastErrors();

		if ($errors['warning_count'] > 0 || $errors['error_count'] > 0)
			return null;

		return new DateTime($date->format('Y-m-d H:i:s T'));
	}

	/**
	 * Adds a limit clause to the SQL query.
	 *
	 * @param string $sql The SQL statement.
	 * @param int $offset Row offset to start at.
	 * @param int $limit Maximum number of rows to return.
	 * @return string The SQL query that will limit results to specified parameters
	 */
	abstract function limit($sql, $offset, $limit);

	/**
	 * Query for column meta info and return statement handle.
	 *
	 * @param string $table Name of a table
	 * @return PDOStatement
	 */
	abstract public function query_column_info($table);

	/**
	 * Query for all tables in the current database. The result must only
	 * contain one column which has the name of the table.
	 *
	 * @return PDOStatement
	 */
	abstract function query_for_tables();
	
	/**
     * Executes query to specify the character set for this connection.
     */
    abstract function set_encoding($charset);
    
    /**
     * Specifies whether or not adapter can use LIMIT/ORDER clauses with DELETE & UPDATE operations
     *
     * @internal
     * @returns boolean (FALSE by default)
     */
    public function accepts_limit_and_order_for_update_and_delete() 
    { 
        return false; 
    }
}

/**
 * An extension of PHP's DateTime class to provide dirty flagging and easier formatting options.
 *
 * All date and datetime fields from your database will be created as instances of this class.
 *
 * Example of formatting and changing the default format:
 *
 * <code>
 * $now = new ActiveRecord\DateTime('2010-01-02 03:04:05');
 * ActiveRecord\DateTime::$DEFAULT_FORMAT = 'short';
 *
 * echo $now->format(); # 02 Jan 03:04
 * echo $now->format('atom'); # 2010-01-02T03:04:05-05:00
 * echo $now->format('Y-m-d'); # 2010-01-02
 *
 * # __toString() uses the default formatter
 * echo (string)$now; # 02 Jan 03:04
 * </code>
 *
 * You can also add your own pre-defined friendly formatters:
 *
 * <code>
 * ActiveRecord\DateTime::$FORMATS['awesome_format'] = 'H:i:s m/d/Y';
 * echo $now->format('awesome_format') # 03:04:05 01/02/2010
 * </code>
 *
 * @package ActiveRecord
 * @see http://php.net/manual/en/class.datetime.php
 */
class DateTime extends \DateTime
{
    /**
     * Default format used for format() and __toString()
     */
    public static $DEFAULT_FORMAT = 'rfc2822';

    /**
     * Pre-defined format strings.
     */
    public static $FORMATS = array(
        'db' => 'Y-m-d H:i:s',
        'number' => 'YmdHis',
        'time' => 'H:i',
        'short' => 'd M H:i',
        'long' => 'F d, Y H:i',
        'atom' => \DateTime::ATOM,
        'cookie' => \DateTime::COOKIE,
        'iso8601' => \DateTime::ISO8601,
        'rfc822' => \DateTime::RFC822,
        'rfc850' => \DateTime::RFC850,
        'rfc1036' => \DateTime::RFC1036,
        'rfc1123' => \DateTime::RFC1123,
        'rfc2822' => \DateTime::RFC2822,
        'rfc3339' => \DateTime::RFC3339,
        'rss' => \DateTime::RSS,
        'w3c' => \DateTime::W3C
    );

    private $model;
    private $attribute_name;

    public function attribute_of($model, $attribute_name)
    {
        $this->model = $model;
        $this->attribute_name = $attribute_name;
    }

    /**
     * Formats the DateTime to the specified format.
     *
     * <code>
     * $datetime->format(); # uses the format defined in DateTime::$DEFAULT_FORMAT
     * $datetime->format('short'); # d M H:i
     * $datetime->format('Y-m-d'); # Y-m-d
     * </code>
     *
     * @see FORMATS
     * @see get_format
     * @param string $format A format string accepted by get_format()
     * @return string formatted date and time string
     */
    public function format($format=null)
    {
        return parent::format(self::get_format($format));
    }

    /**
     * Returns the format string.
     *
     * If $format is a pre-defined format in $FORMATS it will return that otherwise
     * it will assume $format is a format string itself.
     *
     * @see FORMATS
     * @param string $format A pre-defined string format or a raw format string
     * @return string a format string
     */
    public static function get_format($format=null)
    {
        // use default format if no format specified
        if (!$format)
            $format = self::$DEFAULT_FORMAT;

        // format is a friendly
        if (array_key_exists($format, self::$FORMATS))
            return self::$FORMATS[$format];

        // raw format
        return $format;
    }

    public function __toString()
    {
        return $this->format();
    }

    private function flag_dirty()
    {
        if ($this->model)
            $this->model->flag_dirty($this->attribute_name);
    }

    public function setDate($year, $month, $day)
    {
        $this->flag_dirty();
        call_user_func_array(array($this,'parent::setDate'),func_get_args());
    }

    public function setISODate($year, $week , $day=null)
    {
        $this->flag_dirty();
        call_user_func_array(array($this,'parent::setISODate'),func_get_args());
    }

    public function setTime($hour, $minute, $second=null)
    {
        $this->flag_dirty();
        call_user_func_array(array($this,'parent::setTime'),func_get_args());
    }

    public function setTimestamp($unixtimestamp)
    {
        $this->flag_dirty();
        call_user_func_array(array($this,'parent::setTimestamp'),
            func_get_args());
    }
}

/**
 * Singleton to manage any and all database connections.
 *
 * @package ActiveRecord
 */
class ConnectionManager extends Singleton
{
	/**
	 * Array of {@link Connection} objects.
	 * @var array
	 */
	static private $connections = array();

	/**
     * If $name is null then the default connection will be returned.
     *
     * @see Config
     * @param string $name Optional name of a connection
     * @return Connection
     */
    public static function get_connection($name=null)
    {
        $config = Config::instance();
        $name = $name ? $name : $config->get_default_connection();

        if (!isset(self::$connections[$name]) 
            || !self::$connections[$name]->connection)
            self::$connections[$name] =
                Connection::instance($config->get_connection($name));

        return self::$connections[$name];
    }
	
	/**
     * Drops the connection from the connection manager. Does not actually close it since there
     * is no close method in PDO.
     *
     * @param string $name Name of the connection to forget about
     */
    public static function drop_connection($name=null)
    {
        if (isset(self::$connections[$name]))
            unset(self::$connections[$name]);
    }
}

/**
 * Generic base exception for all ActiveRecord specific errors.
 *
 * @package ActiveRecord
 */
class ActiveRecordException extends \Exception {};

/**
 * Thrown when a record cannot be found.
 *
 * @package ActiveRecord
 */
class RecordNotFound extends ActiveRecordException {};

/**
 * Thrown when there was an error performing a database operation.
 *
 * The error will be specific to whatever database you are running.
 *
 * @package ActiveRecord
 */
class DatabaseException extends ActiveRecordException
{
	public function __construct($adapter_or_string_or_mystery)
	{
		if ($adapter_or_string_or_mystery instanceof Connection)
		{
			parent::__construct(
				join(", ",$adapter_or_string_or_mystery->connection->errorInfo()),
				intval($adapter_or_string_or_mystery->connection->errorCode()));
		}
		elseif ($adapter_or_string_or_mystery instanceof \PDOStatement)
		{
			parent::__construct(
				join(", ",$adapter_or_string_or_mystery->errorInfo()),
				intval($adapter_or_string_or_mystery->errorCode()));
		}
		else
			parent::__construct($adapter_or_string_or_mystery);
	}
};

/**
 * Thrown by {@link Model}.
 *
 * @package ActiveRecord
 */
class ModelException extends ActiveRecordException {};

/**
 * Thrown by {@link Expressions}.
 *
 * @package ActiveRecord
 */
class ExpressionsException extends ActiveRecordException {};

/**
 * Thrown for configuration problems.
 *
 * @package ActiveRecord
 */
class ConfigException extends ActiveRecordException {};

/**
 * Thrown when attempting to access an invalid property on a {@link Model}.
 *
 * @package ActiveRecord
 */
class UndefinedPropertyException extends ModelException
{
	/**
	 * Sets the exception message to show the undefined property's name.
	 *
	 * @param str $property_name name of undefined property
	 * @return void
	 */
	public function __construct($class_name, $property_name)
	{
		if (is_array($property_name))
		{
			$this->message = implode("\r\n", $property_name);
			return;
		}

		$this->message = "Undefined property: {$class_name}->{$property_name} in {$this->file} on line {$this->line}";
		parent::__construct();
	}
};

/**
 * Thrown when attempting to perform a write operation on a {@link Model} that is in read-only mode.
 *
 * @package ActiveRecord
 */
class ReadOnlyException extends ModelException
{
	/**
	 * Sets the exception message to show the undefined property's name.
	 *
	 * @param str $class_name name of the model that is read only
	 * @param str $method_name name of method which attempted to modify the model
	 * @return void
	 */
	public function __construct($class_name, $method_name)
	{
		$this->message = "{$class_name}::{$method_name}() cannot be invoked because this model is set to read only";
		parent::__construct();
	}
};

/**
 * Thrown for validations exceptions.
 *
 * @package ActiveRecord
 */
class ValidationsArgumentError extends ActiveRecordException {};

/**
 * Thrown for relationship exceptions.
 *
 * @package ActiveRecord
 */
class RelationshipException extends ActiveRecordException {};

/**
 * Thrown for has many thru exceptions.
 *
 * @package ActiveRecord
 */
class HasManyThroughAssociationException extends RelationshipException {};

/**
 * Templating like class for building SQL statements.
 *
 * Examples:
 * 'name = :name AND author = :author'
 * 'id = IN(:ids)'
 * 'id IN(:subselect)'
 * 
 * @package ActiveRecord
 */
class Expressions
{
	const ParameterMarker = '?';

	private $expressions;
	private $values = array();
	private $connection;

	public function __construct($connection, $expressions=null /* [, $values ... ] */)
	{
		$values = null;
		$this->connection = $connection;

		if (is_array($expressions))
		{
			$glue = func_num_args() > 2 ? func_get_arg(2) : ' AND ';
			list($expressions,$values) = $this->build_sql_from_hash($expressions,$glue);
		}

		if ($expressions != '')
		{
			if (!$values)
				$values = array_slice(func_get_args(),2);

			$this->values = $values;
			$this->expressions = $expressions;
		}
	}

	/**
	 * Bind a value to the specific one based index. There must be a bind marker
	 * for each value bound or to_s() will throw an exception.
	 */
	public function bind($parameter_number, $value)
	{
		if ($parameter_number <= 0)
			throw new ExpressionsException("Invalid parameter index: $parameter_number");

		$this->values[$parameter_number-1] = $value;
	}

	public function bind_values($values)
	{
		$this->values = $values;
	}

	/**
	 * Returns all the values currently bound.
	 */
	public function values()
	{
		return $this->values;
	}

	/**
	 * Returns the connection object.
	 */
	public function get_connection()
	{
		return $this->connection;
	}

	/**
	 * Sets the connection object. It is highly recommended to set this so we can
	 * use the adapter's native escaping mechanism.
	 *
	 * @param string $connection a Connection instance
	 */
	public function set_connection($connection)
	{
		$this->connection = $connection;
	}

	public function to_s($substitute=false, &$options=null)
	{
		if (!$options) $options = array();
		
		$values = array_key_exists('values',$options) ? $options['values'] : $this->values;

		$ret = "";
		$replace = array();
		$num_values = count($values);
		$len = strlen($this->expressions);
		$quotes = 0;

		for ($i=0,$n=strlen($this->expressions),$j=0; $i<$n; ++$i)
		{
			$ch = $this->expressions[$i];

			if ($ch == self::ParameterMarker)
			{
				if ($quotes % 2 == 0)
				{
					if ($j > $num_values-1)
						throw new ExpressionsException("No bound parameter for index $j");

					$ch = $this->substitute($values,$substitute,$i,$j++);
				}
			}
			elseif ($ch == '\'' && $i > 0 && $this->expressions[$i-1] != '\\')
				++$quotes;

			$ret .= $ch;
		}
		return $ret;
	}

	private function build_sql_from_hash(&$hash, $glue)
	{
		$sql = $g = "";

		foreach ($hash as $name => $value)
		{
			if ($this->connection)
				$name = $this->connection->quote_name($name);

			if (is_array($value))
				$sql .= "$g$name IN(?)";
			else
				$sql .= "$g$name=?";

			$g = $glue;
		}
		return array($sql,array_values($hash));
	}

	private function substitute(&$values, $substitute, $pos, $parameter_index)
	{
		$value = $values[$parameter_index];

		if (is_array($value))
		{
			if ($substitute)
			{
				$ret = '';

				for ($i=0,$n=count($value); $i<$n; ++$i)
					$ret .= ($i > 0 ? ',' : '') . $this->stringify_value($value[$i]);

				return $ret;
			}
			return join(',',array_fill(0,count($value),self::ParameterMarker));
		}

		if ($substitute)
			return $this->stringify_value($value);

		return $this->expressions[$pos];
	}

	private function stringify_value($value)
	{
		if (is_null($value))
			return "NULL";

		return is_string($value) ? $this->quote_string($value) : $value;
	}

	private function quote_string($value)
	{
		if ($this->connection)
			return $this->connection->escape($value);

		return "'" . str_replace("'","''",$value) . "'";
	}
}

/**
 * @package ActiveRecord
 */
abstract class Inflector
{
	/**
	 * Get an instance of the {@link Inflector} class.
	 *
	 * @return object
	 */
	public static function instance()
	{
		return new StandardInflector();
	}

	/**
	 * Turn a string into its camelized version.
	 *
	 * @param string $s string to convert
	 * @return string
	 */
	public function camelize($s)
	{
		$s = preg_replace('/[_-]+/','_',trim($s));
		$s = str_replace(' ', '_', $s);

		$camelized = '';

		for ($i=0,$n=strlen($s); $i<$n; ++$i)
		{
			if ($s[$i] == '_' && $i+1 < $n)
				$camelized .= strtoupper($s[++$i]);
			else
				$camelized .= $s[$i];
		}

		$camelized = trim($camelized,' _');

		if (strlen($camelized) > 0)
			$camelized[0] = strtolower($camelized[0]);

		return $camelized;
	}

	/**
	 * Determines if a string contains all uppercase characters.
	 *
	 * @param string $s string to check
	 * @return bool
	 */
	public static function is_upper($s)
	{
		return (strtoupper($s) === $s);
	}

	/**
	 * Determines if a string contains all lowercase characters.
	 *
	 * @param string $s string to check
	 * @return bool
	 */
	public static function is_lower($s)
	{
		return (strtolower($s) === $s);
	}

	/**
	 * Convert a camelized string to a lowercase, underscored string.
	 *
	 * @param string $s string to convert
	 * @return string
	 */
	public function uncamelize($s)
	{
		$normalized = '';

		for ($i=0,$n=strlen($s); $i<$n; ++$i)
		{
			if (ctype_alpha($s[$i]) && self::is_upper($s[$i]))
				$normalized .= '_' . strtolower($s[$i]);
			else
				$normalized .= $s[$i];
		}
		return trim($normalized,' _');
	}
	
	public function keyify($class_name)
    {
        return strtolower(
            $this->underscorify(denamespace($class_name))
        ) . '_id';
    }

	/**
	 * Convert a string with space into a underscored equivalent.
	 *
	 * @param string $s string to convert
	 * @return string
	 */
	public function underscorify($s)
	{
		return preg_replace(array('/[_\- ]+/','/([a-z])([A-Z])/'),array('_','\\1_\\2'),trim($s));
	}

	abstract function variablize($s);
}

/**
 * @package ActiveRecord
 */
class StandardInflector extends Inflector
{
	public function tableize($s) 
	{ 
	    return Utils::pluralize(strtolower($this->underscorify($s))); 
	}
	
	public function variablize($s) 
	{ 
	    return str_replace(
	        array('-',' '),
	        array('_','_'),
	        $this->uncamelize(trim($s))
	    );     
	}
}

/**
 * The base class for your models.
 *
 * Defining an ActiveRecord model for a table called people and orders:
 *
 * <code>
 * CREATE TABLE people(
 *   id int primary key auto_increment,
 *   parent_id int,
 *   first_name varchar(50),
 *   last_name varchar(50)
 * );
 *
 * CREATE TABLE orders(
 *   id int primary key auto_increment,
 *   person_id int not null,
 *   cost decimal(10,2),
 *   total decimal(10,2)
 * );
 * </code>
 *
 * <code>
 * class Person extends ActiveRecord\Model {
 *   static $belongs_to = array(
 *     array('parent', 'foreign_key' => 'parent_id', 'class_name' => 'Person')
 *   );
 *
 *   static $has_many = array(
 *     array('children', 'foreign_key' => 'parent_id', 'class_name' => 'Person'),
 *     array('orders')
 *   );
 *
 *   static $validates_length_of = array(
 *     array('first_name', 'within' => array(1,50)),
 *     array('last_name', 'within' => array(1,50))
 *   );
 * }
 *
 * class Order extends ActiveRecord\Model {
 *   static $belongs_to = array(
 *     array('person')
 *   );
 *
 *   static $validates_numericality_of = array(
 *     array('cost', 'greater_than' => 0),
 *     array('total', 'greater_than' => 0)
 *   );
 *
 *   static $before_save = array('calculate_total_with_tax');
 *
 *   public function calculate_total_with_tax() {
 *     $this->total = $this->cost * 0.045;
 *   }
 * }
 * </code>
 *
 * For a more in-depth look at defining models, relationships, callbacks and many other things
 * please consult our {@link http://www.phpactiverecord.org/guides Guides}.
 *
 * @package ActiveRecord
 * @see BelongsTo
 * @see CallBack
 * @see HasMany
 * @see HasAndBelongsToMany
 * @see Serialization
 * @see Validations
 */
class Model
{
	/**
	 * An instance of {@link Errors} and will be instantiated once a write method is called.
	 *
	 * @var Errors
	 */
	public $errors;

	/**
	 * Contains model values as column_name => value
	 *
	 * @var array
	 */
	private $attributes = array();

	/**
	 * Flag whether or not this model's attributes have been modified since it will either be null or an array of column_names that have been modified
	 *
	 * @var array
	 */
	private $__dirty = null;

	/**
	 * Flag that determines of this model can have a writer method invoked such as: save/update/insert/delete
	 *
	 * @var boolean
	 */
	private $__readonly = false;

	/**
	 * Array of relationship objects as model_attribute_name => relationship
	 *
	 * @var array
	 */
	private $__relationships = array();

	/**
	 * Flag that determines if a call to save() should issue an insert or an update sql statement
	 *
	 * @var boolean
	 */
	private $__new_record = true;

	/**
	 * Set to the name of the connection this {@link Model} should use.
	 *
	 * @var string
	 */
	static $connection;

	/**
	 * Set to the name of the database this Model's table is in.
	 *
	 * @var string
	 */
	static $db;

	/**
	 * Set this to explicitly specify the model's table name if different from inferred name.
	 *
	 * If your table doesn't follow our table name convention you can set this to the
	 * name of your table to explicitly tell ActiveRecord what your table is called.
	 *
	 * @var string
	 */
	static $table_name;

	/**
	 * Set this to override the default primary key name if different from default name of "id".
	 *
	 * @var string
	 */
	static $primary_key;

	/**
	 * Set this to explicitly specify the sequence name for the table.
	 *
	 * @var string
	 */
	static $sequence;

	/**
	 * Allows you to create aliases for attributes.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $alias_attribute = array(
	 *     'the_first_name' => 'first_name',
	 *     'the_last_name' => 'last_name');
	 * }
	 *
	 * $person = Person::first();
	 * $person->the_first_name = 'Tito';
	 * echo $person->the_first_name;
	 * </code>
	 *
	 * @var array
	 */
	static $alias_attribute = array();

	/**
	 * Whitelist of attributes that are checked from mass-assignment calls such as constructing a model or using update_attributes.
	 *
	 * This is the opposite of {@link attr_protected $attr_protected}.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $attr_accessible = array('first_name','last_name');
	 * }
	 *
	 * $person = new Person(array(
	 *   'first_name' => 'Tito',
	 *   'last_name' => 'the Grief',
	 *   'id' => 11111));
	 *
	 * echo $person->id; # => null
	 * </code>
	 *
	 * @var array
	 */
	static $attr_accessible = array();

	/**
	 * Blacklist of attributes that cannot be mass-assigned.
	 *
	 * This is the opposite of {@link attr_accessible $attr_accessible} and the format
	 * for defining these are exactly the same.
	 * Notice: The attribute 'id' never can be mass-assigned. This change is 
	 * added here for Pragwork as a security improvement. (SW)
	 *
	 * @var array
	 */
	static $attr_protected = array();

	/**
	 * Delegates calls to a relationship.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $belongs_to = array(array('venue'),array('host'));
	 *   static $delegate = array(
	 *     array('name', 'state', 'to' => 'venue'),
	 *     array('name', 'to' => 'host', 'prefix' => 'woot'));
	 * }
	 * </code>
	 *
	 * Can then do:
	 *
	 * <code>
	 * $person->state     # same as calling $person->venue->state
	 * $person->name      # same as calling $person->venue->name
	 * $person->woot_name # same as calling $person->host->name
	 * </code>
	 *
	 * @var array
	 */
	static $delegate = array();

	
	/**
     * Constructs a model.
     *
     * When a user instantiates a new object (e.g.: it was not ActiveRecord that instantiated via a find)
     * then @var $attributes will be mapped according to the schema's defaults. Otherwise, the given
     * $attributes will be mapped via set_attributes_via_mass_assignment.
     *
     * <code>
     * new Person(array('first_name' => 'Tito', 'last_name' => 'the Grief'));
     * </code>
     *
     * @param array $attributes Hash containing names and values to mass assign to the model
     * @param boolean $guard_attributes Set to true to guard attributes
     * @param boolean $instantiating_via_find Set to true if this model is being created from a find call
     * @param boolean $new_record Set to true if this should be considered a new record
     * @return Model
     */
    public function __construct($attributes=array(), $guard_attributes=true,
        $instantiating_via_find=false, $new_record=true)
    {
        $this->__new_record = $new_record;
        
        // initialize attributes applying defaults
        if (!$instantiating_via_find)
        {
            foreach (static::table()->columns as $name => $meta)
                $this->attributes[$meta->inflected_name] = $meta->default;
        }

        $this->set_attributes_via_mass_assignment($attributes,  
            $guard_attributes);

        // since all attribute assignment now goes thru assign_attributes() we want to reset
        // dirty if instantiating via find since nothing is really dirty when doing that
        if ($instantiating_via_find)
            $this->__dirty = array();

        $this->invoke_callback('after_construct',false);
    }

	/**
     * Magic method which delegates to read_attribute(). This handles firing off getter methods,
     * as they are not checked/invoked inside of read_attribute(). This circumvents the problem with
     * a getter being accessed with the same name as an actual attribute.
     *
     * You can also define customer getter methods for the model.
     *
     * EXAMPLE:
     * <code>
     * class User extends ActiveRecord\Model {
     *
     * # define custom getter methods. Note you must
     * # prepend get_ to your method name:
     * function get_middle_initial() {
     * return $this->middle_name{0};
     * }
     * }
     *
     * $user = new User();
     * echo $user->middle_name; # will call $user->get_middle_name()
     * </code>
     *
     * If you define a custom getter with the same name as an attribute then you
     * will need to use read_attribute() to get the attribute's value.
     * This is necessary due to the way __get() works.
     *
     * For example, assume 'name' is a field on the table and we're defining a
     * custom getter for 'name':
     *
     * <code>
     * class User extends ActiveRecord\Model {
     *
     * # INCORRECT way to do it
     * # function get_name() {
     * # return strtoupper($this->name);
     * # }
     * 
     * function get_name() {
     * return strtoupper($this->read_attribute('name'));
     * }
     * }
     *
     * $user = new User();
     * $user->name = 'bob';
     * echo $user->name; # => BOB
     * </code>
     *
     *
     * @see read_attribute()
     * @param string $name Name of an attribute
     * @return mixed The value of the attribute
     */
    public function &__get($name)
    {
        // check for getter
        if (method_exists($this, "get_$name"))
        {
            $name = "get_$name";
            $value = $this->$name();
            return $value;
        }

        return $this->read_attribute($name);
    }

	/**
	 * Determines if an attribute exists for this {@link Model}.
	 *
	 * @param string $attribute_name
	 * @return boolean
	 */
	public function __isset($attribute_name)
	{
		return array_key_exists($attribute_name,$this->attributes) || array_key_exists($attribute_name,static::$alias_attribute);
	}

	/**
     * Magic allows un-defined attributes to set via $attributes.
     *
     * You can also define customer setter methods for the model.
     *
     * EXAMPLE:
     * <code>
     * class User extends ActiveRecord\Model {
     *
     * # define custom setter methods. Note you must
     * # prepend set_ to your method name:
     * function set_password($plaintext) {
     * $this->encrypted_password = md5($plaintext);
     * }
     * }
     *
     * $user = new User();
     * $user->password = 'plaintext'; # will call $user->set_password('plaintext')
     * </code>
     *
     * If you define a custom setter with the same name as an attribute then you
     * will need to use assign_attribute() to assign the value to the attribute.
     * This is necessary due to the way __set() works.
     *
     * For example, assume 'name' is a field on the table and we're defining a
     * custom setter for 'name':
     *
     * <code>
     * class User extends ActiveRecord\Model {
     *
     * # INCORRECT way to do it
     * # function set_name($name) {
     * # $this->name = strtoupper($name);
     * # }
     *
     * function set_name($name) {
     * $this->assign_attribute('name',strtoupper($name));
     * }
     * }
     *
     * $user = new User();
     * $user->name = 'bob';
     * echo $user->name; # => BOB
     * </code>
     *
     * @throws {@link UndefinedPropertyException} if $name does not exist
     * @param string $name Name of attribute, relationship or other to set
     * @param mixed $value The value
     * @return mixed The value
     */
    public function __set($name, $value)
    {
        if (array_key_exists($name, static::$alias_attribute))
            $name = static::$alias_attribute[$name];
        elseif (method_exists($this,"set_$name"))
        {
            $name = "set_$name";
            return $this->$name($value);
        }

        if (array_key_exists($name,$this->attributes))
            return $this->assign_attribute($name,$value);

        if ($name == 'id')
            return $this->assign_attribute($this->get_primary_key(true),$value);

        foreach (static::$delegate as &$item)
        {
            if (($delegated_name = $this->is_delegated($name,$item)))
                return $this->$item['to']->$delegated_name = $value;
        }

        throw new UndefinedPropertyException(get_called_class(),$name);
    }
	
	public function __wakeup()
    {
        // make sure the models Table instance gets initialized when waking up
        static::table();
    }

	/**
	 * Assign a value to an attribute.
	 *
	 * @param string $name Name of the attribute
	 * @param mixed $value Value of the attribute
	 * @return mixed the attribute value
	 */
	public function assign_attribute($name, $value)
	{
		$table = static::table();

		if (array_key_exists($name,$table->columns) && !is_object($value))
			$value = $table->columns[$name]->cast($value,static::connection());

        // convert php's \DateTime to ours
        if ($value instanceof \DateTime)
            $value = new DateTime($value->format('Y-m-d H:i:s T'));

        // make sure DateTime values know what model they belong to so
        // dirty stuff works when calling set methods on the DateTime object
        if ($value instanceof DateTime)
            $value->attribute_of($this,$name);
        
		$this->attributes[$name] = $value;
        $this->flag_dirty($name);
		return $value;
	}

	/**
	 * Retrieves an attribute's value or a relationship object based on the name passed. If the attribute
	 * accessed is 'id' then it will return the model's primary key no matter what the actual attribute name is
	 * for the primary key.
	 *
	 * @param string $name Name of an attribute
	 * @return mixed The value of the attribute
	 * @throws {@link UndefinedPropertyException} if name could not be resolved to an attribute, relationship, ...
	 */
	public function &read_attribute($name)
	{
		// check for aliased attribute
		if (array_key_exists($name, static::$alias_attribute))
			$name = static::$alias_attribute[$name];

		// check for attribute
		if (array_key_exists($name,$this->attributes))
			return $this->attributes[$name];

		// check relationships if no attribute
		if (array_key_exists($name,$this->__relationships))
			return $this->__relationships[$name];

		$table = static::table();

		// this may be first access to the relationship so check Table
		if (($relationship = $table->get_relationship($name)))
		{
			$this->__relationships[$name] = $relationship->load($this);
			return $this->__relationships[$name];
		}

		if ($name == 'id')
        {
            $pk = $this->get_primary_key(true);
            if (isset($this->attributes[$pk]))
                return $this->attributes[$pk];
        }

        $value = null;
        
		foreach (static::$delegate as &$item)
		{
			if ($delegated_name = $this->is_delegated($name, $item))
			{
				$to = $item['to'];
				
				if ($this->$to)
				    $value =& $this->$to->__get($delegated_name);
				
				return $value;
			}
		}

		throw new UndefinedPropertyException(get_called_class(),$name);
	}
    
    /**
     * Flags an attribute as dirty.
     *
     * @param string $name Attribute name
     */
    public function flag_dirty($name)
    {
        if (!$this->__dirty)
            $this->__dirty = array();

        $this->__dirty[$name] = true;
    }

	/**
	 * Returns hash of attributes that have been modified since loading the model.
	 *
	 * @return mixed null if no dirty attributes otherwise returns array of dirty attributes.
	 */
	public function dirty_attributes()
	{
		if (!$this->__dirty)
			return null;

		$dirty = array_intersect_key($this->attributes,$this->__dirty);
		return !empty($dirty) ? $dirty : null;
	}
	
	/**
     * Check if a particular attribute has been modified since loading the model.
     * @param string $attribute Name of the attribute
     * @return bool True if it has been modified.
     */
    public function attribute_is_dirty($attribute)
    {
        return $this->__dirty && $this->__dirty[$attribute] 
            && array_key_exists($attribute, $this->attributes);
    }

	/**
	 * Returns a copy of the model's attributes hash.
	 *
	 * @return array A copy of the model's attribute data
	 */
	public function attributes()
	{
		return $this->attributes;
	}

	/**
	 * Retrieve the primary key name.
	 *
	 * @param boolean Set to true to return the first value in the pk array only
	 * @return string The primary key for the model
	 */
	public function get_primary_key($first=false)
	{
		$pk = static::table()->pk;
        return $first ? $pk[0] : $pk;
	}
	
    /**
     * Returns the actual attribute name if $name is aliased.
     *
     * @param string $name An attribute name
     * @return string
     */
    public function get_real_attribute_name($name)
    {
        if (array_key_exists($name,$this->attributes))
            return $name;

        if (array_key_exists($name,static::$alias_attribute))
            return static::$alias_attribute[$name];

        return null;
    }

	/**
	 * Returns array of validator data for this Model.
	 *
	 * Will return an array looking like:
	 *
	 * <code>
	 * array(
	 *   'name' => array(
	 *     array('validator' => 'validates_presence_of'),
	 *     array('validator' => 'validates_inclusion_of', 'in' => array('Bob','Joe','John')),
	 *   'password' => array(
	 *     array('validator' => 'validates_length_of', 'minimum' => 6))
	 *   )
	 * );
	 * </code>
	 *
	 * @return array An array containing validator data for this model.
	 */
	public function get_validation_rules()
	{
		$validator = new Validations($this);
		return $validator->rules();
	}

	/**
	 * Returns an associative array containing values for all the attributes in $attributes
	 *
	 * @param array $attributes Array containing attribute names
	 * @return array A hash containing $name => $value
	 */
	public function get_values_for($attributes)
	{
		$ret = array();

		foreach ($attributes as $name)
		{
			if (array_key_exists($name,$this->attributes))
				$ret[$name] = $this->attributes[$name];
		}
		return $ret;
	}

	/**
	 * Retrieves the name of the table for this Model.
	 *
	 * @return string
	 */
	public static function table_name()
	{
		return static::table()->table;
	}

	/**
	 * Returns the attribute name on the delegated relationship if $name is
	 * delegated or null if not delegated.
	 *
	 * @param string $name Name of an attribute
	 * @param array $delegate An array containing delegate data
	 * @return delegated attribute name or null
	 */
	private function is_delegated($name, &$delegate)
	{
		if ($delegate['prefix'] != '')
			$name = substr($name,strlen($delegate['prefix'])+1);

		if (is_array($delegate) && in_array($name,$delegate['delegate']))
			return $name;

		return null;
	}

	/**
	 * Determine if the model is in read-only mode.
	 *
	 * @return boolean
	 */
	public function is_readonly()
	{
		return $this->__readonly;
	}

	/**
	 * Determine if the model is a new record.
	 *
	 * @return boolean
	 */
	public function is_new_record()
	{
		return $this->__new_record;
	}

	/**
	 * Throws an exception if this model is set to readonly.
	 *
	 * @throws ActiveRecord\ReadOnlyException
	 * @param string $method_name Name of method that was invoked on model for exception message
	 */
	private function verify_not_readonly($method_name)
	{
		if ($this->is_readonly())
			throw new ReadOnlyException(get_class($this), $method_name);
	}

	/**
	 * Flag model as readonly.
	 *
	 * @param boolean $readonly Set to true to put the model into readonly mode
	 */
	public function readonly($readonly=true)
	{
		$this->__readonly = $readonly;
	}

	/**
	 * Retrieve the connection for this model.
	 *
	 * @return Connection
	 */
	public static function connection()
	{
		return static::table()->conn;
	}
	
	/**
     * Re-establishes the database connection with a new connection.
     *
     * @return Connection
     */
    public static function reestablish_connection()
    {
        return static::table()->reestablish_connection();
    }

	/**
	 * Returns the {@link Table} object for this model.
	 *
	 * Be sure to call in static scoping: static::table()
	 *
	 * @return Table
	 */
	public static function table()
	{
		return Table::load(get_called_class());
	}

	/**
	 * Creates a model and saves it to the database.
	 *
	 * @param array $attributes Array of the models attributes
	 * @param boolean $validate True if the validators should be run
	 * @return Model
	 */
	public static function create($attributes, $validate=true)
	{
		$class_name = get_called_class();
		$model = new $class_name($attributes);
		$model->save($validate);
		return $model;
	}

	/**
	 * Save the model to the database.
	 *
	 * This function will automatically determine if an INSERT or UPDATE needs to occur.
	 * If a validation or a callback for this model returns false, then the model will
	 * not be saved and this will return false.
	 *
	 * If saving an existing model only data that has changed will be saved.
	 *
	 * @param boolean $validate Set to true or false depending on if you want the validators to run or not
	 * @return boolean True if the model was saved to the database otherwise false
	 */
	public function save($validate=true)
	{
		$this->verify_not_readonly('save');
		return $this->is_new_record() ? $this->insert($validate) : $this->update($validate);
	}

	/**
	 * Issue an INSERT sql statement for this model's attribute.
	 *
	 * @see save
	 * @param boolean $validate Set to true or false depending on if you want the validators to run or not
	 * @return boolean True if the model was saved to the database otherwise false
	 */
	private function insert($validate=true)
	{
		$this->verify_not_readonly('insert');

        if ($validate && !$this->_validate() 
            || !$this->invoke_callback('before_create',false))
			return false;

		$table = static::table();

		if (!($attributes = $this->dirty_attributes()))
			$attributes = $this->attributes;

		$pk = $this->get_primary_key(true);
		$use_sequence = false;

		if ($table->sequence && !isset($attributes[$pk]))
		{
			if (($conn = static::connection()) instanceof OciAdapter)
			{
				// terrible oracle makes us select the nextval first
				$attributes[$pk] = $conn->get_next_sequence_value($table->sequence);
				$table->insert($attributes);
				$this->attributes[$pk] = $attributes[$pk];
			}
			else
			{
				// unset pk that was set to null
				if (array_key_exists($pk,$attributes))
					unset($attributes[$pk]);

				$table->insert($attributes,$pk,$table->sequence);
				$use_sequence = true;
			}
		}
		else
			$table->insert($attributes);

	    // if we've got an autoincrementing/sequenced pk set it
        // don't need this check until the day comes that we decide to support composite pks
        // if (count($pk) == 1)
        {
            $column = $table->get_column_by_inflected_name($pk);

            if ($column->auto_increment || $use_sequence)
                $this->attributes[$pk] =
                    $table->conn->insert_id($table->sequence);
        }

		$this->invoke_callback('after_create',false);
		$this->__new_record = false;
		return true;
	}

	/**
	 * Issue an UPDATE sql statement for this model's dirty attributes.
	 *
	 * @see save
	 * @param boolean $validate Set to true or false depending on if you want the validators to run or not
	 * @return boolean True if the model was saved to the database otherwise false
	 */
	private function update($validate=true)
	{
		$this->verify_not_readonly('update');

		if ($validate && !$this->_validate())
			return false;

		if ($this->is_dirty())
		{
			$pk = $this->values_for_pk();

			if (empty($pk))
				throw new ActiveRecordException("Cannot update, no primary key defined for: " . get_called_class());

            if (!$this->invoke_callback('before_update',false))
			    return false;
			$dirty = $this->dirty_attributes();
			static::table()->update($dirty,$pk);
			$this->invoke_callback('after_update',false);
		}

		return true;
	}
	
	/**
     * Deletes records matching conditions in $options
     *
     * Does not instantiate models and therefore does not invoke callbacks
     *
     * Delete all using a hash:
     *
     * <code>
     * YourModel::delete_all(array('conditions' => array('name' => 'Tito')));
     * </code>
     *
     * Delete all using an array:
     *
     * <code>
     * YourModel::delete_all(array('conditions' => array('name = ?', 'Tito')));
     * </code>
     *
     * Delete all using a string:
     *
     * <code>
     * YourModel::delete_all(array('conditions' => 'name = "Tito"));
     * </code>
     *
     * An options array takes the following parameters:
     *
     * <ul>
     * <li><b>conditions:</b> Conditions using a string/hash/array</li>
     * <li><b>limit:</b> Limit number of records to delete (MySQL & Sqlite only)</li>
     * <li><b>order:</b> A SQL fragment for ordering such as: 'name asc', 'id desc, name asc' (MySQL & Sqlite only)</li>
     * </ul>
     *
     * @params array $options
     * return integer Number of rows affected
     */
    public static function delete_all($options=array())
    {
        $table = static::table();
        $conn = static::connection();
        $sql = new SQLBuilder($conn, $table->get_fully_qualified_table_name());

        $conditions = is_array($options) ? $options['conditions'] : $options;

        if (is_array($conditions) && !is_hash($conditions))
            call_user_func_array(array($sql, 'delete'), $conditions);
        else
            $sql->delete($conditions);

        if (isset($options['limit']))
            $sql->limit($options['limit']);

        if (isset($options['order']))
            $sql->order($options['order']);

        $values = $sql->bind_values();
        $ret = $conn->query(($table->last_sql = $sql->to_s()), $values);
        return $ret->rowCount();
    }

    /**
     * Updates records using set in $options
     *
     * Does not instantiate models and therefore does not invoke callbacks
     *
     * Update all using a hash:
     *
     * <code>
     * YourModel::update_all(array('set' => array('name' => "Bob")));
     * </code>
     *
     * Update all using a string:
     *
     * <code>
     * YourModel::update_all(array('set' => 'name = "Bob"'));
     * </code>
     *
     * An options array takes the following parameters:
     *
     * <ul>
     * <li><b>set:</b> String/hash of field names and their values to be updated with
     * <li><b>conditions:</b> Conditions using a string/hash/array</li>
     * <li><b>limit:</b> Limit number of records to update (MySQL & Sqlite only)</li>
     * <li><b>order:</b> A SQL fragment for ordering such as: 'name asc', 'id desc, name asc' (MySQL & Sqlite only)</li>
     * </ul>
     *
     * @params array $options
     * return integer Number of rows affected
     */
    public static function update_all($options=array())
    {
        $table = static::table();
        $conn = static::connection();
        $sql = new SQLBuilder($conn, $table->get_fully_qualified_table_name());

        $sql->update($options['set']);

        if (isset($options['conditions']) 
            && ($conditions = $options['conditions']))
        {
            if (is_array($conditions) && !is_hash($conditions))
                call_user_func_array(array($sql, 'where'), $conditions);
            else
                $sql->where($conditions);
        }

        if (isset($options['limit']))
            $sql->limit($options['limit']);

        if (isset($options['order']))
            $sql->order($options['order']);

        $values = $sql->bind_values();
            $ret = $conn->query(($table->last_sql = $sql->to_s()), $values);
        
        return $ret->rowCount();
    }

	/**
	 * Deletes this model from the database and returns true if successful.
	 *
	 * @return boolean
	 */
	public function delete()
	{
		$this->verify_not_readonly('delete');

		$pk = $this->values_for_pk();

		if (empty($pk))
			throw new ActiveRecordException("Cannot delete, no primary key defined for: " . get_called_class());

		if (!$this->invoke_callback('before_destroy',false))
		    return false;
		static::table()->delete($pk);
		$this->invoke_callback('after_destroy',false);

		return true;
	}

	/**
	 * Helper that creates an array of values for the primary key(s).
	 *
	 * @return array An array in the form array(key_name => value, ...)
	 */
	public function values_for_pk()
	{
		return $this->values_for(static::table()->pk);
	}

	/**
	 * Helper to return a hash of values for the specified attributes.
	 *
	 * @param array $attribute_names Array of attribute names
	 * @return array An array in the form array(name => value, ...)
	 */
	public function values_for($attribute_names)
	{
		$filter = array();

		foreach ($attribute_names as $name)
			$filter[$name] = $this->$name;

		return $filter;
	}

	/**
	 * Validates the model.
	 *
	 * @return boolean True if passed validators otherwise false
	 */
	private function _validate()
	{
		$validator = new Validations($this);
		$validation_on = 'validation_on_' . ($this->is_new_record() ? 'create' : 'update');

		foreach (array('before_validation', "before_$validation_on") as $callback)
		{
			if ($this->invoke_callback($callback,false) === false)
				return false;
		}

		// need to store reference b4 validating so that custom validators have access to add errors
        $this->errors = $validator->get_record();
        $validator->validate();

		foreach (array('after_validation', "after_$validation_on") as $callback)
			$this->invoke_callback($callback,false);

		if (!$this->errors->is_empty())
			return false;

		return true;
	}

	/**
	 * Returns true if the model has been modified.
	 *
	 * @return boolean true if modified
	 */
	public function is_dirty()
	{
		return empty($this->__dirty) ? false : true;
	}

	/**
	 * Run validations on model and returns whether or not model passed validation.
	 *
	 * @see is_invalid
	 * @return boolean
	 */
	public function is_valid()
	{
		return $this->_validate();
	}

	/**
	 * Runs validations and returns true if invalid.
	 *
	 * @see is_valid
	 * @return boolean
	 */
	public function is_invalid()
	{
		return !$this->_validate();
	}

	/**
	 * Updates a model's timestamps.
	 */
	public function set_timestamps()
	{
		$now = date('Y-m-d H:i:s');

		if (isset($this->updated_at))
			$this->updated_at = $now;

		if (isset($this->created_at) && $this->is_new_record())
			$this->created_at = $now;
	}

	/**
	 * Mass update the model with an array of attribute data and saves to the database.
	 *
	 * @param mixed $attributes An attribute data array in the form array(name => value, ...) or an Application\Parameters object
	 * @return boolean True if successfully updated and saved otherwise false
	 */
	public function update_attributes($attributes)
	{
		$this->set_attributes($attributes);
		return $this->save();
	}

	/**
	 * Updates a single attribute and saves the record without going through the normal validation procedure.
	 *
	 * @param string $name Name of attribute
	 * @param mixed $value Value of the attribute
	 * @return boolean True if successful otherwise false
	 */
	public function update_attribute($name, $value)
	{
		$this->__set($name, $value);
		return $this->update(false);
	}

	/**
	 * Mass update the model with data from an attributes hash.
	 *
	 * Unlike update_attributes() this method only updates the model's data
	 * but DOES NOT save it to the database.
	 *
	 * @see update_attributes
	 * @param mixed $attributes An array containing data to update in the form array(name => value, ...) or an Application\Parameters object
	 */
	public function set_attributes($attributes)
	{
		$this->set_attributes_via_mass_assignment($attributes, true);
	}

	/**
	 * Passing $guard_attributes as true will throw an exception if an attribute does not exist.
	 *
	 * @throws ActiveRecord\UndefinedPropertyException
	 * @param mixed $attributes An array in the form array(name => value, ...)
	 *     or the 'Application\Parameters' instance
	 * @param boolean $guard_attributes Flag of whether or not attributes should be guarded
	 */
	private function set_attributes_via_mass_assignment(&$attributes, $guard_attributes)
	{
		//access uninflected columns since that is what we would have in result set
		$table = static::table();
		$exceptions = array();
		$use_attr_accessible = !empty(static::$attr_accessible);
		$use_attr_protected = !empty(static::$attr_protected);
		$connection = static::connection();
        
		foreach ($attributes as $name => $value)
		{   
			// is a normal field on the table
			if (array_key_exists($name,$table->columns))
			{
				$value = $table->columns[$name]->cast($value,$connection);
				$name = $table->columns[$name]->inflected_name;
			}

			if ($guard_attributes)
			{
			    if ($name === 'id')
			        continue;
			    
			    if ($use_attr_accessible)
			    {
			        if (is_array(static::$attr_accessible))
			        {
			            if (!in_array($name, static::$attr_accessible))
				            continue;
				    }
					elseif ($name !== static::$attr_accessible)
					    continue;
				}
			    
                if ($use_attr_protected)
                {
                    if (is_array(static::$attr_protected))
                    {
                        if (in_array($name,static::$attr_protected))
                            continue;
                    }
                    elseif ($name === static::$attr_protected)
                        continue;
                }

				// set valid table data
				try 
				{
					$this->$name = $value;
				} 
				catch (UndefinedPropertyException $e) 
				{
					$exceptions[] = $e->getMessage();
				}
			}
			else
			{
				// ignore OciAdapter's limit() stuff
				if ($name == 'ar_rnum__')
					continue;

				// set arbitrary data
                $this->assign_attribute($name,$value);
			}
		}

		if (!empty($exceptions))
			throw new UndefinedPropertyException(get_called_class(),$exceptions);
	}

	/**
	 * Add a model to the given named ($name) relationship.
	 *
	 * @internal This should <strong>only</strong> be used by eager load
	 * @param Model $model
	 * @param $name of relationship for this table
	 * @return void
	 */
	public function set_relationship_from_eager_load(Model $model=null, $name)
	{
		$table = static::table();

		if (($rel = $table->get_relationship($name)))
		{
			if ($rel->is_poly())
			{
				// if the related model is null and it is a poly then we should have an empty array
				if (is_null($model))
					return $this->__relationships[$name] = array();
				else
					return $this->__relationships[$name][] = $model;
			}
			else
				return $this->__relationships[$name] = $model;
		}

		throw new RelationshipException("Relationship named $name has not been declared for class: {$table->class->getName()}");
	}

	/**
	 * Reloads the attributes and relationships of this object from the database.
	 *
	 * @return Model
	 */
	public function reload()
	{
		$this->__relationships = array();
		$pk = array_values($this->get_values_for($this->get_primary_key()));
        
        $this->set_attributes_via_mass_assignment($this->find($pk)->attributes,
            false);
		$this->reset_dirty();

		return $this;
	}

	public function __clone()
	{
		$this->__relationships = array();
		$this->reset_dirty();
		return $this;
	}

	/**
	 * Resets the dirty array.
	 *
	 * @see dirty_attributes
	 */
	public function reset_dirty()
	{
		$this->__dirty = null;
	}

	/**
	 * A list of valid finder options.
	 *
	 * @var array
	 */
	static $VALID_OPTIONS = array('conditions', 'limit', 'offset', 'order', 'select', 'joins', 'include', 'readonly', 'group', 'from', 'having');

	/**
	 * Enables the use of dynamic finders.
	 *
	 * Dynamic finders are just an easy way to do queries quickly without having to
	 * specify an options array with conditions in it.
	 *
	 * <code>
	 * SomeModel::find_by_first_name('Tito');
	 * SomeModel::find_by_first_name_and_last_name('Tito','the Grief');
	 * SomeModel::find_by_first_name_or_last_name('Tito','the Grief');
	 * SomeModel::find_all_by_last_name('Smith');
	 * SomeModel::count_by_name('Bob')
	 * SomeModel::count_by_name_or_state('Bob','VA')
	 * SomeModel::count_by_name_and_state('Bob','VA')
	 * </code>
	 *
	 * You can also create the model if the find call returned no results:
	 *
	 * <code>
	 * Person::find_or_create_by_name('Tito');
	 *
	 * # would be the equivalent of
	 * if (!Person::find_by_name('Tito'))
	 *   Person::create(array('Tito'));
	 * </code>
	 *
	 * Some other examples of find_or_create_by:
	 *
	 * <code>
	 * Person::find_or_create_by_name_and_id('Tito',1);
	 * Person::find_or_create_by_name_and_id(array('name' => 'Tito', 'id' => 1));
	 * </code>
	 *
	 * @param string $method Name of method
	 * @param mixed $args Method args
	 * @return Model
	 * @throws {@link ActiveRecordException} if invalid query
	 * @see find
	 */
	public static function __callStatic($method, $args)
	{
		$options = static::extract_and_validate_options($args);
		$create = false;

		if (substr($method,0,17) == 'find_or_create_by')
		{
			$attributes = substr($method,17);

			// can't take any finders with OR in it when doing a find_or_create_by
			if (strpos($attributes,'_or_') !== false)
				throw new ActiveRecordException("Cannot use OR'd attributes in find_or_create_by");

			$create = true;
			$method = 'find_by' . substr($method,17);
		}

		if (substr($method,0,7) === 'find_by')
		{
			$attributes = substr($method,8);
			$options['conditions'] = SQLBuilder::create_conditions_from_underscored_string(static::table()->conn,$attributes,$args,static::$alias_attribute);

			if (!($ret = static::find('first',$options)) && $create)
				return static::create(SQLBuilder::create_hash_from_underscored_string($attributes,$args,static::$alias_attribute));

			return $ret;
		}
		elseif (substr($method,0,11) === 'find_all_by')
		{
			$options['conditions'] = SQLBuilder::create_conditions_from_underscored_string(static::table()->conn,substr($method,12),$args,static::$alias_attribute);
			return static::find('all',$options);
		}
		elseif (substr($method,0,8) === 'count_by')
		{
			$options['conditions'] = SQLBuilder::create_conditions_from_underscored_string(static::table()->conn,substr($method,9),$args,static::$alias_attribute);
			return static::count($options);
		}

		throw new ActiveRecordException("Call to undefined method: $method");
	}

	/**
	 * Enables the use of build|create for associations.
	 *
	 * @param string $method Name of method
	 * @param mixed $args Method args
	 * @return mixed An instance of a given {@link AbstractRelationship}
	 */
	public function __call($method, $args)
	{
		//check for build|create_association methods
		if (preg_match('/(build|create)_/', $method))
		{
			if (!empty($args))
				$args = $args[0];

			$association_name = str_replace(array('build_', 'create_'), '', $method);
            $method = str_replace($association_name, 'association', $method);
            $table = static::table();
            
			 if (($association = $table->get_relationship($association_name)) 
			    || ($association = $table->get_relationship((
			    $association_name = Utils::pluralize($association_name)))))
			{
				// access association to ensure that the relationship has been loaded
				// so that we do not double-up on records if we append a newly created
				$this->$association_name;
				return $association->$method($this, $args);
			}
		}

		throw new ActiveRecordException("Call to undefined method: $method");
	}

	/**
	 * Alias for self::find('all').
	 *
	 * @see find
	 * @return array array of records found
	 */
	public static function all(/* ... */)
	{
		return call_user_func_array('static::find',array_merge(array('all'),func_get_args()));
	}

	/**
	 * Get a count of qualifying records.
	 *
	 * <code>
	 * YourModel::count(array('conditions' => 'amount > 3.14159265'));
	 * </code>
	 *
	 * @see find
	 * @return int Number of records that matched the query
	 */
	public static function count(/* ... */)
	{
		$args = func_get_args();
		$options = static::extract_and_validate_options($args);
		$options['select'] = 'COUNT(*)';

		if (!empty($args))
		{
			if (is_hash($args[0]))
				$options['conditions'] = $args[0];
			else
				$options['conditions'] = call_user_func_array('static::pk_conditions',$args);
		}

		$table = static::table();
		$sql = $table->options_to_sql($options);
		$values = $sql->get_where_values();
		return $table->conn->query_and_fetch_one($sql->to_s(),$values);
	}

	/**
	 * Determine if a record exists.
	 *
	 * <code>
	 * SomeModel::exists(123);
	 * SomeModel::exists(array('conditions' => array('id=? and name=?', 123, 'Tito')));
	 * SomeModel::exists(array('id' => 123, 'name' => 'Tito'));
	 * </code>
	 *
	 * @see find
	 * @return boolean
	 */
	public static function exists(/* ... */)
	{
		return call_user_func_array('static::count',func_get_args()) > 0 ? true : false;
	}

	/**
	 * Alias for self::find('first').
	 *
	 * @see find
	 * @return Model The first matched record or null if not found
	 */
	public static function first(/* ... */)
	{
		return call_user_func_array('static::find',array_merge(array('first'),func_get_args()));
	}

	/**
	 * Alias for self::find('last')
	 *
	 * @see find
	 * @return Model The last matched record or null if not found
	 */
	public static function last(/* ... */)
	{
		return call_user_func_array('static::find',array_merge(array('last'),func_get_args()));
	}

	/**
	 * Find records in the database.
	 *
	 * Finding by the primary key:
	 *
	 * <code>
	 * # queries for the model with id=123
	 * YourModel::find(123);
	 *
	 * # queries for model with id in(1,2,3)
	 * YourModel::find(1,2,3);
	 *
	 * # finding by pk accepts an options array
	 * YourModel::find(123,array('order' => 'name desc'));
	 * </code>
	 *
	 * Finding by using a conditions array:
	 *
	 * <code>
	 * YourModel::find('first', array('conditions' => array('name=?','Tito'),
	 *   'order' => 'name asc'))
	 * YourModel::find('all', array('conditions' => 'amount > 3.14159265'));
	 * YourModel::find('all', array('conditions' => array('id in(?)', array(1,2,3))));
	 * </code>
	 *
	 * Finding by using a hash:
	 *
	 * <code>
	 * YourModel::find(array('name' => 'Tito', 'id' => 1));
	 * YourModel::find('first',array('name' => 'Tito', 'id' => 1));
	 * YourModel::find('all',array('name' => 'Tito', 'id' => 1));
	 * </code>
	 *
	 * An options array can take the following parameters:
	 *
	 * <ul>
	 * <li><b>select:</b> A SQL fragment for what fields to return such as: '*', 'people.*', 'first_name, last_name, id'</li>
	 * <li><b>joins:</b> A SQL join fragment such as: 'JOIN roles ON(roles.user_id=user.id)' or a named association on the model</li>
	 * <li><b>include:</b> TODO not implemented yet</li>
	 * <li><b>conditions:</b> A SQL fragment such as: 'id=1', array('id=1'), array('name=? and id=?','Tito',1), array('name IN(?)', array('Tito','Bob')),
	 * array('name' => 'Tito', 'id' => 1)</li>
	 * <li><b>limit:</b> Number of records to limit the query to</li>
	 * <li><b>offset:</b> The row offset to return results from for the query</li>
	 * <li><b>order:</b> A SQL fragment for order such as: 'name asc', 'name asc, id desc'</li>
	 * <li><b>readonly:</b> Return all the models in readonly mode</li>
	 * <li><b>group:</b> A SQL group by fragment</li>
	 * </ul>
	 *
	 * @throws {@link RecordNotFound} if no options are passed or finding by pk and no records matched
	 * @return mixed An array of records found if doing a find_all otherwise a
	 *   single Model object or null if it wasn't found. NULL is only return when
	 *   doing a first/last find. If doing an all find and no records matched this
	 *   will return an empty array.
	 */
	public static function find(/* $type, $options */)
	{
		$class = get_called_class();

		if (func_num_args() <= 0)
			throw new RecordNotFound("Couldn't find $class without an ID");

		$args = func_get_args();
		$options = static::extract_and_validate_options($args);
		$num_args = count($args);
		$single = true;

		if ($num_args > 0 && ($args[0] === 'all' || $args[0] === 'first' || $args[0] === 'last'))
		{
			switch ($args[0])
			{
				case 'all':
					$single = false;
					break;

			 	case 'last':
					if (!array_key_exists('order',$options))
						$options['order'] = join(' DESC, ',static::table()->pk) . ' DESC';
					else
						$options['order'] = SQLBuilder::reverse_order($options['order']);

					// fall thru

			 	case 'first':
			 		$options['limit'] = 1;
			 		$options['offset'] = 0;
			 		break;
			}

			$args = array_slice($args,1);
			$num_args--;
		}
		//find by pk
		elseif (1 === count($args) && 1 == $num_args)
			$args = $args[0];

		// anything left in $args is a find by pk
		if ($num_args > 0 && !isset($options['conditions']))
			return static::find_by_pk($args, $options);

		$options['mapped_names'] = static::$alias_attribute;
		$list = static::table()->find($options);

		return $single ? (!empty($list) ? $list[0] : null) : $list;
	}

	/**
	 * Finder method which will find by a single or array of primary keys for this model.
	 *
	 * @see find
	 * @param array $values An array containing values for the pk
	 * @param array $options An options array
	 * @return Model
	 * @throws {@link RecordNotFound} if a record could not be found
	 */
	public static function find_by_pk($values, $options)
	{
		$options['conditions'] = static::pk_conditions($values);
		$list = static::table()->find($options);
		$results = count($list);

		if ($results != ($expected = count($values)))
		{
			$class = get_called_class();

			if ($expected == 1)
			{
				if (!is_array($values))
					$values = array($values);

				throw new RecordNotFound("Couldn't find $class with ID=" . join(',',$values));
			}

			$values = join(',',$values);
			throw new RecordNotFound("Couldn't find all $class with IDs ($values) (found $results, but was looking for $expected)");
		}
		return $expected == 1 ? $list[0] : $list;
	}

	/**
	 * Find using a raw SELECT query.
	 *
	 * <code>
	 * YourModel::find_by_sql("SELECT * FROM people WHERE name=?",array('Tito'));
	 * YourModel::find_by_sql("SELECT * FROM people WHERE name='Tito'");
	 * </code>
	 *
	 * @param string $sql The raw SELECT query
	 * @param array $values An array of values for any parameters that needs to be bound
	 * @return array An array of models
	 */
	public static function find_by_sql($sql, $values=null)
	{
		return static::table()->find_by_sql($sql, $values, true);
	}
	
	/**
     * Helper method to run arbitrary queries against the model's database connection.
     *
     * @param string $sql SQL to execute
     * @param array $values Bind values, if any, for the query
     * @return object A PDOStatement object
     */
    public static function query($sql, $values=null)
    {
        return static::connection()->query($sql, $values);
    }

	/**
	 * Determines if the specified array is a valid ActiveRecord options array.
	 *
	 * @param array $array An options array
	 * @param bool $throw True to throw an exception if not valid
	 * @return boolean True if valid otherwise valse
	 * @throws {@link ActiveRecordException} if the array contained any invalid options
	 */
	public static function is_options_hash($array, $throw=true)
	{
		if (is_hash($array))
		{
			$keys = array_keys($array);
			$diff = array_diff($keys,self::$VALID_OPTIONS);

			if (!empty($diff) && $throw)
				throw new ActiveRecordException("Unknown key(s): " . join(', ',$diff));

			$intersect = array_intersect($keys,self::$VALID_OPTIONS);

			if (!empty($intersect))
				return true;
		}
		return false;
	}

	/**
	 * Returns a hash containing the names => values of the primary key.
	 *
	 * @internal This needs to eventually support composite keys.
	 * @param mixed $args Primary key value(s)
	 * @return array An array in the form array(name => value, ...)
	 */
	public static function pk_conditions($args)
	{
		$table = static::table();
		$ret = array($table->pk[0] => $args);
		return $ret;
	}

	/**
	 * Pulls out the options hash from $array if any.
	 *
	 * @internal DO NOT remove the reference on $array.
	 * @param array &$array An array
	 * @return array A valid options array
	 */
	public static function extract_and_validate_options(array &$array)
	{
		$options = array();

		if ($array)
		{
			$last = &$array[count($array)-1];

			try
			{
				if (self::is_options_hash($last))
				{
					array_pop($array);
					$options = $last;
				}
			}
			catch (ActiveRecordException $e)
			{
				if (!is_hash($last))
					throw $e;

				$options = array('conditions' => $last);
			}
		}
		return $options;
	}

	/**
	 * Returns a JSON representation of this model.
	 *
	 * @see Serialization
	 * @param array $options An array containing options for json serialization (see {@link Serialization} for valid options)
	 * @return string JSON representation of the model
	 */
	public function to_json(array $options=array())
	{
		return $this->serialize('Json', $options);
	}

	/**
	 * Returns an XML representation of this model.
	 *
	 * @see Serialization
	 * @param array $options An array containing options for xml serialization (see {@link Serialization} for valid options)
	 * @return string XML representation of the model
	 */
	public function to_xml(array $options=array())
	{
		return $this->serialize('Xml', $options);
	}
	
	/**
     * Returns an CSV representation of this model.
     * Can take optional delimiter and enclosure
     * (defaults are , and double quotes)
     *
     * Ex:
     * <code>
     * ActiveRecord\CsvSerializer::$delimiter=';';
     * ActiveRecord\CsvSerializer::$enclosure='';
     * YourModel::find('first')->to_csv(array('only'=>array('name','level')));
     * returns: Joe,2
     *
     * YourModel::find('first')->to_csv(array('only_header'=>true,'only'=>array('name','level')));
     * returns: name,level
     * </code>
     *
     * @see Serialization
     * @param array $options An array containing options for csv serialization (see {@link Serialization} for valid options)
     * @return string CSV representation of the model
     */
    public function to_csv(array $options=array())
    {
        return $this->serialize('Csv', $options);
    }
    
    /**
     * Returns an Array representation of this model.
     *
     * @see Serialization
     * @param array $options An array containing options for json serialization (see {@link Serialization} for valid options)
     * @return array Array representation of the model
     */
    public function to_array(array $options=array())
    {
        return $this->serialize('Array', $options);
    }

	/**
     * Creates a serializer based on pre-defined to_serializer()
     *
     * An options array can take the following parameters:
     *
     * <ul>
     * <li><b>only:</b> a string or array of attributes to be included.</li>
     * <li><b>excluded:</b> a string or array of attributes to be excluded.</li>
     * <li><b>methods:</b> a string or array of methods to invoke. The method's name will be used as a key for the final attributes array
     * along with the method's returned value</li>
     * <li><b>include:</b> a string or array of associated models to include in the final serialized product.</li>
     * </ul>
     *
     * @param string $type Either Xml, Json, Csv or Array
     * @param array $options Options array for the serializer
     * @return string Serialized representation of the model
     */
	private function serialize($type, $options)
	{
		$class = "ActiveRecord\\{$type}Serializer";
		$serializer = new $class($this, $options);
		return $serializer->to_s();
	}

	/**
	 * Invokes the specified callback on this model.
	 *
	 * @param string $method_name Name of the call back to run.
	 * @param boolean $must_exist Set to true to raise an exception if the callback does not exist.
	 * @return boolean True if invoked or null if not
	 */
	private function invoke_callback($method_name, $must_exist=true)
	{
		return static::table()->callback->invoke($this,$method_name,$must_exist);
	}

	/**
	 * Executes a block of code inside a database transaction.
	 *
	 * <code>
	 * YourModel::transaction(function()
	 * {
	 *   YourModel::create(array("name" => "blah"));
	 * });
	 * </code>
	 *
	 * If an exception is thrown inside the closure the transaction will
	 * automatically be rolled back. You can also return false from your
	 * closure to cause a rollback:
	 *
	 * <code>
	 * YourModel::transaction(function()
	 * {
	 *   YourModel::create(array("name" => "blah"));
	 *   throw new Exception("rollback!");
	 * });
	 *
	 * YourModel::transaction(function()
	 * {
	 *   YourModel::create(array("name" => "blah"));
	 *   return false; # rollback!
	 * });
	 * </code>
	 *
	 * @param Closure $closure The closure to execute. To cause a rollback have your closure return false or throw an exception.
     * @return boolean True if the transaction was committed, False if rolled back.
	 */
	public static function transaction($closure)
	{
		$connection = static::connection();

		try
		{
			$connection->transaction();

			if ($closure() === false)
			{
				$connection->rollback();
				return false;
			}
			else
				$connection->commit();
		}
		catch (\Exception $e)
		{
			$connection->rollback();
			throw $e;
		}
		return true;
	}
}

/**
 * Simple class that caches reflections of classes.
 *
 * @package ActiveRecord
 */
class Reflections extends Singleton
{
	/**
	 * Current reflections.
	 *
	 * @var array
	 */
	private $reflections = array();

	/**
	 * Instantiates a new ReflectionClass for the given class.
	 *
	 * @param string $class Name of a class
	 * @return Reflections $this so you can chain calls like Reflections::instance()->add('class')->get()
	 */
	public function add($class=null)
	{
		$class = $this->get_class($class);
        
		if (!isset($this->reflections[$class]))
		{
		    foreach (array('has_many', 'has_one', 'has_and_belongs_to_many', 
                'belongs_to') as $assoc_name)
            {
                if (isset($class::$$assoc_name))
                    self::normalize_associations($class::$$assoc_name);
            }
            
			$this->reflections[$class] = new ReflectionClass($class);
		}
			
		return $this;
	}
	
	private static function normalize_associations(&$definitions)
    {
        if ((array) $definitions !== $definitions)
            $definitions = array(array($definitions));
        else 
        {
            $options = array();

            foreach ($definitions as $key => $value)
            {
                if (is_string($key))
                {
                    $options[$key] = $value;
                    unset($definitions[$key]);
                }
                elseif ((array) $value !== $value)
                    $definitions[$key] = array($value);
            }

            if ($options)
            {
                foreach ($definitions as &$entry)
                    $entry += $options;
            }
        }
    }

	/**
	 * Destroys the cached ReflectionClass.
	 *
	 * Put this here mainly for testing purposes.
	 * 
	 * @param string $class Name of a class.
	 * @return void
	 */
	public function destroy($class)
	{
		if (isset($this->reflections[$class]))
			$this->reflections[$class] = null;
	}
	
	/**
	 * Get a cached ReflectionClass.
	 *
	 * @param string $class Optional name of a class
	 * @return mixed null or a ReflectionClass instance
	 * @throws ActiveRecordException if class was not found
	 */
	public function get($class=null)
	{
		$class = $this->get_class($class);

		if (isset($this->reflections[$class]))
			return $this->reflections[$class];

		throw new ActiveRecordException("Class not found: $class");
	}

	/**
	 * Retrieve a class name to be reflected.
	 *
	 * @param mixed $mixed An object or name of a class
	 * @return string
	 */
	private function get_class($mixed=null)
	{
		if (is_object($mixed))
			return get_class($mixed);

		if (!is_null($mixed))
			return $mixed;

		return $this->get_called_class();
	}
}

/**
 * Interface for a table relationship.
 *
 * @package ActiveRecord
 */
interface InterfaceRelationship
{
	public function __construct($options=array());
	public function build_association(Model $model, $attributes=array());
	public function create_association(Model $model, $attributes=array());
}

/**
 * Abstract class that all relationships must extend from.
 *
 * @package ActiveRecord
 * @see http://www.phpactiverecord.org/guides/associations
 */
abstract class AbstractRelationship implements InterfaceRelationship
{
	/**
	 * Name to be used that will trigger call to the relationship.
	 *
	 * @var string
	 */
	public $attribute_name;

	/**
	 * Class name of the associated model.
	 *
	 * @var string
	 */
	public $class_name;

	/**
	 * Name of the foreign key.
	 *
	 * @var string
	 */
	public $foreign_key = array();

	/**
	 * Options of the relationship.
	 *
	 * @var array
	 */
	protected $options = array();

	/**
	 * Is the relationship single or multi.
	 *
	 * @var boolean
	 */
	protected $poly_relationship = false;

	/**
	 * List of valid options for relationships.
	 *
	 * @var array
	 */
	static protected $valid_association_options = array('class_name', 'class', 'foreign_key', 'conditions', 'select', 'readonly');

	/**
	 * Constructs a relationship.
	 *
	 * @param array $options Options for the relationship (see {@link valid_association_options})
	 * @return mixed
	 */
	public function __construct($options=array())
	{
		$this->attribute_name = $options[0];
		$this->options = $this->merge_association_options($options);

		$relationship = strtolower(denamespace(get_called_class()));

		if ($relationship === 'hasmany' || $relationship === 'hasandbelongstomany')
			$this->poly_relationship = true;

		if (isset($this->options['conditions']) && !is_array($this->options['conditions']))
			$this->options['conditions'] = array($this->options['conditions']);

		if (isset($this->options['class']))
			$this->set_class_name($this->options['class']);
		elseif (isset($this->options['class_name']))
			$this->set_class_name($this->options['class_name']);

		$this->attribute_name = strtolower(Inflector::instance()->variablize($this->attribute_name));

		if (!$this->foreign_key && isset($this->options['foreign_key']))
			$this->foreign_key = is_array($this->options['foreign_key']) ? $this->options['foreign_key'] : array($this->options['foreign_key']);
	}

	protected function get_table()
	{
		return Table::load($this->class_name);
	}

	/**
	 * What is this relationship's cardinality?
	 *
	 * @return bool
	 */
	public function is_poly()
	{
		return $this->poly_relationship;
	}

	/**
	 * Eagerly loads relationships for $models.
	 *
	 * This method takes an array of models, collects PK or FK (whichever is needed for relationship), then queries
	 * the related table by PK/FK and attaches the array of returned relationships to the appropriately named relationship on
	 * $models.
	 *
	 * @param Table $table
	 * @param $models array of model objects
	 * @param $attributes array of attributes from $models
	 * @param $includes array of eager load directives
	 * @param $query_keys -> key(s) to be queried for on included/related table
	 * @param $model_values_keys -> key(s)/value(s) to be used in query from model which is including
	 * @return void
	 */
	protected function query_and_attach_related_models_eagerly(Table $table, $models, $attributes, $includes=array(), $query_keys=array(), $model_values_keys=array())
	{
		$values = array();
        $options = $this->options;
		$inflector = Inflector::instance();
		$query_key = $query_keys[0];
		$model_values_key = $model_values_keys[0];

		foreach ($attributes as $column => $value)
			$values[] = $value[$inflector->variablize($model_values_key)];

		$values = array($values);
		$conditions = SQLBuilder::create_conditions_from_underscored_string(
		    $table->conn,
		    $query_key,
		    $values
		);

        if (isset($options['conditions']) &&strlen($options['conditions'][0])>1)
            Utils::add_condition($options['conditions'], $conditions);
        else
            $options['conditions'] = $conditions;

		if (!empty($includes))
			$options['include'] = $includes;
        
        $options = $this->unset_non_finder_options($options);

		$class = $this->class_name;

		$related_models = $class::find('all', $options);
		$used_models = array();
		$model_values_key = $inflector->variablize($model_values_key);
		$query_key = $inflector->variablize($query_key);

		foreach ($models as $model)
		{
			$matches = 0;
			$key_to_match = $model->$model_values_key;

			foreach ($related_models as $related)
			{
				if ($related->$query_key == $key_to_match)
				{
					$hash = spl_object_hash($related);

					if (in_array($hash, $used_models))
						$model->set_relationship_from_eager_load(clone($related), $this->attribute_name);
					else
						$model->set_relationship_from_eager_load($related, $this->attribute_name);

					$used_models[] = $hash;
					$matches++;
				}
			}

			if (0 === $matches)
				$model->set_relationship_from_eager_load(null, $this->attribute_name);
		}
	}

	/**
	 * Creates a new instance of specified {@link Model} with the attributes pre-loaded.
	 *
	 * @param Model $model The model which holds this association
	 * @param array $attributes Hash containing attributes to initialize the model with
	 * @return Model
	 */
	public function build_association(Model $model, $attributes=array())
	{
		$class_name = $this->class_name;
		return new $class_name($attributes);
	}

	/**
	 * Creates a new instance of {@link Model} and invokes save.
	 *
	 * @param Model $model The model which holds this association
	 * @param array $attributes Hash containing attributes to initialize the model with
	 * @return Model
	 */
	public function create_association(Model $model, $attributes=array())
	{
		$class_name = $this->class_name;
		$new_record = $class_name::create($attributes);
		return $this->append_record_to_associate($model, $new_record);
	}

	protected function append_record_to_associate(Model $associate, Model $record)
	{
		$association =& $associate->{$this->attribute_name};

		if ($this->poly_relationship)
			$association[] = $record;
		else
			$association = $record;

		return $record;
	}

	protected function merge_association_options($options)
	{
		$available_options = array_merge(self::$valid_association_options,static::$valid_association_options);
		$valid_options = array_intersect_key(array_flip($available_options),$options);

		foreach ($valid_options as $option => $v)
			$valid_options[$option] = $options[$option];

		return $valid_options;
	}

	protected function unset_non_finder_options($options)
	{
		foreach (array_keys($options) as $option)
		{
			if (!in_array($option, Model::$VALID_OPTIONS))
				unset($options[$option]);
		}
		return $options;
	}

	/**
	 * Infers the $this->class_name based on $this->attribute_name.
	 *
	 * Will try to guess the appropriate class by singularizing and uppercasing $this->attribute_name.
	 *
	 * @return void
	 * @see attribute_name
	 */
	protected function set_inferred_class_name()
	{
		$this->set_class_name(classify($this->attribute_name));
	}

	protected function set_class_name($class_name)
	{
        $class_name = add_namespace($class_name);
		$reflection = Reflections::instance()->add($class_name)->get($class_name);

		if (!$reflection->isSubClassOf('ActiveRecord\\Model'))
			throw new RelationshipException("'$class_name' must extend from ActiveRecord\\Model");

		$this->class_name = $class_name;
	}

	protected function create_conditions_from_keys(Model $model, $condition_keys=array(), $value_keys=array())
	{
		$condition_string = implode('_and_', $condition_keys);
		$condition_values = array_values($model->get_values_for($value_keys));

		// return null if all the foreign key values are null so that we don't try to do a query like "id is null"
		if (all(null,$condition_values))
			return null;

		$conditions = SQLBuilder::create_conditions_from_underscored_string(Table::load(get_class($model))->conn,$condition_string,$condition_values);

		# DO NOT CHANGE THE NEXT TWO LINES. add_condition operates on a reference and will screw options array up
		if (isset($this->options['conditions']))
			$options_conditions = $this->options['conditions'];
		else
			$options_conditions = array();

		return Utils::add_condition($options_conditions, $conditions);
	}

	/**
	 * Creates INNER JOIN SQL for associations.
	 *
	 * @param Table $from_table the table used for the FROM SQL statement
	 * @param bool $using_through is this a THROUGH relationship?
	 * @param string $alias a table alias for when a table is being joined twice
	 * @return string SQL INNER JOIN fragment
	 */
	public function construct_inner_join_sql(Table $from_table, $using_through=false, $alias=null)
	{
		if ($using_through)
		{
			$join_table = $from_table;
			$join_table_name = $from_table->get_fully_qualified_table_name();
			$from_table_name = Table::load($this->class_name)->get_fully_qualified_table_name();
 		}
		else
		{
			$join_table = Table::load($this->class_name);
			$join_table_name = $join_table->get_fully_qualified_table_name();
			$from_table_name = $from_table->get_fully_qualified_table_name();
		}

		// need to flip the logic when the key is on the other table
		if ($this instanceof HasMany || $this instanceof HasOne)
		{
			$this->set_keys($from_table->class->getName());

			if ($using_through)
			{
				$foreign_key = $this->primary_key[0];
				$join_primary_key = $this->foreign_key[0];
			}
			else
			{
				$join_primary_key = $this->foreign_key[0];
				$foreign_key = $this->primary_key[0];
			}
		}
		else
		{
			$foreign_key = $this->foreign_key[0];
			$join_primary_key = $this->primary_key[0];
		}

		if (!is_null($alias))
		{
			$aliased_join_table_name = $alias = $this->get_table()->conn->quote_name($alias);
			$alias .= ' ';
		}
		else
			$aliased_join_table_name = $join_table_name;

		return "INNER JOIN $join_table_name {$alias}ON($from_table_name.$foreign_key = $aliased_join_table_name.$join_primary_key)";
	}

	/**
	 * This will load the related model data.
	 *
	 * @param Model $model The model this relationship belongs to
	 */
	abstract function load(Model $model);
};

/**
 * One-to-many relationship.
 *
 * <code>
 * # Table: people
 * # Primary key: id
 * # Foreign key: school_id
 * class Person extends ActiveRecord\Model {}
 *
 * # Table: schools
 * # Primary key: id
 * class School extends ActiveRecord\Model {
 *   static $has_many = array(
 *     array('people')
 *   );
 * });
 * </code>
 *
 * Example using options:
 *
 * <code>
 * class Payment extends ActiveRecord\Model {
 *   static $belongs_to = array(
 *     array('person'),
 *     array('order')
 *   );
 * }
 *
 * class Order extends ActiveRecord\Model {
 *   static $has_many = array(
 *     array('people',
 *           'through'    => 'payments',
 *           'select'     => 'people.*, payments.amount',
 *           'conditions' => 'payments.amount < 200')
 *     );
 * }
 * </code>
 *
 * @package ActiveRecord
 * @see http://www.phpactiverecord.org/guides/associations
 * @see valid_association_options
 */
class HasMany extends AbstractRelationship
{
	/**
	 * Valid options to use for a {@link HasMany} relationship.
	 *
	 * <ul>
	 * <li><b>limit/offset:</b> limit the number of records</li>
     * <li><b>primary_key:</b> name of the primary_key of the association (defaults to "id")</li>
     * <li><b>group:</b> GROUP BY clause</li>
     * <li><b>order:</b> ORDER BY clause</li>
     * <li><b>through:</b> name of a model</li>
     * </ul>
	 *
	 * @var array
	 */
	static protected $valid_association_options = array('primary_key', 'order', 'group', 'having', 'limit', 'offset', 'through', 'source');

	protected $primary_key;

	private $has_one = false;
	private $through;

	/**
	 * Constructs a {@link HasMany} relationship.
	 *
	 * @param array $options Options for the association
	 * @return HasMany
	 */
	public function __construct($options=array())
	{
		parent::__construct($options);

		if (isset($this->options['through']))
		{
			$this->through = $this->options['through'];

			if (isset($this->options['source']))
				$this->set_class_name($this->options['source']);
		}

		if (!$this->primary_key && isset($this->options['primary_key']))
			$this->primary_key = is_array($this->options['primary_key']) ? $this->options['primary_key'] : array($this->options['primary_key']);

		if (!$this->class_name)
			$this->set_inferred_class_name();
	}

	protected function set_keys($model_class_name, $override=false)
	{
		//infer from class_name
		if (!$this->foreign_key || $override)
		    $this->foreign_key =
		        array(Inflector::instance()->keyify($model_class_name));

		if (!$this->primary_key || $override)
			$this->primary_key = Table::load($model_class_name)->pk;
	}

	public function load(Model $model)
	{
		$class_name = $this->class_name;
		$this->set_keys(get_class($model));

		// since through relationships depend on other relationships we can't do
		// this initiailization in the constructor since the other relationship
		// may not have been created yet and we only want this to run once
		if (!isset($this->initialized))
		{
			if ($this->through)
			{
				// verify through is a belongs_to or has_many for access of keys
				if (!($through_relationship = $this->get_table()->get_relationship($this->through)))
					throw new HasManyThroughAssociationException("Could not find the association $this->through in model " . get_class($model));

				if (!($through_relationship instanceof HasMany) && !($through_relationship instanceof BelongsTo))
					throw new HasManyThroughAssociationException('has_many through can only use a belongs_to or has_many association');

				// save old keys as we will be reseting them below for inner join convenience
				$pk = $this->primary_key;
				$fk = $this->foreign_key;

				$this->set_keys($this->get_table()->class->getName(), true);

				$through_table = Table::load(classify($this->through, true));
				$this->options['joins'] = $this->construct_inner_join_sql($through_table, true);

				// reset keys
				$this->primary_key = $pk;
				$this->foreign_key = $fk;
			}

			$this->initialized = true;
		}

		if (!($conditions = $this->create_conditions_from_keys($model, $this->foreign_key, $this->primary_key)))
			return null;

		$options = $this->unset_non_finder_options($this->options);
		$options['conditions'] = $conditions;
		return $class_name::find($this->poly_relationship ? 'all' : 'first',$options);
	}

	private function inject_foreign_key_for_new_association(Model $model, &$attributes)
	{
		$this->set_keys($model);
		$primary_key = Inflector::instance()->variablize($this->foreign_key[0]);

		if (!isset($attributes[$primary_key]))
			$attributes[$primary_key] = $model->id;

		return $attributes;
	}

	public function build_association(Model $model, $attributes=array())
	{
		$attributes = $this->inject_foreign_key_for_new_association($model, $attributes);
		return parent::build_association($model, $attributes);
	}

	public function create_association(Model $model, $attributes=array())
	{
		$attributes = $this->inject_foreign_key_for_new_association($model, $attributes);
		return parent::create_association($model, $attributes);
	}

	public function load_eagerly($models=array(), $attributes=array(), $includes, Table $table)
	{
		$this->set_keys($table->class->name);
		$this->query_and_attach_related_models_eagerly($table,$models,$attributes,$includes,$this->foreign_key, $table->pk);
	}
	
	protected function set_inferred_class_name()
	{
		$this->set_class_name(classify($this->attribute_name, true));
	}
};

/**
 * One-to-one relationship.
 *
 * <code>
 * # Table name: states
 * # Primary key: id
 * class State extends ActiveRecord\Model {}
 *
 * # Table name: people
 * # Foreign key: state_id
 * class Person extends ActiveRecord\Model {
 *   static $has_one = array(array('state'));
 * }
 * </code>
 *
 * @package ActiveRecord
 * @see http://www.phpactiverecord.org/guides/associations
 */
class HasOne extends HasMany
{
};

/**
 * @todo implement me
 * @package ActiveRecord
 * @see http://www.phpactiverecord.org/guides/associations
 */
class HasAndBelongsToMany extends AbstractRelationship
{
	public function __construct($options=array())
	{
		/* options =>
		 *   join_table - name of the join table if not in lexical order
		 *   foreign_key -
		 *   association_foreign_key - default is {assoc_class}_id
		 *   uniq - if true duplicate assoc objects will be ignored
		 *   validate
		 */
	}

	public function load(Model $model)
	{

	}
};

/**
 * Belongs to relationship.
 *
 * <code>
 * class School extends ActiveRecord\Model {}
 *
 * class Person extends ActiveRecord\Model {
 *   static $belongs_to = array(
 *     array('school')
 *   );
 * }
 * </code>
 *
 * Example using options:
 *
 * <code>
 * class School extends ActiveRecord\Model {}
 *
 * class Person extends ActiveRecord\Model {
 *   static $belongs_to = array(
 *     array('school', 'primary_key' => 'school_id')
 *   );
 * }
 * </code>
 *
 * @package ActiveRecord
 * @see valid_association_options
 * @see http://www.phpactiverecord.org/guides/associations
 */
class BelongsTo extends AbstractRelationship
{
	public function __construct($options=array())
	{
		parent::__construct($options);

		if (!$this->class_name)
			$this->set_inferred_class_name();

		//infer from class_name
		if (!$this->foreign_key)
		    $this->foreign_key = 
		        array(Inflector::instance()->keyify($this->class_name));

		$this->primary_key = array(Table::load($this->class_name)->pk[0]);
	}

	public function load(Model $model)
	{
		$keys = array();
		$inflector = Inflector::instance();

		foreach ($this->foreign_key as $key)
			$keys[] = $inflector->variablize($key);

		if (!($conditions = $this->create_conditions_from_keys($model, $this->primary_key, $keys)))
			return null;

		$options = $this->unset_non_finder_options($this->options);
		$options['conditions'] = $conditions;
		$class = $this->class_name;
		return $class::first($options);
	}

	public function load_eagerly($models=array(), $attributes, $includes, Table $table)
	{
		$this->query_and_attach_related_models_eagerly($table,$models,$attributes,$includes, $this->primary_key,$this->foreign_key);
	}
}

/**
 * Base class for Model serializers.
 *
 * All serializers support the following options:
 *
 * <ul>
 * <li><b>only:</b> a string or array of attributes to be included.</li>
 * <li><b>except:</b> a string or array of attributes to be excluded.</li>
 * <li><b>methods:</b> a string or array of methods to invoke. The method's name will be used as a key for the final attributes array
 * along with the method's returned value</li>
 * <li><b>include:</b> a string or array of associated models to include in the final serialized product.</li>
 * <li><b>only_method:</b> a method that's called and only the resulting array is serialized
 * <li><b>skip_instruct:</b> set to true to skip the <?xml ...?> declaration.</li>
 * </ul>
 *
 * Example usage:
 *
 * <code>
 * # include the attributes id and name
 * # run $model->encoded_description() and include its return value
 * # include the comments association
 * # include posts association with its own options (nested)
 * $model->to_json(array(
 *   'only' => array('id','name', 'encoded_description'),
 *   'methods' => array('encoded_description'),
 *   'include' => array('comments', 'posts' => array('only' => 'id'))
 * ));
 *
 * # except the password field from being included
 * $model->to_xml(array('except' => 'password')));
 * </code>
 *
 * @package ActiveRecord
 * @link http://www.phpactiverecord.org/guides/utilities#topic-serialization
 */
abstract class Serialization
{
	protected $model;
	protected $options;
	protected $attributes;
    
    /**
     * The default format to serialize DateTime objects to.
     *
     * @see DateTime
     */
    public static $DATETIME_FORMAT = 'iso8601';
	
	/**
	 * Set this to true if the serializer needs to create a nested array keyed
	 * on the name of the included classes such as for xml serialization.
	 *
	 * Setting this to true will produce the following attributes array when
	 * the include option was used:
	 *
	 * <code>
	 * $user = array('id' => 1, 'name' => 'Tito',
	 *   'permissions' => array(
	 *     'permission' => array(
	 *       array('id' => 100, 'name' => 'admin'),
	 *       array('id' => 101, 'name' => 'normal')
	 *     )
	 *   )
	 * );
	 * </code>
	 *
	 * Setting to false will produce this:
	 *
	 * <code>
	 * $user = array('id' => 1, 'name' => 'Tito',
	 *   'permissions' => array(
	 *     array('id' => 100, 'name' => 'admin'),
	 *     array('id' => 101, 'name' => 'normal')
	 *   )
	 * );
	 * </code>
	 *
	 * @var boolean
	 */
	protected $includes_with_class_name_element = false;

	/**
	 * Constructs a {@link Serialization} object.
	 *
	 * @param Model $model The model to serialize
	 * @param array &$options Options for serialization
	 * @return Serialization
	 */
	public function __construct(Model $model, &$options)
	{
		$this->model = $model;
		$this->options = $options;
		$this->attributes = $model->attributes();
		$this->parse_options();
	}

	private function parse_options()
	{
		$this->check_only();
		$this->check_except();
		$this->check_methods();
		$this->check_include();
		$this->check_only_method(); 
	}

	private function check_only()
	{
		if (isset($this->options['only']))
		{
			$this->options_to_a('only');
			
			$exclude = array_diff(array_keys($this->attributes),$this->options['only']);
			$this->attributes = array_diff_key($this->attributes,array_flip($exclude));
		}
	}

	private function check_except()
	{
	    if (isset($this->options['except']) && !isset($this->options['only']))
		{
			$this->options_to_a('except');
			$this->attributes = array_diff_key($this->attributes,array_flip($this->options['except']));
		}
	}

	private function check_methods()
	{
		if (isset($this->options['methods']))
		{
			$this->options_to_a('methods');

			foreach ($this->options['methods'] as $method)
			{
				if (method_exists($this->model, $method))
					$this->attributes[$method] = $this->model->$method();
			}
		}
	}
	
	private function check_only_method()
    {
        if (isset($this->options['only_method']))
        {
            $method = $this->options['only_method'];
            if (method_exists($this->model, $method))
                $this->attributes = $this->model->$method();
        }
    }

	private function check_include()
	{
		if (isset($this->options['include']))
		{
			$this->options_to_a('include');

			$serializer_class = get_class($this);

			foreach ($this->options['include'] as $association => $options)
			{
				if (!is_array($options))
				{
					$association = $options;
					$options = array();
				}

				try {
					$assoc = $this->model->$association;

					if (!is_array($assoc))
					{
						$serialized = new $serializer_class($assoc, $options);
						$this->attributes[$association] = $serialized->to_a();;
					}
					else
					{
						$includes = array();

						foreach ($assoc as $a)
						{
							$serialized = new $serializer_class($a, $options);

							if ($this->includes_with_class_name_element)
								$includes[strtolower(get_class($a))][] = $serialized->to_a();
							else
								$includes[] = $serialized->to_a();
						}

						$this->attributes[$association] = $includes;
					}

				} catch (UndefinedPropertyException $e) {
					;//move along
				}
			}
		}
	}

	final protected function options_to_a($key)
	{
		if (!is_array($this->options[$key]))
			$this->options[$key] = array($this->options[$key]);
	}

	/**
     * Returns the attributes array.
     * @return array
     */
    final public function to_a()
    {
        foreach ($this->attributes as &$value)
        {
            if ($value instanceof \DateTime)
                $value = $value->format(self::$DATETIME_FORMAT);
        }
        return $this->attributes;
    }

	/**
	 * Returns the serialized object as a string.
	 * @see to_s
	 * @return string
	 */
	final public function __toString()
	{
		return $this->to_s();
	}

	/**
	 * Performs the serialization.
	 * @return string
	 */
	abstract public function to_s();
};

/**
 * Array serializer.
 *
 * @package ActiveRecord
 */
class ArraySerializer extends Serialization
{
    public static $include_root = false;

    public function to_s()
    {
        return self::$include_root 
            ? array(strtolower(get_class($this->model)) => $this->to_a()) 
            : $this->to_a();
    }
}

/**
 * JSON serializer.
 *
 * @package ActiveRecord
 */
class JsonSerializer extends ArraySerializer
{
    public static $include_root = false;

    public function to_s()
    {
        parent::$include_root = self::$include_root;
        return json_encode(parent::to_s());
    }
}

/**
 * XML serializer.
 *
 * @package ActiveRecord
 */
class XmlSerializer extends Serialization
{
	private $writer;

	public function __construct(Model $model, &$options)
	{
		$this->includes_with_class_name_element = true;
		parent::__construct($model,$options);
	}

	public function to_s()
	{
		return $this->xml_encode();
	}

	private function xml_encode()
	{
		$this->writer = new XmlWriter();
		$this->writer->openMemory();
		$this->writer->startDocument('1.0', 'UTF-8');
		$this->writer->startElement(strtolower(denamespace(($this->model))));
        $this->write($this->to_a());
		$this->writer->endElement();
		$this->writer->endDocument();
		$xml = $this->writer->outputMemory(true);

		if (@$this->options['skip_instruct'] == true)
			$xml = preg_replace('/<\?xml version.*?\?>/','',$xml);

		return $xml;
	}

	private function write($data, $tag=null)
	{
		foreach ($data as $attr => $value)
		{
			if ($tag != null)
				$attr = $tag;

			if (is_array($value) || is_object($value))
			{
				if (!is_int(key($value)))
				{
					$this->writer->startElement($attr);
					$this->write($value);
					$this->writer->endElement();
				}
				else
					$this->write($value, $attr);

				continue;
			}

			$this->writer->writeElement($attr, $value);
		}
	}
}

/**
 * CSV serializer.
 *
 * @package ActiveRecord
 */
class CsvSerializer extends Serialization
{
    public static $delimiter = ',';
    public static $enclosure = '"';

    public function to_s()
    {
        if (@$this->options['only_header'] == true) return $this->header();
        return $this->row();
    }

    private function header()
    {
        return $this->to_csv(array_keys($this->to_a()));
    }

    private function row()
    {
        return $this->to_csv($this->to_a());
    }

    private function to_csv($arr)
    {
        $outstream = fopen('php://temp', 'w');
        fputcsv($outstream, $arr, self::$delimiter, self::$enclosure);
        rewind($outstream);
        $buffer = trim(stream_get_contents($outstream));
        fclose($outstream);
        return $buffer;
    }
}

/**
 * This implementation of the singleton pattern does not conform to the strong definition
 * given by the "Gang of Four." The __construct() method has not be privatized so that
 * a singleton pattern is capable of being achieved; however, multiple instantiations are also
 * possible. This allows the user more freedom with this pattern.
 *
 * @package ActiveRecord
 */
abstract class Singleton
{
	/**
	 * Array of cached singleton objects.
	 *
	 * @var array
	 */
	private static $instances = array();

	/**
	 * Static method for instantiating a singleton object.
	 *
	 * @return object
	 */
	final public static function instance()
	{
		$class_name = get_called_class();

		if (!isset(self::$instances[$class_name]))
			self::$instances[$class_name] = new $class_name;

		return self::$instances[$class_name];
	}

	/**
	 * Singleton objects should not be cloned.
	 *
	 * @return void
	 */
	final private function __clone() {}

	/**
	 * Similar to a get_called_class() for a child class to invoke.
	 *
	 * @return string
	 */
	final protected function get_called_class()
	{
		$backtrace = debug_backtrace();
    	return get_class($backtrace[2]['object']);
	}
}

/**
 * Helper class for building sql statements progmatically.
 *
 * @package ActiveRecord
 */
class SQLBuilder
{
	private $connection;
	private $operation = 'SELECT';
	private $table;
	private $select = '*';
	private $joins;
	private $order;
	private $limit;
	private $offset;
	private $group;
	private $having;
	private $update;

	// for where
	private $where;
	private $where_values = array();

	// for insert/update
	private $data;
	private $sequence;

	/**
	 * Constructor.
	 *
	 * @param Connection $connection A database connection object
	 * @param string $table Name of a table
	 * @return SQLBuilder
	 * @throws ActiveRecordException if connection was invalid
	 */
	public function __construct($connection, $table)
	{
		if (!$connection)
			throw new ActiveRecordException('A valid database connection is required.');

		$this->connection	= $connection;
		$this->table		= $table;
	}

	/**
	 * Returns the SQL string.
	 *
	 * @return string
	 */
	public function __toString()
	{
		return $this->to_s();
	}

	/**
	 * Returns the SQL string.
	 *
	 * @see __toString
	 * @return string
	 */
	public function to_s()
	{
		$func = 'build_' . strtolower($this->operation);
		return $this->$func();
	}

	/**
	 * Returns the bind values.
	 *
	 * @return array
	 */
	public function bind_values()
	{
		$ret = array();

		if ($this->data)
			$ret = array_values($this->data);

		if ($this->get_where_values())
			$ret = array_merge($ret,$this->get_where_values());

		return array_flatten($ret);
	}

	public function get_where_values()
	{
		return $this->where_values;
	}

	public function where(/* (conditions, values) || (hash) */)
	{
		$this->apply_where_conditions(func_get_args());
		return $this;
	}

	public function order($order)
	{
		$this->order = $order;
		return $this;
	}

	public function group($group)
	{
		$this->group = $group;
		return $this;
	}

	public function having($having)
	{
		$this->having = $having;
		return $this;
	}

	public function limit($limit)
	{
		$this->limit = intval($limit);
		return $this;
	}

	public function offset($offset)
	{
		$this->offset = intval($offset);
		return $this;
	}

	public function select($select)
	{
		$this->operation = 'SELECT';
		$this->select = $select;
		return $this;
	}

	public function joins($joins)
	{
		$this->joins = $joins;
		return $this;
	}

	public function insert($hash, $pk=null, $sequence_name=null)
	{
		if (!is_hash($hash))
			throw new ActiveRecordException('Inserting requires a hash.');

		$this->operation = 'INSERT';
		$this->data = $hash;

		if ($pk && $sequence_name)
			$this->sequence = array($pk,$sequence_name);

		return $this;
	}

	public function update($mixed)
    {
        $this->operation = 'UPDATE';

        if (is_hash($mixed))
            $this->data = $mixed;
        elseif (is_string($mixed))
            $this->update = $mixed;
        else
            throw new ActiveRecordException('Updating requires a hash or string.');

        return $this;
    }

	public function delete()
	{
		$this->operation = 'DELETE';
		$this->apply_where_conditions(func_get_args());
		return $this;
	}

	/**
	 * Reverses an order clause.
	 */
	public static function reverse_order($order)
	{
		if (!trim($order))
			return $order;

		$parts = explode(',',$order);

		for ($i=0,$n=count($parts); $i<$n; ++$i)
		{
			$v = strtolower($parts[$i]);

			if (strpos($v,' asc') !== false)
				$parts[$i] = preg_replace('/asc/i','DESC',$parts[$i]);
			elseif (strpos($v,' desc') !== false)
				$parts[$i] = preg_replace('/desc/i','ASC',$parts[$i]);
			else
				$parts[$i] .= ' DESC';
		}
		return join(',',$parts);
	}

	/**
	 * Converts a string like "id_and_name_or_z" into a conditions value like array("id=? AND name=? OR z=?", values, ...).
	 *
	 * @param Connection $connection
	 * @param $name Underscored string
	 * @param $values Array of values for the field names. This is used
	 *   to determine what kind of bind marker to use: =?, IN(?), IS NULL
	 * @param $map A hash of "mapped_column_name" => "real_column_name"
	 * @return A conditions array in the form array(sql_string, value1, value2,...)
	 */
	public static function create_conditions_from_underscored_string(Connection $connection, $name, &$values=array(), &$map=null)
	{
		if (!$name)
			return null;

		$parts = preg_split('/(_and_|_or_)/i',$name,-1,PREG_SPLIT_DELIM_CAPTURE);
		$num_values = count($values);
		$conditions = array('');

		for ($i=0,$j=0,$n=count($parts); $i<$n; $i+=2,++$j)
		{
			if ($i >= 2)
				$conditions[0] .= preg_replace(array('/_and_/i','/_or_/i'),array(' AND ',' OR '),$parts[$i-1]);

			if ($j < $num_values)
			{
				if (!is_null($values[$j]))
				{
					$bind = is_array($values[$j]) ? ' IN(?)' : '=?';
					$conditions[] = $values[$j];
				}
				else
					$bind = ' IS NULL';
			}
			else
				$bind = ' IS NULL';

			// map to correct name if $map was supplied
			$name = $map && isset($map[$parts[$i]]) ? $map[$parts[$i]] : $parts[$i];

			$conditions[0] .= $connection->quote_name($name) . $bind;
		}
		return $conditions;
	}

	/**
	 * Like create_conditions_from_underscored_string but returns a hash of name => value array instead.
	 *
	 * @param string $name A string containing attribute names connected with _and_ or _or_
	 * @param $args Array of values for each attribute in $name
	 * @param $map A hash of "mapped_column_name" => "real_column_name"
	 * @return array A hash of array(name => value, ...)
	 */
	public static function create_hash_from_underscored_string($name, &$values=array(), &$map=null)
	{
		$parts = preg_split('/(_and_|_or_)/i',$name);
		$hash = array();

		for ($i=0,$n=count($parts); $i<$n; ++$i)
		{
			// map to correct name if $map was supplied
			$name = $map && isset($map[$parts[$i]]) ? $map[$parts[$i]] : $parts[$i];
			$hash[$name] = $values[$i];
		}
		return $hash;
	}
	
	/**
     * prepends table name to hash of field names to get around ambiguous fields when SQL builder
     * has joins
     *
     * @param array $hash
     * @return array $new
     */
    private function prepend_table_name_to_fields($hash=array())
    {
        $new = array();
        $table = $this->connection->quote_name($this->table);

        foreach ($hash as $key => $value)
        {
            $k = $this->connection->quote_name($key);
            $new[$table.'.'.$k] = $value;
        }

        return $new;
    }
	
	private function apply_where_conditions($args)
	{
		$num_args = count($args);

		if ($num_args == 1 && is_hash($args[0]))
		{
			$hash = is_null($this->joins) 
			    ? $args[0] : $this->prepend_table_name_to_fields($args[0]);
            $e = new Expressions($this->connection,$hash);
			$this->where = $e->to_s();
			$this->where_values = array_flatten($e->values());
		}
		elseif ($num_args > 0)
		{
			// if the values has a nested array then we'll need to use Expressions to expand the bind marker for us
			$values = array_slice($args,1);

			foreach ($values as $name => &$value)
			{
				if (is_array($value))
				{
					$e = new Expressions($this->connection,$args[0]);
					$e->bind_values($values);
					$this->where = $e->to_s();
					$this->where_values = array_flatten($e->values());
					return;
				}
			}

			// no nested array so nothing special to do
			$this->where = $args[0];
			$this->where_values = &$values;
		}
	}

	private function build_delete()
    {
        $sql = "DELETE FROM $this->table";

        if ($this->where)
            $sql .= " WHERE $this->where";

        if ($this->connection->accepts_limit_and_order_for_update_and_delete())
        {
            if ($this->order)
                $sql .= " ORDER BY $this->order";

            if ($this->limit)
                $sql = $this->connection->limit($sql,null,$this->limit);
        }

        return $sql;
    }

	private function build_insert()
	{
		$keys = join(',',$this->quoted_key_names());

		if ($this->sequence)
		{
			$sql =
				"INSERT INTO $this->table($keys," 
				. $this->connection->quote_name($this->sequence[0]) 
				. ") VALUES(?," 
				. $this->connection->next_sequence_value($this->sequence[1]) 
				. ")";
		}
		else
			$sql = "INSERT INTO $this->table($keys) VALUES(?)";

		$e = new Expressions($this->connection,$sql,array_values($this->data));
		return $e->to_s();
	}

	private function build_select()
	{
		$sql = "SELECT $this->select FROM $this->table";

		if ($this->joins)
			$sql .= ' ' . $this->joins;

		if ($this->where)
			$sql .= " WHERE $this->where";

		if ($this->group)
			$sql .= " GROUP BY $this->group";

		if ($this->having)
			$sql .= " HAVING $this->having";

		if ($this->order)
			$sql .= " ORDER BY $this->order";

		if ($this->limit || $this->offset)
			$sql = $this->connection->limit($sql,$this->offset,$this->limit);

		return $sql;
	}

	private function build_update()
    {
        if (strlen($this->update) > 0)
            $set = $this->update;
        else
            $set = join('=?, ', $this->quoted_key_names()) . '=?';

        $sql = "UPDATE $this->table SET $set";

        if ($this->where)
            $sql .= " WHERE $this->where";

        if ($this->connection->accepts_limit_and_order_for_update_and_delete())
        {
            if ($this->order)
                $sql .= " ORDER BY $this->order";

            if ($this->limit)
                $sql = $this->connection->limit($sql,null,$this->limit);
        }

        return $sql;
    }

	private function quoted_key_names()
	{
		$keys = array();

		foreach ($this->data as $key => $value)
			$keys[] = $this->connection->quote_name($key);

		return $keys;
	}
}

/**
 * Manages reading and writing to a database table.
 *
 * This class manages a database table and is used by the Model class for
 * reading and writing to its database table. There is one instance of Table
 * for every table you have a model for.
 *
 * @package ActiveRecord
 */
class Table
{
	private static $cache = array();

	public $class;
	public $conn;
	public $pk;
	public $last_sql;

	// Name/value pairs of columns in this table
	public $columns = array();

	/**
	 * Name of the table.
	 */
	public $table;

	/**
	 * Name of the database (optional)
	 */
	public $db_name;

	/**
	 * Name of the sequence for this table (optional). Defaults to {$table}_seq
	 */
	public $sequence;

	/**
	 * A instance of CallBack for this model/table
	 * @static
	 * @var object ActiveRecord\CallBack
	 */
	public $callback;

	/**
	 * List of relationships for this table.
	 */
	private $relationships = array();

	public static function load($model_class_name)
	{
	    $model_class_name = add_namespace($model_class_name);
		if (!isset(self::$cache[$model_class_name]))
		{
			/* do not place set_assoc in constructor..it will lead to infinite loop due to
			   relationships requesting the model's table, but the cache hasn't been set yet */
			self::$cache[$model_class_name] = new Table($model_class_name);
			self::$cache[$model_class_name]->set_associations();
		}

		return self::$cache[$model_class_name];
	}

	public static function clear_cache($model_class_name=null)
	{
		if ($model_class_name && array_key_exists($model_class_name,self::$cache))
			unset(self::$cache[$model_class_name]);
		else
			self::$cache = array();
	}

	public function __construct($class_name)
    {
        $this->class =
            Reflections::instance()->add($class_name)->get($class_name);

        $this->reestablish_connection(false);
        $this->set_table_name();
        $this->get_meta_data();
        $this->set_primary_key();
        $this->set_sequence_name();
        $this->set_delegates();

        $this->callback = new CallBack($class_name);
        $this->callback->register(
            'before_save', 
            function(Model $model) {   
                $model->set_timestamps(); 
            }, 
            array('prepend' => true)
        );
        $this->callback->register(
            'after_save', 
            function(Model $model) { 
                $model->reset_dirty(); 
            }, 
            array('prepend' => true)
        );
    }
    
    public function reestablish_connection($close=true)
    {
        // if connection name property is null the connection manager 
        // will use the default connection
        $connection = $this->class->getStaticPropertyValue('connection',null);

        if ($close)
        {
            ConnectionManager::drop_connection($connection);
            static::clear_cache();
        }

            return ($this->conn =
                ConnectionManager::get_connection($connection));
    }

	public function create_joins($joins)
	{
		if (!is_array($joins))
			return $joins;

		$self = $this->table;
		$ret = $space = '';

		$existing_tables = array();
		foreach ($joins as $value)
		{
			$ret .= $space;

			if (stripos($value,'JOIN ') === false)
			{
				if (array_key_exists($value, $this->relationships))
				{
					$rel = $this->get_relationship($value);

					// if there is more than 1 join for a given table we need to alias the table names
					if (array_key_exists($rel->class_name, $existing_tables))
					{
						$alias = $value;
						$existing_tables[$rel->class_name]++;
					}
					else
					{
						$existing_tables[$rel->class_name] = true;
						$alias = null;
					}

					$ret .= $rel->construct_inner_join_sql($this, false, $alias);
				}
				else
					throw new RelationshipException("Relationship named $value has not been declared for class: {$this->class->getName()}");
			}
			else
				$ret .= $value;

			$space = ' ';
		}
		return $ret;
	}

	public function options_to_sql($options)
	{
		$table = array_key_exists('from', $options) ? $options['from'] : $this->get_fully_qualified_table_name();
		$sql = new SQLBuilder($this->conn, $table);

		if (array_key_exists('joins',$options))
		{
			$sql->joins($this->create_joins($options['joins']));

			// by default, an inner join will not fetch the fields from the joined table
			if (!array_key_exists('select', $options))
				$options['select'] = $this->get_fully_qualified_table_name() . '.*';
		}

		if (array_key_exists('select',$options))
			$sql->select($options['select']);

		if (array_key_exists('conditions',$options))
		{
			if (!is_hash($options['conditions']))
			{
				if (is_string($options['conditions']))
					$options['conditions'] = array($options['conditions']);

				call_user_func_array(array($sql,'where'),$options['conditions']);
			}
			else
			{
				if (!empty($options['mapped_names']))
					$options['conditions'] = $this->map_names($options['conditions'],$options['mapped_names']);

				$sql->where($options['conditions']);
			}
		}

		if (array_key_exists('order',$options))
			$sql->order($options['order']);

		if (array_key_exists('limit',$options))
			$sql->limit($options['limit']);

		if (array_key_exists('offset',$options))
			$sql->offset($options['offset']);

		if (array_key_exists('group',$options))
			$sql->group($options['group']);

		if (array_key_exists('having',$options))
			$sql->having($options['having']);

		return $sql;
	}

	public function find($options)
	{
		$sql = $this->options_to_sql($options);
		$readonly = (array_key_exists('readonly',$options) && $options['readonly']) ? true : false;
		$eager_load = array_key_exists('include',$options) ? $options['include'] : null;

		return $this->find_by_sql($sql->to_s(),$sql->get_where_values(), $readonly, $eager_load);
	}

	public function find_by_sql($sql, $values=null, $readonly=false, $includes=null)
	{
		$this->last_sql = $sql;

		$collect_attrs_for_includes = is_null($includes) ? false : true;
		$list = $attrs = array();
		$sth = $this->conn->query($sql,$this->process_data($values));

		while (($row = $sth->fetch()))
		{
			$model = new $this->class->name($row,false,true,false);

			if ($readonly)
				$model->readonly();

			if ($collect_attrs_for_includes)
				$attrs[] = $model->attributes();

			$list[] = $model;
		}

	    if ($collect_attrs_for_includes && !empty($list))
            $this->execute_eager_load($list, $attrs, $includes);

		return $list;
	}

	/**
	 * Executes an eager load of a given named relationship for this table.
	 *
	 * @param $models array found modesl for this table
	 * @param $attrs array of attrs from $models
	 * @param $includes array eager load directives
	 * @return void
	 */
	private function execute_eager_load($models=array(), $attrs=array(), $includes=array())
	{
		if (!is_array($includes))
			$includes = array($includes);

		foreach ($includes as $index => $name)
		{
			// nested include
			if (is_array($name))
			{
				$nested_includes = count($name) > 1 ? $name : $name[0];
				$name = $index;
			}
			else
				$nested_includes = array();

			$rel = $this->get_relationship($name, true);
			$rel->load_eagerly($models, $attrs, $nested_includes, $this);
		}
	}

	public function get_column_by_inflected_name($inflected_name)
	{
		foreach ($this->columns as $raw_name => $column)
		{
			if ($column->inflected_name == $inflected_name)
				return $column;
		}
		return null;
	}

	public function get_fully_qualified_table_name($quote_name=true)
	{
		$table = $quote_name ? $this->conn->quote_name($this->table) : $this->table;

		if ($this->db_name)
			$table = $this->conn->quote_name($this->db_name) . ".$table";

		return $table;
	}

	/**
	 * Retrieve a relationship object for this table. Strict as true will throw an error
	 * if the relationship name does not exist.
	 *
	 * @param $name string name of Relationship
	 * @param $strict bool
	 * @throws RelationshipException
	 * @return Relationship or null
	 */
	public function get_relationship($name, $strict=false)
	{
		if ($this->has_relationship($name))
			return $this->relationships[$name];

		if ($strict)
			throw new RelationshipException("Relationship named $name has not been declared for class: {$this->class->getName()}");

		return null;
	}

	/**
	 * Does a given relationship exist?
	 *
	 * @param $name string name of Relationship
	 * @return bool
	 */
	public function has_relationship($name)
	{
		return array_key_exists($name, $this->relationships);
	}

	public function insert(&$data, $pk=null, $sequence_name=null)
	{
		$data = $this->process_data($data);

		$sql = new SQLBuilder($this->conn,$this->get_fully_qualified_table_name());
		$sql->insert($data,$pk,$sequence_name);

		$values = array_values($data);
		return $this->conn->query(($this->last_sql = $sql->to_s()),$values);
	}

	public function update(&$data, $where)
	{
		$data = $this->process_data($data);

		$sql = new SQLBuilder($this->conn,$this->get_fully_qualified_table_name());
		$sql->update($data)->where($where);

		$values = $sql->bind_values();
		return $this->conn->query(($this->last_sql = $sql->to_s()),$values);
	}

	public function delete($data)
	{
		$data = $this->process_data($data);

		$sql = new SQLBuilder($this->conn,$this->get_fully_qualified_table_name());
		$sql->delete($data);

		$values = $sql->bind_values();
		return $this->conn->query(($this->last_sql = $sql->to_s()),$values);
	}

	/**
	 * Add a relationship.
	 *
	 * @param Relationship $relationship a Relationship object
	 */
	private function add_relationship($relationship)
	{
		$this->relationships[$relationship->attribute_name] = $relationship;
	}

	private function get_meta_data()
	{
		// as more adapters are added probably want to do this a better way
		// than using instanceof but gud enuff for now
		$quote_name = !($this->conn instanceof PgsqlAdapter);

		$table_name = $this->get_fully_qualified_table_name($quote_name);
        $conn = $this->conn;
        $this->columns = Cache::get("get_meta_data-$table_name", 
            function() use ($conn, $table_name) { 
                return $conn->columns($table_name); 
            }
        );
	}

	/**
	 * Replaces any aliases used in a hash based condition.
	 *
	 * @param $hash array A hash
	 * @param $map array Hash of used_name => real_name
	 * @return array Array with any aliases replaced with their read field name
	 */
	private function map_names(&$hash, &$map)
	{
		$ret = array();

		foreach ($hash as $name => &$value)
		{
			if (array_key_exists($name,$map))
				$name = $map[$name];

			$ret[$name] = $value;
		}
		return $ret;
	}

	private function &process_data($hash)
	{
		foreach ($hash as $name => &$value)
		{
			if ($value instanceof \DateTime)
            {
                if (isset($this->columns[$name]) 
                    && $this->columns[$name]->type == Column::DATE)
                    $hash[$name] = $this->conn->date_to_string($value);
                else
                    $hash[$name] = $this->conn->datetime_to_string($value);
            }
            else
                $hash[$name] = $value;
		}
		return $hash;
	}

	private function set_primary_key()
	{
		if (($pk = $this->class->getStaticPropertyValue('pk',null)) || ($pk = $this->class->getStaticPropertyValue('primary_key',null)))
			$this->pk = is_array($pk) ? $pk : array($pk);
		else
		{
			$this->pk = array();

			foreach ($this->columns as $c)
			{
				if ($c->pk)
					$this->pk[] = $c->inflected_name;
			}
		}
	}

	private function set_table_name()
	{
		if (($table = $this->class->getStaticPropertyValue('table',null)) || ($table = $this->class->getStaticPropertyValue('table_name',null)))
			$this->table = $table;
		else
		{
			// infer table name from the class name
			$this->table = Inflector::instance()->tableize($this->class->getName());

			// strip namespaces from the table name if any
			$parts = explode('\\',$this->table);
			$this->table = $parts[count($parts)-1];
		}

		if(($db = $this->class->getStaticPropertyValue('db',null)) || ($db = $this->class->getStaticPropertyValue('db_name',null)))
			$this->db_name = $db;
	}

	private function set_sequence_name()
	{
		if (!$this->conn->supports_sequences())
			return;

		if (!($this->sequence = $this->class->getStaticPropertyValue('sequence')))
			$this->sequence = $this->conn->get_sequence_name($this->table,$this->pk[0]);
	}

	private function set_associations()
	{
		foreach ($this->class->getStaticProperties() as $name => $definitions)
		{
			if (!$definitions || !is_array($definitions))
				continue;
            
			foreach ($definitions as $definition)
			{
				$relationship = null;
                
				switch ($name)
				{
					case 'has_many':
						$relationship = new HasMany($definition);
						break;

					case 'has_one':
						$relationship = new HasOne($definition);
						break;

					case 'belongs_to':
						$relationship = new BelongsTo($definition);
						break;

					case 'has_and_belongs_to_many':
						$relationship = new HasAndBelongsToMany($definition);
						break;
				}

				if ($relationship)
					$this->add_relationship($relationship);
			}
		}
	}

	/**
	 * Rebuild the delegates array into format that we can more easily work with in Model.
	 * Will end up consisting of array of:
	 *
	 * array('delegate' => array('field1','field2',...),
	 *       'to'       => 'delegate_to_relationship',
	 *       'prefix'	=> 'prefix')
	 */
	private function set_delegates()
	{
		$delegates = $this->class->getStaticPropertyValue('delegate', array());
		$new = array();
        
		if (!array_key_exists('processed', $delegates))
		{
		    // normalize
		    if (!empty($delegates))
		        $delegates = array($delegates);
		        
			$delegates['processed'] = false;
        }
        
		if (!$delegates['processed'])
		{
			foreach ($delegates as &$delegate)
			{
				if (!is_array($delegate) || !isset($delegate['to']))
					continue;

				if (!isset($delegate['prefix']))
					$delegate['prefix'] = null;

				$new_delegate = array(
					'to'		=> $delegate['to'],
					'prefix'	=> $delegate['prefix'],
					'delegate'	=> array());

				foreach ($delegate as $name => $value)
				{
					if (is_numeric($name))
						$new_delegate['delegate'][] = $value;
				}

				$new[] = $new_delegate;
			}

			$new['processed'] = true;
			$this->class->setStaticPropertyValue('delegate',$new);
		}
	}
}

/*
 * Thanks to http://www.eval.ca/articles/php-pluralize (MIT license)
 *           http://dev.rubyonrails.org/browser/trunk/activesupport/lib/active_support/inflections.rb (MIT license)
 *           http://www.fortunecity.com/bally/durrus/153/gramch13.html
 *           http://www2.gsu.edu/~wwwesl/egw/crump.htm
 *
 * Changes (12/17/07)
 *   Major changes
 *   --
 *   Fixed irregular noun algorithm to use regular expressions just like the original Ruby source.
 *       (this allows for things like fireman -> firemen
 *   Fixed the order of the singular array, which was backwards.
 *
 *   Minor changes
 *   --
 *   Removed incorrect pluralization rule for /([^aeiouy]|qu)ies$/ => $1y
 *   Expanded on the list of exceptions for *o -> *oes, and removed rule for buffalo -> buffaloes
 *   Removed dangerous singularization rule for /([^f])ves$/ => $1fe
 *   Added more specific rules for singularizing lives, wives, knives, sheaves, loaves, and leaves and thieves
 *   Added exception to /(us)es$/ => $1 rule for houses => house and blouses => blouse
 *   Added excpetions for feet, geese and teeth
 *   Added rule for deer -> deer
 *
 * Changes:
 *   Removed rule for virus -> viri
 *   Added rule for potato -> potatoes
 *   Added rule for *us -> *uses
 */

function classify($class_name, $singularize=false)
{
	if ($singularize)
	    $class_name = Utils::singularize($class_name);

	$class_name = Inflector::instance()->camelize($class_name);
	return ucfirst($class_name);
}

// http://snippets.dzone.com/posts/show/4660
function array_flatten(array $array)
{
    $i = 0;

    while ($i < count($array))
    {
        if (is_array($array[$i]))
            array_splice($array,$i,1,$array[$i]);
        else
            ++$i;
    }
    return $array;
}

/**
 * Somewhat naive way to determine if an array is a hash.
 */
function is_hash(&$array)
{
	if (!is_array($array))
		return false;

	$keys = array_keys($array);
	return @is_string($keys[0]) ? true : false;
}

/**
 * Strips a class name of any namespaces and namespace operator.
 *
 * @param string $class
 * @return string stripped class name
 * @access public
 */
function denamespace($class_name)
{
	if (is_object($class_name))
		$class_name = get_class($class_name);

	if (has_namespace($class_name))
	{
		$parts = explode('\\', $class_name);
		return end($parts);
	}
	return $class_name;
}

/**
 * Adds the 'Models' namespace to the given class name if there is no namespace 
 * yet.
 *
 * $param string $class_name
 * return string Class name prepended with the 'Models' namespace
 */
function add_namespace($class_name)
{
    return (strpos($class_name, '\\') === false)
        ? 'Models\\' . $class_name
        : $class_name;
}

function get_namespaces($class_name)
{
	if (has_namespace($class_name))
		return explode('\\', $class_name);
	return null;
}

function has_namespace($class_name)
{
	if (strpos($class_name, '\\') !== false)
		return true;
	return false;
}

/**
 * Returns true if all values in $haystack === $needle
 * @param $needle
 * @param $haystack
 * @return unknown_type
 */
function all($needle, array $haystack)
{
	foreach ($haystack as $value)
	{
		if ($value !== $needle)
			return false;
	}
	return true;
}

function collect(&$enumerable, $name_or_closure)
{
	$ret = array();

	foreach ($enumerable as $value)
	{
		if (is_string($name_or_closure))
			$ret[] = is_array($value) ? $value[$name_or_closure] : $value->$name_or_closure;
		elseif ($name_or_closure instanceof Closure)
			$ret[] = $name_or_closure($value);
	}
	return $ret;
}

function get_public_properties($obj)
{
    return get_object_vars($obj);
}

/**
 * Some internal utility functions.
 *
 * @package ActiveRecord
 */
class Utils
{
	public static function extract_options($options)
	{
		return is_array(end($options)) ? end($options) : array();
	}

	public static function add_condition(&$conditions=array(), $condition, $conjuction='AND')
	{
		if (is_array($condition))
		{
			if (empty($conditions))
				$conditions = array_flatten($condition);
			else
			{
				$conditions[0] .= " $conjuction " . array_shift($condition);
				$conditions[] = array_flatten($condition);
			}
		}
		elseif (is_string($condition))
			$conditions[0] .= " $conjuction $condition";

		return $conditions;
	}

	public static function is_odd($number)
	{
		return $number & 1;
	}

	public static function is_a($type, $var)
	{
		switch($type)
		{
			case 'range':
				if (is_array($var) && (int)$var[0] < (int)$var[1])
					return true;

		}

		return false;
	}

	public static function is_blank($var)
	{
		return 0 === strlen($var);
	}

	private static $plural = array(
        '/(quiz)$/i'               => "$1zes",
        '/^(ox)$/i'                => "$1en",
        '/([m|l])ouse$/i'          => "$1ice",
        '/(matr|vert|ind)ix|ex$/i' => "$1ices",
        '/(x|ch|ss|sh)$/i'         => "$1es",
        '/([^aeiouy]|qu)y$/i'      => "$1ies",
        '/(hive)$/i'               => "$1s",
        '/(?:([^f])fe|([lr])f)$/i' => "$1$2ves",
        '/(shea|lea|loa|thie)f$/i' => "$1ves",
        '/sis$/i'                  => "ses",
        '/([ti])um$/i'             => "$1a",
        '/(tomat|potat|ech|her|vet)o$/i'=> "$1oes",
        '/(bu)s$/i'                => "$1ses",
        '/(alias)$/i'              => "$1es",
        '/(octop)us$/i'            => "$1i",
        '/(ax|test)is$/i'          => "$1es",
        '/(us)$/i'                 => "$1es",
        '/s$/i'                    => "s",
        '/$/'                      => "s"
    );

    private static $singular = array(
        '/(quiz)zes$/i'             => "$1",
        '/(matr)ices$/i'            => "$1ix",
        '/(vert|ind)ices$/i'        => "$1ex",
        '/^(ox)en$/i'               => "$1",
        '/(alias)es$/i'             => "$1",
        '/(octop|vir)i$/i'          => "$1us",
        '/(cris|ax|test)es$/i'      => "$1is",
        '/(shoe)s$/i'               => "$1",
        '/(o)es$/i'                 => "$1",
        '/(bus)es$/i'               => "$1",
        '/([m|l])ice$/i'            => "$1ouse",
        '/(x|ch|ss|sh)es$/i'        => "$1",
        '/(m)ovies$/i'              => "$1ovie",
        '/(s)eries$/i'              => "$1eries",
        '/([^aeiouy]|qu)ies$/i'     => "$1y",
        '/([lr])ves$/i'             => "$1f",
        '/(tive)s$/i'               => "$1",
        '/(hive)s$/i'               => "$1",
        '/(li|wi|kni)ves$/i'        => "$1fe",
        '/(shea|loa|lea|thie)ves$/i'=> "$1f",
        '/(^analy)ses$/i'           => "$1sis",
        '/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i'  => "$1$2sis",
        '/([ti])a$/i'               => "$1um",
        '/(n)ews$/i'                => "$1ews",
        '/(h|bl)ouses$/i'           => "$1ouse",
        '/(corpse)s$/i'             => "$1",
        '/(us)es$/i'                => "$1",
        '/(us|ss)$/i'               => "$1",
        '/s$/i'                     => ""
    );

    private static $irregular = array(
        'move'   => 'moves',
        'foot'   => 'feet',
        'goose'  => 'geese',
        'sex'    => 'sexes',
        'child'  => 'children',
        'man'    => 'men',
        'tooth'  => 'teeth',
        'person' => 'people'
    );

    private static $uncountable = array(
        'sheep',
        'fish',
        'deer',
        'series',
        'species',
        'money',
        'rice',
        'information',
        'equipment'
    );

    public static function pluralize( $string )
    {
        // save some time in the case that singular and plural are the same
        if ( in_array( strtolower( $string ), self::$uncountable ) )
            return $string;

        // check for irregular singular forms
        foreach ( self::$irregular as $pattern => $result )
        {
            $pattern = '/' . $pattern . '$/i';

            if ( preg_match( $pattern, $string ) )
                return preg_replace( $pattern, $result, $string);
        }

        // check for matches using regular expressions
        foreach ( self::$plural as $pattern => $result )
        {
            if ( preg_match( $pattern, $string ) )
                return preg_replace( $pattern, $result, $string );
        }

        return $string;
    }

    public static function singularize($string)
    {    
        // save some time in the case that singular and plural are the same
        if ( in_array( strtolower( $string ), self::$uncountable ) )
            return $string;

        // check for irregular plural forms
        foreach ( self::$irregular as $result => $pattern )
        {
            $pattern = '/' . $pattern . '$/i';

            if ( preg_match( $pattern, $string ) )
                return preg_replace( $pattern, $result, $string);
        }

        // check for matches using regular expressions
        foreach ( self::$singular as $pattern => $result )
        {
            if ( preg_match( $pattern, $string ) )
                return preg_replace( $pattern, $result, $string );
        }

        return $string;
    }

    public static function pluralize_if($count, $string)
    {
        if ($count == 1)
            return $string;
        else
            return self::pluralize($string);
    }

	public static function squeeze($char, $string)
	{
		return preg_replace("/$char+/",$char,$string);
	}
}

class Memcache
{
    private $memcache;

    public function __construct($options)
    {
        $this->memcache = new \Memcache();

        if (!$this->memcache->connect($options['host']))
            throw new CacheException("Could not connect to $options[host]:$options[port]");
    }

    public function flush()
    {
        $this->memcache->flush();
    }

    public function read($key)
    {
        return $this->memcache->get($key);
    }

    public function write($key, $value, $expire)
    {
        $this->memcache->set($key,$value,null,$expire);
    }
}

/**
 * Cache::get('the-cache-key', function() {
 * # this gets executed when cache is stale
 * return "your cacheable datas";
 * });
 */
class Cache
{
    static $adapter = null;
    static $options = array();

    /**
     * Initializes the cache.
     *
     * @param string $url URL to your cache server
     * @param array $options Specify additional options
     */
    public static function initialize($url, $options=array())
    {
        if ($url)
        {
            $url = parse_url($url);
            $file = ucwords(Inflector::instance()->camelize($url['scheme']));
            $class = "ActiveRecord\\$file";
            require_once dirname(__FILE__) . "/cache/$file.php";
            static::$adapter = new $class($url);
        }
        else
            static::$adapter = null;

        static::$options = array_merge(array('expire' => 30),$options);
    }

    public static function flush()
    {
        if (static::$adapter)
            static::$adapter->flush();
    }

    public static function get($key, $closure)
    {
        if (!static::$adapter)
            return $closure();

        if (!($value = static::$adapter->read($key)))
            static::$adapter->write($key,($value = $closure()),static::$options['expire']);

        return $value;
    }
}

/**
 * Manages validations for a {@link Model}.
 *
 * This class isn't meant to be directly used. Instead you define
 * validators thru static variables in your {@link Model}. Example:
 *
 * <code>
 * class Person extends ActiveRecord\Model {
 *   static $validates_length_of = array(
 *     array('name', 'within' => array(30,100),
 *     array('state', 'is' => 2)
 *   );
 * }
 *
 * $person = new Person();
 * $person->name = 'Tito';
 * $person->state = 'this is not two characters';
 *
 * if (!$person->is_valid())
 *   print_r($person->errors);
 * </code>
 *
 * @package ActiveRecord
 * @see Errors
 * @link http://www.phpactiverecord.org/guides/validations
 */
class Validations
{
	private $model;
	private $options = array();
	private $validators = array();
	private $record;

	private static $VALIDATION_FUNCTIONS = array(
		'validates_presence_of',
		'validates_size_of',
		'validates_length_of',
		'validates_inclusion_of',
		'validates_exclusion_of',
		'validates_format_of',
		'validates_numericality_of',
		'validates_uniqueness_of'
	);

	private static $DEFAULT_VALIDATION_OPTIONS = array(
		'on' => 'save',
		'allow_null' => false,
		'allow_blank' => false,
		'message' => null,
	);

	private static  $ALL_RANGE_OPTIONS = array(
		'is' => null,
		'within' => null,
		'in' => null,
		'minimum' => null,
		'maximum' => null,
	);

	private static $ALL_NUMERICALITY_CHECKS = array(
		'greater_than' => null,
		'greater_than_or_equal_to'  => null,
		'equal_to' => null,
		'less_than' => null,
		'less_than_or_equal_to' => null,
		'odd' => null,
		'even' => null
	);

	/**
	 * Constructs a {@link Validations} object.
	 *
	 * @param Model $model The model to validate
	 * @return Validations
	 */
	public function __construct($model)
	{
		$this->model = $model;
		$this->record = new Errors($this->model);
		$this->klass = Reflections::instance()->get(get_class($this->model));
        $this->validators =
            array_intersect(array_keys($this->klass->getStaticProperties()),        
            self::$VALIDATION_FUNCTIONS);
    }

    public function get_record()
    {
        return $this->record;
    }    
	
	/**
     * Normalizes static definitions (e.g. wraps string definitions 
     * (if any) into arrays).
     */
    private static function normalize_definitions($definitions)
    {   
        if ((array) $definitions !== $definitions)
            return array(array($definitions));

        $normalized_definitions = array();
        $outer_options = array();

        foreach ($definitions as $key => $body)
        {   
            if ((string) $key === $key)
                $outer_options[$key] = $body;
            elseif ((array) $body === $body)
            {    
                $inner_options = array();

                foreach ($body as $k => $v)
                {
                    if ((string) $k === $k)
                    {
                        $inner_options[$k] = $v;
                        unset($body[$k]);
                    }
                }

                foreach ($body as $b)
                    $normalized_definitions[] = array($b) + $inner_options;
            }
            else
                $normalized_definitions[] = array($body);                        
        }

        if ($outer_options)
        {
            foreach ($normalized_definitions as &$nd)
                $nd += $outer_options;
        }

        return $normalized_definitions;
    }

	/**
	 * Returns validator data.
	 *
	 * @return array
	 */
	public function rules()
    {
        $data = array();

        foreach ($this->validators as $validate)
        {
    	    $attrs = $this->klass->getStaticPropertyValue($validate);
            
    	    foreach (self::normalize_definitions($attrs) as $attr)
    	    {
    	        $field = $attr[0];

				if (!isset($data[$field]) || !is_array($data[$field]))
					$data[$field] = array();

				$attr['validator'] = $validate;
				unset($attr[0]);
				array_push($data[$field],$attr);
    	    }
    	}
        return $data;
    }

	/**
	 * Runs the validators.
	 *
	 * @return Errors the validation errors if any
	 */
	public function validate()
    {   
		foreach ($this->validators as $validate)
		{
		    $definition = $this->klass->getStaticPropertyValue($validate);
			$this->$validate(self::normalize_definitions($definition));
        }
        
        $model_reflection = Reflections::instance()->get($this->model);
        if ($model_reflection->hasMethod('validate') 
            && $model_reflection->getMethod('validate')->isPublic())
            $this->model->validate();
        
        $this->record->clear_model();
		return $this->record;
    }

	/**
	 * Validates a field is not null and not blank.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $validates_presence_of = array(
	 *     array('first_name'),
	 *     array('last_name')
	 *   );
	 * }
	 * </code>
	 *
	 * Available options:
	 *
	 * <ul>
	 * <li><b>message:</b> custom error message</li>
	 * </ul>
	 *
	 * @param array $attrs Validation definition
	 */
	public function validates_presence_of($attrs)
	{
		$configuration = array_merge(self::$DEFAULT_VALIDATION_OPTIONS, array('message' => Errors::$DEFAULT_ERROR_MESSAGES['blank'], 'on' => 'save'));

		foreach ($attrs as $attr)
		{
			$options = array_merge($configuration, $attr);
			$this->record->add_on_blank($options[0], $options['message']);
		}
	}

	/**
	 * Validates that a value is included the specified array.
	 *
	 * <code>
	 * class Car extends ActiveRecord\Model {
	 *   static $validates_inclusion_of = array(
	 *     array('fuel_type', 'in' => array('hyrdogen', 'petroleum', 'electric')),
	 *   );
	 * }
	 * </code>
	 *
	 * Available options:
	 *
	 * <ul>
	 * <li><b>in/within:</b> attribute should/shouldn't be a value within an array</li>
	 * <li><b>message:</b> custome error message</li>
	 * </ul>
	 *
	 * @param array $attrs Validation definition
	 */
	public function validates_inclusion_of($attrs)
	{
		$this->validates_inclusion_or_exclusion_of('inclusion', $attrs);
	}

	/**
	 * This is the opposite of {@link validates_include_of}.
	 *
	 * @param array $attrs Validation definition
	 * @see validates_inclusion_of
	 */
	public function validates_exclusion_of($attrs)
	{
		$this->validates_inclusion_or_exclusion_of('exclusion', $attrs);
	}

	/**
	 * Validates that a value is in or out of a specified list of values.
	 *
	 * @see validates_inclusion_of
	 * @see validates_exclusion_of
	 * @param string $type Either inclusion or exclusion
	 * @param $attrs Validation definition
	 */
	public function validates_inclusion_or_exclusion_of($type, $attrs)
	{
		$configuration = array_merge(self::$DEFAULT_VALIDATION_OPTIONS, array('message' => Errors::$DEFAULT_ERROR_MESSAGES[$type], 'on' => 'save'));

		foreach ($attrs as $attr)
		{
			$options = array_merge($configuration, $attr);
			$attribute = $options[0];
			$var = $this->model->$attribute;

			if (isset($options['in']))
				$enum = $options['in'];
			elseif (isset($options['within']))
				$enum = $options['within'];

			if (!is_array($enum))
				array($enum);

			$message = str_replace('%s', $var, $options['message']);

			if ($this->is_null_with_option($var, $options) || $this->is_blank_with_option($var, $options))
				continue;

			if (('inclusion' == $type && !in_array($var, $enum)) || ('exclusion' == $type && in_array($var, $enum)))
				$this->record->add($attribute, $message);
		}
	}

	/**
     * Validates that a value is numeric.
     *
     * <code>
     * class Person extends ActiveRecord\Model {
     *     static $validates_numericality_of = array(
     *         array('salary', 'greater_than' => 19.99, 'less_than' => 99.99)
     *     );
     * }
     * </code>
     *
     * Available options:
     *
     * <ul>
     * <li><b>only_integer:</b> value must be an integer (e.g. not a float)</li>
     * <li><b>even:</b> must be even</li>
     * <li><b>odd:</b> must be odd"</li>
     * <li><b>greater_than:</b> must be greater than specified number</li>
     * <li><b>greater_than_or_equal_to:</b> must be greater than or equal to specified number</li>
     * <li><b>equal_to:</b> ...</li>
     * <li><b>less_than:</b> ...</li>
     * <li><b>less_than_or_equal_to:</b> ...</li>
     * </ul>
     *
     * @param array $attrs Validation definition
     */
    public function validates_numericality_of($attrs)
    {
        $configuration = array_merge(
            self::$DEFAULT_VALIDATION_OPTIONS,     
            array('only_integer' => false)
        );

        // Notice that for fixnum and float columns empty strings are converted to nil.
        // Validates whether the value of the specified attribute is numeric by trying to convert it to a float with Kernel.Float
        // (if only_integer is false) or applying it to the regular expression /\A[+\-]?\d+\Z/ (if only_integer is set to true).
        foreach ($attrs as $attr)
        {
            $options = array_merge($configuration, $attr);
            $attribute = $options[0];
            $var = $this->model->$attribute;

            $numericalityOptions =
                array_intersect_key(self::$ALL_NUMERICALITY_CHECKS, $options);

            if ($this->is_null_with_option($var, $options))
                continue;

            $not_a_number_message = isset($options['message']) 
                ? $options['message'] 
                : Errors::$DEFAULT_ERROR_MESSAGES['not_a_number'];

            if (true === $options['only_integer'] && !is_integer($var))
            {
                if (!preg_match('/\A[+-]?\d+\Z/', (string)($var)))
                {
                    $this->record->add($attribute, $not_a_number_message);
                    continue;
                }
            }
            else
            {
                if (!is_numeric($var))
                {
                    $this->record->add($attribute, $not_a_number_message);
                    continue;
                }

                $var = (float)$var;
            }

            foreach ($numericalityOptions as $option => $check)
            {
                $option_value = $options[$option];
                $message = isset($options['message']) 
                    ? $options['message'] 
                    : Errors::$DEFAULT_ERROR_MESSAGES[$option];

                if ('odd' != $option && 'even' != $option)
                {
                    $option_value = (float)$options[$option];

                    if (!is_numeric($option_value))
                        throw new ValidationsArgumentError(
                            "$option must be a number"
                        );

                    $message = str_replace('%d', $option_value, $message);

                    if ('greater_than' == $option && !($var > $option_value))
                        $this->record->add($attribute, $message);
                    elseif ('greater_than_or_equal_to' == $option 
                        && !($var >= $option_value))
                        $this->record->add($attribute, $message);
                    elseif ('equal_to' == $option && !($var == $option_value))
                        $this->record->add($attribute, $message);
                    elseif ('less_than' == $option && !($var < $option_value))
                        $this->record->add($attribute, $message);
                    elseif ('less_than_or_equal_to' == $option 
                        && !($var <= $option_value))
                    $this->record->add($attribute, $message);
                }
                else
                {
                    if (('odd' == $option && !Utils::is_odd($var)) 
                        || ('even' == $option && Utils::is_odd($var)))
                        $this->record->add($attribute, $message);
                }
            }
        }
    }

	/**
	 * Alias of {@link validates_length_of}
	 *
	 * @param array $attrs Validation definition
	 */
	public function validates_size_of($attrs)
	{
		$this->validates_length_of($attrs);
	}

	/**
	 * Validates that a value is matches a regex.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $validates_format_of = array(
	 *     array('email', 'with' => '/^.*?@.*$/')
	 *   );
	 * }
	 * </code>
	 *
	 * Available options:
	 *
	 * <ul>
	 * <li><b>with:</b> a regular expression</li>
	 * <li><b>message:</b> custom error message</li>
	 * </ul>
	 *
	 * @param array $attrs Validation definition
	 */
	public function validates_format_of($attrs)
	{
		$configuration = array_merge(self::$DEFAULT_VALIDATION_OPTIONS, array('message' => Errors::$DEFAULT_ERROR_MESSAGES['invalid'], 'on' => 'save', 'with' => null));

		foreach ($attrs as $attr)
		{
			$options = array_merge($configuration, $attr);
			$attribute = $options[0];
			$var = $this->model->$attribute;

			if (is_null($options['with']) || !is_string($options['with']) || !is_string($options['with']))
				throw new ValidationsArgumentError('A regular expression must be supplied as the [with] option of the configuration array.');
			else
				$expression = $options['with'];

			if ($this->is_null_with_option($var, $options) || $this->is_blank_with_option($var, $options))
				continue;

			if (!@preg_match($expression, $var))
			$this->record->add($attribute, $options['message']);
		}
	}

	/**
	 * Validates the length of a value.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $validates_length_of = array(
	 *     array('name', 'within' => array(1,50))
	 *   );
	 * }
	 * </code>
	 *
	 * Available options:
	 *
	 * <ul>
	 * <li><b>is:</b> attribute should be exactly n characters long</li>
	 * <li><b>in/within:</b> attribute should be within an range array(min,max)</li>
	 * <li><b>maximum/minimum:</b> attribute should not be above/below respectively</li>
	 * <li><b>message:</b> custome error message</li>
     * <li><b>allow_blank:</b> allow blank strings</li>
     * <li><b>allow_null:</b> allow null strings. (Even if this is set to false, a null string is always shorter than a maximum value.)</li>
     * </ul>
	 * </ul>
	 *
	 * @param array $attrs Validation definition
	 */
    public function validates_length_of($attrs)
    {
        $configuration = array_merge(self::$DEFAULT_VALIDATION_OPTIONS, array(
            'too_long' => Errors::$DEFAULT_ERROR_MESSAGES['too_long'],
            'too_short' => Errors::$DEFAULT_ERROR_MESSAGES['too_short'],
            'wrong_length' => Errors::$DEFAULT_ERROR_MESSAGES['wrong_length']
        ));

        foreach ($attrs as $attr)
        {
            $options = array_merge($configuration, $attr);
            $range_options = array_intersect(
                array_keys(self::$ALL_RANGE_OPTIONS), 
                array_keys($attr)
            );
            sort($range_options);

            switch (sizeof($range_options))
            {
                case 0:
                    throw new ValidationsArgumentError('Range unspecified. Specify the [within], [maximum], or [is] option.');
                case 1:
                    break;
                default:
                    throw new ValidationsArgumentError('Too many range options specified. Choose only one.');
            }

            $attribute = $options[0];
            $var = $this->model->$attribute;
            
            if ($this->is_null_with_option($var, $options) 
                || $this->is_blank_with_option($var, $options))
                continue;
            
            if ($range_options[0] == 'within' || $range_options[0] == 'in')
            {
                $range = $options[$range_options[0]];

                if (!(Utils::is_a('range', $range)))
                    throw new ValidationsArgumentError("$range_option must be an array composing a range of numbers with key [0] being less than key [1]");
                
                $range_options = array('minimum', 'maximum');
                $attr['minimum'] = $range[0];
                $attr['maximum'] = $range[1];
            }
            
            foreach ($range_options as $range_option)
            {
                $option = $attr[$range_option];

                if ((int)$option <= 0)
                    throw new ValidationsArgumentError("$range_option value cannot use a signed integer.");

                if (is_float($option))
                    throw new ValidationsArgumentError("$range_option value cannot use a float for length.");

                if (!($range_option == 'maximum' 
                    && is_null($this->model->$attribute)))
                {
                    $messageOptions = array(
                        'is' => 'wrong_length', 
                        'minimum' => 'too_short', 
                        'maximum' => 'too_long'
                    );

                    if (isset($options['message']))
                        $message = $options['message'];
                    else
                        $message = $options[$messageOptions[$range_option]];


                    $message = str_replace('%d', $option, $message);
                    $attribute_value = $this->model->$attribute;
                    $len = strlen($attribute_value);
                    $value = (int)$attr[$range_option];

                    if ('maximum' == $range_option && $len > $value)
                        $this->record->add($attribute, $message);

                    if ('minimum' == $range_option && $len < $value)
                        $this->record->add($attribute, $message);

                    if ('is' == $range_option && $len !== $value)
                        $this->record->add($attribute, $message);
                }
            }
        }
    }

	/**
	 * Validates the uniqueness of a value.
	 *
	 * <code>
	 * class Person extends ActiveRecord\Model {
	 *   static $validates_uniqueness_of = array(
	 *     array('name'),
	 *     array(array('blah','bleh'), 'message' => 'blech')
	 *   );
	 * }
	 * </code>
	 *
	 * @param array $attrs Validation definition
	 */
	public function validates_uniqueness_of($attrs)
	{
		$configuration = array_merge(self::$DEFAULT_VALIDATION_OPTIONS, array(
			'message' => Errors::$DEFAULT_ERROR_MESSAGES['unique']
		));

		foreach ($attrs as $attr)
		{
			$options = array_merge($configuration, $attr);
			$pk = $this->model->get_primary_key();
			$pk_value = $this->model->$pk[0];

			if (is_array($options[0]))
			{
				$add_record = join("_and_", $options[0]);
				$fields = $options[0];
			}
			else
			{
				$add_record = $options[0];
				$fields = array($options[0]);
			}

			$sql = "";
			$conditions = array("");

			if ($pk_value === null)
				$sql = "{$pk[0]} is not null";
			else
			{
				$sql = "{$pk[0]}!=?";
				array_push($conditions,$pk_value);
			}

			foreach ($fields as $field)
			{
			    $field = $this->model->get_real_attribute_name($field);
				$sql .= " and {$field}=?";
				array_push($conditions,$this->model->$field);
			}

			$conditions[0] = $sql;

			if ($this->model->exists(array('conditions' => $conditions)))
				$this->record->add($add_record, $options['message']);
		}
	}

	private function is_null_with_option($var, &$options)
	{
		return (is_null($var) && (isset($options['allow_null']) && $options['allow_null']));
	}

	private function is_blank_with_option($var, &$options)
	{
		return (Utils::is_blank($var) && (isset($options['allow_blank']) && $options['allow_blank']));
	}
}

/**
 * Class that holds {@link Validations} errors.
 *
 * @package ActiveRecord
 */
class Errors implements IteratorAggregate
{
	private $model;
	private $errors;

	public static $DEFAULT_ERROR_MESSAGES = array(
   		'inclusion'		=> "is not included in the list",
     	'exclusion'		=> "is reserved",
      	'invalid'		=> "is invalid",
      	'empty'			=> "can't be empty",
      	'blank'			=> "can't be blank",
      	'too_long'		=> "is too long (maximum is %d characters)",
      	'too_short'		=> "is too short (minimum is %d characters)",
      	'wrong_length'	=> "is the wrong length (should be %d characters)",
      	'not_a_number'	=> "is not a number",
      	'greater_than'	=> "must be greater than %d",
      	'equal_to'		=> "must be equal to %d",
      	'less_than'		=> "must be less than %d",
      	'odd'			=> "must be odd",
      	'even'			=> "must be even",
		'unique'		=> "must be unique",
      	'less_than_or_equal_to' => "must be less than or equal to %d",
      	'greater_than_or_equal_to' => "must be greater than or equal to %d"
   	);

   	/**
	 * Constructs an {@link Errors} object.
	 *
	 * @param $model The model the error is for
	 * @return Errors
   	 */
	public function __construct($model)
	{
		$this->model = $model;
	}
	
    /**
     * Nulls $model so we don't get pesky circular references. 
     * $model is only needed during the validation process and 
     * so can be safely cleared once that is done.
     */
    public function clear_model()
    {
        $this->model = null;
    }

	/**
	 * Add an error message.
	 *
	 * @param string $attribute Name of an attribute on the model
	 * @param string $msg The error message
	 */
	public function add($attribute, $msg)
	{
		if (is_null($msg))
			$msg = self :: $DEFAULT_ERROR_MESSAGES['invalid'];

		if (!isset($this->errors[$attribute]))
			$this->errors[$attribute] = array($msg);
		else
			$this->errors[$attribute][] = $msg;
	}

	/**
	 * Adds an error message only if the attribute value is {@link http://www.php.net/empty empty}.
	 *
	 * @param string $attribute Name of an attribute on the model
	 * @param string $msg The error message
	 */
	public function add_on_empty($attribute, $msg)
	{
		if (empty($msg))
			$msg = self::$DEFAULT_ERROR_MESSAGES['empty'];

		if (empty($this->model->$attribute))
			$this->add($attribute, $msg);
	}

    /**
     * Retrieve error messages for an attribute.
     *
     * @param string $attribute Name of an attribute on the model
     * @return array or null if there is no error.
     */
    public function __get($attribute)
    {
        if (!isset($this->errors[$attribute]))
            return null;

        return $this->errors[$attribute];
    }

	/**
	 * Adds the error message only if the attribute value was null or an empty string.
	 * 
	 * FIXED by Szymon Wrozynski to allow 0 value.
	 * @param string $attribute Name of an attribute on the model
	 * @param string $msg The error message
	 */
	public function add_on_blank($attribute, $msg)
	{
		if (!$msg)
			$msg = self::$DEFAULT_ERROR_MESSAGES['blank'];
        
        $var = $this->model->$attribute;

        if (is_numeric($var))
            return;

    	if (!$var)
    		$this->add($attribute, $msg);
	}

	/**
	 * Returns true if the specified attribute had any error messages.
	 *
	 * @param string $attribute Name of an attribute on the model
	 * @return boolean
	 */
	public function is_invalid($attribute)
	{
		return isset($this->errors[$attribute]);
	}

	/**
     * Returns the error message(s) for the specified attribute or null if none.
     *
     * @param string $attribute Name of an attribute on the model
     * @return string/array Array of strings if several error occured on this attribute.
     */
    public function on($attribute)
    {
        $errors = $this->$attribute;
        return $errors && count($errors) == 1 ? $errors[0] : $errors;
    }
    
    /**
     * Returns the internal errors object.
     *
     * <code>
     * $model->errors->get_raw_errors();
     *
     * # array(
     * # "name" => array("can't be blank"),
     * # "state" => array("is the wrong length (should be 2 chars)",
     * # )
     * </code>
     */
    public function get_raw_errors()
    {
        return $this->errors;
    }

	/**
	 * Returns all the error messages as an array.
	 *
	 * <code>
	 * $model->errors->full_messages();
	 *
	 * # array(
	 * #  "Name can't be blank",
	 * #  "State is the wrong length (should be 2 chars)"
	 * # )
	 * </code>
	 *
	 * @param mixed $separator Separator used between a name and a message. 
	 *     If empty the name will be omitted. Default: ' '
	 * @param bool $localize Explicitly turns on/off localization (true/false)
	 * @return array
	 */
	public function full_messages($separator=' ', $localize=null)
	{
		$full_messages = array();
		
		$this->to_array(
		    $separator, 
		    $localize, 
		    function($a, $m) use (&$full_messages) { $full_messages[] = $m; }
		);
		
		return $full_messages;
	}
	
	/**
     * Returns all the error messages as an array, including error key.
     *
     * <code>
     * $model->errors->to_array();
     *
     * # array(
     * # "name" => array("Name can't be blank"),
     * # "state" => array("State is the wrong length (should be 2 chars))"
     * # )
     * </code>
     *
     * @param mixed $separator Separator used between a name and a message. 
 	 *     If empty the name will be omitted. Default: ' '
 	 * @param bool $localize Explicitly turns on/off localization (true/false)
 	 * @param \Closure $closure Closure to fetch the errors in some other format
 	 *     (optional). This closure has the signature function($attribute, 
 	 *     $message) and is called for each available error message.
 	 * @return array
     */
	public function to_array($separator=' ', $localize=null, $closure=null)
	{
		$errors = array();
            
		if ($this->errors)
		{
		    if ($localize === null)
                $localize = (LOCALIZATION !== false);
            
			foreach ($this->errors as $attr => $error_messages)
			{
				foreach ($error_messages as $em)
				{
					if ($em === null)
						continue;
						
					if (!$separator)
					    $msg = $localize ? t($em) : $em;
					elseif ($localize)
					    $msg = t($attr) . $separator . t($em);
					else
					    $msg=ucfirst(str_replace('_',' ',$attr)).$separator.$em;
					
					$errors[$attr][] = $msg;
					
					if ($closure)
					    $closure($attr, $msg);
				}
			}
		}
		
		return $errors;
	}

	/**
	 * Returns true if there are no error messages.
	 * @return boolean
	 */
	public function is_empty()
	{
		return empty($this->errors);
	}

	/**
	 * Clears out all error messages.
	 */
	public function clear()
	{
		$this->errors = array();
	}

	/**
	 * Returns the number of error messages there are.
	 * @return int
	 */
	public function size()
	{
		if ($this->is_empty())
			return 0;

		$count = 0;

		foreach ($this->errors as $attribute => $error)
			$count += count($error);

		return $count;
	}
	
	/**
     * Convert all error messages to a String.
     * This function is called implicitely if the object is casted to a string:
     *
     * <code>
     * echo $error;
     *
     * # "Name can't be blank\nState is the wrong length (should be 2 chars)"
     * </code>
     * @return string
     */
    public function __toString()
    {
        return implode("\n", $this->full_messages());
    }

	/**
	 * Returns an iterator to the error messages.
	 *
	 * This will allow you to iterate over the {@link Errors} object using foreach.
	 *
	 * <code>
	 * foreach ($model->errors as $msg)
	 *   echo "$msg\n";
	 * </code>
	 *
	 * @return ArrayIterator
	 */
	public function getIterator()
	{
		return new ArrayIterator($this->full_messages());
	}
}

class MysqlAdapter extends Connection
{
	static $DEFAULT_PORT = 3306;
    
    public function limit($sql, $offset, $limit)
    {
        $offset = is_null($offset) ? '' : intval($offset) . ',';
        $limit = intval($limit);
        return "$sql LIMIT {$offset}$limit";
    }

	public function query_column_info($table)
	{
		return $this->query("SHOW COLUMNS FROM $table");
	}

	public function query_for_tables()
	{
		return $this->query('SHOW TABLES');
	}

	public function create_column(&$column)
	{
		$c = new Column();
		$c->inflected_name	= Inflector::instance()->variablize($column['field']);
		$c->name			= $column['field'];
		$c->nullable		= ($column['null'] === 'YES' ? true : false);
		$c->pk				= ($column['key'] === 'PRI' ? true : false);
		$c->auto_increment	= ($column['extra'] === 'auto_increment' ? true : false);

		if ($column['type'] == 'timestamp' || $column['type'] == 'datetime')
		{
			$c->raw_type = 'datetime';
			$c->length = 19;
		}
		elseif ($column['type'] == 'date')
		{
			$c->raw_type = 'date';
			$c->length = 10;
		}
		elseif ($column['type'] == 'time')
		{
			$c->raw_type = 'time';
			$c->length = 8;
		}
		else
		{
			preg_match('/^([A-Za-z0-9_]+)(\(([0-9]+(,[0-9]+)?)\))?/',$column['type'],$matches);

			$c->raw_type = (count($matches) > 0 ? $matches[1] : $column['type']);

			if (count($matches) >= 4)
				$c->length = intval($matches[3]);
		}

		$c->map_raw_type();
		$c->default = $c->cast($column['default'],$this);

		return $c;
	}
	
	public function set_encoding($charset)
    {
        $params = array($charset);
        $this->query('SET NAMES ?',$params);
    }
    
    public function accepts_limit_and_order_for_update_and_delete() 
    { 
        return true; 
    }
}
	
class TablelessModel
{
	public $errors;
	private $_callback;

	public function __construct($attributes=null)
	{
	    Reflections::instance()->add($this);
	    $this->_callback = new CallBack(get_class($this));
	    if ($attributes)
	        $this->set_attributes($attributes);
	}
	
	public function attributes()
	{
	    $attributes = get_public_properties($this);
	    unset($attributes['errors']);
		return $attributes;
	}
	
	public function get_validation_rules()
	{
		$validator = new Validations($this);
		return $validator->rules();
	}

	public function get_values_for($attributes)
	{
		$ret = array();
		$public_attributes = $this->attributes();
    	foreach ($attributes as $name)
		{
			if (array_key_exists($name, $public_attributes))
				$ret[$name] = $this->$name;
    	}
    	return $ret;
    }

	public function values_for($attribute_names)
	{
		$filter = array();
		foreach ($attribute_names as $name)
			$filter[$name] = $this->$name;

		return $filter;
	}

	private function _validate()
	{
    	$validator = new Validations($this);
    	
    	if ($this->_callback->invoke($this, 'before_validation', false) 
    	    === false)
			return false;
        
        $this->errors = $validator->get_record();
        $validator->validate();
		$this->_callback->invoke($this, 'after_validation', false);
		return $this->errors->is_empty();
    }

	public function is_valid()
	{
		return $this->_validate();
	}

    public function is_invalid()
    {
    	return !$this->_validate();
    }
    
    public function update_attributes($attributes)
	{
		$this->set_attributes($attributes);
		return $this->is_valid();
	}

    public function set_attributes($attributes)
    {   
    	foreach ($attributes as $name => $value)
    	{
    	    if ($name !== 'errors')
    	        $this->$name = $value;
    	}
    }
    
    public function __get($name)
    {
        $name = "get_$name";
        if (method_exists($this, $name))
            return $this->$name();
        
        throw new UndefinedPropertyException(get_called_class(), $name);
    }

    public function __set($name, $value)
    {        
        if (method_exists($this, "set_$name"))
        {
            $name = "set_$name";
            return $this->$name($value);
        }
           
        throw new UndefinedPropertyException(get_called_class(), $name);
    }
}
    
/**
 * Adapter for OCI (not completed yet).
 * 
 * @package ActiveRecord
 */
class OciAdapter extends Connection
{
	static $QUOTE_CHARACTER = '';
	static $DEFAULT_PORT = 1521;

	protected function __construct($info)
	{
		try 
		{
		    $this->dsn_params = isset($info->charset) 
		        ? ";charset=$info->charset" : "";
			$this->connection = 
			    new PDO("oci:dbname=//$info->host/$info->db$this->dsn_params",
			        $info->user,$info->pass,static::$PDO_OPTIONS
			    );
		} 
		catch (PDOException $e) 
		{
			throw new DatabaseException($e);
		}
	}

	public function supports_sequences() { return true; }

	public function get_next_sequence_value($sequence_name)
	{
		return $this->query_and_fetch_one('SELECT ' . $this->next_sequence_value($sequence_name) . ' FROM dual');
	}

	public function next_sequence_value($sequence_name)
	{
		return "$sequence_name.nextval";
	}
	
	public function date_to_string($datetime)
    {
        return $datetime->format('d-M-Y');
    }

	public function datetime_to_string($datetime)
	{
		return $datetime->format('d-M-Y h:i:s A');
	}

	// $string = DD-MON-YYYY HH12:MI:SS(\.[0-9]+) AM
	public function string_to_datetime($string)
	{
		return parent::string_to_datetime(str_replace('.000000','',$string));
	}

	public function limit($sql, $offset, $limit)
	{
		$offset = intval($offset);
		$stop = $offset + intval($limit);
		return 
			"SELECT * FROM (SELECT a.*, rownum ar_rnum__ FROM ($sql) a " .
			"WHERE rownum <= $stop) WHERE ar_rnum__ > $offset";
	}

	public function query_column_info($table)
	{
		$sql = 
			"SELECT c.column_name, c.data_type, c.data_length, c.data_scale, c.data_default, c.nullable, " .
				"(SELECT a.constraint_type " .
				"FROM all_constraints a, all_cons_columns b " .
				"WHERE a.constraint_type='P' " .
				"AND a.constraint_name=b.constraint_name " .
				"AND a.table_name = t.table_name AND b.column_name=c.column_name) AS pk " .
			"FROM user_tables t " .
			"INNER JOIN user_tab_columns c on(t.table_name=c.table_name) " .
			"WHERE t.table_name=?";
		$values = array(strtoupper($table));
		return $this->query($sql,$values);
	}

	public function query_for_tables()
	{
		return $this->query("SELECT table_name FROM user_tables");
	}

	public function create_column(&$column)
	{
		$column['column_name'] = strtolower($column['column_name']);
		$column['data_type'] = strtolower(preg_replace('/\(.*?\)/','',$column['data_type']));

		if ($column['data_default'] !== null)
			$column['data_default'] = trim($column['data_default'],"' ");

		if ($column['data_type'] == 'number')
		{
			if ($column['data_scale'] > 0)
				$column['data_type'] = 'decimal';
			elseif ($column['data_scale'] == 0)
				$column['data_type'] = 'int';
		}

		$c = new Column();
		$c->inflected_name	= Inflector::instance()->variablize($column['column_name']);
		$c->name			= $column['column_name'];
		$c->nullable		= $column['nullable'] == 'Y' ? true : false;
		$c->pk				= $column['pk'] == 'P' ? true : false;
		$c->length			= $column['data_length'];

		if ($column['data_type'] == 'timestamp')
			$c->raw_type = 'datetime';
		else
			$c->raw_type = $column['data_type'];

		$c->map_raw_type();
		$c->default	= $c->cast($column['data_default'],$this);

		return $c;
	}
	
	public function set_encoding($charset)
	{
        // is handled in the constructor
    }
}
    
/**
 * Adapter for Postgres (not completed yet)
 * 
 * @package ActiveRecord
 */
class PgsqlAdapter extends Connection
{
	static $QUOTE_CHARACTER	= '"';
	static $DEFAULT_PORT	= 5432;

	public function supports_sequences() { return true; }
	
	public function get_sequence_name($table, $column_name)
	{
		return "{$table}_{$column_name}_seq";
	}

	public function next_sequence_value($sequence_name)
	{
		return "nextval('" . str_replace("'","\\'",$sequence_name) . "')";
	}

	public function limit($sql, $offset, $limit)
	{
		return $sql . ' LIMIT ' . intval($limit) . ' OFFSET ' . intval($offset);
	}

	public function query_column_info($table)
	{
		$sql = <<<SQL
SELECT a.attname AS field, a.attlen,
REPLACE(pg_catalog.format_type(a.atttypid, a.atttypmod),'character varying','varchar') AS type,
a.attnotnull AS not_nullable, 
i.indisprimary as pk,
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(s.column_default,'::[a-z_ ]+',''),'\'$',''),'^\'','') AS default
FROM pg_catalog.pg_attribute a
LEFT JOIN pg_catalog.pg_class c ON(a.attrelid=c.oid)
LEFT JOIN pg_catalog.pg_index i ON(c.oid=i.indrelid AND a.attnum=any(i.indkey))
LEFT JOIN information_schema.columns s ON(s.table_name=? AND a.attname=s.column_name)
WHERE a.attrelid = (select c.oid from pg_catalog.pg_class c inner join pg_catalog.pg_namespace n on(n.oid=c.relnamespace) where c.relname=? and pg_catalog.pg_table_is_visible(c.oid))
AND a.attnum > 0
AND NOT a.attisdropped
ORDER BY a.attnum
SQL;
		$values = array($table,$table);
		return $this->query($sql,$values);
	}

	public function query_for_tables()
	{
		return $this->query("SELECT tablename FROM pg_tables WHERE schemaname NOT IN('information_schema','pg_catalog')");
	}

	public function create_column(&$column)
	{
		$c = new Column();
		$c->inflected_name	= Inflector::instance()->variablize($column['field']);
		$c->name			= $column['field'];
		$c->nullable		= ($column['not_nullable'] ? false : true);
		$c->pk				= ($column['pk'] ? true : false);
		$c->auto_increment	= false;

		if (substr($column['type'],0,9) == 'timestamp')
		{
			$c->raw_type = 'datetime';
			$c->length = 19;
		}
		elseif ($column['type'] == 'date')
		{
			$c->raw_type = 'date';
			$c->length = 10;
		}
		else
		{
			preg_match('/^([A-Za-z0-9_]+)(\(([0-9]+(,[0-9]+)?)\))?/',$column['type'],$matches);

			$c->raw_type = (count($matches) > 0 ? $matches[1] : $column['type']);
			$c->length = count($matches) >= 4 ? intval($matches[3]) : intval($column['attlen']);

			if ($c->length < 0)
				$c->length = null;
		}

		$c->map_raw_type();

		if ($column['default'])
		{
			preg_match("/^nextval\('(.*)'\)$/",$column['default'],$matches);

			if (count($matches) == 2)
				$c->sequence = $matches[1];
			else
				$c->default = $c->cast($column['default'],$this);
		}
		return $c;
	}
	
	public function set_encoding($charset)
    {
        $this->query("SET NAMES '$charset'");
    }
}

/**
 * Adapter for SQLite.
 *
 * @package ActiveRecord
 */
class SqliteAdapter extends Connection
{
	protected function __construct($info)
	{
		if (!file_exists($info->host))
			throw new DatabaseException("Could not find sqlite db: $info->host");

		$this->connection = new PDO("sqlite:$info->host",null,null,static::$PDO_OPTIONS);
	}

	public function limit($sql, $offset, $limit)
    {
        $offset = is_null($offset) ? '' : intval($offset) . ',';
        $limit = intval($limit);
        return "$sql LIMIT {$offset}$limit";
    }

	public function query_column_info($table)
	{
		return $this->query("pragma table_info($table)");
	}

	public function query_for_tables()
	{
		return $this->query("SELECT name FROM sqlite_master");
	}

	public function create_column($column)
	{
		$c = new Column();
		$c->inflected_name	= Inflector::instance()->variablize($column['name']);
		$c->name			= $column['name'];
		$c->nullable		= $column['notnull'] ? false : true;
		$c->pk				= $column['pk'] ? true : false;
		$c->auto_increment	= $column['type'] == 'INTEGER' && $c->pk;

		$column['type'] = preg_replace('/ +/',' ',$column['type']);
		$column['type'] = str_replace(array('(',')'),' ',$column['type']);
		$column['type'] = Utils::squeeze(' ',$column['type']);
		$matches = explode(' ',$column['type']);

		if (!empty($matches))
		{
			$c->raw_type = strtolower($matches[0]);

			if (count($matches) > 1)
				$c->length = intval($matches[1]);
		}

		$c->map_raw_type();

		if ($c->type == Column::DATETIME)
			$c->length = 19;
		elseif ($c->type == Column::DATE)
			$c->length = 10;

		// From SQLite3 docs: The value is a signed integer, stored in 1, 2, 3, 4, 6,
		// or 8 bytes depending on the magnitude of the value.
		// so is it ok to assume it's possible an int can always go up to 8 bytes?
		if ($c->type == Column::INTEGER && !$c->length)
			$c->length = 8;

		$c->default = $c->cast($column['dflt_value'],$this);

		return $c;
	}
	
	public function set_encoding($charset)
    {
        throw new ActiveRecordException(
            "SqliteAdapter::set_charset not supported."
        );
    }
    
    public function accepts_limit_and_order_for_update_and_delete() 
    { 
        return true; 
    }
}

require CONFIG . 'activerecord.php';
?>'''), STRIP_PHPDOC)

def make_lightopenid_module(work):
    write(os.path.join(work, 'modules', 'lightopenid.php'), R'''<?php
/**
 * LightOpenID 0.1 Module 1.0 for Pragwork %s
 *
 * @copyright Copyright (c) 2010, Mewp, API changes - Szymon Wrozynski
 * @license http://www.opensource.org/licenses/mit-license.php MIT
 * @version %s
 * @package LightOpenID
 */
''' % (__pragwork_version__, __pragwork_version__) + __strip_phpdoc(R'''
/**
 * This class provides a simple interface for OpenID (1.1 and 2.0) authentication.
 * Supports Yadis discovery.
 * The authentication process is stateless/dumb.
 *
 * Usage:
 * Sign-on with OpenID is a two step process:
 * Step one is authentication with the provider:
 * <code>
 * $openid = new LightOpenID;
 * $openid->identity = 'ID supplied by user';
 * header('Location: ' . $openid->auth_url());
 * </code>
 * The provider then sends various parameters via GET, one of them is openid_mode.
 * Step two is verification:
 * <code>
 * if ($this->data['openid_mode']) {
 *     $openid = new LightOpenID;
 *     echo $openid->validate() ? 'Logged in.' : 'Failed';
 * }
 * </code>
 *
 * Optionally, you can set $return_url and $realm (or $trust_root, which is an alias).
 * The default values for those are:
 * $openid->realm     = (!empty($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
 * $openid->return_url = $openid->realm . $_SERVER['REQUEST_URI'];
 * If you don't know their meaning, refer to any openid tutorial, or specification. Or just guess.
 *
 * AX and SREG extensions are supported.
 * To use them, specify $openid->required and/or $openid->optional.
 * These are arrays, with values being AX schema paths (the 'path' part of the URL).
 * For example:
 *   $openid->required = array('namePerson/friendly', 'contact/email');
 *   $openid->optional = array('namePerson/first');
 * If the server supports only SREG or OpenID 1.1, these are automaticaly
 * mapped to SREG names, so that user doesn't have to know anything about the server.
 *
 * To get the values, use $openid->get_attributes().
 *
 *
 * The library depends on curl, and requires PHP 5.
 * @author Mewp
 * @copyright Copyright (c) 2010, Mewp
 * @license http://www.opensource.org/licenses/mit-license.php MIT
 */
class LightOpenID
{
    public $return_url
         , $required = array()
         , $optional = array();
    private $identity, $claimed_id;
    protected $server, $version, $trust_root, $aliases, $identifier_select = false
            , $ax = false, $sreg = false, $data;
    static protected $ax_to_sreg = array(
        'namePerson/friendly'     => 'nickname',
        'contact/email'           => 'email',
        'namePerson'              => 'fullname',
        'birthDate'               => 'dob',
        'person/gender'           => 'gender',
        'contact/postalCode/home' => 'postcode',
        'contact/country/home'    => 'country',
        'pref/language'           => 'language',
        'pref/timezone'           => 'timezone',
        );

    function __construct()
    {
        $this->trust_root = ($_SERVER['SERVER_PORT'] == (SSL_PORT ?: 443) 
            ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
        $this->return_url = $this->trust_root . $_SERVER['REQUEST_URI'];

        if (!function_exists('curl_exec')) {
            throw new ErrorException('Curl extension is required.');
        }

        $this->data = $_POST + $_GET; # OPs may send data as POST or GET.
    }

    function __set($name, $value)
    {
        switch ($name) {
        case 'identity':
            if (strlen($value = trim($value))) {
                if (preg_match('#^xri:/*#i', $value, $m)) {
                    $value = substr($value, strlen($m[0]));
                } elseif (!preg_match('/^(?:[=@+\$!\(]|https?:)/i', $value)) {
                    $value = "http://$value";
                }
                if (preg_match('#^https?://[^/]+$#i', $value, $m)) {
                    $value .= '/';
                }
            }
            $this->$name = $this->claimed_id = $value;
            break;
        case 'trust_root':
        case 'realm':
            $this->trust_root = trim($value);
        }
    }

    function __get($name)
    {
        switch ($name) {
        case 'identity':
            # We return claimed_id instead of identity,
            # because the developer should see the claimed identifier,
            # i.e. what he set as identity, not the op-local identifier (which is what we verify)
            return $this->claimed_id;
        case 'trust_root':
        case 'realm':
            return $this->trust_root;
        }
    }

    protected function request($url, $method='GET', $params=array())
    {
        $params = http_build_query($params, '', '&');
        $curl = curl_init($url . ($method == 'GET' && $params ? '?' . $params : ''));
        curl_setopt($curl, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($curl, CURLOPT_HEADER, false);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        if ($method == 'POST') {
            curl_setopt($curl, CURLOPT_POST, true);
            curl_setopt($curl, CURLOPT_POSTFIELDS, $params);
        } elseif ($method == 'HEAD') {
            curl_setopt($curl, CURLOPT_HEADER, true);
            curl_setopt($curl, CURLOPT_NOBODY, true);
        } else {
            curl_setopt($curl, CURLOPT_HTTPGET, true);
        }
        $response = curl_exec($curl);

        if (curl_errno($curl)) {
            throw new ErrorException(curl_error($curl), curl_errno($curl));
        }

        return $response;
    }

    protected function build_url($url, $parts)
    {
        if (isset($url['query'], $parts['query'])) {
            $parts['query'] = $url['query'] . '&' . $parts['query'];
        }

        $url = $parts + $url;
        $url = $url['scheme'] . '://'
             . (empty($url['username'])?''
                 :(empty($url['password'])? "{$url['username']}@"
                 :"{$url['username']}:{$url['password']}@"))
             . $url['host']
             . (empty($url['port'])?'':":{$url['port']}")
             . (empty($url['path'])?'':$url['path'])
             . (empty($url['query'])?'':"?{$url['query']}")
             . (empty($url['fragment'])?'':":{$url['fragment']}");
        return $url;
    }

    /**
     * Helper function used to scan for <meta>/<link> tags and extract information
     * from them
     */
    protected function html_tag($content, $tag, $attr_name, $attr_value, $value_name)
    {
        preg_match_all("#<{$tag}[^>]*$attr_name=['\"].*?$attr_value.*?['\"][^>]*$value_name=['\"](.+?)['\"][^>]*/?>#i", $content, $matches1);
        preg_match_all("#<{$tag}[^>]*$value_name=['\"](.+?)['\"][^>]*$attr_name=['\"].*?$attr_value.*?['\"][^>]*/?>#i", $content, $matches2);

        $result = array_merge($matches1[1], $matches2[1]);
        return empty($result)?false:$result[0];
    }

    /**
     * Performs Yadis and HTML discovery. Normally not used.
     * @param $url Identity URL.
     * @return String OP Endpoint (i.e. OpenID provider address).
     * @throws ErrorException
     */
    function discover($url)
    {
        if (!$url) throw new ErrorException('No identity supplied.');
        # Use xri.net proxy to resolve i-name identities
        if (!preg_match('#^https?:#', $url)) {
            $url = "https://xri.net/$url";
        }

        # We save the original url in case of Yadis discovery failure.
        # It can happen when we'll be lead to an XRDS document
        # which does not have any OpenID2 services.
        $original_url = $url;

        # A flag to disable yadis discovery in case of failure in headers.
        $yadis = true;

        # We'll jump a maximum of 5 times, to avoid endless redirections.
        for ($i = 0; $i < 5; $i ++) {
            if ($yadis) {
                $headers = explode("\n",$this->request($url, 'HEAD'));

                $next = false;
                foreach ($headers as $header) {
                    if (preg_match('#X-XRDS-Location\s*:\s*(.*)#', $header, $m)) {
                        $url = $this->build_url(parse_url($url), parse_url(trim($m[1])));
                        $next = true;
                    }

                    if (preg_match('#Content-Type\s*:\s*application/xrds\+xml#i', $header)) {
                        # Found an XRDS document, now let's find the server, and optionally delegate.
                        $content = $this->request($url, 'GET');

                        # OpenID 2
                        # We ignore it for MyOpenID, as it breaks sreg if using OpenID 2.0
                        $ns = preg_quote('http://specs.openid.net/auth/2.0/');
                        if (preg_match('#<Service.*?>(.*)<Type>\s*'.$ns.'(.*?)\s*</Type>(.*)</Service>#s', $content, $m)) {
                            $content = ' ' . $m[1] . $m[3]; # The space is added, so that strpos doesn't return 0.
                            if ($m[2] == 'server') $this->identifier_select = true;

                            preg_match('#<URI.*?>(.*)</URI>#', $content, $server);
                            preg_match('#<(Local|Canonical)ID>(.*)</\1ID>#', $content, $delegate);
                            if (empty($server)) {
                                return false;
                            }
                            # Does the server advertise support for either AX or SREG?
                            $this->ax   = (bool) strpos($content, '<Type>http://openid.net/srv/ax/1.0</Type>');
                            $this->sreg = strpos($content, '<Type>http://openid.net/sreg/1.0</Type>')
                                       || strpos($content, '<Type>http://openid.net/extensions/sreg/1.1</Type>');

                            $server = $server[1];
                            if (isset($delegate[2])) $this->identity = trim($delegate[2]);
                            $this->version = 2;

                            $this->server = $server;
                            return $server;
                        }

                        # OpenID 1.1
                        $ns = preg_quote('http://openid.net/signon/1.1');
                        if (preg_match('#<Service.*?>(.*)<Type>\s*'.$ns.'\s*</Type>(.*)</Service>#s', $content, $m)) {
                            $content = ' ' . $m[1] . $m[2];

                            preg_match('#<URI.*?>(.*)</URI>#', $content, $server);
                            preg_match('#<.*?Delegate>(.*)</.*?Delegate>#', $content, $delegate);
                            if (empty($server)) {
                                return false;
                            }
                            # AX can be used only with OpenID 2.0, so checking only SREG
                            $this->sreg = strpos($content, '<Type>http://openid.net/sreg/1.0</Type>')
                                       || strpos($content, '<Type>http://openid.net/extensions/sreg/1.1</Type>');

                            $server = $server[1];
                            if (isset($delegate[1])) $this->identity = $delegate[1];
                            $this->version = 1;

                            $this->server = $server;
                            return $server;
                        }

                        $next = true;
                        $yadis = false;
                        $url = $original_url;
                        $content = null;
                        break;
                    }
                }
                if ($next) continue;

                # There are no relevant information in headers, so we search the body.
                $content = $this->request($url, 'GET');
                if ($location = $this->html_tag($content, 'meta', 'http-equiv', 'X-XRDS-Location', 'value')) {
                    $url = $this->build_url(parse_url($url), parse_url($location));
                    continue;
                }
            }

            if (!$content) $content = $this->request($url, 'GET');

            # At this point, the YADIS Discovery has failed, so we'll switch
            # to openid2 HTML discovery, then fallback to openid 1.1 discovery.
            $server   = $this->html_tag($content, 'link', 'rel', 'openid2.provider', 'href');
            $delegate = $this->html_tag($content, 'link', 'rel', 'openid2.local_id', 'href');
            $this->version = 2;

            if (!$server) {
                # The same with openid 1.1
                $server   = $this->html_tag($content, 'link', 'rel', 'openid.server', 'href');
                $delegate = $this->html_tag($content, 'link', 'rel', 'openid.delegate', 'href');
                $this->version = 1;
            }

            if ($server) {
                # We found an OpenID2 OP Endpoint
                if ($delegate) {
                    # We have also found an OP-Local ID.
                    $this->identity = $delegate;
                }
                $this->server = $server;
                return $server;
            }

            throw new ErrorException('No servers found!');
        }
        throw new ErrorException('Endless redirection!');
    }

    protected function sregParams()
    {
        $params = array();
        # We always use SREG 1.1, even if the server is advertising only support for 1.0.
        # That's because it's fully backwards compatibile with 1.0, and some providers
        # advertise 1.0 even if they accept only 1.1. One such provider is myopenid.com
        $params['openid.ns.sreg'] = 'http://openid.net/extensions/sreg/1.1';
        if ($this->required) {
            $params['openid.sreg.required'] = array();
            foreach ($this->required as $required) {
                if (!isset(self::$ax_to_sreg[$required])) continue;
                $params['openid.sreg.required'][] = self::$ax_to_sreg[$required];
            }
            $params['openid.sreg.required'] = implode(',', $params['openid.sreg.required']);
        }

        if ($this->optional) {
            $params['openid.sreg.optional'] = array();
            foreach ($this->optional as $optional) {
                if (!isset(self::$ax_to_sreg[$optional])) continue;
                $params['openid.sreg.optional'][] = self::$ax_to_sreg[$optional];
            }
            $params['openid.sreg.optional'] = implode(',', $params['openid.sreg.optional']);
        }
        return $params;
    }
    protected function ax_params()
    {
        $params = array();
        if ($this->required || $this->optional) {
            $params['openid.ns.ax'] = 'http://openid.net/srv/ax/1.0';
            $params['openid.ax.mode'] = 'fetch_request';
            $this->aliases  = array();
            $counts   = array();
            $required = array();
            $optional = array();
            foreach (array('required','optional') as $type) {
                foreach ($this->$type as $alias => $field) {
                    if (is_int($alias)) $alias = strtr($field, '/', '_');
                    $this->aliases[$alias] = 'http://axschema.org/' . $field;
                    if (empty($counts[$alias])) $counts[$alias] = 0;
                    $counts[$alias] += 1;
                    ${$type}[] = $alias;
                }
            }
            foreach ($this->aliases as $alias => $ns) {
                $params['openid.ax.type.' . $alias] = $ns;            }
            foreach ($counts as $alias => $count) {
                if ($count == 1) continue;
                $params['openid.ax.count.' . $alias] = $count;
            }
            $params['openid.ax.required'] = implode(',', $required);
            $params['openid.ax.if_avaiable'] = implode(',', $optional);
        }
        return $params;
    }

    protected function auth_url_v1()
    {
	$return_url = $this->return_url;
        # If we have an openid.delegate that is different from our claimed id,
        # we need to somehow preserve the claimed id between requests.
        # The simplest way is to just send it along with the return_to url.
        if($this->identity != $this->claimed_id) {
            $return_url .= (strpos($return_url, '?') ? '&' : '?') . 'openid.claimed_id=' . $this->claimed_id;
        }

        $params = array(
            'openid.return_to'  => $return_url,
            'openid.mode'       => 'checkid_setup',
            'openid.identity'   => $this->identity,
            'openid.trust_root' => $this->trust_root,
            ) + $this->sregParams();

        return $this->build_url(parse_url($this->server)
                               , array('query' => http_build_query($params, '', '&')));
    }

    protected function auth_url_v2($identifier_select)
    {
        $params = array(
            'openid.ns'          => 'http://specs.openid.net/auth/2.0',
            'openid.mode'        => 'checkid_setup',
            'openid.return_to'   => $this->return_url,
            'openid.realm'       => $this->trust_root,
        );
        if ($this->ax) {
            $params += $this->ax_params();
        }
        if ($this->sreg) {
            $params += $this->sregParams();
        }
        if (!$this->ax && !$this->sreg) {
            # If OP doesn't advertise either SREG, nor AX, let's send them both
            # in worst case we don't get anything in return.
            $params += $this->ax_params() + $this->sregParams();
        }

        if ($identifier_select) {
            $params['openid.identity'] = $params['openid.claimed_id']
                 = 'http://specs.openid.net/auth/2.0/identifier_select';
        } else {
            $params['openid.identity'] = $this->identity;
            $params['openid.claimed_id'] = $this->claimed_id;
        }

        return $this->build_url(parse_url($this->server)
                               , array('query' => http_build_query($params, '', '&')));
    }

    /**
     * Returns authentication url. Usually, you want to redirect your user to it.
     * @return String The authentication url.
     * @param String $select_identifier Whether to request OP to select identity for an user in OpenID 2. Does not affect OpenID 1.
     * @throws ErrorException
     */
    function auth_url($identifier_select = null)
    {
        if (!$this->server) $this->discover($this->identity);

        if ($this->version == 2) {
            if ($identifier_select === null) {
                return $this->auth_url_v2($this->identifier_select);
            }
            return $this->auth_url_v2($identifier_select);
        }
        return $this->auth_url_v1();
    }

    /**
     * Performs OpenID verification with the OP.
     * @return Bool Whether the verification was successful.
     * @throws ErrorException
     */
    function validate()
    {
        $this->claimed_id = isset($this->data['openid_claimed_id'])?$this->data['openid_claimed_id']:$this->data['openid_identity'];
        $params = array(
            'openid.assoc_handle' => $this->data['openid_assoc_handle'],
            'openid.signed'       => $this->data['openid_signed'],
            'openid.sig'          => $this->data['openid_sig'],
            );

        if (isset($this->data['openid_op_endpoint'])) {
            # We're dealing with an OpenID 2.0 server, so let's set an ns
            # Even though we should know location of the endpoint,
            # we still need to verify it by discovery, so $server is not set here
            $params['openid.ns'] = 'http://specs.openid.net/auth/2.0';
        }
        $server = $this->discover($this->data['openid_identity']);

        foreach (explode(',', $this->data['openid_signed']) as $item) {
            # Checking whether magic_quotes_gpc is turned on, because
            # the function may fail if it is. For example, when fetching
            # AX namePerson, it might containg an apostrophe, which will be escaped.
            # In such case, validation would fail, since we'd send different data than OP
            # wants to verify. stripslashes() should solve that problem, but we can't
            # use it when magic_quotes is off.
            $value = $this->data['openid_' . str_replace('.','_',$item)];
            $params['openid.' . $item] = get_magic_quotes_gpc() ? stripslashes($value) : $value; 
        }

        $params['openid.mode'] = 'check_authentication';

        $response = $this->request($server, 'POST', $params);

        return preg_match('/is_valid\s*:\s*true/i', $response);
    }
    protected function get_ax_attributes()
    {
        $alias = null;
        if (isset($this->data['openid_ns_ax'])
            && $this->data['openid_ns_ax'] != 'http://openid.net/srv/ax/1.0'
        ) { # It's the most likely case, so we'll check it before
            $alias = 'ax';
        } else {
            # 'ax' prefix is either undefined, or points to another extension,
            # so we search for another prefix
            foreach ($this->data as $key => $val) {
                if (substr($key, 0, strlen('openid_ns_')) == 'openid_ns_'
                    && $val == 'http://openid.net/srv/ax/1.0'
                ) {
                    $alias = substr($key, strlen('openid_ns_'));
                    break;
                }
            }
        }
        if (!$alias) {
            # An alias for AX schema has not been found,
            # so there is no AX data in the OP's response
            return array();
        }

        foreach ($this->data as $key => $value) {
            $keyMatch = 'openid_' . $alias . '_value_';
            if (substr($key, 0, strlen($keyMatch)) != $keyMatch) {
                continue;
            }
            $key = substr($key, strlen($keyMatch));
            if (!isset($this->data['openid_' . $alias . '_type_' . $key])) {
                # OP is breaking the spec by returning a field without
                # associated ns. This shouldn't happen, but it's better
                # to check, than cause an E_NOTICE.
                continue;
            }
            $key = substr($this->data['openid_' . $alias . '_type_' . $key],
                          strlen('http://axschema.org/'));
            $attributes[$key] = $value;
        }
        # Found the AX attributes, so no need to scan for SREG.
        return $attributes;
    }
    protected function get_sreg_attributes()
    {
        $attributes = array();
        $sreg_to_ax = array_flip(self::$ax_to_sreg);
        foreach ($this->data as $key => $value) {
            $keyMatch = 'openid_sreg_';
            if (substr($key, 0, strlen($keyMatch)) != $keyMatch) {
                continue;
            }
            $key = substr($key, strlen($keyMatch));
            if (!isset($sreg_to_ax[$key])) {
                # The field name isn't part of the SREG spec, so we ignore it.
                continue;
            }
            $attributes[$sreg_to_ax[$key]] = $value;
        }
        return $attributes;
    }
    /**
     * Gets AX/SREG attributes provided by OP. should be used only after successful validaton.
     * Note that it does not guarantee that any of the required/optional parameters will be present,
     * or that there will be no other attributes besides those specified.
     * In other words. OP may provide whatever information it wants to.
     *     * SREG names will be mapped to AX names.
     *     * @return Array Array of attributes with keys being the AX schema names, e.g. 'contact/email'
     * @see http://www.axschema.org/types/
     */
    function get_attributes()
    {
        $attributes;
        if (isset($this->data['openid_ns'])
            && $this->data['openid_ns'] == 'http://specs.openid.net/auth/2.0'
        ) { # OpenID 2.0
            # We search for both AX and SREG attributes, with AX taking precedence.
            return $this->get_ax_attributes() + $this->get_sreg_attributes();
        }
        return $this->get_sreg_attributes();
    }
}
?>'''), STRIP_PHPDOC)

def make_mailer_module(work):
    write(os.path.join(work, 'modules', 'mailer.php'), R'''<?php
/**
 * Mailer Module 1.0 for Pragwork %s
 * This is a PHP Mailer v. 5.1 library with a bit changed API, to follow
 * Pragwork conventions.
 * 
 * @copyright All authors mentioned in the copyright notices below. 
 *            API changes - Szymon Wrozynski
 * @license LGPL
 * @version %s
 * @package Mailer
 */
''' % (__pragwork_version__, __pragwork_version__) + __strip_phpdoc(R'''
namespace Mailer;
/*~ class.smtp.php
.---------------------------------------------------------------------------.
|  Software: PHPMailer - PHP email class                                    |
|   Version: 5.1                                                            |
|   Contact: via sourceforge.net support pages (also www.codeworxtech.com)  |
|      Info: http://phpmailer.sourceforge.net                               |
|   Support: http://sourceforge.net/projects/phpmailer/                     |
| ------------------------------------------------------------------------- |
|     Admin: Andy Prevost (project admininistrator)                         |
|   Authors: Andy Prevost (codeworxtech) codeworxtech@users.sourceforge.net |
|          : Marcus Bointon (coolbru) coolbru@users.sourceforge.net         |
|   Founder: Brent R. Matzelle (original founder)                           |
| Copyright (c) 2004-2009, Andy Prevost. All Rights Reserved.               |
| Copyright (c) 2001-2003, Brent R. Matzelle                                |
| ------------------------------------------------------------------------- |
|   License: Distributed under the Lesser General Public License (LGPL)     |
|            http://www.gnu.org/copyleft/lesser.html                        |
| This program is distributed in the hope that it will be useful - WITHOUT  |
| ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or     |
| FITNESS FOR A PARTICULAR PURPOSE.                                         |
| ------------------------------------------------------------------------- |
| We offer a number of paid services (www.codeworxtech.com):                |
| - Web Hosting on highly optimized fast and secure servers                 |
| - Technology Consulting                                                   |
| - Oursourcing (highly qualified programmers and graphic designers)        |
'---------------------------------------------------------------------------'
*/

/*
 * PHPMailer - PHP SMTP email transport class
 * NOTE: Designed for use with PHP version 5 and up
 * @package PHPMailer
 * @author Andy Prevost
 * @author Marcus Bointon
 * @copyright 2004 - 2008 Andy Prevost
 * @license http://www.gnu.org/copyleft/lesser.html Distributed under the Lesser General Public License (LGPL)
 * @version $Id: class.smtp.php 444 2009-05-05 11:22:26Z coolbru $
 */

/*
 * SMTP is rfc 821 compliant and implements all the rfc 821 SMTP
 * commands except TURN which will always return a not implemented
 * error. SMTP also provides some utility methods for sending mail
 * to an SMTP server.
 * original author: Chris Ryan
 */

class SMTP {
  /**
   *  SMTP server port
   *  @var int
   */
  public $SMTP_PORT = 25;

  /**
   *  SMTP reply line ending
   *  @var string
   */
  public $CRLF = "\r\n";

  /**
   *  Sets whether debugging is turned on
   *  @var bool
   */
  public $do_debug;       // the level of debug to perform

  /**
   *  Sets VERP use on/off (default is off)
   *  @var bool
   */
  public $do_verp = false;

  /////////////////////////////////////////////////
  // PROPERTIES, PRIVATE AND PROTECTED
  /////////////////////////////////////////////////

  private $smtp_conn; // the socket to the server
  private $error;     // error if any on the last call
  private $helo_rply; // the reply the server sent to us for HELO

  /**
   * Initialize the class so that the data is in a known state.
   * @access public
   * @return void
   */
  public function __construct() {
    $this->smtp_conn = 0;
    $this->error = null;
    $this->helo_rply = null;

    $this->do_debug = 0;
  }

  /////////////////////////////////////////////////
  // CONNECTION FUNCTIONS
  /////////////////////////////////////////////////

  /**
   * Connect to the server specified on the port specified.
   * If the port is not specified use the default SMTP_PORT.
   * If tval is specified then a connection will try and be
   * established with the server for that number of seconds.
   * If tval is not specified the default is 30 seconds to
   * try on the connection.
   *
   * SMTP CODE SUCCESS: 220
   * SMTP CODE FAILURE: 421
   * @access public
   * @return bool
   */
  public function Connect($host, $port = 0, $tval = 30) {
    // set the error val to null so there is no confusion
    $this->error = null;

    // make sure we are __not__ connected
    if($this->connected()) {
      // already connected, generate error
      $this->error = array("error" => "Already connected to a server");
      return false;
    }

    if(empty($port)) {
      $port = $this->SMTP_PORT;
    }

    // connect to the smtp server
    $this->smtp_conn = @fsockopen($host,    // the host of the server
                                 $port,    // the port to use
                                 $errno,   // error number if any
                                 $errstr,  // error message if any
                                 $tval);   // give up after ? secs
    // verify we connected properly
    if(empty($this->smtp_conn)) {
      $this->error = array("error" => "Failed to connect to server",
                           "errno" => $errno,
                           "errstr" => $errstr);
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": $errstr ($errno)" . $this->CRLF . '<br />';
      }
      return false;
    }

    // SMTP server can take longer to respond, give longer timeout for first read
    // Windows does not have support for this timeout function
    if(substr(PHP_OS, 0, 3) != "WIN")
     socket_set_timeout($this->smtp_conn, $tval, 0);

    // get any announcement
    $announce = $this->get_lines();

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $announce . $this->CRLF . '<br />';
    }

    return true;
  }

  /**
   * Initiate a TLS communication with the server.
   *
   * SMTP CODE 220 Ready to start TLS
   * SMTP CODE 501 Syntax error (no parameters allowed)
   * SMTP CODE 454 TLS not available due to temporary reason
   * @access public
   * @return bool success
   */
  public function StartTLS() {
    $this->error = null; # to avoid confusion

    if(!$this->connected()) {
      $this->error = array("error" => "Called StartTLS() without being connected");
      return false;
    }

    fputs($this->smtp_conn,"STARTTLS" . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 220) {
      $this->error =
         array("error"     => "STARTTLS not accepted from server",
               "smtp_code" => $code,
               "smtp_msg"  => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    // Begin encrypted connection
    if(!stream_socket_enable_crypto($this->smtp_conn, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
      return false;
    }

    return true;
  }

  /**
   * Performs SMTP authentication.  Must be run after running the
   * Hello() method.  Returns true if successfully authenticated.
   * @access public
   * @return bool
   */
  public function Authenticate($username, $password) {
    // Start authentication
    fputs($this->smtp_conn,"AUTH LOGIN" . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($code != 334) {
      $this->error =
        array("error" => "AUTH not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    // Send encoded username
    fputs($this->smtp_conn, base64_encode($username) . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($code != 334) {
      $this->error =
        array("error" => "Username not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    // Send encoded password
    fputs($this->smtp_conn, base64_encode($password) . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($code != 235) {
      $this->error =
        array("error" => "Password not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    return true;
  }

  /**
   * Returns true if connected to a server otherwise false
   * @access public
   * @return bool
   */
  public function Connected() {
    if(!empty($this->smtp_conn)) {
      $sock_status = socket_get_status($this->smtp_conn);
      if($sock_status["eof"]) {
        // the socket is valid but we are not connected
        if($this->do_debug >= 1) {
            echo "SMTP -> NOTICE:" . $this->CRLF . "EOF caught while checking if connected";
        }
        $this->Close();
        return false;
      }
      return true; // everything looks good
    }
    return false;
  }

  /**
   * Closes the socket and cleans up the state of the class.
   * It is not considered good to use this function without
   * first trying to use QUIT.
   * @access public
   * @return void
   */
  public function Close() {
    $this->error = null; // so there is no confusion
    $this->helo_rply = null;
    if(!empty($this->smtp_conn)) {
      // close the connection and cleanup
      fclose($this->smtp_conn);
      $this->smtp_conn = 0;
    }
  }

  /////////////////////////////////////////////////
  // SMTP COMMANDS
  /////////////////////////////////////////////////

  /**
   * Issues a data command and sends the msg_data to the server
   * finializing the mail transaction. $msg_data is the message
   * that is to be send with the headers. Each header needs to be
   * on a single line followed by a <CRLF> with the message headers
   * and the message body being seperated by and additional <CRLF>.
   *
   * Implements rfc 821: DATA <CRLF>
   *
   * SMTP CODE INTERMEDIATE: 354
   *     [data]
   *     <CRLF>.<CRLF>
   *     SMTP CODE SUCCESS: 250
   *     SMTP CODE FAILURE: 552,554,451,452
   * SMTP CODE FAILURE: 451,554
   * SMTP CODE ERROR  : 500,501,503,421
   * @access public
   * @return bool
   */
  public function Data($msg_data) {
    $this->error = null; // so no confusion is caused

    if(!$this->connected()) {
      $this->error = array(
              "error" => "Called Data() without being connected");
      return false;
    }

    fputs($this->smtp_conn,"DATA" . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 354) {
      $this->error =
        array("error" => "DATA command not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    /* the server is ready to accept data!
     * according to rfc 821 we should not send more than 1000
     * including the CRLF
     * characters on a single line so we will break the data up
     * into lines by \r and/or \n then if needed we will break
     * each of those into smaller lines to fit within the limit.
     * in addition we will be looking for lines that start with
     * a period '.' and append and additional period '.' to that
     * line. NOTE: this does not count towards limit.
     */

    // normalize the line breaks so we know the explode works
    $msg_data = str_replace("\r\n","\n",$msg_data);
    $msg_data = str_replace("\r","\n",$msg_data);
    $lines = explode("\n",$msg_data);

    /* we need to find a good way to determine is headers are
     * in the msg_data or if it is a straight msg body
     * currently I am assuming rfc 822 definitions of msg headers
     * and if the first field of the first line (':' sperated)
     * does not contain a space then it _should_ be a header
     * and we can process all lines before a blank "" line as
     * headers.
     */

    $field = substr($lines[0],0,strpos($lines[0],":"));
    $in_headers = false;
    if(!empty($field) && !strstr($field," ")) {
      $in_headers = true;
    }

    $max_line_length = 998; // used below; set here for ease in change

    while(list(,$line) = @each($lines)) {
      $lines_out = null;
      if($line == "" && $in_headers) {
        $in_headers = false;
      }
      // ok we need to break this line up into several smaller lines
      while(strlen($line) > $max_line_length) {
        $pos = strrpos(substr($line,0,$max_line_length)," ");

        // Patch to fix DOS attack
        if(!$pos) {
          $pos = $max_line_length - 1;
          $lines_out[] = substr($line,0,$pos);
          $line = substr($line,$pos);
        } else {
          $lines_out[] = substr($line,0,$pos);
          $line = substr($line,$pos + 1);
        }

        /* if processing headers add a LWSP-char to the front of new line
         * rfc 822 on long msg headers
         */
        if($in_headers) {
          $line = "\t" . $line;
        }
      }
      $lines_out[] = $line;

      // send the lines to the server
      while(list(,$line_out) = @each($lines_out)) {
        if(strlen($line_out) > 0)
        {
          if(substr($line_out, 0, 1) == ".") {
            $line_out = "." . $line_out;
          }
        }
        fputs($this->smtp_conn,$line_out . $this->CRLF);
      }
    }

    // message data has been sent
    fputs($this->smtp_conn, $this->CRLF . "." . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 250) {
      $this->error =
        array("error" => "DATA not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }
    return true;
  }

  /**
   * Sends the HELO command to the smtp server.
   * This makes sure that we and the server are in
   * the same known state.
   *
   * Implements from rfc 821: HELO <SP> <domain> <CRLF>
   *
   * SMTP CODE SUCCESS: 250
   * SMTP CODE ERROR  : 500, 501, 504, 421
   * @access public
   * @return bool
   */
  public function Hello($host = '') {
    $this->error = null; // so no confusion is caused

    if(!$this->connected()) {
      $this->error = array(
            "error" => "Called Hello() without being connected");
      return false;
    }

    // if hostname for HELO was not specified send default
    if(empty($host)) {
      // determine appropriate default to send to server
      $host = "localhost";
    }

    // Send extended hello first (RFC 2821)
    if(!$this->SendHello("EHLO", $host)) {
      if(!$this->SendHello("HELO", $host)) {
        return false;
      }
    }

    return true;
  }

  /**
   * Sends a HELO/EHLO command.
   * @access private
   * @return bool
   */
  private function SendHello($hello, $host) {
    fputs($this->smtp_conn, $hello . " " . $host . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER: " . $rply . $this->CRLF . '<br />';
    }

    if($code != 250) {
      $this->error =
        array("error" => $hello . " not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    $this->helo_rply = $rply;

    return true;
  }

  /**
   * Starts a mail transaction from the email address specified in
   * $from. Returns true if successful or false otherwise. If True
   * the mail transaction is started and then one or more Recipient
   * commands may be called followed by a Data command.
   *
   * Implements rfc 821: MAIL <SP> FROM:<reverse-path> <CRLF>
   *
   * SMTP CODE SUCCESS: 250
   * SMTP CODE SUCCESS: 552,451,452
   * SMTP CODE SUCCESS: 500,501,421
   * @access public
   * @return bool
   */
  public function Mail($from) {
    $this->error = null; // so no confusion is caused

    if(!$this->connected()) {
      $this->error = array(
              "error" => "Called Mail() without being connected");
      return false;
    }

    $useVerp = ($this->do_verp ? "XVERP" : "");
    fputs($this->smtp_conn,"MAIL FROM:<" . $from . ">" . $useVerp . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 250) {
      $this->error =
        array("error" => "MAIL not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }
    return true;
  }

  /**
   * Sends the quit command to the server and then closes the socket
   * if there is no error or the $close_on_error argument is true.
   *
   * Implements from rfc 821: QUIT <CRLF>
   *
   * SMTP CODE SUCCESS: 221
   * SMTP CODE ERROR  : 500
   * @access public
   * @return bool
   */
  public function Quit($close_on_error = true) {
    $this->error = null; // so there is no confusion

    if(!$this->connected()) {
      $this->error = array(
              "error" => "Called Quit() without being connected");
      return false;
    }

    // send the quit command to the server
    fputs($this->smtp_conn,"quit" . $this->CRLF);

    // get any good-bye messages
    $byemsg = $this->get_lines();

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $byemsg . $this->CRLF . '<br />';
    }

    $rval = true;
    $e = null;

    $code = substr($byemsg,0,3);
    if($code != 221) {
      // use e as a tmp var cause Close will overwrite $this->error
      $e = array("error" => "SMTP server rejected quit command",
                 "smtp_code" => $code,
                 "smtp_rply" => substr($byemsg,4));
      $rval = false;
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $e["error"] . ": " . $byemsg . $this->CRLF . '<br />';
      }
    }

    if(empty($e) || $close_on_error) {
      $this->Close();
    }

    return $rval;
  }

  /**
   * Sends the command RCPT to the SMTP server with the TO: argument of $to.
   * Returns true if the recipient was accepted false if it was rejected.
   *
   * Implements from rfc 821: RCPT <SP> TO:<forward-path> <CRLF>
   *
   * SMTP CODE SUCCESS: 250,251
   * SMTP CODE FAILURE: 550,551,552,553,450,451,452
   * SMTP CODE ERROR  : 500,501,503,421
   * @access public
   * @return bool
   */
  public function Recipient($to) {
    $this->error = null; // so no confusion is caused

    if(!$this->connected()) {
      $this->error = array(
              "error" => "Called Recipient() without being connected");
      return false;
    }

    fputs($this->smtp_conn,"RCPT TO:<" . $to . ">" . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 250 && $code != 251) {
      $this->error =
        array("error" => "RCPT not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }
    return true;
  }

  /**
   * Sends the RSET command to abort and transaction that is
   * currently in progress. Returns true if successful false
   * otherwise.
   *
   * Implements rfc 821: RSET <CRLF>
   *
   * SMTP CODE SUCCESS: 250
   * SMTP CODE ERROR  : 500,501,504,421
   * @access public
   * @return bool
   */
  public function Reset() {
    $this->error = null; // so no confusion is caused

    if(!$this->connected()) {
      $this->error = array(
              "error" => "Called Reset() without being connected");
      return false;
    }

    fputs($this->smtp_conn,"RSET" . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 250) {
      $this->error =
        array("error" => "RSET failed",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }

    return true;
  }

  /**
   * Starts a mail transaction from the email address specified in
   * $from. Returns true if successful or false otherwise. If True
   * the mail transaction is started and then one or more Recipient
   * commands may be called followed by a Data command. This command
   * will send the message to the users terminal if they are logged
   * in and send them an email.
   *
   * Implements rfc 821: SAML <SP> FROM:<reverse-path> <CRLF>
   *
   * SMTP CODE SUCCESS: 250
   * SMTP CODE SUCCESS: 552,451,452
   * SMTP CODE SUCCESS: 500,501,502,421
   * @access public
   * @return bool
   */
  public function SendAndMail($from) {
    $this->error = null; // so no confusion is caused

    if(!$this->connected()) {
      $this->error = array(
          "error" => "Called SendAndMail() without being connected");
      return false;
    }

    fputs($this->smtp_conn,"SAML FROM:" . $from . $this->CRLF);

    $rply = $this->get_lines();
    $code = substr($rply,0,3);

    if($this->do_debug >= 2) {
      echo "SMTP -> FROM SERVER:" . $rply . $this->CRLF . '<br />';
    }

    if($code != 250) {
      $this->error =
        array("error" => "SAML not accepted from server",
              "smtp_code" => $code,
              "smtp_msg" => substr($rply,4));
      if($this->do_debug >= 1) {
        echo "SMTP -> ERROR: " . $this->error["error"] . ": " . $rply . $this->CRLF . '<br />';
      }
      return false;
    }
    return true;
  }

  /**
   * This is an optional command for SMTP that this class does not
   * support. This method is here to make the RFC821 Definition
   * complete for this class and __may__ be implimented in the future
   *
   * Implements from rfc 821: TURN <CRLF>
   *
   * SMTP CODE SUCCESS: 250
   * SMTP CODE FAILURE: 502
   * SMTP CODE ERROR  : 500, 503
   * @access public
   * @return bool
   */
  public function Turn() {
    $this->error = array("error" => "This method, TURN, of the SMTP ".
                                    "is not implemented");
    if($this->do_debug >= 1) {
      echo "SMTP -> NOTICE: " . $this->error["error"] . $this->CRLF . '<br />';
    }
    return false;
  }

  /**
  * Get the current error
  * @access public
  * @return array
  */
  public function getError() {
    return $this->error;
  }

  /////////////////////////////////////////////////
  // INTERNAL FUNCTIONS
  /////////////////////////////////////////////////

  /**
   * Read in as many lines as possible
   * either before eof or socket timeout occurs on the operation.
   * With SMTP we can tell if we have more lines to read if the
   * 4th character is '-' symbol. If it is a space then we don't
   * need to read anything else.
   * @access private
   * @return string
   */
  private function get_lines() {
    $data = "";
    while($str = @fgets($this->smtp_conn,515)) {
      if($this->do_debug >= 4) {
        echo "SMTP -> get_lines(): \$data was \"$data\"" . $this->CRLF . '<br />';
        echo "SMTP -> get_lines(): \$str is \"$str\"" . $this->CRLF . '<br />';
      }
      $data .= $str;
      if($this->do_debug >= 4) {
        echo "SMTP -> get_lines(): \$data is \"$data\"" . $this->CRLF . '<br />';
      }
      // if 4th character is a space, we are done reading, break the loop
      if(substr($str,3,1) == " ") { break; }
    }
    return $data;
  }

}
''' %()) + R'''

/*~ class.phpmailer.php
.---------------------------------------------------------------------------.
|  Software: PHPMailer - PHP email class                                    |
|   Version: 5.1                                                            |
|   Contact: via sourceforge.net support pages (also www.worxware.com)      |
|      Info: http://phpmailer.sourceforge.net                               |
|   Support: http://sourceforge.net/projects/phpmailer/                     |
| ------------------------------------------------------------------------- |
|     Admin: Andy Prevost (project admininistrator)                         |
|   Authors: Andy Prevost (codeworxtech) codeworxtech@users.sourceforge.net |
|          : Marcus Bointon (coolbru) coolbru@users.sourceforge.net         |
|   Founder: Brent R. Matzelle (original founder)                           |
| Copyright (c) 2004-2009, Andy Prevost. All Rights Reserved.               |
| Copyright (c) 2001-2003, Brent R. Matzelle                                |
| ------------------------------------------------------------------------- |
|   License: Distributed under the Lesser General Public License (LGPL)     |
|            http://www.gnu.org/copyleft/lesser.html                        |
| This program is distributed in the hope that it will be useful - WITHOUT  |
| ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or     |
| FITNESS FOR A PARTICULAR PURPOSE.                                         |
| ------------------------------------------------------------------------- |
| We offer a number of paid services (www.worxware.com):                    |
| - Web Hosting on highly optimized fast and secure servers                 |
| - Technology Consulting                                                   |
| - Oursourcing (highly qualified programmers and graphic designers)        |
'---------------------------------------------------------------------------'
*/

/**
 * PHPMailer - PHP email transport class
 * NOTE: Requires PHP version 5 or later
 * @package PHPMailer
 * @author Andy Prevost
 * @author Marcus Bointon
 * @copyright 2004 - 2009 Andy Prevost
 * @version $Id: class.phpmailer.php 447 2009-05-25 01:36:38Z codeworxtech $
 * @license http://www.gnu.org/copyleft/lesser.html GNU Lesser General Public License
 */
''' + __strip_phpdoc(R'''
if (version_compare(PHP_VERSION, '5.0.0', '<') ) exit("Sorry, this version of PHPMailer will only run on PHP version 5 or greater!\n");

class Mailer {

  /////////////////////////////////////////////////
  // PROPERTIES, PUBLIC
  /////////////////////////////////////////////////

  /**
   * Email priority (1 = High, 3 = Normal, 5 = low).
   * @var int
   */
  public $priority          = 3;

  /**
   * Sets the charset of the message.
   * @var string
   */
  public $charset           = 'utf-8';

  /**
   * Sets the Content-type of the message.
   * @var string
   */
  public $content_type       = 'text/plain';

  /**
   * Sets the encoding of the message. Options for this are
   *  "8bit", "7bit", "binary", "base64", and "quoted-printable".
   * @var string
   */
  public $encoding          = '8bit';

  /**
   * Holds the most recent mailer error message.
   * @var string
   */
  public $error_info         = '';

  /**
   * Sets the From email address for the message.
   * @var string
   */
  public $from              = 'root@localhost';

  /**
   * Sets the From name of the message.
   * @var string
   */
  public $from_name          = 'Root User';

  /**
   * Sets the sender email (Return-Path) of the message.  If not empty,
   * will be sent via -f to sendmail or as 'MAIL FROM' in smtp mode.
   * @var string
   */
  public $sender            = '';

  /**
   * Sets the subject of the message.
   * @var string
   */
  public $subject           = '';

  /**
   * Sets the body of the message.  This can be either an HTML or text body.
   * If HTML then run use_html(true).
   * @var string
   */
  public $body              = '';

  /**
   * Sets the text-only body of the message.  This automatically sets the
   * email to multipart/alternative.  This body can be read by mail
   * clients that do not have HTML email capability such as mutt. Clients
   * that can read HTML will view the normal body.
   * @var string
   */
  public $alt_body           = '';

  /**
   * Sets word wrapping on the body of the message to a given number of
   * characters.
   * @var int
   */
  public $word_wrap          = 0;

  /**
   * Method to send mail: ("mail", "sendmail", or "smtp").
   * @var string
   */
  public $mailer            = 'mail';

  /**
   * Sets the path of the sendmail program.
   * @var string
   */
  public $sendmail          = '/usr/sbin/sendmail';

  /**
   * Path to PHPMailer plugins.  Useful if the SMTP class
   * is in a different directory than the PHP include path.
   * @var string
   */
  // public $plugin_dir         = ''; // TODO remove

  /**
   * Sets the email address that a reading confirmation will be sent.
   * @var string
   */
  public $confirm_reading_to  = '';

  /**
   * Sets the hostname to use in Message-Id and Received headers
   * and as default HELO string. If empty, the value returned
   * by SERVER_NAME is used or 'localhost.localdomain'.
   * @var string
   */
  public $hostname          = '';

  /**
   * Sets the message ID to be used in the Message-Id header.
   * If empty, a unique id will be generated.
   * @var string
   */
  public $message_id         = '';

  /////////////////////////////////////////////////
  // PROPERTIES FOR SMTP
  /////////////////////////////////////////////////

  /**
   * Sets the SMTP hosts.  All hosts must be separated by a
   * semicolon.  You can also specify a different port
   * for each host by using this format: [hostname:port]
   * (e.g. "smtp1.example.com:25;smtp2.example.com").
   * Hosts will be tried in order.
   * @var string
   */
  public $host          = 'localhost';

  /**
   * Sets the default SMTP server port.
   * @var int
   */
  public $port          = 25;

  /**
   * Sets the SMTP HELO of the message (Default is $Hostname).
   * @var string
   */
  public $helo          = '';

  /**
   * Sets connection prefix.
   * Options are "", "ssl" or "tls"
   * @var string
   */
  public $SMTP_secure    = '';

  /**
   * Sets SMTP authentication. Utilizes the Username and Password variables.
   * @var bool
   */
  public $SMTP_auth      = false;

  /**
   * Sets SMTP username.
   * @var string
   */
  public $username      = '';

  /**
   * Sets SMTP password.
   * @var string
   */
  public $password      = '';

  /**
   * Sets the SMTP server timeout in seconds.
   * This function will not work with the win32 version.
   * @var int
   */
  public $timeout       = 10;

  /**
   * Sets SMTP class debugging on or off.
   * @var bool
   */
  public $SMTP_debug     = false;

  /**
   * Prevents the SMTP connection from being closed after each mail
   * sending.  If this is set to true then to close the connection
   * requires an explicit call to smtp_close().
   * @var bool
   */
  public $SMTP_keep_alive = false;

  /**
   * Provides the ability to have the TO field process individual
   * emails, instead of sending to entire TO addresses
   * @var bool
   */
  public $single_to      = false;

   /**
   * If single_to is true, this provides the array to hold the email addresses
   * @var bool
   */
  public $single_to_array = array();

 /**
   * Provides the ability to change the line ending
   * @var string
   */
  public $LE              = "\n";

  /**
   * Used with DKIM DNS Resource Record
   * @var string
   */
  public $DKIM_selector   = 'phpmailer';

  /**
   * Used with DKIM DNS Resource Record
   * optional, in format of email address 'you@yourdomain.com'
   * @var string
   */
  public $DKIM_identity   = '';

  /**
   * Used with DKIM DNS Resource Record
   * optional, in format of email address 'you@yourdomain.com'
   * @var string
   */
  public $DKIM_domain     = '';

  /**
   * Used with DKIM DNS Resource Record
   * optional, in format of email address 'you@yourdomain.com'
   * @var string
   */
  public $DKIM_private    = '';

  /**
   * Callback Action function name
   * the function that handles the result of the send email action. Parameters:
   *   bool    $result        result of the send action
   *   string  $to            email address of the recipient
   *   string  $cc            cc email addresses
   *   string  $bcc           bcc email addresses
   *   string  $subject       the subject
   *   string  $body          the email body
   * @var string
   */
  public $action_function = ''; //'callbackAction';

  /**
   * Sets the PHPMailer Version number
   * @var string
   */
  public $version         = '5.1';

  /////////////////////////////////////////////////
  // PROPERTIES, PRIVATE AND PROTECTED
  /////////////////////////////////////////////////

  private   $smtp           = NULL;
  private   $to             = array();
  private   $cc             = array();
  private   $bcc            = array();
  private   $ReplyTo        = array();
  private   $all_recipients = array();
  private   $attachment     = array();
  private   $CustomHeader   = array();
  private   $message_type   = '';
  private   $boundary       = array();
  protected $language       = array();
  private   $error_count    = 0;
  private   $sign_cert_file = "";
  private   $sign_key_file  = "";
  private   $sign_key_pass  = "";
  private   $exceptions     = false;

  /////////////////////////////////////////////////
  // CONSTANTS
  /////////////////////////////////////////////////

  const STOP_MESSAGE  = 0; // message only, continue processing
  const STOP_CONTINUE = 1; // message?, likely ok to continue processing
  const STOP_CRITICAL = 2; // message, plus full stop, critical error reached

  /////////////////////////////////////////////////
  // METHODS, VARIABLES
  /////////////////////////////////////////////////

  /**
   * Constructor
   * @param boolean $exceptions Should we throw external exceptions?
   */
  public function __construct($exceptions=true) {
    $this->exceptions = ($exceptions == true);
  }

  /**
   * Sets message type to HTML.
   * @param bool $use_html
   * @return void
   */
  public function use_html($use_html = true) {
    if ($use_html) {
      $this->content_type = 'text/html';
    } else {
      $this->content_type = 'text/plain';
    }
  }

  /**
   * Sets Mailer to send message using SMTP.
   * @return void
   */
  public function use_SMTP() {
    $this->mailer = 'smtp';
  }

  /**
   * Sets Mailer to send message using PHP mail() function.
   * @return void
   */
  public function use_mail() {
    $this->mailer = 'mail';
  }

  /**
   * Sets Mailer to send message using the $Sendmail program.
   * @return void
   */
  public function use_sendmail() {
    if (!stristr(ini_get('sendmail_path'), 'sendmail')) {
      $this->sendmail = '/var/qmail/bin/sendmail';
    }
    $this->mailer = 'sendmail';
  }

  /**
   * Sets Mailer to send message using the qmail MTA.
   * @return void
   */
  public function use_qmail() {
    if (stristr(ini_get('sendmail_path'), 'qmail')) {
      $this->sendmail = '/var/qmail/bin/sendmail';
    }
    $this->mailer = 'sendmail';
  }

  /////////////////////////////////////////////////
  // METHODS, RECIPIENTS
  /////////////////////////////////////////////////

  /**
   * Adds a "To" address.
   * @param string $address
   * @param string $name
   * @return boolean true on success, false if address already used
   */
  public function add_address($address, $name = '') {
    return $this->add_an_address('to', $address, $name);
  }

  /**
   * Adds a "Cc" address.
   * Note: this function works with the SMTP mailer on win32, not with the "mail" mailer.
   * @param string $address
   * @param string $name
   * @return boolean true on success, false if address already used
   */
  public function add_cc($address, $name = '') {
    return $this->add_an_address('cc', $address, $name);
  }

  /**
   * Adds a "Bcc" address.
   * Note: this function works with the SMTP mailer on win32, not with the "mail" mailer.
   * @param string $address
   * @param string $name
   * @return boolean true on success, false if address already used
   */
  public function add_bcc($address, $name = '') {
    return $this->add_an_address('bcc', $address, $name);
  }

  /**
   * Adds a "Reply-to" address.
   * @param string $address
   * @param string $name
   * @return boolean
   */
  public function add_reply_to($address, $name = '') {
    return $this->add_an_address('ReplyTo', $address, $name);
  }

  /**
   * Adds an address to one of the recipient arrays
   * Addresses that have been added already return false, but do not throw exceptions
   * @param string $kind One of 'to', 'cc', 'bcc', 'ReplyTo'
   * @param string $address The email address to send to
   * @param string $name
   * @return boolean true on success, false if address already used or invalid in some way
   * @access private
   */
  private function add_an_address($kind, $address, $name = '') {
    if (!preg_match('/^(to|cc|bcc|ReplyTo)$/', $kind)) {
      echo 'Invalid recipient array: ' . kind;
      return false;
    }
    $address = trim($address);
    $name = trim(preg_replace('/[\r\n]+/', '', $name)); //Strip breaks and trim
    if (!self::validate_address($address)) {
      $this->set_error($this->lang('invalid_address').': '. $address);
      if ($this->exceptions) {
        throw new MailerException($this->lang('invalid_address').': '.$address);
      }
      echo $this->lang('invalid_address').': '.$address;
      return false;
    }
    if ($kind != 'ReplyTo') {
      if (!isset($this->all_recipients[strtolower($address)])) {
        array_push($this->$kind, array($address, $name));
        $this->all_recipients[strtolower($address)] = true;
        return true;
      }
    } else {
      if (!array_key_exists(strtolower($address), $this->ReplyTo)) {
        $this->ReplyTo[strtolower($address)] = array($address, $name);
      return true;
    }
  }
  return false;
}

/**
 * Set the from and from_name properties
 * @param string $address
 * @param string $name
 * @return boolean
 */
  public function set_from($address, $name = '',$auto=1) {
    $address = trim($address);
    $name = trim(preg_replace('/[\r\n]+/', '', $name)); //Strip breaks and trim
    if (!self::validate_address($address)) {
      $this->set_error($this->lang('invalid_address').': '. $address);
      if ($this->exceptions) {
        throw new MailerException($this->lang('invalid_address').': '.$address);
      }
      echo $this->lang('invalid_address').': '.$address;
      return false;
    }
    $this->from = $address;
    $this->from_name = $name;
    if ($auto) {
      if (empty($this->ReplyTo)) {
        $this->add_an_address('ReplyTo', $address, $name);
      }
      if (empty($this->sender)) {
        $this->sender = $address;
      }
    }
    return true;
  }

  /**
   * Check that a string looks roughly like an email address should
   * Static so it can be used without instantiation
   * Tries to use PHP built-in validator in the filter extension (from PHP 5.2), falls back to a reasonably competent regex validator
   * Conforms approximately to RFC2822
   * @link http://www.hexillion.com/samples/#Regex Original pattern found here
   * @param string $address The email address to check
   * @return boolean
   * @static
   * @access public
   */
  public static function validate_address($address) {
    if (function_exists('filter_var')) { //Introduced in PHP 5.2
      if(filter_var($address, FILTER_VALIDATE_EMAIL) === FALSE) {
        return false;
      } else {
        return true;
      }
    } else {
      return preg_match('/^(?:[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+\.)*[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+@(?:(?:(?:[a-zA-Z0-9_](?:[a-zA-Z0-9_\-](?!\.)){0,61}[a-zA-Z0-9_-]?\.)+[a-zA-Z0-9_](?:[a-zA-Z0-9_\-](?!$)){0,61}[a-zA-Z0-9_]?)|(?:\[(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\]))$/', $address);
    }
  }

  /////////////////////////////////////////////////
  // METHODS, MAIL SENDING
  /////////////////////////////////////////////////

  /**
   * Creates message and assigns Mailer. If the message is
   * not sent successfully then it returns false.  Use the error_info
   * variable to view description of the error.
   * @return bool
   */
  public function send() {
    try {
      if ((count($this->to) + count($this->cc) + count($this->bcc)) < 1) {
        throw new MailerException($this->lang('provide_address'), self::STOP_CRITICAL);
      }

      // Set whether the message is multipart/alternative
      if(!empty($this->alt_body)) {
        $this->content_type = 'multipart/alternative';
      }

      $this->error_count = 0; // reset errors
      $this->set_message_type();
      $header = $this->create_header();
      $body = $this->create_body();

      if (empty($this->body)) {
        throw new MailerException($this->lang('empty_message'), self::STOP_CRITICAL);
      }

      // digitally sign with DKIM if enabled
      if ($this->DKIM_domain && $this->DKIM_private) {
        $header_dkim = $this->DKIM_add($header,$this->subject,$body);
        $header = str_replace("\r\n","\n",$header_dkim) . $header;
      }

      // Choose the mailer and send through it
      switch($this->mailer) {
        case 'sendmail':
          return $this->sendmail_send($header, $body);
        case 'smtp':
          return $this->smtp_send($header, $body);
        default:
          return $this->mail_send($header, $body);
      }

    } catch (MailerException $e) {
      $this->set_error($e->getMessage());
      if ($this->exceptions) {
        throw $e;
      }
      echo $e->getMessage()."\n";
      return false;
    }
  }

  /**
   * Sends mail using the $Sendmail program.
   * @param string $header The message headers
   * @param string $body The message body
   * @access protected
   * @return bool
   */
  protected function sendmail_send($header, $body) {
    if ($this->sender != '') {
      $sendmail = sprintf("%s -oi -f %s -t", escapeshellcmd($this->sendmail), escapeshellarg($this->sender));
    } else {
      $sendmail = sprintf("%s -oi -t", escapeshellcmd($this->sendmail));
    }
    if ($this->single_to === true) {
      foreach ($this->single_to_array as $key => $val) {
        if(!@$mail = popen($sendmail, 'w')) {
          throw new MailerException($this->lang('execute') . $this->sendmail, self::STOP_CRITICAL);
        }
        fputs($mail, "To: " . $val . "\n");
        fputs($mail, $header);
        fputs($mail, $body);
        $result = pclose($mail);
        // implement call back function if it exists
        $isSent = ($result == 0) ? 1 : 0;
        $this->do_callback($isSent,$val,$this->cc,$this->bcc,$this->subject,$body);
        if($result != 0) {
          throw new MailerException($this->lang('execute') . $this->sendmail, self::STOP_CRITICAL);
        }
      }
    } else {
      if(!@$mail = popen($sendmail, 'w')) {
        throw new MailerException($this->lang('execute') . $this->sendmail, self::STOP_CRITICAL);
      }
      fputs($mail, $header);
      fputs($mail, $body);
      $result = pclose($mail);
      // implement call back function if it exists
      $isSent = ($result == 0) ? 1 : 0;
      $this->do_callback($isSent,$this->to,$this->cc,$this->bcc,$this->subject,$body);
      if($result != 0) {
        throw new MailerException($this->lang('execute') . $this->sendmail, self::STOP_CRITICAL);
      }
    }
    return true;
  }

  /**
   * Sends mail using the PHP mail() function.
   * @param string $header The message headers
   * @param string $body The message body
   * @access protected
   * @return bool
   */
  protected function mail_send($header, $body) {
    $toArr = array();
    foreach($this->to as $t) {
      $toArr[] = $this->addr_format($t);
    }
    $to = implode(', ', $toArr);

    $params = sprintf("-oi -f %s", $this->sender);
    if ($this->sender != '' && strlen(ini_get('safe_mode'))< 1) {
      $old_from = ini_get('sendmail_from');
      ini_set('sendmail_from', $this->sender);
      if ($this->single_to === true && count($toArr) > 1) {
        foreach ($toArr as $key => $val) {
          $rt = @mail($val, $this->encode_header($this->secure_header($this->subject)), $body, $header, $params);
          // implement call back function if it exists
          $isSent = ($rt == 1) ? 1 : 0;
          $this->do_callback($isSent,$val,$this->cc,$this->bcc,$this->subject,$body);
        }
      } else {
        $rt = @mail($to, $this->encode_header($this->secure_header($this->subject)), $body, $header, $params);
        // implement call back function if it exists
        $isSent = ($rt == 1) ? 1 : 0;
        $this->do_callback($isSent,$to,$this->cc,$this->bcc,$this->subject,$body);
      }
    } else {
      if ($this->single_to === true && count($toArr) > 1) {
        foreach ($toArr as $key => $val) {
          $rt = @mail($val, $this->encode_header($this->secure_header($this->subject)), $body, $header, $params);
          // implement call back function if it exists
          $isSent = ($rt == 1) ? 1 : 0;
          $this->do_callback($isSent,$val,$this->cc,$this->bcc,$this->subject,$body);
        }
      } else {
        $rt = @mail($to, $this->encode_header($this->secure_header($this->subject)), $body, $header);
        // implement call back function if it exists
        $isSent = ($rt == 1) ? 1 : 0;
        $this->do_callback($isSent,$to,$this->cc,$this->bcc,$this->subject,$body);
      }
    }
    if (isset($old_from)) {
      ini_set('sendmail_from', $old_from);
    }
    if(!$rt) {
      throw new MailerException($this->lang('instantiate'), self::STOP_CRITICAL);
    }
    return true;
  }

  /**
   * Sends mail via SMTP using PhpSMTP
   * Returns false if there is a bad MAIL FROM, RCPT, or DATA input.
   * @param string $header The message headers
   * @param string $body The message body
   * @uses SMTP
   * @access protected
   * @return bool
   */
  protected function smtp_send($header, $body) {
    $bad_rcpt = array();

    if(!$this->smtp_connect()) {
      throw new MailerException($this->lang('smtp_connect_failed'), self::STOP_CRITICAL);
    }
    $smtp_from = ($this->sender == '') ? $this->from : $this->sender;
    if(!$this->smtp->Mail($smtp_from)) {
      throw new MailerException($this->lang('from_failed') . $smtp_from, self::STOP_CRITICAL);
    }

    // Attempt to send attach all recipients
    foreach($this->to as $to) {
      if (!$this->smtp->Recipient($to[0])) {
        $bad_rcpt[] = $to[0];
        // implement call back function if it exists
        $isSent = 0;
        $this->do_callback($isSent,$to[0],'','',$this->subject,$body);
      } else {
        // implement call back function if it exists
        $isSent = 1;
        $this->do_callback($isSent,$to[0],'','',$this->subject,$body);
      }
    }
    foreach($this->cc as $cc) {
      if (!$this->smtp->Recipient($cc[0])) {
        $bad_rcpt[] = $cc[0];
        // implement call back function if it exists
        $isSent = 0;
        $this->do_callback($isSent,'',$cc[0],'',$this->subject,$body);
      } else {
        // implement call back function if it exists
        $isSent = 1;
        $this->do_callback($isSent,'',$cc[0],'',$this->subject,$body);
      }
    }
    foreach($this->bcc as $bcc) {
      if (!$this->smtp->Recipient($bcc[0])) {
        $bad_rcpt[] = $bcc[0];
        // implement call back function if it exists
        $isSent = 0;
        $this->do_callback($isSent,'','',$bcc[0],$this->subject,$body);
      } else {
        // implement call back function if it exists
        $isSent = 1;
        $this->do_callback($isSent,'','',$bcc[0],$this->subject,$body);
      }
    }


    if (count($bad_rcpt) > 0 ) { //Create error message for any bad addresses
      $badaddresses = implode(', ', $bad_rcpt);
      throw new MailerException($this->lang('recipients_failed') . $badaddresses);
    }
    if(!$this->smtp->Data($header . $body)) {
      throw new MailerException($this->lang('data_not_accepted'), self::STOP_CRITICAL);
    }
    if($this->SMTP_keep_alive == true) {
      $this->smtp->Reset();
    }
    return true;
  }

  /**
   * Initiates a connection to an SMTP server.
   * Returns false if the operation failed.
   * @uses SMTP
   * @access public
   * @return bool
   */
  public function smtp_connect() {
    if(is_null($this->smtp)) {
      $this->smtp = new SMTP();
    }

    $this->smtp->do_debug = $this->SMTP_debug;
    $hosts = explode(';', $this->host);
    $index = 0;
    $connection = $this->smtp->Connected();

    // Retry while there is no connection
    try {
      while($index < count($hosts) && !$connection) {
        $hostinfo = array();
        if (preg_match('/^(.+):([0-9]+)$/', $hosts[$index], $hostinfo)) {
          $host = $hostinfo[1];
          $port = $hostinfo[2];
        } else {
          $host = $hosts[$index];
          $port = $this->port;
        }

        $tls = ($this->SMTP_secure == 'tls');
        $ssl = ($this->SMTP_secure == 'ssl');

        if ($this->smtp->Connect(($ssl ? 'ssl://':'').$host, $port, $this->timeout)) {

          $hello = ($this->helo != '' ? $this->helo : $this->server_hostname());
          $this->smtp->Hello($hello);

          if ($tls) {
            if (!$this->smtp->StartTLS()) {
              throw new MailerException($this->lang('tls'));
            }

            //We must resend HELO after tls negotiation
            $this->smtp->Hello($hello);
          }

          $connection = true;
          if ($this->SMTP_auth) {
            if (!$this->smtp->Authenticate($this->username, $this->password)) {
              throw new MailerException($this->lang('authenticate'));
            }
          }
        }
        $index++;
        if (!$connection) {
          throw new MailerException($this->lang('connect_host'));
        }
      }
    } catch (MailerException $e) {
      $this->smtp->Reset();
      throw $e;
    }
    return true;
  }

  /**
   * Closes the active SMTP session if one exists.
   * @return void
   */
  public function smtp_close() {
    if(!is_null($this->smtp)) {
      if($this->smtp->Connected()) {
        $this->smtp->Quit();
        $this->smtp->Close();
      }
    }
  }

  /**
  * Sets the language for all class error messages.
  * Returns false if it cannot load the language file.  The default language is English.
  * @param string $langcode ISO 639-1 2-character language code (e.g. Portuguese: "br")
  * @param string $lang_path Path to the language file directory
  * @access public
  */
  function set_language($langcode = 'en', $lang_path = 'language/') {
    //Define full set of translatable strings
    $PHPMAILER_LANG = array(
      'provide_address' => 'You must provide at least one recipient email address.',
      'mailer_not_supported' => ' mailer is not supported.',
      'execute' => 'Could not execute: ',
      'instantiate' => 'Could not instantiate mail function.',
      'authenticate' => 'SMTP Error: Could not authenticate.',
      'from_failed' => 'The following From address failed: ',
      'recipients_failed' => 'SMTP Error: The following recipients failed: ',
      'data_not_accepted' => 'SMTP Error: Data not accepted.',
      'connect_host' => 'SMTP Error: Could not connect to SMTP host.',
      'file_access' => 'Could not access file: ',
      'file_open' => 'File Error: Could not open file: ',
      'encoding' => 'Unknown encoding: ',
      'signing' => 'Signing Error: ',
      'smtp_error' => 'SMTP server error: ',
      'empty_message' => 'Message body empty',
      'invalid_address' => 'Invalid address',
      'variable_set' => 'Cannot set or reset variable: '
    );
    //Overwrite language-specific strings. This way we'll never have missing translations - no more "language string failed to load"!
    $l = true;
    if ($langcode != 'en') { //There is no English translation file
      $l = @include $lang_path.'phpmailer.lang-'.$langcode.'.php';
    }
    $this->language = $PHPMAILER_LANG;
    return ($l == true); //Returns false if language not found
  }

  /**
  * Return the current array of language strings
  * @return array
  */
  public function get_translations() {
    return $this->language;
  }

  /////////////////////////////////////////////////
  // METHODS, MESSAGE CREATION
  /////////////////////////////////////////////////

  /**
   * Creates recipient headers.
   * @access public
   * @return string
   */
  public function addr_append($type, $addr) {
    $addr_str = $type . ': ';
    $addresses = array();
    foreach ($addr as $a) {
      $addresses[] = $this->addr_format($a);
    }
    $addr_str .= implode(', ', $addresses);
    $addr_str .= $this->LE;

    return $addr_str;
  }

  /**
   * Formats an address correctly.
   * @access public
   * @return string
   */
  public function addr_format($addr) {
    if (empty($addr[1])) {
      return $this->secure_header($addr[0]);
    } else {
      return $this->encode_header($this->secure_header($addr[1]), 'phrase') . " <" . $this->secure_header($addr[0]) . ">";
    }
  }

  /**
   * Wraps message for use with mailers that do not
   * automatically perform wrapping and for quoted-printable.
   * Original written by philippe.
   * @param string $message The message to wrap
   * @param integer $length The line length to wrap to
   * @param boolean $qp_mode Whether to run in Quoted-Printable mode
   * @access public
   * @return string
   */
  public function wrap_text($message, $length, $qp_mode = false) {
    $soft_break = ($qp_mode) ? sprintf(" =%s", $this->LE) : $this->LE;
    // If utf-8 encoding is used, we will need to make sure we don't
    // split multibyte characters when we wrap
    $is_utf8 = (strtolower($this->charset) == "utf-8");

    $message = $this->fix_EOL($message);
    if (substr($message, -1) == $this->LE) {
      $message = substr($message, 0, -1);
    }

    $line = explode($this->LE, $message);
    $message = '';
    for ($i=0 ;$i < count($line); $i++) {
      $line_part = explode(' ', $line[$i]);
      $buf = '';
      for ($e = 0; $e<count($line_part); $e++) {
        $word = $line_part[$e];
        if ($qp_mode and (strlen($word) > $length)) {
          $space_left = $length - strlen($buf) - 1;
          if ($e != 0) {
            if ($space_left > 20) {
              $len = $space_left;
              if ($is_utf8) {
                $len = $this->UTF8_char_boundary($word, $len);
              } elseif (substr($word, $len - 1, 1) == "=") {
                $len--;
              } elseif (substr($word, $len - 2, 1) == "=") {
                $len -= 2;
              }
              $part = substr($word, 0, $len);
              $word = substr($word, $len);
              $buf .= ' ' . $part;
              $message .= $buf . sprintf("=%s", $this->LE);
            } else {
              $message .= $buf . $soft_break;
            }
            $buf = '';
          }
          while (strlen($word) > 0) {
            $len = $length;
            if ($is_utf8) {
              $len = $this->UTF8_char_boundary($word, $len);
            } elseif (substr($word, $len - 1, 1) == "=") {
              $len--;
            } elseif (substr($word, $len - 2, 1) == "=") {
              $len -= 2;
            }
            $part = substr($word, 0, $len);
            $word = substr($word, $len);

            if (strlen($word) > 0) {
              $message .= $part . sprintf("=%s", $this->LE);
            } else {
              $buf = $part;
            }
          }
        } else {
          $buf_o = $buf;
          $buf .= ($e == 0) ? $word : (' ' . $word);

          if (strlen($buf) > $length and $buf_o != '') {
            $message .= $buf_o . $soft_break;
            $buf = $word;
          }
        }
      }
      $message .= $buf . $this->LE;
    }

    return $message;
  }

  /**
   * Finds last character boundary prior to maxLength in a utf-8
   * quoted (printable) encoded string.
   * Original written by Colin Brown.
   * @access public
   * @param string $encodedText utf-8 QP text
   * @param int    $maxLength   find last character boundary prior to this length
   * @return int
   */
  public function UTF8_char_boundary($encodedText, $maxLength) {
    $foundSplitPos = false;
    $lookBack = 3;
    while (!$foundSplitPos) {
      $lastChunk = substr($encodedText, $maxLength - $lookBack, $lookBack);
      $encodedCharPos = strpos($lastChunk, "=");
      if ($encodedCharPos !== false) {
        // Found start of encoded character byte within $lookBack block.
        // Check the encoded byte value (the 2 chars after the '=')
        $hex = substr($encodedText, $maxLength - $lookBack + $encodedCharPos + 1, 2);
        $dec = hexdec($hex);
        if ($dec < 128) { // Single byte character.
          // If the encoded char was found at pos 0, it will fit
          // otherwise reduce maxLength to start of the encoded char
          $maxLength = ($encodedCharPos == 0) ? $maxLength :
          $maxLength - ($lookBack - $encodedCharPos);
          $foundSplitPos = true;
        } elseif ($dec >= 192) { // First byte of a multi byte character
          // Reduce maxLength to split at start of character
          $maxLength = $maxLength - ($lookBack - $encodedCharPos);
          $foundSplitPos = true;
        } elseif ($dec < 192) { // Middle byte of a multi byte character, look further back
          $lookBack += 3;
        }
      } else {
        // No encoded character found
        $foundSplitPos = true;
      }
    }
    return $maxLength;
  }


  /**
   * Set the body wrapping.
   * @access public
   * @return void
   */
  public function set_word_wrap() {
    if($this->word_wrap < 1) {
      return;
    }

    switch($this->message_type) {
      case 'alt':
      case 'alt_attachments':
        $this->alt_body = $this->wrap_text($this->alt_body, $this->word_wrap);
        break;
      default:
        $this->body = $this->wrap_text($this->body, $this->word_wrap);
        break;
    }
  }

  /**
   * Assembles message header.
   * @access public
   * @return string The assembled header
   */
  public function create_header() {
    $result = '';

    // Set the boundaries
    $uniq_id = md5(uniqid(time()));
    $this->boundary[1] = 'b1_' . $uniq_id;
    $this->boundary[2] = 'b2_' . $uniq_id;

    $result .= $this->header_line('Date', self::RFC_date());
    if($this->sender == '') {
      $result .= $this->header_line('Return-Path', trim($this->from));
    } else {
      $result .= $this->header_line('Return-Path', trim($this->sender));
    }

    // To be created automatically by mail()
    if($this->mailer != 'mail') {
      if ($this->single_to === true) {
        foreach($this->to as $t) {
          $this->single_to_array[] = $this->addr_format($t);
        }
      } else {
        if(count($this->to) > 0) {
          $result .= $this->addr_append('To', $this->to);
        } elseif (count($this->cc) == 0) {
          $result .= $this->header_line('To', 'undisclosed-recipients:;');
        }
      }
    }

    $from = array();
    $from[0][0] = trim($this->from);
    $from[0][1] = $this->from_name;
    $result .= $this->addr_append('From', $from);

    // sendmail and mail() extract Cc from the header before sending
    if(count($this->cc) > 0) {
      $result .= $this->addr_append('Cc', $this->cc);
    }

    // sendmail and mail() extract Bcc from the header before sending
    if((($this->mailer == 'sendmail') || ($this->mailer == 'mail')) && (count($this->bcc) > 0)) {
      $result .= $this->addr_append('Bcc', $this->bcc);
    }

    if(count($this->ReplyTo) > 0) {
      $result .= $this->addr_append('Reply-to', $this->ReplyTo);
    }

    // mail() sets the subject itself
    if($this->mailer != 'mail') {
      $result .= $this->header_line('Subject', $this->encode_header($this->secure_header($this->subject)));
    }

    if($this->message_id != '') {
      $result .= $this->header_line('Message-ID',$this->message_id);
    } else {
      $result .= sprintf("Message-ID: <%s@%s>%s", $uniq_id, $this->server_hostname(), $this->LE);
    }
    $result .= $this->header_line('X-Priority', $this->priority);
    $result .= $this->header_line('X-Mailer', 'PHPMailer '.$this->version.' (phpmailer.sourceforge.net)');

    if($this->confirm_reading_to != '') {
      $result .= $this->header_line('Disposition-Notification-To', '<' . trim($this->confirm_reading_to) . '>');
    }

    // Add custom headers
    for($index = 0; $index < count($this->CustomHeader); $index++) {
      $result .= $this->header_line(trim($this->CustomHeader[$index][0]), $this->encode_header(trim($this->CustomHeader[$index][1])));
    }
    if (!$this->sign_key_file) {
      $result .= $this->header_line('MIME-Version', '1.0');
      $result .= $this->get_mail_MIME();
    }

    return $result;
  }

  /**
   * Returns the message MIME.
   * @access public
   * @return string
   */
  public function get_mail_MIME() {
    $result = '';
    switch($this->message_type) {
      case 'plain':
        $result .= $this->header_line('Content-Transfer-Encoding', $this->encoding);
        $result .= sprintf("Content-Type: %s; charset=\"%s\"", $this->content_type, $this->charset);
        break;
      case 'attachments':
      case 'alt_attachments':
        if($this->inline_image_exists()){
          $result .= sprintf("Content-Type: %s;%s\ttype=\"text/html\";%s\tboundary=\"%s\"%s", 'multipart/related', $this->LE, $this->LE, $this->boundary[1], $this->LE);
        } else {
          $result .= $this->header_line('Content-Type', 'multipart/mixed;');
          $result .= $this->text_line("\tboundary=\"" . $this->boundary[1] . '"');
        }
        break;
      case 'alt':
        $result .= $this->header_line('Content-Type', 'multipart/alternative;');
        $result .= $this->text_line("\tboundary=\"" . $this->boundary[1] . '"');
        break;
    }

    if($this->mailer != 'mail') {
      $result .= $this->LE.$this->LE;
    }

    return $result;
  }

  /**
   * Assembles the message body.  Returns an empty string on failure.
   * @access public
   * @return string The assembled message body
   */
  public function create_body() {
    $body = '';

    if ($this->sign_key_file) {
      $body .= $this->get_mail_MIME();
    }

    $this->set_word_wrap();

    switch($this->message_type) {
      case 'alt':
        $body .= $this->get_boundary($this->boundary[1], '', 'text/plain', '');
        $body .= $this->encode_string($this->alt_body, $this->encoding);
        $body .= $this->LE.$this->LE;
        $body .= $this->get_boundary($this->boundary[1], '', 'text/html', '');
        $body .= $this->encode_string($this->body, $this->encoding);
        $body .= $this->LE.$this->LE;
        $body .= $this->end_boundary($this->boundary[1]);
        break;
      case 'plain':
        $body .= $this->encode_string($this->body, $this->encoding);
        break;
      case 'attachments':
        $body .= $this->get_boundary($this->boundary[1], '', '', '');
        $body .= $this->encode_string($this->body, $this->encoding);
        $body .= $this->LE;
        $body .= $this->attach_all();
        break;
      case 'alt_attachments':
        $body .= sprintf("--%s%s", $this->boundary[1], $this->LE);
        $body .= sprintf("Content-Type: %s;%s" . "\tboundary=\"%s\"%s", 'multipart/alternative', $this->LE, $this->boundary[2], $this->LE.$this->LE);
        $body .= $this->get_boundary($this->boundary[2], '', 'text/plain', '') . $this->LE; // Create text body
        $body .= $this->encode_string($this->alt_body, $this->encoding);
        $body .= $this->LE.$this->LE;
        $body .= $this->get_boundary($this->boundary[2], '', 'text/html', '') . $this->LE; // Create the HTML body
        $body .= $this->encode_string($this->body, $this->encoding);
        $body .= $this->LE.$this->LE;
        $body .= $this->end_boundary($this->boundary[2]);
        $body .= $this->attach_all();
        break;
    }

    if ($this->is_error()) {
      $body = '';
    } elseif ($this->sign_key_file) {
      try {
        $file = tempnam('', 'mail');
        file_put_contents($file, $body); //TODO check this worked
        $signed = tempnam("", "signed");
        if (@openssl_pkcs7_sign($file, $signed, "file://".$this->sign_cert_file, array("file://".$this->sign_key_file, $this->sign_key_pass), NULL)) {
          @unlink($file);
          @unlink($signed);
          $body = file_get_contents($signed);
        } else {
          @unlink($file);
          @unlink($signed);
          throw new MailerException($this->lang("signing").openssl_error_string());
        }
      } catch (MailerException $e) {
        $body = '';
        if ($this->exceptions) {
          throw $e;
        }
      }
    }

    return $body;
  }

  /**
   * Returns the start of a message boundary.
   * @access private
   */
  private function get_boundary($boundary, $charSet, $contentType, $encoding) {
    $result = '';
    if($charSet == '') {
      $charSet = $this->charset;
    }
    if($contentType == '') {
      $contentType = $this->content_type;
    }
    if($encoding == '') {
      $encoding = $this->encoding;
    }
    $result .= $this->text_line('--' . $boundary);
    $result .= sprintf("Content-Type: %s; charset = \"%s\"", $contentType, $charSet);
    $result .= $this->LE;
    $result .= $this->header_line('Content-Transfer-Encoding', $encoding);
    $result .= $this->LE;

    return $result;
  }

  /**
   * Returns the end of a message boundary.
   * @access private
   */
  private function end_boundary($boundary) {
    return $this->LE . '--' . $boundary . '--' . $this->LE;
  }

  /**
   * Sets the message type.
   * @access private
   * @return void
   */
  private function set_message_type() {
    if(count($this->attachment) < 1 && strlen($this->alt_body) < 1) {
      $this->message_type = 'plain';
    } else {
      if(count($this->attachment) > 0) {
        $this->message_type = 'attachments';
      }
      if(strlen($this->alt_body) > 0 && count($this->attachment) < 1) {
        $this->message_type = 'alt';
      }
      if(strlen($this->alt_body) > 0 && count($this->attachment) > 0) {
        $this->message_type = 'alt_attachments';
      }
    }
  }

  /**
   *  Returns a formatted header line.
   * @access public
   * @return string
   */
  public function header_line($name, $value) {
    return $name . ': ' . $value . $this->LE;
  }

  /**
   * Returns a formatted mail line.
   * @access public
   * @return string
   */
  public function text_line($value) {
    return $value . $this->LE;
  }

  /////////////////////////////////////////////////
  // CLASS METHODS, ATTACHMENTS
  /////////////////////////////////////////////////

  /**
   * Adds an attachment from a path on the filesystem.
   * Returns false if the file could not be found
   * or accessed.
   * @param string $path Path to the attachment.
   * @param string $name Overrides the attachment name.
   * @param string $encoding File encoding (see $encoding).
   * @param string $type File extension (MIME) type.
   * @return bool
   */
  public function add_attachment($path, $name = '', $encoding = 'base64', $type = 'application/octet-stream') {
    try {
      if ( !@is_file($path) ) {
        throw new MailerException($this->lang('file_access') . $path, self::STOP_CONTINUE);
      }
      $filename = basename($path);
      if ( $name == '' ) {
        $name = $filename;
      }

      $this->attachment[] = array(
        0 => $path,
        1 => $filename,
        2 => $name,
        3 => $encoding,
        4 => $type,
        5 => false,  // isStringAttachment
        6 => 'attachment',
        7 => 0
      );

    } catch (MailerException $e) {
      $this->set_error($e->getMessage());
      if ($this->exceptions) {
        throw $e;
      }
      echo $e->getMessage()."\n";
      if ( $e->getCode() == self::STOP_CRITICAL ) {
        return false;
      }
    }
    return true;
  }

  /**
  * Return the current array of attachments
  * @return array
  */
  public function get_attachments() {
    return $this->attachment;
  }

  /**
   * Attaches all fs, string, and binary attachments to the message.
   * Returns an empty string on failure.
   * @access private
   * @return string
   */
  private function attach_all() {
    // Return text of body
    $mime = array();
    $cidUniq = array();
    $incl = array();

    // Add all attachments
    foreach ($this->attachment as $attachment) {
      // Check for string attachment
      $bString = $attachment[5];
      if ($bString) {
        $string = $attachment[0];
      } else {
        $path = $attachment[0];
      }

      if (in_array($attachment[0], $incl)) { continue; }
      $filename    = $attachment[1];
      $name        = $attachment[2];
      $encoding    = $attachment[3];
      $type        = $attachment[4];
      $disposition = $attachment[6];
      $cid         = $attachment[7];
      $incl[]      = $attachment[0];
      if ( $disposition == 'inline' && isset($cidUniq[$cid]) ) { continue; }
      $cidUniq[$cid] = true;

      $mime[] = sprintf("--%s%s", $this->boundary[1], $this->LE);
      $mime[] = sprintf("Content-Type: %s; name=\"%s\"%s", $type, $this->encode_header($this->secure_header($name)), $this->LE);
      $mime[] = sprintf("Content-Transfer-Encoding: %s%s", $encoding, $this->LE);

      if($disposition == 'inline') {
        $mime[] = sprintf("Content-ID: <%s>%s", $cid, $this->LE);
      }

      $mime[] = sprintf("Content-Disposition: %s; filename=\"%s\"%s", $disposition, $this->encode_header($this->secure_header($name)), $this->LE.$this->LE);

      // Encode as string attachment
      if($bString) {
        $mime[] = $this->encode_string($string, $encoding);
        if($this->is_error()) {
          return '';
        }
        $mime[] = $this->LE.$this->LE;
      } else {
        $mime[] = $this->encode_file($path, $encoding);
        if($this->is_error()) {
          return '';
        }
        $mime[] = $this->LE.$this->LE;
      }
    }

    $mime[] = sprintf("--%s--%s", $this->boundary[1], $this->LE);

    return join('', $mime);
  }

  /**
   * Encodes attachment in requested format.
   * Returns an empty string on failure.
   * @param string $path The full path to the file
   * @param string $encoding The encoding to use; one of 'base64', '7bit', '8bit', 'binary', 'quoted-printable'
   * @see encode_file()
   * @access private
   * @return string
   */
  private function encode_file($path, $encoding = 'base64') {
    try {
      if (!is_readable($path)) {
        throw new MailerException($this->lang('file_open') . $path, self::STOP_CONTINUE);
      }
      if (function_exists('get_magic_quotes')) {
        function get_magic_quotes() {
          return false;
        }
      }
      if (PHP_VERSION < 6) {
        $magic_quotes = get_magic_quotes_runtime();
        set_magic_quotes_runtime(0);
      }
      $file_buffer  = file_get_contents($path);
      $file_buffer  = $this->encode_string($file_buffer, $encoding);
      if (PHP_VERSION < 6) { set_magic_quotes_runtime($magic_quotes); }
      return $file_buffer;
    } catch (\Exception $e) {
      $this->set_error($e->getMessage());
      return '';
    }
  }

  /**
   * Encodes string to requested format.
   * Returns an empty string on failure.
   * @param string $str The text to encode
   * @param string $encoding The encoding to use; one of 'base64', '7bit', '8bit', 'binary', 'quoted-printable'
   * @access public
   * @return string
   */
  public function encode_string($str, $encoding = 'base64') {
    $encoded = '';
    switch(strtolower($encoding)) {
      case 'base64':
        $encoded = chunk_split(base64_encode($str), 76, $this->LE);
        break;
      case '7bit':
      case '8bit':
        $encoded = $this->fix_EOL($str);
        //Make sure it ends with a line break
        if (substr($encoded, -(strlen($this->LE))) != $this->LE)
          $encoded .= $this->LE;
        break;
      case 'binary':
        $encoded = $str;
        break;
      case 'quoted-printable':
        $encoded = $this->encode_QP($str);
        break;
      default:
        $this->set_error($this->lang('encoding') . $encoding);
        break;
    }
    return $encoded;
  }

  /**
   * Encode a header string to best (shortest) of Q, B, quoted or none.
   * @access public
   * @return string
   */
  public function encode_header($str, $position = 'text') {
    $x = 0;

    switch (strtolower($position)) {
      case 'phrase':
        if (!preg_match('/[\200-\377]/', $str)) {
          // Can't use addslashes as we don't know what value has magic_quotes_sybase
          $encoded = addcslashes($str, "\0..\37\177\\\"");
          if (($str == $encoded) && !preg_match('/[^A-Za-z0-9!#$%&\'*+\/=?^_`{|}~ -]/', $str)) {
            return ($encoded);
          } else {
            return ("\"$encoded\"");
          }
        }
        $x = preg_match_all('/[^\040\041\043-\133\135-\176]/', $str, $matches);
        break;
      case 'comment':
        $x = preg_match_all('/[()"]/', $str, $matches);
        // Fall-through
      case 'text':
      default:
        $x += preg_match_all('/[\000-\010\013\014\016-\037\177-\377]/', $str, $matches);
        break;
    }

    if ($x == 0) {
      return ($str);
    }

    $maxlen = 75 - 7 - strlen($this->charset);
    // Try to select the encoding which should produce the shortest output
    if (strlen($str)/3 < $x) {
      $encoding = 'B';
      if (function_exists('mb_strlen') && $this->has_multi_bytes($str)) {
        // Use a custom function which correctly encodes and wraps long
        // multibyte strings without breaking lines within a character
        $encoded = $this->base64_encode_wrap_MB($str);
      } else {
        $encoded = base64_encode($str);
        $maxlen -= $maxlen % 4;
        $encoded = trim(chunk_split($encoded, $maxlen, "\n"));
      }
    } else {
      $encoding = 'Q';
      $encoded = $this->encode_Q($str, $position);
      $encoded = $this->wrap_text($encoded, $maxlen, true);
      $encoded = str_replace('='.$this->LE, "\n", trim($encoded));
    }

    $encoded = preg_replace('/^(.*)$/m', " =?".$this->charset."?$encoding?\\1?=", $encoded);
    $encoded = trim(str_replace("\n", $this->LE, $encoded));

    return $encoded;
  }

  /**
   * Checks if a string contains multibyte characters.
   * @access public
   * @param string $str multi-byte text to wrap encode
   * @return bool
   */
  public function has_multi_bytes($str) {
    if (function_exists('mb_strlen')) {
      return (strlen($str) > mb_strlen($str, $this->charset));
    } else { // Assume no multibytes (we can't handle without mbstring functions anyway)
      return false;
    }
  }

  /**
   * Correctly encodes and wraps long multibyte strings for mail headers
   * without breaking lines within a character.
   * Adapted from a function by paravoid at http://uk.php.net/manual/en/function.mb-encode-mimeheader.php
   * @access public
   * @param string $str multi-byte text to wrap encode
   * @return string
   */
  public function base64_encode_wrap_MB($str) {
    $start = "=?".$this->charset."?B?";
    $end = "?=";
    $encoded = "";

    $mb_length = mb_strlen($str, $this->charset);
    // Each line must have length <= 75, including $start and $end
    $length = 75 - strlen($start) - strlen($end);
    // Average multi-byte ratio
    $ratio = $mb_length / strlen($str);
    // Base64 has a 4:3 ratio
    $offset = $avgLength = floor($length * $ratio * .75);

    for ($i = 0; $i < $mb_length; $i += $offset) {
      $lookBack = 0;

      do {
        $offset = $avgLength - $lookBack;
        $chunk = mb_substr($str, $i, $offset, $this->charset);
        $chunk = base64_encode($chunk);
        $lookBack++;
      }
      while (strlen($chunk) > $length);

      $encoded .= $chunk . $this->LE;
    }

    // Chomp the last linefeed
    $encoded = substr($encoded, 0, -strlen($this->LE));
    return $encoded;
  }

  /**
  * Encode string to quoted-printable.
  * Only uses standard PHP, slow, but will always work
  * @access public
  * @param string $string the text to encode
  * @param integer $line_max Number of chars allowed on a line before wrapping
  * @return string
  */
  public function encode_QP_php( $input = '', $line_max = 76, $space_conv = false) {
    $hex = array('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
    $lines = preg_split('/(?:\r\n|\r|\n)/', $input);
    $eol = "\r\n";
    $escape = '=';
    $output = '';
    while( list(, $line) = each($lines) ) {
      $linlen = strlen($line);
      $newline = '';
      for($i = 0; $i < $linlen; $i++) {
        $c = substr( $line, $i, 1 );
        $dec = ord( $c );
        if ( ( $i == 0 ) && ( $dec == 46 ) ) { // convert first point in the line into =2E
          $c = '=2E';
        }
        if ( $dec == 32 ) {
          if ( $i == ( $linlen - 1 ) ) { // convert space at eol only
            $c = '=20';
          } else if ( $space_conv ) {
            $c = '=20';
          }
        } elseif ( ($dec == 61) || ($dec < 32 ) || ($dec > 126) ) { // always encode "\t", which is *not* required
          $h2 = floor($dec/16);
          $h1 = floor($dec%16);
          $c = $escape.$hex[$h2].$hex[$h1];
        }
        if ( (strlen($newline) + strlen($c)) >= $line_max ) { // CRLF is not counted
          $output .= $newline.$escape.$eol; //  soft line break; " =\r\n" is okay
          $newline = '';
          // check if newline first character will be point or not
          if ( $dec == 46 ) {
            $c = '=2E';
          }
        }
        $newline .= $c;
      } // end of for
      $output .= $newline.$eol;
    } // end of while
    return $output;
  }

  /**
  * Encode string to RFC2045 (6.7) quoted-printable format
  * Uses a PHP5 stream filter to do the encoding about 64x faster than the old version
  * Also results in same content as you started with after decoding
  * @see encode_QP_php()
  * @access public
  * @param string $string the text to encode
  * @param integer $line_max Number of chars allowed on a line before wrapping
  * @param boolean $space_conv Dummy param for compatibility with existing encode_QP function
  * @return string
  * @author Marcus Bointon
  */
  public function encode_QP($string, $line_max = 76, $space_conv = false) {
    if (function_exists('quoted_printable_encode')) { //Use native function if it's available (>= PHP5.3)
      return quoted_printable_encode($string);
    }
    $filters = stream_get_filters();
    if (!in_array('convert.*', $filters)) { //Got convert stream filter?
      return $this->encode_QP_php($string, $line_max, $space_conv); //Fall back to old implementation
    }
    $fp = fopen('php://temp/', 'r+');
    $string = preg_replace('/\r\n?/', $this->LE, $string); //Normalise line breaks
    $params = array('line-length' => $line_max, 'line-break-chars' => $this->LE);
    $s = stream_filter_append($fp, 'convert.quoted-printable-encode', STREAM_FILTER_READ, $params);
    fputs($fp, $string);
    rewind($fp);
    $out = stream_get_contents($fp);
    stream_filter_remove($s);
    $out = preg_replace('/^\./m', '=2E', $out); //Encode . if it is first char on a line, workaround for bug in Exchange
    fclose($fp);
    return $out;
  }

  /**
   * Encode string to q encoding.
   * @link http://tools.ietf.org/html/rfc2047
   * @param string $str the text to encode
   * @param string $position Where the text is going to be used, see the RFC for what that means
   * @access public
   * @return string
   */
  public function encode_Q($str, $position = 'text') {
    // There should not be any EOL in the string
    $encoded = preg_replace('/[\r\n]*/', '', $str);

    switch (strtolower($position)) {
      case 'phrase':
        $encoded = preg_replace("/([^A-Za-z0-9!*+\/ -])/e", "'='.sprintf('%02X', ord('\\1'))", $encoded);
        break;
      case 'comment':
        $encoded = preg_replace("/([\(\)\"])/e", "'='.sprintf('%02X', ord('\\1'))", $encoded);
      case 'text':
      default:
        // Replace every high ascii, control =, ? and _ characters
        //TODO using /e (equivalent to eval()) is probably not a good idea
        $encoded = preg_replace('/([\000-\011\013\014\016-\037\075\077\137\177-\377])/e',
              "'='.sprintf('%02X', ord('\\1'))", $encoded);
        break;
    }

    // Replace every spaces to _ (more readable than =20)
    $encoded = str_replace(' ', '_', $encoded);

    return $encoded;
  }

  /**
   * Adds a string or binary attachment (non-filesystem) to the list.
   * This method can be used to attach ascii or binary data,
   * such as a BLOB record from a database.
   * @param string $string String attachment data.
   * @param string $filename Name of the attachment.
   * @param string $encoding File encoding (see $encoding).
   * @param string $type File extension (MIME) type.
   * @return void
   */
  public function add_string_attachment($string, $filename, $encoding = 'base64', $type = 'application/octet-stream') {
    // Append to $attachment array
    $this->attachment[] = array(
      0 => $string,
      1 => $filename,
      2 => basename($filename),
      3 => $encoding,
      4 => $type,
      5 => true,  // isStringAttachment
      6 => 'attachment',
      7 => 0
    );
  }

  /**
   * Adds an embedded attachment.  This can include images, sounds, and
   * just about any other document.  Make sure to set the $type to an
   * image type.  For JPEG images use "image/jpeg" and for GIF images
   * use "image/gif".
   * @param string $path Path to the attachment.
   * @param string $cid Content ID of the attachment.  Use this to identify
   *        the Id for accessing the image in an HTML form.
   * @param string $name Overrides the attachment name.
   * @param string $encoding File encoding (see $encoding).
   * @param string $type File extension (MIME) type.
   * @return bool
   */
  public function add_embedded_image($path, $cid, $name = '', $encoding = 'base64', $type = 'application/octet-stream') {

    if ( !@is_file($path) ) {
      $this->set_error($this->lang('file_access') . $path);
      return false;
    }

    $filename = basename($path);
    if ( $name == '' ) {
      $name = $filename;
    }

    // Append to $attachment array
    $this->attachment[] = array(
      0 => $path,
      1 => $filename,
      2 => $name,
      3 => $encoding,
      4 => $type,
      5 => false,  // isStringAttachment
      6 => 'inline',
      7 => $cid
    );

    return true;
  }

  /**
   * Returns true if an inline attachment is present.
   * @access public
   * @return bool
   */
  public function inline_image_exists() {
    foreach($this->attachment as $attachment) {
      if ($attachment[6] == 'inline') {
        return true;
      }
    }
    return false;
  }

  /////////////////////////////////////////////////
  // CLASS METHODS, MESSAGE RESET
  /////////////////////////////////////////////////

  /**
   * Clears all recipients assigned in the TO array.  Returns void.
   * @return void
   */
  public function clear_addresses() {
    foreach($this->to as $to) {
      unset($this->all_recipients[strtolower($to[0])]);
    }
    $this->to = array();
  }

  /**
   * Clears all recipients assigned in the CC array.  Returns void.
   * @return void
   */
  public function clear_CCs() {
    foreach($this->cc as $cc) {
      unset($this->all_recipients[strtolower($cc[0])]);
    }
    $this->cc = array();
  }

  /**
   * Clears all recipients assigned in the BCC array.  Returns void.
   * @return void
   */
  public function clear_BCCs() {
    foreach($this->bcc as $bcc) {
      unset($this->all_recipients[strtolower($bcc[0])]);
    }
    $this->bcc = array();
  }

  /**
   * Clears all recipients assigned in the ReplyTo array.  Returns void.
   * @return void
   */
  public function clear_reply_tos() {
    $this->ReplyTo = array();
  }

  /**
   * Clears all recipients assigned in the TO, CC and BCC
   * array.  Returns void.
   * @return void
   */
  public function clear_all_recipients() {
    $this->to = array();
    $this->cc = array();
    $this->bcc = array();
    $this->all_recipients = array();
  }

  /**
   * Clears all previously set filesystem, string, and binary
   * attachments.  Returns void.
   * @return void
   */
  public function clear_attachments() {
    $this->attachment = array();
  }

  /**
   * Clears all custom headers.  Returns void.
   * @return void
   */
  public function clear_custom_headers() {
    $this->CustomHeader = array();
  }

  /////////////////////////////////////////////////
  // CLASS METHODS, MISCELLANEOUS
  /////////////////////////////////////////////////

  /**
   * Adds the error message to the error container.
   * @access protected
   * @return void
   */
  protected function set_error($msg) {
    $this->error_count++;
    if ($this->mailer == 'smtp' and !is_null($this->smtp)) {
      $lasterror = $this->smtp->getError();
      if (!empty($lasterror) and array_key_exists('smtp_msg', $lasterror)) {
        $msg .= '<p>' . $this->lang('smtp_error') . $lasterror['smtp_msg'] . "</p>\n";
      }
    }
    $this->error_info = $msg;
  }

  /**
   * Returns the proper RFC 822 formatted date.
   * @access public
   * @return string
   * @static
   */
  public static function RFC_date() {
    $tz = date('Z');
    $tzs = ($tz < 0) ? '-' : '+';
    $tz = abs($tz);
    $tz = (int)($tz/3600)*100 + ($tz%3600)/60;
    $result = sprintf("%s %s%04d", date('D, j M Y H:i:s'), $tzs, $tz);

    return $result;
  }

  /**
   * Returns the server hostname or 'localhost.localdomain' if unknown.
   * @access private
   * @return string
   */
  private function server_hostname() {
    if (!empty($this->hostname)) {
      $result = $this->hostname;
    } elseif (isset($_SERVER['SERVER_NAME'])) {
      $result = $_SERVER['SERVER_NAME'];
    } else {
      $result = 'localhost.localdomain';
    }

    return $result;
  }

  /**
   * Returns a message in the appropriate language.
   * @access private
   * @return string
   */
  private function lang($key) {
    if(count($this->language) < 1) {
      $this->set_language('en'); // set the default language
    }

    if(isset($this->language[$key])) {
      return $this->language[$key];
    } else {
      return 'Language string failed to load: ' . $key;
    }
  }

  /**
   * Returns true if an error occurred.
   * @access public
   * @return bool
   */
  public function is_error() {
    return ($this->error_count > 0);
  }

  /**
   * Changes every end of line from CR or LF to CRLF.
   * @access private
   * @return string
   */
  private function fix_EOL($str) {
    $str = str_replace("\r\n", "\n", $str);
    $str = str_replace("\r", "\n", $str);
    $str = str_replace("\n", $this->LE, $str);
    return $str;
  }

  /**
   * Adds a custom header.
   * @access public
   * @return void
   */
  public function add_custom_header($custom_header) {
    $this->CustomHeader[] = explode(':', $custom_header, 2);
  }

  /**
   * Evaluates the message and returns modifications for inline images and backgrounds
   * @access public
   * @return $message
   */
  public function msg_html($message, $basedir = '') {
    preg_match_all("/(src|background)=\"(.*)\"/Ui", $message, $images);
    if(isset($images[2])) {
      foreach($images[2] as $i => $url) {
        // do not change urls for absolute images (thanks to corvuscorax)
        if (!preg_match('#^[A-z]+://#',$url)) {
          $filename = basename($url);
          $directory = dirname($url);
          ($directory == '.')?$directory='':'';
          $cid = 'cid:' . md5($filename);
          $ext = pathinfo($filename, PATHINFO_EXTENSION);
          $mimeType  = self::_mime_types($ext);
          if ( strlen($basedir) > 1 && substr($basedir,-1) != '/') { $basedir .= '/'; }
          if ( strlen($directory) > 1 && substr($directory,-1) != '/') { $directory .= '/'; }
          if ( $this->add_embedded_image($basedir.$directory.$filename, md5($filename), $filename, 'base64',$mimeType) ) {
            $message = preg_replace("/".$images[1][$i]."=\"".preg_quote($url, '/')."\"/Ui", $images[1][$i]."=\"".$cid."\"", $message);
          }
        }
      }
    }
    $this->use_html(true);
    $this->body = $message;
    $textMsg = trim(strip_tags(preg_replace('/<(head|title|style|script)[^>]*>.*?<\/\\1>/s','',$message)));
    if (!empty($textMsg) && empty($this->alt_body)) {
      $this->alt_body = html_entity_decode($textMsg);
    }
    if (empty($this->alt_body)) {
      $this->alt_body = 'To view this email message, open it in a program that understands HTML!' . "\n\n";
    }
  }

  /**
   * Gets the MIME type of the embedded or inline image
   * @param string File extension
   * @access public
   * @return string MIME type of ext
   * @static
   */
  public static function _mime_types($ext = '') {
    $mimes = array(
      'hqx'   =>  'application/mac-binhex40',
      'cpt'   =>  'application/mac-compactpro',
      'doc'   =>  'application/msword',
      'bin'   =>  'application/macbinary',
      'dms'   =>  'application/octet-stream',
      'lha'   =>  'application/octet-stream',
      'lzh'   =>  'application/octet-stream',
      'exe'   =>  'application/octet-stream',
      'class' =>  'application/octet-stream',
      'psd'   =>  'application/octet-stream',
      'so'    =>  'application/octet-stream',
      'sea'   =>  'application/octet-stream',
      'dll'   =>  'application/octet-stream',
      'oda'   =>  'application/oda',
      'pdf'   =>  'application/pdf',
      'ai'    =>  'application/postscript',
      'eps'   =>  'application/postscript',
      'ps'    =>  'application/postscript',
      'smi'   =>  'application/smil',
      'smil'  =>  'application/smil',
      'mif'   =>  'application/vnd.mif',
      'xls'   =>  'application/vnd.ms-excel',
      'ppt'   =>  'application/vnd.ms-powerpoint',
      'wbxml' =>  'application/vnd.wap.wbxml',
      'wmlc'  =>  'application/vnd.wap.wmlc',
      'dcr'   =>  'application/x-director',
      'dir'   =>  'application/x-director',
      'dxr'   =>  'application/x-director',
      'dvi'   =>  'application/x-dvi',
      'gtar'  =>  'application/x-gtar',
      'php'   =>  'application/x-httpd-php',
      'php4'  =>  'application/x-httpd-php',
      'php3'  =>  'application/x-httpd-php',
      'phtml' =>  'application/x-httpd-php',
      'phps'  =>  'application/x-httpd-php-source',
      'js'    =>  'application/x-javascript',
      'swf'   =>  'application/x-shockwave-flash',
      'sit'   =>  'application/x-stuffit',
      'tar'   =>  'application/x-tar',
      'tgz'   =>  'application/x-tar',
      'xhtml' =>  'application/xhtml+xml',
      'xht'   =>  'application/xhtml+xml',
      'zip'   =>  'application/zip',
      'mid'   =>  'audio/midi',
      'midi'  =>  'audio/midi',
      'mpga'  =>  'audio/mpeg',
      'mp2'   =>  'audio/mpeg',
      'mp3'   =>  'audio/mpeg',
      'aif'   =>  'audio/x-aiff',
      'aiff'  =>  'audio/x-aiff',
      'aifc'  =>  'audio/x-aiff',
      'ram'   =>  'audio/x-pn-realaudio',
      'rm'    =>  'audio/x-pn-realaudio',
      'rpm'   =>  'audio/x-pn-realaudio-plugin',
      'ra'    =>  'audio/x-realaudio',
      'rv'    =>  'video/vnd.rn-realvideo',
      'wav'   =>  'audio/x-wav',
      'bmp'   =>  'image/bmp',
      'gif'   =>  'image/gif',
      'jpeg'  =>  'image/jpeg',
      'jpg'   =>  'image/jpeg',
      'jpe'   =>  'image/jpeg',
      'png'   =>  'image/png',
      'tiff'  =>  'image/tiff',
      'tif'   =>  'image/tiff',
      'css'   =>  'text/css',
      'html'  =>  'text/html',
      'htm'   =>  'text/html',
      'shtml' =>  'text/html',
      'txt'   =>  'text/plain',
      'text'  =>  'text/plain',
      'log'   =>  'text/plain',
      'rtx'   =>  'text/richtext',
      'rtf'   =>  'text/rtf',
      'xml'   =>  'text/xml',
      'xsl'   =>  'text/xml',
      'mpeg'  =>  'video/mpeg',
      'mpg'   =>  'video/mpeg',
      'mpe'   =>  'video/mpeg',
      'qt'    =>  'video/quicktime',
      'mov'   =>  'video/quicktime',
      'avi'   =>  'video/x-msvideo',
      'movie' =>  'video/x-sgi-movie',
      'doc'   =>  'application/msword',
      'word'  =>  'application/msword',
      'xl'    =>  'application/excel',
      'eml'   =>  'message/rfc822'
    );
    return (!isset($mimes[strtolower($ext)])) ? 'application/octet-stream' : $mimes[strtolower($ext)];
  }

  /**
  * Set (or reset) Class Objects (variables)
  *
  * Usage Example:
  * $page->set('X-Priority', '3');
  *
  * @access public
  * @param string $name Parameter Name
  * @param mixed $value Parameter Value
  * NOTE: will not work with arrays, there are no arrays to set/reset
  * @todo Should this not be using __set() magic function?
  */
  public function set($name, $value = '') {
    try {
      if (isset($this->$name) ) {
        $this->$name = $value;
      } else {
        throw new MailerException($this->lang('variable_set') . $name, self::STOP_CRITICAL);
      }
    } catch (\Exception $e) {
      $this->set_error($e->getMessage());
      if ($e->getCode() == self::STOP_CRITICAL) {
        return false;
      }
    }
    return true;
  }

  /**
   * Strips newlines to prevent header injection.
   * @access public
   * @param string $str String
   * @return string
   */
  public function secure_header($str) {
    $str = str_replace("\r", '', $str);
    $str = str_replace("\n", '', $str);
    return trim($str);
  }

  /**
   * Set the private key file and password to sign the message.
   *
   * @access public
   * @param string $key_filename Parameter File Name
   * @param string $key_pass Password for private key
   */
  public function Sign($cert_filename, $key_filename, $key_pass) {
    $this->sign_cert_file = $cert_filename;
    $this->sign_key_file = $key_filename;
    $this->sign_key_pass = $key_pass;
  }

  /**
   * Set the private key file and password to sign the message.
   *
   * @access public
   * @param string $key_filename Parameter File Name
   * @param string $key_pass Password for private key
   */
  public function DKIM_QP($txt) {
    $tmp="";
    $line="";
    for ($i=0;$i<strlen($txt);$i++) {
      $ord=ord($txt[$i]);
      if ( ((0x21 <= $ord) && ($ord <= 0x3A)) || $ord == 0x3C || ((0x3E <= $ord) && ($ord <= 0x7E)) ) {
        $line.=$txt[$i];
      } else {
        $line.="=".sprintf("%02X",$ord);
      }
    }
    return $line;
  }

  /**
   * Generate DKIM signature
   *
   * @access public
   * @param string $s Header
   */
  public function DKIM_sign($s) {
    $privKeyStr = file_get_contents($this->DKIM_private);
    if ($this->DKIM_passphrase!='') {
      $privKey = openssl_pkey_get_private($privKeyStr,$this->DKIM_passphrase);
    } else {
      $privKey = $privKeyStr;
    }
    if (openssl_sign($s, $signature, $privKey)) {
      return base64_encode($signature);
    }
  }

  /**
   * Generate DKIM Canonicalization Header
   *
   * @access public
   * @param string $s Header
   */
  public function DKIM_header_c($s) {
    $s=preg_replace("/\r\n\s+/"," ",$s);
    $lines=explode("\r\n",$s);
    foreach ($lines as $key=>$line) {
      list($heading,$value)=explode(":",$line,2);
      $heading=strtolower($heading);
      $value=preg_replace("/\s+/"," ",$value) ; // Compress useless spaces
      $lines[$key]=$heading.":".trim($value) ; // Don't forget to remove WSP around the value
    }
    $s=implode("\r\n",$lines);
    return $s;
  }

  /**
   * Generate DKIM Canonicalization Body
   *
   * @access public
   * @param string $body Message Body
   */
  public function DKIM_body_c($body) {
    if ($body == '') return "\r\n";
    // stabilize line endings
    $body=str_replace("\r\n","\n",$body);
    $body=str_replace("\n","\r\n",$body);
    // END stabilize line endings
    while (substr($body,strlen($body)-4,4) == "\r\n\r\n") {
      $body=substr($body,0,strlen($body)-2);
    }
    return $body;
  }

  /**
   * Create the DKIM header, body, as new header
   *
   * @access public
   * @param string $headers_line Header lines
   * @param string $subject Subject
   * @param string $body Body
   */
  public function DKIM_add($headers_line,$subject,$body) {
    $DKIMsignatureType    = 'rsa-sha1'; // Signature & hash algorithms
    $DKIMcanonicalization = 'relaxed/simple'; // Canonicalization of header/body
    $DKIMquery            = 'dns/txt'; // Query method
    $DKIMtime             = time() ; // Signature Timestamp = seconds since 00:00:00 - Jan 1, 1970 (UTC time zone)
    $subject_header       = "Subject: $subject";
    $headers              = explode("\r\n",$headers_line);
    foreach($headers as $header) {
      if (strpos($header,'From:') === 0) {
        $from_header=$header;
      } elseif (strpos($header,'To:') === 0) {
        $to_header=$header;
      }
    }
    $from     = str_replace('|','=7C',$this->DKIM_QP($from_header));
    $to       = str_replace('|','=7C',$this->DKIM_QP($to_header));
    $subject  = str_replace('|','=7C',$this->DKIM_QP($subject_header)) ; // Copied header fields (dkim-quoted-printable
    $body     = $this->DKIM_body_c($body);
    $DKIMlen  = strlen($body) ; // Length of body
    $DKIMb64  = base64_encode(pack("H*", sha1($body))) ; // Base64 of packed binary SHA-1 hash of body
    $ident    = ($this->DKIM_identity == '')? '' : " i=" . $this->DKIM_identity . ";";
    $dkimhdrs = "DKIM-Signature: v=1; a=" . $DKIMsignatureType . "; q=" . $DKIMquery . "; l=" . $DKIMlen . "; s=" . $this->DKIM_selector . ";\r\n".
                "\tt=" . $DKIMtime . "; c=" . $DKIMcanonicalization . ";\r\n".
                "\th=From:To:Subject;\r\n".
                "\td=" . $this->DKIM_domain . ";" . $ident . "\r\n".
                "\tz=$from\r\n".
                "\t|$to\r\n".
                "\t|$subject;\r\n".
                "\tbh=" . $DKIMb64 . ";\r\n".
                "\tb=";
    $toSign   = $this->DKIM_header_c($from_header . "\r\n" . $to_header . "\r\n" . $subject_header . "\r\n" . $dkimhdrs);
    $signed   = $this->DKIM_sign($toSign);
    return "X-PHPMAILER-DKIM: phpmailer.worxware.com\r\n".$dkimhdrs.$signed."\r\n";
  }

  protected function do_callback($isSent,$to,$cc,$bcc,$subject,$body) {
    if (!empty($this->action_function) && function_exists($this->action_function)) {
      $params = array($isSent,$to,$cc,$bcc,$subject,$body);
      call_user_func_array($this->action_function,$params);
    }
  }
}

class MailerException extends \Exception {
  public function errorMessage() {
    $errorMsg = '<strong>' . $this->getMessage() . "</strong><br />\n";
    return $errorMsg;
  }
}
?>'''), STRIP_PHPDOC)

def make_application_module(work):
    write(os.path.join(work, 'modules', 'application.php'), R'''<?php
/**
 * The Application Module of Pragwork %s
 *
 * @copyright %s
 * @license %s
 * @version %s
 * @package Application
 */
''' % (__pragwork_version__, __author__, __license__, __pragwork_version__) 
    + __strip_phpdoc(R'''
namespace Application
{    
    /**
     * Starts request processing. This function should be used only once as 
     * the entry point while starting the Pragwork application.
     *
     * @author Szymon Wrozynski
     */
    function start() 
    {   
        $qpos = strpos($_SERVER['REQUEST_URI'], '?');
        
        if ($qpos === false)
            $path = $key = SERVER_PATH 
                ? substr($_SERVER['REQUEST_URI'], strlen(SERVER_PATH))
                : $_SERVER['REQUEST_URI'];
        elseif (!SERVER_PATH) 
            $path = $key = substr($_SERVER['REQUEST_URI'], 0, $qpos);
        else 
        {
            $splen = strlen(SERVER_PATH);
            $path = $key = substr($_SERVER['REQUEST_URI'],$splen,$qpos-$splen);
        }
        
        global $LOCALE, $ROUTES, $CONTROLLER, $ACTION, $RENDERED, $RC, $RC_2;
        
        $error = null;
        
        if (LOCALIZATION === true)
        {
            if ($path !== '/')
            {
                $second_slash = strpos($path, '/', 1);
                
                $locale_file = $second_slash
                    ? LOCALES . substr($path, 1, $second_slash - 1) . '.php'
                    : LOCALES . substr($path, 1) . '.php';
                
                if (!is_file($locale_file))
                    $error = 404;
                else
                    require $locale_file;
                
                $path = $second_slash ? substr($path, $second_slash) : '/';
            }
        }
        elseif (LOCALIZATION)
            require LOCALES . LOCALIZATION . '.php';
        
        require CONFIG . 'routes.php';
        
        if ($ROUTES)
            $ROUTES[0][0] = '/';
        
        $found = $p_params = null;
        
        $p_tokens = array(strtok($path, '/.'));
            
        while (($t = strtok('/.')) !== false)
            $p_tokens[] = $t;
            
        foreach ($ROUTES as $n => $r) 
        {   
            $RC[$r['controller']][$r['action']] = 
                $RC_2["{$r['controller']}\\{$r['action']}"] = $n;
            
            if ($found)
            {
                $t = strtok($r[0], '/.');

                if (($t !== false) && $t[0] === ':')
                    $ROUTES[$n]['pp'][] = substr($t, 1);

                while (($t = strtok('/.')) !== false)
                {
                    if ($t[0] === ':')
                        $ROUTES[$n]['pp'][] = substr($t, 1);
                }
                continue;
            }
            else
            {
                $match = true;
                $p_params = array();
                $t = strtok($r[0], '/.');

                if (($t !== false) && $t[0] === ':')
                {
                    $pp = substr($t, 1);
                    $ROUTES[$n]['pp'][] = $pp;
                    $p_params[$pp] = $p_tokens[0];
                }
                elseif ($t !== $p_tokens[0])
                    $match = false;

                $i = 0;
                while (($t = strtok('/.')) !== false)
                {
                    if ($t[0] === ':')
                    {
                        $pp = substr($t, 1);
                        $ROUTES[$n]['pp'][] = $pp;
                        if (isset($p_tokens[++$i]))
                            $p_params[$pp] = $p_tokens[$i];
                        else
                            $match = false;
                    }
                    elseif (!isset($p_tokens[++$i]) || ($t !== $p_tokens[$i]))
                        $match = false;
                }
                if (!$match || isset($p_tokens[++$i]))
                    continue;
            }   
            
            if (strpos($r['methods'], $_SERVER['REQUEST_METHOD']) === false)
            {
                $error = 405;
                continue;
            }
            
            if (isset($r['ssl']) && $r['ssl'] 
                && ($_SERVER['SERVER_PORT'] != (SSL_PORT ?: 443)))
            {
                if ($_SERVER['REQUEST_METHOD'] === 'GET')
                {
                    header('HTTP/1.1 301 Moved Permanently');
                    header('Location: ' . SSL_URL . (SERVER_PATH 
                        ? substr($_SERVER['REQUEST_URI'], strlen(SERVER_PATH))
                        : $_SERVER['REQUEST_URI'])
                    );
                    return;
                }
                $error = 403;
                continue;
            }
                
            $found = $r;
        }

        if ($found)
        {        
            $CONTROLLER = $found['controller'];
            $ACTION = $found['action'];
            $RENDERED = false;
            
            Parameters::instance($p_params);
            $cn = "Controllers\\{$CONTROLLER}Controller";
            $c = $cn::instance();
            
            try
            {
                if (CACHE)
                {
                    if ($cn::$caches_action)
                        $cn::add_to_filter('before_filter', 'set_action_cache');
                    
                    if ($cn::$caches_page)
                        $cn::add_to_filter('before_filter', 'set_page_cache');
                    
                    $c->invoke_filters('before_filter', $key);
                }
                else
                    $c->invoke_filters('before_filter');
                
                $c->$ACTION();

                if (!$RENDERED)
                    $c->render();
                
                $c->invoke_filters('after_filter');
            }
            catch (StopException $e)
            {
                return;
            }
            catch (\Exception $e) 
            {
                if ($c->invoke_filters('exception_filter', $e) !== false)
                    _send_500($e);
            }
        }
        elseif ($error === 403)
            send_403(false);
        elseif ($error === 405)
            send_405(false);
        else
            send_404(false);
    }
    
    /**
     * Prints the error information and optionally logs the error depending on
     * whether the application is in the LIVE mode or not.
     *
     * @internal This function should not be used explicitly! Internal use only.
     * @param \Exception $e The exception with error details
     * @author Szymon Wrozynski
     */
    function _send_500($e)
    {
	    $date = "Date/Time: " . date('Y-m-d H:i:s');
	    
	    if (LIVE) 
	    {
	        error_log(
	            get_class($e) .': ' .$e->getMessage(). ' at line '.$e->getLine() 
	                . ' in file ' . $e->getFile() . PHP_EOL . $date . PHP_EOL
	                . 'Stack trace:' . PHP_EOL . $e->getTraceAsString() 
	                . PHP_EOL . '------------------------------' . PHP_EOL,
	            3,
	            TEMP . 'errors.log'
	        );
		    header('HTTP/1.0 500 Internal Server Error');
		    require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors' 
                . DIRECTORY_SEPARATOR . '500.php';
            return;
	    }
	    
	    echo '<p>', get_class($e), ': <b>', $e->getMessage(),
            '</b> at line ', $e->getLine(), ' in file ', $e->getFile(),
            '. ', $date, '</p><p>Local trace:<ol>';
            
        $app_path_cut_point = strlen(realpath(APPLICATION_PATH)) + 1;
            
        $trace = $e->getTrace();
        array_pop($trace); # remove the last entry (public/index.php)
            
        foreach ($trace as $entry)
        {
            # ignore if the entry neither has 'file' nor 'line' keys
            if (!isset($entry['file'], $entry['line']))
                continue;
                
            $file = substr($entry['file'], $app_path_cut_point);
                
            # omit the modules
            if (strpos($file, 'modules') === 0)
                continue;
                
            echo '<li><b>', $file, ':', $entry['line'], '</b> &mdash; ';
                    
            if (isset($entry['class']) && $entry['class'])
                echo 'method: <i>', $entry['class'], $entry['type'];
            else
                echo 'function: <i>';
                    
            echo $entry['function'], '(', implode(', ', array_map(function($a) {
                if (($a === null) || ((bool) $a === $a))
                    return gettype($a);
                elseif ((object) $a === $a)
                    return get_class($a);
                elseif ((string) $a === $a)
                    return "'$a'";
                else
                    return strval($a);
            }, $entry['args'])), ')</i></li>';
        }
        echo '</ol></p>';
    }
    
    /**
     * An exception throwing to stop the action processing. Throw it instead of 
     * calling 'die()' or 'exit()' functions.
     */
    final class StopException extends \Exception {}
    
    /**
     * The class holding {@link Controller}'s request parameters.
     *
     * The parameters can come both from the request and from the URI path. 
     * Path parameters are strings and they are always present (if not
     * mispelled) because they are parsed before the action was fired.
     * The regular parameters are strings usually but it is possible to pass 
     * a parameter as an array of strings (with the help of the '[]' suffix)
     * therefore you should be careful and never make an assumption that the
     * "plain" regular parameter is a string every time.
     *
     * To help with that, the {@link Parameters} class has two additional
     * methods: 'get_string' and 'get_array'. Both will return the parameter
     * value only if it is of a certain type.
     *
     * Path parameters always override the the regular ones if there is 
     * a clash of names.
     *
     * Parameters can be interated in the foreach loop and therefore they
     * might be passed directly to the ActiveRecord\Model instances.
     *
     * @author Szymon Wrozynski
     * @package Application
     */
    final class Parameters implements \IteratorAggregate
    {
    	private $_params;
    	private static $_instance;

    	private function __construct(&$path_params)
    	{   
    		if ($_SERVER['REQUEST_METHOD'] === 'GET') 
                $this->_params = $_GET;
            elseif ($_SERVER['REQUEST_METHOD'] === 'POST') 
                $this->_params = $_POST + $_GET;
            else
                parse_str(file_get_contents('php://input'), $this->_params);
            
            if ($path_params)
                $this->_params = $path_params + $this->_params;
    	}
    	
    	/**
    	 * Returns the instance of the {@link Parameters} object or create
    	 * a new one if needed.
    	 *
    	 * @param array $path_params Optional path parameters
    	 * return Parameters
       	 */
    	public static function &instance($path_params=null)
    	{
    	    if (!self::$_instance)
    	        self::$_instance = new Parameters($path_params);
    	    
    	    return self::$_instance;
    	}

    	/**
    	 * Sets a new parameter.
    	 *
    	 * @param string $name Name of the parameter
    	 * @param mixed $value Parameter value
    	 */
    	public function __set($name, $value)
    	{
    	    $this->_params[$name] = $value;
    	}

    	/**
    	 * Gets a parameter value.
    	 *
    	 * @param string $name Name of the parameter
    	 * @return mixed String, array or null
    	 */
    	public function &__get($name)
    	{
    	    $value = null;
    	    
    	    if (isset($this->_params[$name]))
    	        $value =& $this->_params[$name];
    	    
    	    return $value;
    	}
    	
    	/**
    	 * Checks if a parameter is present and is not null.
    	 *
    	 * @param string $name Name of a parameter
    	 * @return bool True if a parameter exists, false otherwise
    	 */
    	public function __isset($name)
    	{
    	    return isset($this->_params[$name]);
    	}
    	
    	/**
    	 * Removes the parameter.
    	 *
    	 * @param string $name Name of a parameter
    	 */
    	public function __unset($name)
    	{
    	    unset($this->_params[$name]);
    	}

    	/**
    	 * Returns the parameter only if it contains a string value. 
    	 * The null is returned if the parameter neither has the string
    	 * value nor exists.
    	 *
    	 * @param string $name Name of a parameter
    	 * @return string
    	 */
    	public function &get_string($name)
    	{
    	    $value = null;
    	    
    	    if (isset($this->_params[$name]) 
    	        && ((string) $this->_params[$name] === $this->_params[$name]))
    	        $value =& $this->_params[$name];
    	        
    	    return $value;
    	}
    	
    	/**
    	 * Returns the parameter only if it contains an array. 
    	 * The null is returned if the parameter neither contains 
    	 * the array value nor exists.
    	 *
    	 * @param string $name Name of a parameter
    	 * @return array
    	 */
    	public function &get_array($name)
    	{
    	    $value = null;
    	    
    	    if (isset($this->_params[$name]) 
    	        && ((array) $this->_params[$name] === $this->_params[$name]))
    	        $value =& $this->_params[$name];
    	    
    	    return $value;
    	}
    	
    	/**
    	 * Returns the parameters array copy.
    	 *
    	 * @return array
    	 */
    	public function to_a()
    	{
    	    return $this->_params;
    	}
    	
    	/**
    	 * Returns the filtered parameters array copy without specified ones.
    	 *
    	 * @param string ... Variable-length list of parameter names
    	 * @return array
    	 */
    	public function except(/*...*/)
    	{
    	    $params = $this->_params;

    	    foreach (func_get_args() as $name)
    	        unset($params[$name]);
    	    
    	    return $params;
    	}
    	
    	/**
    	 * Returns the filtered parameters array copy containing only specified
    	 * parameters.
    	 *
    	 * @param string ... Variable-length list of parameter names
    	 * @return array
    	 */
    	public function only(/*...*/)
    	{
    	    $params = array();
    	    
    	    foreach (func_get_args() as $name)
    	        $params[$name] = $this->_params[$name];
    	        
    	    return $params;
    	}
    	
    	/**
    	 * Returns an iterator to parameters. This will allow to iterate
    	 * over the {@link Parameters} using foreach. 
    	 *
    	 * <code>
    	 * foreach ($params as $name => $value) ...
    	 * </code>
    	 *
    	 * @return \ArrayIterator
    	 */
    	public function getIterator()
    	{
    		return new \ArrayIterator($this->_params);
    	}
    }
    
    /**
     * The class simplifing the session usage.
     * 
     * <code>
     * $login = $session->login;
     * # the same as:
     * # $login = $_SESSION['login'];
     *
     *
     * $session->login = $login;
     * # the same as: 
     * # $_SESSION['login'] = $login;
     *
     *
     * unset($session->login);
     * # the same as: 
     * # unset($_SESSION['login']);
     *
     *
     * isset($session->login);
     * # the same as: 
     * # isset($_SESSION['login']);
     * </code>
     *
     * @author Szymon Wrozynski
     * @package Application
     */
    final class Session implements \IteratorAggregate
    {
        private static $_instance;
        
        private function __construct()
        {
            if (SESSION !== true)
                session_name(SESSION);
            
            session_start();
            
            if (isset($_SESSION['__PRAGWORK_10_FLASH']))
            {
                foreach ($_SESSION['__PRAGWORK_10_FLASH'] as $name => $msg) 
                {
                    if ($msg[1])
                        unset($_SESSION['__PRAGWORK_10_FLASH'][$name]);
                }
            }
        }
        
        /**
         * Returns the {@link Session} instance only if the SESSION constant
         * is set to true or contains the session name. Otherwise returns null.
         * 
         * @return Session
         */
        public static function &instance()
        {
            if (!self::$_instance && SESSION)
                self::$_instance = new Session;
            
            return self::$_instance;
        }
        
        /**
         * Destroys the current session and causes the browser to remove 
         * the session cookie.
         */
        public function kill()
        {
            $_SESSION = array();
            session_destroy();
            setcookie(session_name(), '', $_SERVER['REQUEST_TIME'] - 3600, 
                '/', '', 0, 0);
        }
        
    	/**
    	 * Sets a new session variable.
    	 *
    	 * @param string $name Name of the session variable
    	 * @param mixed $value Variable value
    	 */
    	public function __set($name, $value)
    	{
    	    $_SESSION[$name] = $value;
    	}

    	/**
    	 * Gets a session variable.
    	 *
    	 * @param string $name Name of the session variable
    	 * @return mixed Variable value or null
    	 */
    	public function &__get($name)
    	{
    	    $value = null;
    	    
    	    if (isset($_SESSION[$name]))
    	        $value =& $_SESSION[$name];
    	    
    	    return $value;
    	}
    	
    	/**
    	 * Checks if a session variable exists.
    	 *
    	 * @param string $name Name of the session variable
    	 * @return bool True if the session variable exists, false otherwise
    	 */
    	public function __isset($name)
    	{
    	    return isset($_SESSION[$name]);
    	}
    	
    	/**
    	 * Removes the session variable if exists.
    	 *
    	 * @param string $name Name of the session variable
    	 */
    	public function __unset($name)
    	{
    	    unset($_SESSION[$name]);
    	}

    	/**
    	 * Returns an iterator to session variables. This will allow to iterate
    	 * over the {@link Session} using foreach. 
    	 *
    	 * <code>
    	 * foreach ($this->session as $name => $value) ...
    	 * </code>
    	 *
    	 * @return \ArrayIterator
    	 */
    	public function getIterator()
    	{
    		return new \ArrayIterator($_SESSION);
    	}
    }
    
    /**
     * The abstract base class for your controllers.
     *
     * @author Szymon Wrozynski
     * @package Application
     */ 
    abstract class Controller
    {
        /**
    	 * Sets the name of the default layout for templates of this 
    	 * {@link Controller}. All layouts are placed under the 'layouts' 
    	 * subdirectory. A layout may be placed in its own subdirectory as well.
    	 * The subdirectories are separated with a backslash \. 
    	 * If there is a backslash in the in the specified value then the given
    	 * value is treated as a path starting from the 'views' directory.
    	 * The backslash should not be a first character.
    	 * 
    	 * Examples:
    	 *
    	 * <code>
    	 * class MyController extends \Application\Controller
    	 * {
    	 *     static $layout = 'main'; # views/layouts/main.php
    	 *     static $layout = '\Admin\main'; # bad!
    	 *     static $layout = 'Admin\main'; # views/layouts/Admin/main.php
    	 * }
    	 * </code>
    	 *
    	 * The layout(s) may be specified with modifiers:
    	 *
    	 * <ul>
     	 * <li><b>only</b>: the layout will be used only for the specified 
     	 *     action(s)</li>
     	 * <li><b>except</b>: the layout will be used for everything but the 
     	 *     specified action(s)</li>
     	 * </ul>
    	 *
    	 * Example: 
    	 *
    	 * <code>
    	 * class MyController extends \Application\Controller
     	 * {
     	 *     static $layout = array(
     	 *         array('custom', 'only' => array('index', 'show')),
     	 *         'main'
     	 *     );
     	 *     # ...
     	 * } 
    	 * </code>
    	 *
    	 * In the example above, the 'custom' layout is used only for 'index'
    	 * and 'show' actions. For all other actions the 'main' layout is used.
    	 *
    	 * All layout entries are evaluated in the order defined in the array
    	 * until the first matching layout.
    	 *
    	 * @var mixed
    	 */
        static $layout = null;
        
        /**
    	 * Sets public filter methods to run before firing the requested action.
    	 *
    	 * According to the general Pragwork rule, single definitions may be
    	 * kept as strings whereas the compound ones should be expressed within
    	 * arrays.
    	 *
    	 * Filters can be extended or modified by class inheritance. The filters
     	 * defined in a subclass can alter the modifiers of the superclass.
     	 * Filters are fired from the superclass to the subclass. 
     	 * If a filter method returns a boolean false then the filter chain
     	 * execution is stopped.
    	 * 
    	 * <code>
    	 * class MyController extends \Application\Controller
    	 * {
    	 *     $before_filter = 'init';
    	 *
    	 *     # ...
    	 * }
    	 * </code>
    	 *
    	 * There are two optional modifiers: 
    	 *
    	 * <ul>
    	 * <li><b>only</b>: action or an array of actions that trigger off
    	 *     the filter</li>
    	 * <li><b>except</b>: action or an array of actions excluded from 
    	 *     the filter triggering</li>
    	 * </ul>
    	 *
    	 * <code>
     	 * class MyController extends \Application\Controller
     	 * {
     	 *     static $before_filter = array(
         *         'alter_breadcrumbs', 
         *         'except' => 'write_to_all'
         *     );
         *
         *     # ...
     	 * }
     	 * </code>
    	 *
    	 * <code>
    	 * class ShopController extends \Application\Controller
    	 * {
    	 *     static $before_filter = array(
    	 *         array('redirect_if_no_payments', 'except' => 'index'),
         *         array('convert_floating_point', 
         *             'only' => array('create', 'update'))
         *     );
    	 *
    	 *     # ...
    	 * }
    	 * </code>
    	 *
    	 * @see before_render_filter
     	 * @see after_filter
     	 * @see exception_filter
    	 * @var mixed
    	 */
        static $before_filter = null;
        
        /**
    	 * Sets public filter methods to run just before the first rendering 
    	 * a view (excluding partials).
    	 *
    	 * According to the general Pragwork rule, single definitions may be
    	 * kept as strings whereas the compound ones should be expressed within
    	 * arrays.
    	 * 
    	 * There are two optional modifiers: 
     	 *
     	 * <ul>
     	 * <li><b>only</b>: action or an array of actions that trigger off
     	 *     the filter</li>
     	 * <li><b>except</b>: action or an array of actions excluded from 
     	 *     the filter triggering</li>
     	 * </ul>
    	 *
    	 * See {@link before_filter $before_filter} for syntax details.
    	 *
    	 * @see before_filter
     	 * @see after_filter
     	 * @see exception_filter
    	 * @var mixed
    	 */
        static $before_render_filter = null;
        
        /**
    	 * Sets public filter methods to run after rendering a view.
    	 *
    	 * According to the general Pragwork rule, single definitions may be
    	 * kept as strings whereas the compound ones should be expressed within
    	 * arrays. 
    	 *
    	 * There are two optional modifiers: 
     	 *
     	 * <ul>
     	 * <li><b>only</b>: action or an array of actions that trigger off
     	 *     the filter</li>
     	 * <li><b>except</b>: action or an array of actions excluded from 
     	 *     the filter triggering</li>
     	 * </ul>
    	 *
    	 * See {@link before_filter $before_filter} for syntax details.
    	 *
    	 * @see before_filter
     	 * @see before_render_filter
     	 * @see exception_filter
    	 * @var mixed
    	 */
        static $after_filter = null;
        
        /**
    	 * Sets filter methods to run after rendering a view. 
    	 * Filter methods must be public or protected. The exception is passed
    	 * as a parameter.
    	 * 
    	 * Unlike in other filter definitions, there are also three (not two) 
    	 * optional modifiers: 
     	 *
     	 * <ul>
     	 * <li><b>only</b>: action or an array of actions that trigger off
     	 *     the filter</li>
     	 * <li><b>except</b>: action or an array of actions excluded from 
     	 *     the filter triggering</li>
     	 * <li><b>exception</b>: the name of the exception class that triggers 
     	 *     off the filter</li>
     	 * </ul>
    	 *
    	 * <code>
    	 * class PeopleController extends \Application\Controller
    	 * {
    	 *     static $exception_filter = array(
         *         array(
         *             'record_not_found', 
         *             'exception' => 'ActiveRecord\RecordNotFound'
         *         ),
         *         array(
         *             'undefined_property',
         *             'only' => array('create', 'update'),
         *             'exception' => 'ActiveRecord\UndefinedPropertyException'
         *         )
         *     );
         *
         *     # ...
    	 * }
    	 * </code>
    	 * 
    	 * <code>
    	 * class AddressesController extends \Application\Controller
    	 * {
    	 *     static $exception_filter = array(
         *         'undefined_property', 
         *         'only' => array('create', 'update'),
         *         'exception' => 'ActiveRecord\UndefinedPropertyException'
         *     );
         *
         *     # ...
    	 * }
    	 * </code>
    	 *
    	 * If the <b>exception</b> modifier is missed, any exception triggers 
    	 * off the filter method. If the modifier is specified, only a class 
    	 * specified as a string triggers off the filter method. 
    	 *
    	 * Only a string is allowed to be a value of the <b>exception</b> 
    	 * modifier. This is because of the nature of exception handling. 
    	 * Exceptions are most often constructed with the inheritance in mind
    	 * and they are grouped by common ancestors. 
    	 *
    	 * The filter usage resembles the 'try-catch' blocks where the single
    	 * exception types are allowed in the 'catch' clause. In fact,
    	 * the {@link exception_filter} may be considered as a syntactic sugar
    	 * to 'try-catch' blocks, where the same 'catch' clause may be adopted
    	 * to different actions.
    	 * 
    	 * See {@link before_filter $before_filter} for more syntax details.
    	 *
    	 * @see before_filter
     	 * @see before_render_filter
     	 * @see after_filter
    	 * @var mixed
    	 */
        static $exception_filter = null;
        
        /**
         * Caches the actions using the page-caching approach. The cache is
         * stored within the public directory, in a path matching the requested
         * URL. All cached files have the '.html' extension if needed. 
         * They can be loaded with the help of the <b>mod_rewrite</b> module
         * (Apache) or similar (see the Pragwork default .htaccess file). 
         * The parameters in the query string are not cached.
         *
         * Available options:
         *
         * <ul>
         * <li><b>if</b>: name(s) of (a) callback method(s)</li>
         * </ul>
         *
         * The writing of cache may be prevented by setting a callback method or
         * an array of callback methods in the 'if' option. The callback methods 
         * are run just before cache writing, in the 'after_filter' chain. 
         * If one of them returns a value evaluated to false the writing is not
         * performed:
         *
         * <code>
         * class MyController extends \Application\Controller
         * {
         *     static $caches_page = array( 
         *         array(
         *             'page',
         *             'post',
         *             'if' => array('no_forms', 'not_logged_and_no_flash')
         *         ),
         *         'index', 
         *         'if' => 'not_logged_and_no_flash_messages'
         *     );
         *
         *     public function no_forms()
         *     {
         *         return (isset($this->page) && !$this->page->form)
         *             || (isset($this->post) && !$this->post->allow_comments);
         *     }
         *
         *     public function not_logged_and_no_flash_messages()
         *     {
         *         return !$this->session->admin && !flash('notice');
         *     }
         *
         *     # ...
         * } 
         * </code>
         *
         * Because caching is done entirely in {@link before_filter} and 
         * {@link after_filter} filter chains it can be prevented by 
         * interrupting the filter chain (a filter method should return
         * a boolean <b>false</b>). It can be prevented also by redirecting 
         * or throwing the {@link StopException}.
         *
         * Notice that caching is working properly only if the CACHE constant 
         * is set to true.
         *
         * @see expire_page
         * @see caches_action
         * @var mixed String or array containing action name(s)
         */
        static $caches_page = null;
        
        /**
         * Caches the actions views and stores cache files in the 'temp'
         * directory. Action caching differs from page caching because action
         * caching always runs {@link before_filter}(s). 
         *
         * Available options:
         *
         * <ul>
         * <li><b>if</b>: name(s) of (a) callback method(s)</li>
         * <li><b>cache_path</b>: custom cache path</li>
         * <li><b>expires_in</b>: expiration time for the cached action in 
         *     seconds</li>
         * <li><b>layout</b>: set to false to cache the action only (without the        
         *     default layout)</li>
         * </ul>
         *
         * The writing of cache may be prevented by setting a callback method or
         * an array of callback methods in the 'if' option. The callback methods 
         * are run just before cache writing, in the 'after_filter' chain. 
         * If one of them returns a value evaluated to false the writing is not
         * performed.
         *
         * Because caching is done entirely in the {@link before_filter} and 
         * {@link after_filter} filter chains it can be prevented by 
         * interrupting the filter chain (a filter method should return
         * a boolean <b>false</b>). It can be prevented also by redirecting 
         * or throwing the {@link StopException}.
         *
         * The 'cache_path' option may be a string started from '/' or just a 
         * name of a method returning the path. If a method is used, then its
         * returned value should be a string beginning with '/' or a full
         * URL (starting with 'http') as returned by the {@link url_for} 
         * function.
         *
         * <code>
         * class MyController extends \Application\Controller
         * {
         *     static $caches_action = array(
         *         'edit', 
         *         'cache_path' => 'edit_cache_path'
         *     );
         *     
         *     public function edit_cache_path()
         *     {
         *         return url_for(array(
         *             'edit', 
         *             'params' => $this->params->only('lang')
         *         ));
         *     }
         *
         *     # ...
         * }
         * </code>
         *
         * Notice that caching is working properly only if the CACHE constant 
         * is set to true.
         *
         * @see expire_action
         * @see caches_page
         * @var mixed String or array with action name(s)
         */
        static $caches_action = null;
        
        /**
         * The {@link Parameters} object that contains request parameters. 
         *
         * @see Parameters
         * @var Parameters
         */
        public $params;
        
        /**
         * The {@link Session} object that simplifies the session usage 
         * or null if sessions are disabled.
         *
         * @see Session
         * @var Session
         */
        public $session;
        
        private static $_content;
        private static $_instance;
        private static $_ch_file;
        private static $_ch_dir;
        private static $_ch_layout;
        private static $_ch_if;
        
        private final function __construct()
        {
            $this->params = Parameters::instance();
            $this->session = Session::instance();
            
            $class = get_class($this);
            do 
            {
                require HELPERS . str_replace('\\', DIRECTORY_SEPARATOR, 
                    substr($class, 12, -10)) . 'Helper.php';
            }
            while (($class = get_parent_class($class)) !== __CLASS__);
        }
        
        /**
         * Returns the current instance of a controller or creates a new one.
         *
         * If there is no instance yet and this method is used within 
         * a subclass of the {@link Controller} class it creates the new one.
         * Usually controller is created automatically in the 
         * {@link Application\start()} function.
         * 
         * return Controller
         */
        public static final function &instance()
        {
            if (!self::$_instance)
            {
                $controller = get_called_class();
                
                if ($controller !== __CLASS__)
                    self::$_instance = new $controller;
            }
            
            return self::$_instance;
        }

        /**
         * Returns the actual URI path without a specified server path.
         * 
     	 * @return string Current URI path
         */
        public function uri()
        {
            return SERVER_PATH 
                ? substr($_SERVER['REQUEST_URI'], strlen(SERVER_PATH))
                : $_SERVER['REQUEST_URI']; 
        }

        /**
         * Returns the current HTTP request method.
         *
         * @return string Current HTTP method
         */
        public function method()
        {
            return $_SERVER['REQUEST_METHOD'];
        }

        /**
         * Determines if the current HTTP request is secure (SSL) or not.
         *
         * @return bool True if SSL is used, false otherwise
         */
        public function is_ssl()
        {
            return $_SERVER['SERVER_PORT'] == (SSL_PORT ?: 443);
        }

        /**
         * Determines if the current HTTP request uses a GET method.
         *
         * @return bool True if a GET method is used, false otherwise
         */
        public function is_get()
        {
            return $_SERVER['REQUEST_METHOD'] === 'GET';
        }

        /**
         * Determines if the current HTTP request uses a POST method.
         *
         * @return bool True if a POST method is used, false otherwise
         */
        public function is_post()
        {
            return $_SERVER['REQUEST_METHOD'] === 'POST';
        }
        
        /**
         * Determines if the current HTTP request uses a PUT method.
         *
         * @return bool True if a PUT method is used, false otherwise
         */
        public function is_put()
        {
            return $_SERVER['REQUEST_METHOD'] === 'PUT';
        }

        /**
         * Determines if the current HTTP request uses a DELETE method.
         *
         * @return bool True if a DELETE method is used, false otherwise
         */
        public function is_delete()
        {
            return $_SERVER['REQUEST_METHOD'] === 'DELETE';
        }
        
        /**
         * Returns the default URL options used by all functions based on 
         * the {@link url_for} function. This method should return an array of
         * default options or nothing (a null value). Each default option may be
         * overridden by each call to the {@link url_for} function.
         *
         * @see url_for
         * @return array Default URL options or null
         */
        public function default_url_options() {}
        
        /**
         * Deletes the cached page, cached via the {@link $caches_page}.
         * The cache path is computed from options passed internally to the 
         * {@link url_for} function. Therefore see the {@link url_for} function
         * for options syntax.
         *
         * @see caches_page
         * @param mixed $options Options array or action name (string)
         */
        public function expire_page($options=array())
        {
            $key = url_for($options);
            $qpos = strpos($key, '?');
            $start = strlen(($key[4] === 's') ? SSL_URL : HTTP_URL);
            $key = ($qpos === false) 
                ? trim(substr($key, $start), '/.')
                : trim(substr($key, $start, $qpos - $start), '/.');
            
            if (isset($key[0]))
            {
                $cached_page = str_replace('/', DIRECTORY_SEPARATOR, $key);
                if (substr($key, -5) !== '.html')
                    $cached_page .= '.html';
            }
            else
                $cached_page = 'index.html';
            
            if (is_file($cached_page))
            {
                unlink($cached_page);
            
                while (($dir = dirname($cached_page)) !== '.')
                {
                    $empty = true;
                    $handler = opendir($dir);
                    while (false !== ($file = readdir($handler)))
                    {
                        if (($file !== '.') && ($file !== '..'))
                        {
                            $empty = false;
                            break;
                        }
                    }
                    closedir($handler);
                
                    if (!$empty)
                        break;
                        
                    rmdir($dir);
                    $cached_page = $dir;
                }
            }
        }
        
        /**
         * Deletes the cached action view, cached via the 
         * {@link $caches_action}. The cache path is computed from options
         * passed internally to the {@link url_for} function. Therefore see
         * the {@link url_for} function for options syntax. 
         *
         * @see caches_action
         * @param mixed $options Options array or action name (string)
         */
        public function expire_action($options=array())
        {
            $key = url_for($options);
            $key = substr($key, strlen(($key[4]==='s') ? SSL_URL : HTTP_URL));
            
            # if longer than 1 char (e.g. longer than '/')
            if (isset($key[1])) 
                $key = rtrim($key, '/.');
                
            $cached_dir = TEMP . 'ca_' . md5($key);
            
            if (is_dir($cached_dir))
            {
                $handler = opendir($cached_dir);

                while (false !== ($file = readdir($handler)))
                {
                    if ($file[0] !== '.')
                        unlink($cached_dir . DIRECTORY_SEPARATOR . $file);
                }

                closedir($handler);
                rmdir($cached_dir);
            }
            
            $cached_action = $cached_dir . '.cache';
            
            if (is_file($cached_action))
                unlink($cached_action);
        }
        
        /**
         * Returns true if the cached fragment is available. The cache path is 
         * computed from options passed internally to the {@link url_for}
         * function. Therefore see the {@link url_for} function for options 
         * syntax. Moreover, the additional following options are available:
         *
         * <ul>
         * <li><b>action_suffix</b>: the path suffix allowing many fragments in 
         *     the same action</li>
         * </ul>
         *
         * @see cache
         * @see expire_fragment
         * @param mixed $options Options array or action name (string)
         * @return bool True if the fragment exists, false otherwise
         */
        public function fragment_exists($options=array())
        {
            return is_file(self::fragment_file($options));
        }
        
        /**
         * Deletes a cached fragment. The cache path is computed from options 
         * passed internally to the {@link url_for} function. Therefore see 
         * the {@link url_for} function for options syntax. Moreover, 
         * the additional following options are available:
         *
         * <ul>
         * <li><b>action_suffix</b>: the path suffix allowing many fragments in
         *     the same action</li>
         * </ul>
         *
         * @see cache
         * @see fragment_exists
         * @param mixed $options Options array or action name (string)
         */
        public function expire_fragment($options=array())
        {
            $fragment = self::fragment_file($options);
            if (is_file($fragment))
                unlink($fragment);
        }
        
        /**
         * Caches the fragment enclosed in the closure. The cache path is 
         * computed from options passed internally to the {@link url_for}
         * function. Therefore see the {@link url_for} function for options 
         * syntax. Moreover, the additional following options are available:
         *
         * <ul>
         * <li><b>action_suffix</b>: the suffix allowing many fragments in the
         *     same action</li>
         * <li><b>expires_in</b>: time-to-live for the cached fragment 
         *     (in sec)</li>
         * </ul>
         *
         * Notice, this method will write and read cached fragments only 
         * if the CACHE constant is set to true.
         *
         * @see expire_fragment
         * @see fragment_exists
         * @param mixed $options Options array or action name (string)
         * @param \Closure $closure Content to be cached and displayed
         */
        public function cache($options, $closure)
        {
            if (!CACHE)
                return $closure($this);
            
            $frag = self::fragment_file($options);
            
            if (is_file($frag))
            {
                if (isset($options['expires_in']))
                {
                    if ((filemtime($frag) + $options['expires_in']) 
                        > $_SERVER['REQUEST_TIME'])
                        return readfile($frag);
                }
                else
                    return readfile($frag);
            }
            
            ob_start();
            $closure($this);
            $output = ob_get_clean();
            file_put_contents($frag, $output);
            echo $output;
        }
        
        private static final function fragment_file($options)
        {
            $key = url_for($options);
            $key = substr($key,strlen(($key[4]==='s') ?SSL_URL:HTTP_URL));   
            
            if (isset($options['action_suffix']))
                $key .= $options['action_suffix'];
            
            return TEMP . 'cf_' . md5($key) . '.cache';
        }
        
        private final function render_cache_in_layout()
        {
            if (is_dir(self::$_ch_dir))
            {
                $handler = opendir(self::$_ch_dir);

                while (false !== ($file = readdir($handler)))
                {
                    if ($file[0] !== '.')
                        self::$_content[$file] = file_get_contents(
                            self::$_ch_dir . DIRECTORY_SEPARATOR . $file
                        );
                }

                closedir($handler);
            }
            
            $this->render(array(
                'text' => file_get_contents(self::$_ch_file),
                'layout' => true
            ));
            
            throw new StopException;
        }
        
        /**
         * A filter method added automatically to {@link before_filter} chain to
         * perform action caching (render or create).
         * 
         * @param string $key The cache path passed automatically to the filter
         * @throws {@link StopException} If cache was loaded and rendered
         * @internal
         */
        protected final function set_action_cache($key)
        {
            if (self::$_ch_file)
                return;
            
            global $ACTION;
            
            foreach (self::normalize_defs(static::$caches_action) as $ch)
            {
                if ($ch[0] !== $ACTION)
                    continue;
                
                if (isset($ch['cache_path']))
                {
                    if ($ch['cache_path'][0] === '/')
                        self::$_ch_dir = TEMP . 'ca_' . md5($ch['cache_path']);
                    else
                    {
                        $chp = $this->$ch['cache_path']();
                            
                        if ($chp[0] === '/')
                            self::$_ch_dir = TEMP . 'ca_' . md5($chp);
                        elseif ($chp[4] === 's')
                            self::$_ch_dir = TEMP . 'ca_' 
                                . md5(substr($chp, strlen(SSL_URL)));
                        else
                            self::$_ch_dir = TEMP . 'ca_' 
                                . md5(substr($chp, strlen(HTTP_URL)));
                    }
                }
                else
                    self::$_ch_dir = TEMP . 'ca_' 
                        . md5(isset($key[1]) ? rtrim($key, '/.') : $key);

                self::$_ch_file = self::$_ch_dir . '.cache';
                
                if (isset($ch['layout']) && !$ch['layout'])
                { 
                    if (is_file(self::$_ch_file))
                    {
                        if (isset($ch['expires_in']))
                        { 
                            if ((filemtime(self::$_ch_file) + $ch['expires_in']) 
                                > $_SERVER['REQUEST_TIME'])
                                $this->render_cache_in_layout();
                        }
                        else
                            $this->render_cache_in_layout();
                    }
                    self::$_ch_layout = self::get_layout();
                    static::$layout = null;
                }
                elseif (is_file(self::$_ch_file))
                {
                    if (isset($ch['expires_in']))
                    { 
                        if ((filemtime(self::$_ch_file) + $ch['expires_in']) 
                            > $_SERVER['REQUEST_TIME'])
                        {
                            readfile(self::$_ch_file);
                            throw new StopException;
                        }
                    }
                    else
                    {
                        readfile(self::$_ch_file);
                        throw new StopException;
                    }
                }
                
                if (isset($ch['if']))
                    self::$_ch_if = $ch['if'];
                   
                self::add_to_filter('after_filter', 'write_and_show_cache');
                ob_start();
                break;
            }
        }
        
        /**
         * A filter method added automatically to {@link before_filter} chain to
         * create page cache.
         * 
         * @param string $key The cache path passed automatically to the filter
         * @internal
         */
        protected final function set_page_cache($key)
        {
            if (self::$_ch_file)
                return;
            
            global $ACTION;
            
            foreach (self::normalize_defs(static::$caches_page) as $ch)
            {   
                if ($ch[0] !== $ACTION)
                    continue;
                            
                $key = trim($key, '/.');
                    
                if (isset($key[0]))
                {
                    self::$_ch_file = str_replace('/',DIRECTORY_SEPARATOR,$key);
                                        
                    if (!strpos($key, '.'))
                        self::$_ch_file .= '.html';
                }
                else
                    self::$_ch_file = 'index.html';
                
                if (isset($ch['if']))
                    self::$_ch_if = $ch['if'];
                
                self::add_to_filter('after_filter', 'write_and_show_cache');
                ob_start();
                break;
            }
        }
        
        /**
         * A filter method added automatically to {@link after_filter} chain to
         * write and render cache file prepared in {@link set_page_cache} or 
         * {@link set_action_cache} methods.
         *
         * @internal
         */
        protected final function write_and_show_cache()
        {            
            if (self::$_ch_if)
            {
                if ((array) self::$_ch_if === self::$_ch_if)
                {
                    foreach (self::$_ch_if as $ifm)
                    {
                        if (!$this->$ifm())
                            return;
                    }
                }
                else
                {
                    $ifm = self::$_ch_if;
                    if (!$this->$ifm())
                        return;
                }
            }
            
            if (!self::$_ch_dir) # if caches page
            {
                $dir = dirname(self::$_ch_file);
                    
                if (!is_dir($dir))
                    mkdir($dir, 0775, true);
            }
            
            $output = ob_get_clean();
            file_put_contents(self::$_ch_file, $output);    
            
            if (self::$_ch_layout)
            {
                if (self::$_content)
                {
                    if (is_dir(self::$_ch_dir))
                    {
                        $handler = opendir(self::$_ch_dir);

                        while (false !== ($f = readdir($handler)))
                        {
                            if ($f[0] !== '.')
                                unlink(self::$_ch_dir .DIRECTORY_SEPARATOR .$f);
                        }

                        closedir($handler);
                    }
                    else
                        mkdir(self::$_ch_dir, 0775);
                    
                    foreach (self::$_content as $r => $c)
                        file_put_contents(self::$_ch_dir.DIRECTORY_SEPARATOR.$r,
                            $c);       
                }
                
                $this->render(array(
                    'text' => $output,
                    'layout' => self::$_ch_layout
                ));
            }
            else
                echo $output;
        }
        
        /**
    	 * Sends a location in the HTTP header causing a HTTP client 
    	 * to redirect. The location URL is obtained from {@link url_for}
    	 * function. See {@link url_for} function for options syntax.
    	 *
    	 * Additionally, following options are available:
    	 * 
    	 * <ul>
         * <li><b>status</b>: HTTP status code (default: 302, see below)</li>
         * <li><b>[name]</b>: additional flash message</li>
         * </ul>
         *
    	 * Available HTTP 1.1 statuses:
    	 *
    	 * <ul>
    	 * <li><b>301</b>: 301 Moved Permanently</li>
    	 * <li><b>302</b>: 302 Found (default)</li>
    	 * <li><b>303</b>: 303 See Other</li>
    	 * <li><b>307</b>: 307 Temporary Redirect</li>
    	 * </ul>
    	 *
    	 * Example:
    	 *
    	 * <code>
    	 * $this->redirect_to(array('index', 'notice' => 'Post updated.'));
    	 * # Redirects to the action 'index' and sets the appropriate flash
    	 * # message.
    	 * </code>
    	 *
    	 * @see url_for
    	 * @see redirect_to_url
    	 * @param mixed $options Options array or action name (string)
    	 * @throws {@link StopException} In order to stop further execution
    	 */
        public function redirect_to($options=array())
        {
            if ((array) $options !== $options)
                $this->redirect_to_url(url_for($options));
            elseif (!$this->session)
                $this->redirect_to_url(url_for($options), $options);
            
            $url = url_for($options);
            
            unset(
                $options['params'], 
                $options[0],
                $options['name'],
                $options['ssl'], 
                $options['anchor'],
                $options['locale'],
                $options['action'], 
                $options['controller']
            );
            
            $this->redirect_to_url($url, $options);
        }
        
        /**
    	 * Sends a location in the HTTP header causing a HTTP client 
     	 * to redirect. The following options are available:
     	 * 
     	 * <ul>
         * <li><b>status</b>: HTTP status code (default: 302, see below)</li>
         * <li><b>[name]</b>: additional flash message</li>
         * </ul>
         *
     	 * Available HTTP 1.1 statuses:
     	 *
     	 * <ul>
     	 * <li><b>301</b>: 301 Moved Permanently</li>
     	 * <li><b>302</b>: 302 Found (default)</li>
     	 * <li><b>303</b>: 303 See Other</li>
     	 * <li><b>307</b>: 307 Temporary Redirect</li>
     	 * </ul>
     	 *
    	 * @see redirect_to
    	 * @param string $url URL of the location
         * @param mixed $options Options array
    	 * @throws {@link StopException} In order to stop further execution
    	 */
        public function redirect_to_url($url, $options=array())
        {
            if (isset($options['status']))
            {
                if ($options['status'] === 301)
                    header('HTTP/1.1 301 Moved Permanently');
                elseif ($options['status'] === 303)
                    header('HTTP/1.1 303 See Other');
                elseif ($options['status'] === 307)
                    header('HTTP/1.1 307 Temporary Redirect');
                
                unset($options['status']);
            }
            
            foreach ($options as $name => $msg)
                $_SESSION['__PRAGWORK_10_FLASH'][$name] = array($msg, false);
            
            header('Location: ' . $url);
            throw new StopException;
        }
        
        /**
         * Renders a template depending on parameters passed via $options.
         * The rendering topic may be divided into two big areas of use:
         * rendering of templates and rendering of partial templates.
         * 
         * A. General rendering of templates
         *
         * Templates are placed under the directory 'views' of the application
         * code. They fill the directory structure according to the controllers
         * structure.
         *
         * A.1. Rendering a template in the current controller 
         *
         * <code>
         * class ShopController extends \Application\Controller
         * {
         *     public function index()
         *     {
         *         # $this->render();
         *     }
         *
         *     public function show()
         *     {
         *         $this->render('index');
         *         $this->render(array('index'));
         *         $this->render(arary('action' => 'index'));
         *     }
         * }
         * </code>
         *
         * Each of the method calls in the action 'show' above renders 
         * the template of the action 'index' of the current controller.
         * However you should render a template once. Notice also, rendering
         * the template does not stop the further action execution.
         *
         * The 'render()' with no arguments renders the template of the current
         * action. But the action renders its own template implicitly if no
         * other render is used (except partial templates). Therefore there is
         * no need to explicit call 'render()' in the 'index' action above.
         *
         * A.2. Rendering a template of another controller 
         *
         * <code>
         * class CustomersController extends \Application\Controller
         * {
         *     public function edit() {}
         * }
         *
         * class ShopController extends \Application\Controller
         * {
         *     public function show()
         *     {
         *         $this->render(array(
         *             'action' => 'edit', 
         *             'controller' => 'Customers'
         *         ));
         *
         *         # or just: $this->render('Customers\edit')
         *     }
         * }
         * </code>
         *
         * Renders the template of the 'edit' action of the Customers 
         * controller.
         *
         * A.3. Rendering a custom template
         *
         * <code>
         * $this->render('my_custom_template');
         * $this->render('my_templates\my_custom_template');
         * $this->render(array('my_custom_template', 'layout' => false))
         * $this->render(array('my_custom_template', 'layout' => 'my_layout'));
         * </code>
         *
         * Renders a custom template. The custom template may be placed 
         * in a subdirectory. The subdirectories are separated with 
         * a backslash \. If there is a backslash in the string, the path 
         * starts from the root (the 'views' directory).
         *
         * Each of the examples from the part A can be altered with an option
         * 'layout' which can point to a certain {@link $layout}. 
         * Also, this option can be set to <b>false</b> disabling the global
         * layout defined in the controller. The layout file should be put 
         * in the 'views/layouts' directory.
         *
         * <code>
         * class ShopController extends \Application\Controller
         * {
         *     static $layout = 'shop';
         *
         *     public function index()
         *     {
         *         # use the default layout ('views/layouts/shop.php')
         *     }
         *
         *     public function show()
         *     {
         *         $this->render(array('layout' => false));
         *
         *         # do not use any layout, same as self::$layout = null;
         *     }
         *
         *     public function edit()
         *     {
         *         $this->render(array(
         *             'action' => 'show',
         *             'layout' => 'custom_layout'
         *         ));
         *
         *         # or just:
         *         # $this->render(array('show', 'layout' => 'custom_layout'));
         *
         *         # use the template 'views/Shop/show.php' with 
         *         # the layout 'views/layouts/custom_layout.php'.
         *     }
         * }
         * </code>
         *
         * A.4. Content Format
         *
         * It is possible to specify a content format in the header sended with 
         * the first use of the render() method (excluding partials). It can be
         * done with help of the 'content_status' option.
         *
         * <code>
         * $this->render(array('show', 'content_format' => 'text/xml'));
         * </code>
         *
         * A.5. Format
         *
         * Format enables additional headers to be sent on the first call of 
         * render() (again partials does not count). Also, it provides
         * additional, specific behavior, depending on the chosen format.
         *
         * Currently there is only one format available: <b>xml</b>.
         *
         * <code>
         * $this->render(array('format' => 'xml'));
         * </code>
         *
         * It renders the template (the default one in this particular example)
         * with the header: "Content-Type: text/xml; charset=utf-8" (no content
         * format was specified). Moreover, it disables the global layout. 
         * You can always use a layout by specifying a layout template:
         *
         * <code>
         * $this->render(array('format' => 'xml', 'layout' => 'my_xml_layout'));
         * </code>
         *
         * Or, you can turn on the global layout by setting 'layout' to true 
         * explicitly.
         *
         * A.6. Text, XML, JSON
         * 
         * You can also specify a text (or xml, json) instead of a template. 
         * It is useful especially in the AJAX applications.
         *
         * <code>
         * $this->render(array('text' => 'OK'));
         * $this->render(array('xml' => $xml));
         * $this->render(array('json' => array('a' => 1, 'b' => 2, 'c' => 3)));
         * </code>
         *
         * If you do not set the custom content format, the 'application/xml' is
         * used for XML and 'application/json' is used for JSON (the header is
         * set in the first method call).
         * 
         * The 'json' option allows to pass 'json_options' bitmask, just like 
         * it is done in the global json_encode() function.
         * 
         * <code>
         * $this->render(array(
         *     'json' => array(array(1, 2, 3)), 
         *     'json_options' => JSON_FORCE_OBJECT
         * ));
         * </code>
         *
         *
         * B. Rendering partial templates
         *
         * Partial templates are placed in the same directory structure as
         * normal templates. They differ from the normal ones in extensions.
         * Partial templates ends with the '.part.php' extension.
         *
         * Whereas normal rendering of templates is taking place in 
         * the controller, the rendering of partials is the domain of template
         * files mainly. Usually partial templates represent repetitive portions
         * of code used to construct more compound structures. The result of
         * rendering the partial template is returned as a string - it is not
         * displayed immediately and therefore it should be displayed explicitly
         * with the 'echo' function.
         *
         * If the '.part.php' file is not found the '.php' one is used instead
         * and the template is rendered in the normal way described in the
         * section A.
         *
         * B.1. Rendering the partial template
         * 
         * <code>
         * <?php echo $this->render('item') ?>
         * </code>
         *
         * The code above renders the partial template 'item.part.php' placed
         * under the controller's directory in the views structure. 
         * If the partial template name contains a backslash \ the absolute path
         * will be used (with the root set to 'views' directory).
         *
         * <code>
         * <?php echo $this->render('shared\header') ?>
         * # renders /views/shared/header.part.php
         * </code>
         *
         * Everything (except 'collection') passed as named array elements are
         * converted to local variables inside the partial template.
         * 
         * <code>
         * <?php echo $this->render(array('item', 'text' => 'Hello')) ?>
         * # renders the partial template ('item.part.php') and creates a local 
         * # variable named $text there.
         * </code>
         *
         * B.2. Rendering a partial template with a collection
         *
         * If you use the 'collection' option you can render the partial
         * template a few times, according to items passed in an array 
         * as 'collection'. The current item from the collection is named 
         * after the template name, and the array key name has the '_key'
         * suffix.
         *
         * So the code below:
         *
         * <code>
         * <?php $this->render(array(
         *     'person', 
         *     'collection' => array('John', 'Frank'),
         *     'message' => 'The message.'
         * )) ?>
         * </code>
         *
         * could be used in the 'person.part.php' like here:
         *
         * <code>
         * <h1><?php echo Hello $person ?></h1>
         * <p><?php echo $message ?></p>
         * <p>And the current key is: <?php echo $person_key ?></p>
         * </code>
         * 
         * In the above example the 'person.part.php' will be rendered twice,
         * with different names ($person) and keys ($person_key). The whole
         * collection will be still available under the $collection variable.
         *
         * @see layout
         * @param mixed $options Options array or string
         * @return mixed Rendered partial template or null
         */
        public function render($options=array())
        {
            global $CONTROLLER, $ACTION, $RENDERED;
            
            if ((array) $options !== $options)
            {
                $template = VIEWS . ((strpos($options, '\\') === false)
                    ? str_replace('\\', DIRECTORY_SEPARATOR, $CONTROLLER) 
                        . DIRECTORY_SEPARATOR . $options
                    : str_replace('\\', DIRECTORY_SEPARATOR, $options));
                
                $partial = $template . '.part.php';
                
                if (is_file($partial))
                {
                    ob_start();
                    require $partial;
                    return ob_get_clean();
                }
                
                if (!$RENDERED)
                {
                    $this->invoke_filters('before_render_filter');
                    $RENDERED = true;
                }
                
                $layout = self::get_layout();
                
                if ($layout)
                {
                    ob_start();
                    require $template . '.php';
                    self::$_content[0] = ob_get_clean();
                    require VIEWS . 'layouts' . DIRECTORY_SEPARATOR
                        . str_replace('\\', DIRECTORY_SEPARATOR, $layout)
                        . '.php';
                }
                else
                    require $template . '.php';
                
                return;
            }
            elseif (isset($options[0]))
            {
                $template = VIEWS . ((strpos($options[0], '\\') === false)
                    ? str_replace('\\', DIRECTORY_SEPARATOR, $CONTROLLER) 
                        . DIRECTORY_SEPARATOR . $options[0]
                    : str_replace('\\', DIRECTORY_SEPARATOR, $options[0]));
                
                $partial = $template . '.part.php';
                
                if (is_file($partial))
                {
                    unset($options[0]);
                    ob_start();
                
                    if (isset($options['collection']))
                    {
                        $name = basename($partial, '.part.php');        
                        $key_name = $name . '_key';
                    
                        foreach ($options['collection'] as $key => $item)
                        {
                            $this->render_partial($partial, array(
                                $name => $item,
                                $key_name => $key
                            ) + $options);
                        }
                    }
                    else
                        $this->render_partial($partial, $options);
                
                    return ob_get_clean();
                }
            }
            elseif (isset($options['xml']))
            {
                if (!isset($options['content_type']))
                    $options['content_type'] = 'application/xml';
                $options['text'] = $xml;
            }
            elseif (isset($options['json']))
            {
                if (!isset($options['content_type']))
                    $options['content_type'] = 'application/json';
                
                $options['text'] = isset($options['json_options'])
                    ? json_encode($options['json'], $options['json_options'])
                    : json_encode($options['json']);
            }
            elseif (!isset($options['text']))
                $template = VIEWS . str_replace('\\', DIRECTORY_SEPARATOR,
                    isset($options['controller']) 
                        ? $options['controller'] : $CONTROLLER) 
                    . DIRECTORY_SEPARATOR . (isset($options['action'])
                        ? $options['action'] : $ACTION);
            
            if (isset($options['text']))
            {
                if (!$RENDERED)
                {
                    $RENDERED = true;
                    $this->invoke_filters('before_render_filter');
                    
                    if (isset($options['content_type']))
                        header('Content-Type: ' . $options['content_type']
                            . '; charset=utf-8');
                }
                
                if (isset($options['layout']))
                {
                    if ($options['layout'] === true)
                        $options['layout'] = self::get_layout();
                    
                    self::$_content[0] = $options['text'];
                    require VIEWS . 'layouts' . DIRECTORY_SEPARATOR.str_replace(
                        '\\', DIRECTORY_SEPARATOR, $options['layout']) . '.php';
                }
                else
                    echo $options['text'];
                
                return;
            }
            
            if (isset($options['format']) && $options['format'] === 'xml')
            {
                if (!isset($options['content_type']))
                    $options['content_type'] = 'text/xml';
                if (!isset($options['layout']))
                    $options['layout'] = false;
            }
            elseif (!isset($options['layout']))
                $options['layout'] = self::get_layout();
            
            if (!$RENDERED)
            {
                $this->invoke_filters('before_render_filter');
                $RENDERED = true;
                
                if (isset($options['content_type']))
                    header('Content-Type: ' . $options['content_type']
                        . '; charset=utf-8');
            }
            
            if ($options['layout'])
            {
                ob_start();
                require $template . '.php';
                self::$_content[0] = ob_get_clean();
                require VIEWS . 'layouts' . DIRECTORY_SEPARATOR 
                    . str_replace('\\', DIRECTORY_SEPARATOR, $options['layout']) 
                    . '.php';
            }
            else
                require $template . '.php';
        }
        
        /**
         * Renders the template just like the {@link render} method but returns
         * the results as a string. Also, this method does not send any
         * headers and does not cause {@link before_render_filter} filters 
         * to run.
         *
         * @see render
         * $param mixed $options Options array or string
         * @return string
         */
        public function render_to_string($options=array())
        {
            global $RENDERED;
            ob_start();
            
            if ($RENDERED)
                $str = $this->render($options);
            else
            {
                $RENDERED = true;
                $str = $this->render($options);
                $RENDERED = false;
            }
            
            return ob_get_clean() ?: $str;
        }
        
        private function render_partial($___path___, $___args___)
        {   
            foreach ($___args___ as $___n___ => $___v___) 
                $$___n___ = $___v___;
            
            require $___path___;
        }

        /**
         * Returns a rendered template or a template region constructed 
         * with the {@link content_for} method and a name passed as a parameter. 
         * This method should be used directly from a layout template. 
         * If the region does not exist the null is returned instead.
         *
         * <code>
         * <?php echo $this->yield() ?>
         * </code>
         *
         * <code>
         * <?php echo $this->yield('title') ?>
         * </code>
         *
         * @see content_for
         * @see render
         * @param string $region Optional region name
         * @return mixed Rendered template, template region, or null
         */
        public function yield($region=0)
        {
            if (isset(self::$_content[$region]))
                return self::$_content[$region];
        }
        
        /**
         * Inserts a named content block into a layout view directly from 
         * a template. The region name can be used in the layout with the 
         * {@link yield} function. The closure with the content may have 
         * an argument. If so, the current controller instance is passed 
         * there allowing to get to controller methods and variables. 
         *
         * <code>
         * <?php $this->content_for('title', function() { ?>
         *     Just simple title
         * <?php }) ?>
         * </code>
         *
         * <code>
         * <?php $this->content_for('title', function($that) { ?>
         *
         *     # the current controller is named '$that' by convention
         *     # and because '$this' cannot be used in the closure context
         *
         *     Records found: <?php echo count($that->records) ?>
         * <?php }) ?>
         * </code>
         *
         * @see yield
         * @param string $region Region name
         * @param \Closure $closure Content for partial yielding
         */
        public function content_for($region, $closure)
        {
            ob_start();
            $closure($this);
            self::$_content[$region] = ob_get_clean();
        }
        
        private static final function get_layout()
        {
            if (!static::$layout)
                return;
            
            static $layout;
            
            if (!isset($layout))
            {
                $layout = null;
                global $ACTION;
                
                foreach (self::normalize_defs(static::$layout) as $l)
                {
                    if (isset($l['only']))
                    {
                        if ((((array) $l['only'] === $l['only']) 
                            && in_array($ACTION, $l['only'], true))
                            || ($l['only'] === $ACTION))
                        {
                            $layout = $l[0];
                            break;
                        }
                        continue;
                    }
                    elseif (isset($l['except'])
                        && ((((array) $l['except'] === $l['except']) 
                        && in_array($ACTION, $l['except'], true))
                        || ($l['except'] === $ACTION)))
                        continue;
                    
                    $layout = $l[0];
                    break;
                }
            }
            
            return $layout;
        }
        
        private static final function get_filter_mods(&$entry)
        {
            $modifiers = array();
            if (isset($entry['only']))
            {
                $modifiers['only'] = ((array) $entry['only'] === $entry['only'])
                    ? $entry['only']
                    : array($entry['only']);
                unset($entry['only']);
            }
            if (isset($entry['except']))
            {
                $modifiers['except'] = 
                    ((array) $entry['except'] === $entry['except'])
                        ? $entry['except']
                        : array($entry['except']);
                unset($entry['except']);
            }
            if (isset($entry['exception']))
            {
                $modifiers['exception'] = $entry['exception'];
                unset($entry['exception']);
            }
            return $modifiers;
        }
        
        private static final function normalize_defs($definitions)
        {   
            if ((array) $definitions !== $definitions)
                return array(array($definitions));

            $normalized_definitions = array();
            $outer_options = array();

            foreach ($definitions as $key => $body)
            {   
                if ((string) $key === $key)
                    $outer_options[$key] = $body;
                elseif ((array) $body === $body)
                {    
                    $inner_options = array();

                    foreach ($body as $k => $v)
                    {
                        if ((string) $k === $k)
                        {
                            $inner_options[$k] = $v;
                            unset($body[$k]);
                        }
                    }

                    foreach ($body as $b)
                        $normalized_definitions[] = array($b) + $inner_options;
                }
                else
                    $normalized_definitions[] = array($body);                        
            }

            if ($outer_options)
            {
                foreach ($normalized_definitions as &$nd)
                    $nd += $outer_options;
            }

            return $normalized_definitions;
        }
        
        /**
         * Appends a filter method to the given chain. It allows to alter the
         * filter chain dynamically during the execution time.
         *
         * @param string $filter Name of filter chain
         * @param string $method Name of filter method to append
         * @internal
         */
        public static final function add_to_filter($filter, $method)
        {
            if (!static::$$filter)
                static::$$filter = $method;
            elseif ((array) static::$$filter === static::$$filter)
            {
                if (array_key_exists('except', static::$$filter) 
                    || array_key_exists('only', static::$$filter))
                    static::$$filter = self::normalize_defs(static::$$filter);
                
                array_push(static::$$filter, $method);
            }
            else
                static::$$filter = array(static::$$filter, $method);
        }
        
        /**
         * Runs the filters with the specified name and an optional value.
         * This method is intended to use internally by framework router.
         * You do not have to trigger filters manually. 
         *
    	 * @see before_filter
    	 * @see before_render_filter
    	 * @see after_filter
    	 * @see exception_filter 
    	 * @internal
    	 * @param string $filter Name of filter chain to run
    	 * @param mixed $value Optional value passed to filter chain methods
    	 * @return bool False if one of filter methods interrupts filter chain
    	 */
        public function invoke_filters($filter, $value=null)
        {   
            $filter_chain = array();
            
            $class = get_class($this);
            do 
            {
                $class_filters = $class::$$filter;
                
                if (!$class_filters)
                    continue;
                    
                if ((array) $class_filters !== $class_filters)
                {
                    if (!isset($filter_chain[$class_filters]))
                        $filter_chain[$class_filters] = null;
                }
                else
                {
                    $class_mods = self::get_filter_mods($class_filters);
                
                    foreach (array_reverse($class_filters) as $entry)
                    {
                        if ((array) $entry !== $entry)
                        {
                            if (!isset($filter_chain[$entry]))
                                $filter_chain[$entry] = $class_mods;
                        }
                        else
                        {
                            $mods = self::get_filter_mods($entry);
                        
                            foreach (array_reverse($entry) as $e)
                            {
                                if (!isset($filter_chain[$e]))
                                    $filter_chain[$e] = $mods ?: $class_mods;
                            }
                        }
                    }
                }
            } while (($class = get_parent_class($class)) !== __CLASS__);
            
            global $ACTION;
            
            foreach (array_reverse($filter_chain) as $flt => $mods)
            {
                if (isset($mods['only']) 
                    && !in_array($ACTION, $mods['only']))
                    continue;
                elseif (isset($mods['except']) 
                    && in_array($ACTION, $mods['except']))
                    continue;
                elseif (isset($mods['exception']) 
                    && !($value && is_a($value, $mods['exception'])))
                    continue;

                if ($this->$flt($value) === false)
                    return false;
            }
        }
    }
}

namespace
{
    /**
     * Absolute path to the configuration directory. 
     *
     * @internal
     */
    define('CONFIG', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'config' 
        . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to the user application code directory.
     *
     * @internal
     */
     define('APP', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'app' . 
        DIRECTORY_SEPARATOR);
    
    /**
     * HTTP URL part used to construct URLs.
     *
     * @internal
     */
    define('HTTP_URL', 'http://' . $_SERVER['SERVER_NAME'] 
        . (HTTP_PORT ? ':' . HTTP_PORT : '') . SERVER_PATH);

    /**
     * HTTPS URL part used to construct URLs.
     *
     * @internal
     */
    define('SSL_URL', 'https://' . $_SERVER['SERVER_NAME'] 
        . (SSL_PORT ? ':' . SSL_PORT : '') . SERVER_PATH);
    
    /**
     * Absolute path to helpers directory.
     *
     * @internal
     */
    define('HELPERS', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'app' 
        . DIRECTORY_SEPARATOR . 'helpers' . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to views directory.
     *
     * @internal
     */
    define('VIEWS', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'app' 
        . DIRECTORY_SEPARATOR . 'views' . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to locales directory.
     *
     * @internal
     */
    define('LOCALES', APPLICATION_PATH . DIRECTORY_SEPARATOR 
        . 'locales' . DIRECTORY_SEPARATOR);
    
    /**
     * Absolute path to the directory for temporary files.
     *
     * @internal
     */
    define('TEMP', APPLICATION_PATH . DIRECTORY_SEPARATOR . 'temp' 
        . DIRECTORY_SEPARATOR);
    
    /**
     * Internal class autoloader. The provided class name should not be started
     * with a backslash <b>\</b> character. Notice, that PHP strips the leading
     * backslashes automatically even if you provide it in the code:
     * 
     * <code>
     * $bar = new \Foo\Bar;
     * # it passes 'Foo\Bar' string to the class loader if class has not been
     * # loaded yet
     * </code>
     *
     * However, a user may provide a leading backslash accidentally while
     * dealing with classes loaded from strings:
     *
     * <code>
     * $class_name = '\Foo\Bar'; # WRONG!
     * $bar = new $class_name;
     *
     * $class_name = 'Foo\Bar';  # CORRECT
     * $bar = new $class_name;   # It is an equivalent of: $bar = new \Foo\Bar;
     * </code>
     *
     * Remember, namespaces in strings are always regarded as absolute ones.
     *
     * @param $class Class name
     * @internal This function should not be used explicitly! Internal use only.
     */
    function __autoload($class)
    {
        require APP . str_replace('\\', DIRECTORY_SEPARATOR, $class) . '.php';
    }

    /**
     * Internal error handler.
     *
     * @internal This function should not be used explicitly! Internal use only.
     */
    function exception_error_handler($errno, $errstr, $errfile, $errline) 
    {
        throw new ErrorException($errstr, 0, $errno, $errfile, $errline);
    }
    
    set_error_handler('exception_error_handler');
    
    /**
     * Constructs URL based on the route name or an action (or a controller)
     * passed as $options. The routes are defined in the application
     * configuration directory ('routes.php').
     *
     * The following options are available:
     *
     * <ul>
     * <li><b>name</b>: explicit name of the route
     * <li><b>action</b>: name of the action</li>
     * <li><b>controller</b>: name of the controller</li>
     * <li><b>ssl</b>: value must be a bool</li>
     * <li><b>anchor</b>: anchor part of the URL</li>
     * <li><b>params</b>: array of parameters or a model</li>
     * <li><b>locale</b>: custom locale code</li>
     * </ul>
     *
     * 1. URL for a specified route
     *
     * <code>
     * url_for(array('name' => 'help'));
     * </code> 
     *
     * Returns an URL for the route name 'help'.
     *
     * 2. URL for the action and the controller
     * 
     * <code>
     * url_for();
     * </code>
     *
     * Returns an URL for the current action of the current controller. 
     * If the action or controller is not given the current one is used instead.
     * If there is no controller at all (e.g. inside error templates) the root
     * controller is assumed.
     *
     * <code>
     * url_for('/');
     * </code>
     *
     * Returns an URL to the root route of the application ('/'). The root 
     * route is always the first entry (0th index) in the $ROUTES array.
     *
     * <code>
     * url_for('index'); 
     * url_for(array('index'));
     * url_for(array('action' => 'index'));
     * </code>
     *
     * Returns the URL for the 'index' action of the current controller.
     *
     * <code>
     * url_for('Shop\index');
     * url_for(array('Shop\index'));
     * url_for(array('action' => 'index', 'controller' => 'Shop'));
     * </code>
     * 
     * Returns the URL for the 'index' action of the Shop controller.
     * The controllers should be specified with the enclosing namespace 
     * (if any), e.g. 'Admin\Configuration' - for the controller with the full 
     * name: \Controllers\Admin\ConfigurationController.
     *
     * 3. Static assets
     *
     * If the string (2 characters length min.) starting with a slash <b>/</b> 
     * is passed as $options or the first (0th index) element of the options
     * array then it is treated as an URI path to a static asset. 
     * This feature is used by special assets tags in the Tags module, 
     * therefore rarely there is a need to explicit use it.
     *
     * <code>
     * url_for('/img/foo.png');
     * url_for($this->uri());
     * </code>
     *
     * 4. SSL
     *
     * <code> 
     * url_for(array('index', 'ssl' => true));
     * url_for(array('name' => 'help', 'ssl' => false));
     * </code>
     *
     * Returns the URL with the secure protocol or not. If the 'ssl' option is
     * omitted the default SSL setting is used (from the corresponding entry
     * in the 'routes.php' configuration file). The HTTP and HTTPS protocols use
     * the ports defined in the 'index.php' file in the 'public' directory. 
     * If those ports are set to null, default values are used (80 and 443).
     *
     * 5. Anchor
     * 
     * <code>
     * url_for(array('index', 'anchor' => 'foo'));
     * </code>
     *
     * Generates the URL with the anchor 'foo', for example: 
     * 'http://www.mydomain.com/index#foo'.
     *
     * 6. Parameters
     *
     * Parameters are passed an an option named 'params'. There are two kind 
     * of parameters in the URL: path parameters and query parameters. 
     * Path parameters are used to compose the URI path, and query parameters
     * are used to create the query appended to the URL. Usually, parameters are 
     * passed as an array where the keys are parameter names. However, path
     * parameters can be passed without keys at all. In such case, they are
     * taken as first ones depending on their order. Path parameters always 
     * have higher priority than query parameters, and keyless path parameters
     * have higher priority than others.
     *
     * If there is only one keyless parameter, the array may be omitted.
     *
     * Consider the simplest example:
     *
     * <code>
     * url_for(array('show', 'params' => array(
     *     'id' => 12, 
     *     'size' => 25, 
     *     'color' => 'blue'
     * )));
     * </code>
     * 
     * The result could be (assuming the according route is e.g. '/items/:id'):
     * 'http://www.mydomain.com/items/12?size=25&color=blue'.
     * 
     * But you can also write it in a short manner, using the 0th array element:
     * 
     * <code>
     * url_for(array('show', 'params' => array(12,'size'=>25,'color'=>'blue')));
     * </code>
     *
     * Also, if there had not been other parameters than the path one, you would
     * have written it even shorter:
     * 
     * <code>
     * url_for(array('show', 'params' => 12));
     * </code>
     *
     * 7. Locale
     * 
     * If the LOCALIZATION constant is set to true, this option affects 
     * the locale code used to construct the URL. It could be useful e.g. to
     * provide language choice options. Notice, if the LOCALIZATION is set to 
     * true the root action allows the localization to be omitted and thus 
     * the locale remains undefined (unloaded). In such case, in the root action
     * flow, you have to specify the locale manually or you will get an error.
     *
     * @see Controller
     * @param mixed $options Array of options
     * @return string URL generated from given $options
     * @author Szymon Wrozynski
     */
    function url_for($options=array())
    {
        if ((array) $options !== $options)
            $options = array($options);
        
        global $ROUTES, $CONTROLLER, $ACTION, $LOCALE, $RC, $RC_2;
        
        static $duo;
        
        if (!isset($duo))
        {
            if (isset($CONTROLLER, $ACTION))
                $duo =Application\Controller::instance()->default_url_options()
                    ?: false;
            else
            {
                $CONTROLLER = $ROUTES[0]['controller'];
                $ACTION = $ROUTES[0]['action'];
                $duo = false;
            }
        }
        
        if ($duo)
        {
            if (isset($duo['params'], $options['params']))
                $options['params'] = array_merge(
                    ((array) $duo['params'] === $duo['params'])
                        ? $duo['params'] : array($duo['params']),
                    ((array) $options['params'] === $options['params'])
                        ? $options['params'] : array($options['params'])
                );
            
            $options = array_merge($duo, $options);
        }
        
        if (isset($options[0][0]))
        {
            if ($options[0] === '/')
                $options['name'] = 0;
            elseif ($options[0][0] === '/')
            {
                if (!isset($options['ssl']))
                    $options['ssl'] = $_SERVER['SERVER_PORT']==(SSL_PORT ?:443);
                        
                return ($options['ssl'] ? SSL_URL : HTTP_URL) . $options[0];        
            }
            elseif (strpos($options[0], '\\') > 0)
                $options['name'] = $RC_2[$options[0]];
            else
                $options['name'] = $RC[$CONTROLLER][$options[0]];
        }
        elseif (!isset($options['name']))
            $options['name'] = $RC[isset($options['controller'])
                ? $options['controller'] : $CONTROLLER]
                [isset($options['action']) ? $options['action'] : $ACTION];
        
        if (LOCALIZATION === true)
            $uri = '/' . (isset($options['locale'])
                ? $options['locale'] : $LOCALE[0]).$ROUTES[$options['name']][0];
        else
            $uri = $ROUTES[$options['name']][0];
        
        if (isset($options['anchor']))
            $uri .= '#' . $options['anchor'];
        
        if (isset($options['params']))
        {    
            if (isset($ROUTES[$options['name']]['pp']))
            {
                if ((array) $options['params'] !== $options['params'])
                {
                    $uri = str_replace(
                        ':' . $ROUTES[$options['name']]['pp'][0],
                        $options['params'],
                        $uri
                    );
                    unset($options['params']);
                }    
                else
                {
                    foreach ($ROUTES[$options['name']]['pp'] as $i => $pp)
                    {
                        if (isset($options['params'][$i]))
                        {
                            $uri = str_replace(":$pp", $options['params'][$i],
                                $uri);
                            unset($options['params'][$i]);
                        }
                        elseif (isset($options['params'][$pp]))
                        {
                            $uri = str_replace(":$pp", $options['params'][$pp],
                                $uri);
                            unset($options['params'][$pp]);
                        }
                    }
                }
            }
            if (!empty($options['params']))
                $uri .= '?' . http_build_query($options['params']);
        }
        
        if (isset($options['ssl']))
            return ($options['ssl'] ? SSL_URL : HTTP_URL) . $uri;
        elseif (isset($ROUTES[$options['name']]['ssl']))
            return ($ROUTES[$options['name']]['ssl'] ? SSL_URL : HTTP_URL).$uri;
        
        return HTTP_URL . $uri;
    }
    
    /**
     * Loads the modules listed in the argument list.
     *
     * <code>
     * modules('tags', 'activerecord');
     * </code>
     *
     * @param string ... Variable-length list of module names
     * @author Szymon Wrozynski
     */
    function modules(/*...*/)
    {
        foreach (func_get_args() as $m)
            require_once MODULES . $m . '.php';
    }

    /**
     * Reads or writes the instant message stored in the session. 
     * Once read it is discarded upon the next request. 
     * The message is stored under the given name.
     *
     * This function requires session to be enabled.
     * 
     * Examples:
     *
     * <code>
     * flash('notice', 'This is a notice.'); # saves the message
     * </code>
     *
     * <code>
     * echo flash('notice'); # gets the message - now it is marked as read
     * </code>
     *
     * @param string $name Message name
     * @param mixed $message Message (for writing) or null (for reading)
     * @return mixed Message (if reading) or null (if writing)
     * @author Szymon Wrozynski
     */
    function flash($name, $message=null)
    {   
        if ($message !== null)
            $_SESSION['__PRAGWORK_10_FLASH'][$name] = array($message, false);
        elseif (isset($_SESSION['__PRAGWORK_10_FLASH'][$name])) 
        {
            $_SESSION['__PRAGWORK_10_FLASH'][$name][1] = true;
            return $_SESSION['__PRAGWORK_10_FLASH'][$name][0];
        }
    }
    
    /**
     * Sends the HTTP error 403 - Forbidden. It renders the 403.php file from
     * the 'errors' directory and stops other processing. It is used if, for
     * example, a plain HTTP request was made to action required SSL protocol.
     *
     * @param bool $stop If true stops further execution and throws an exception
     * @throws {@link \Application\StopException} If true passed (default)
     * @author Szymon Wrozynski
     */
    function send_403($stop=true)
    {
        header('HTTP/1.1 403 Forbidden');
        require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors'
            . DIRECTORY_SEPARATOR . '403.php';
        if ($stop)
            throw new \Application\StopException;
    }

    /**
     * Sends the HTTP error 404 - Not Found. It renders the 404.php file from
     * the 'errors' directory and stops other processing. It is used if, for
     * example, a request was made to an unknown resource.
     *
     * @param bool $stop If true stops further execution and throws an exception
     * @throws {@link \Application\StopException} If true passed (default)
     * @author Szymon Wrozynski
     */
    function send_404($stop=true)
    {
        header('HTTP/1.1 404 Not Found');
        require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors' 
            . DIRECTORY_SEPARATOR . '404.php';
        if ($stop)
            throw new \Application\StopException;
    }

    /**
     * Sends the HTTP error 405 - Method Not Allowed. It renders the 405.php 
     * file from the 'errors' directory and stops other processing. It is used
     * if, for example, a request was made to the known resource but using 
     * a wrong HTTP method.
     *
     * @param bool $stop If true stops further execution and throws an exception
     * @throws {@link \Application\StopException} If true passed (default)
     * @author Szymon Wrozynski
     */
    function send_405($stop=true)
    {
        header('HTTP/1.1 405 Method Not Allowed');
        require APPLICATION_PATH . DIRECTORY_SEPARATOR . 'errors' 
            . DIRECTORY_SEPARATOR . '405.php';
        if ($stop)
            throw new \Application\StopException;
    }
    
    /**
     * Translates the given key according to the current locale loaded. 
     * If the translation was not found the given key is returned back.
     *
     * The key can be a string but it is strongly advised not to use
     * the escape characters like \ inside though it is technically possible. 
     * Instead, use double quotes to enclose single quotes and vice versa. 
     * This will help the <b>prag</b> tool to recognize such keys and maintain
     * locale files correctly. Otherwise, you will have to handle such keys by
     * hand. The same applies to compound keys evaluated dynamically.
     *
     * <code>
     * t('Editor\'s Choice');   # Avoid!
     * t($editor_msg);          # Avoid!
     * t("Editor's Choice");    # OK
     * </code>
     *
     * Pragwork requires the first entry (0th index) in the locale file
     * array contains the locale code therefore, by specifying <code>t(0)</code> 
     * or just <code>t()</code>, the current locale code is returned.
     * Also, if there is no locale loaded yet this will return 0 (the passed or
     * implied locale key). Such test against 0 (int) might be helpful while
     * translating and customizing error pages, where there is no certainty
     * that the locale code was parsed correctly (e.g. a 404 error).
     *
     * @param mixed $key Key to translation (string) or 0 (default)
     * @return string Localized text or the locale code (if 0 passed)
     * @author Szymon Wrozynski
     */
    function t($key=0)
    {
        global $LOCALE;
        return isset($LOCALE[$key]) ? $LOCALE[$key] : $key;
    }
    
    /**
     * Returns the array of strings with available locale codes based on
     * filenames found in the 'locales' directory. Filenames starting with
     * a dot <b>.</b> are omitted.
     *
     * @return array Available locale codes as strings in alphabetical order
     * @author Szymon Wrozynski
     */
    function locales()
    {
        static $locales;
        
        if (isset($locales))
            return $locales;
        
        $locales = array();
        $handler = opendir(LOCALES);
        
        while (false !== ($file = readdir($handler)))
        {
            if ($file[0] !== '.')
                $locales[] = substr($file, 0, -4);
        }
        
        closedir($handler);
        
        sort($locales);
        return $locales;
    }
}
?>'''), STRIP_PHPDOC)

def make_tags_module(work):    
    write(os.path.join(work, 'modules', 'tags.php'), R'''<?php
/**
 * Tags Module 1.0 for Pragwork %s
 *
 * @copyright %s
 * @license %s
 * @version %s
 * @package Tags
 */
''' % (__pragwork_version__, __author__, __license__, __pragwork_version__) 
    + __strip_phpdoc(R'''
namespace
{
    /**
     * Creates the <a> tag from the passed text and options. 
     * The text is used as the inner text of the link. It might be a plain text
     * or other HTML code. The options are used to construct the URL for the
     * link (see {@link url_for} for syntax details). All other options left are 
     * appended to the constructed tag as its attributes.
     *
     * <code>
     * echo link_to('link 1', 'index');
     *
     * # <a href="http://www.mydomain.com/shop/index">link 1</a>;
     *
     * echo link_to('link 2', array(
     *     'action' => 'add', 
     *     'controller' => 'Shop', 
     *     'anchor' => 'foo', 
     *     'class' => 'my-link'
     * ));
     *
     * # <a href="http://www.mydomain.com/shop/add#foo" class="my-link">
     * # link 2</a>
     * </code>
     *
     * @see link_to_url
     * @see url_for
     * @param string $text Inner text of the link
     * @param mixed $options Options for URL and attributes
     * @return string <a> HTML tag
     * @author Szymon Wrozynski
     */
    function link_to($text, $options=array())
    {
        if ((array) $options !== $options)
            return link_to_url($text, url_for($options));
        
        $url = url_for($options);
        
        unset(
            $options['params'], 
            $options[0],
            $options['name'],
            $options['ssl'], 
            $options['anchor'],
            $options['locale'],
            $options['action'], 
            $options['controller']
        );
        
        return link_to_url($text, $url, $options);
    }
    
    /**
     * Creates the <a> tag from the passed text, URL, and options. 
     * The text is used as the inner text of the link. It might be a plain text
     * or other HTML code. The URL is placed in the 'href' attribute. 
     * Options are appended to the constructed tag as its attributes.
     *
     * <code>
     * echo link_to_url('Pragwork', 'http://pragwork.com');
     *
     * # <a href="http://pragwork.com">Pragwork</a>
     *
     * echo link_to_url('Pragwork', 'http://pragwork.com', array(
     *     'class' => 'my-link'
     * ));
     *
     * # <a href="http://pragwork.com" class="my-link">Pragwork</a>
     * </code>
     *
     * @see link_to
     * @param string $text Inner text of the link
     * @param string $url URL used to create the hiperlink
     * @param array $options Attributes
     * @return string <a> HTML tag
     * @author Szymon Wrozynski
     */
    function link_to_url($text, $url, $options=array())
    {
        $html = '<a href="' . $url . '"';
        
        foreach ($options as $n => $v)
            $html .= ' ' . $n . '="' . $v . '"';
        
        return $html . '>' . $text . '</a>';
    }
    
    /**
     * Creates the one button form (An <input> tag enclosed in a
     * <form>). The text is used as the value of the button.
     * The options are used to construct the URL for the
     * link (see {@link url_for} for syntax details). 
     * However, there are special options:
     * 
     * <ul>
     * <li><b>method</b>: HTTP method for the form (default: POST)</li>
     * <li><b>confirm</b>: confirmation message (default: null)</li>
     * <li><b>hidden_fields</b>: (array) adds hidden fields to the form</li>
     * </ul>
     *
     * If the HTTP GET method is used then all query parameters are abandoned
     * because the new query string is created automatically from form fields
     * upon form sending. Therefore you should specify custom parameters as
     * 'hidden_fields' in such case.
     *
     * All other options left are appended to the <input> tag as its
     * attributes. The possible confirm message is used to construct a
     * javascript confirm dialog. All quotes in the message are safely encoded.
     *
     * The <form> tag has a special class - 'button-to'. The <input>
     * can have the class defined explicitly in the options.
     * 
     * <code>
     * echo button_to('button 1', 'index');
     *
     * # <form class="button-to" action="http://www.mydomain.com/shop/index"
     * # method="post"><input type="submit" 
     * # value="button 1" /></form>
     * 
     * echo button_to('button 2', array(
     *     'action' => 'add', 
     *     'controller' => 'Shop',  
     *     'method' => 'get',
     *     'class' => 'my-button'
     * ));
     *
     * # <form class="button-to" action="http://www.mydomain.com/shop/add"
     * # method="get"><input type="submit" value="button 2"
     * # class="my-button"/></form>
     *
     * echo button_to('button 3', array('delete', 'params' => array(':id' => 3),
     *     'confirm' => 'Are you sure?'));
     *
     * # <form class="button-to"
     * # action="http://www.mydomain.com/shop/delete/3" method="post"
     * # onSubmit="return confirm('Are you sure?');">
     * # <input type="submit" value="button 1" /></form>
     * </code>
     *
     * @see button_to_url
     * @see url_for
     * @param string $text Value of the <submit> tag
     * @param mixed $options Options for URL and attributes
     * @return string One button <form> tag
     * @author Szymon Wrozynski
     */
    function button_to($text, $options=array())
    {
        if ((array) $options !== $options)
            return button_to_url($text, url_for($options));
        
        $url = url_for($options);
        
        unset(
            $options['params'], 
            $options[0],
            $options['name'],
            $options['ssl'], 
            $options['anchor'],
            $options['locale'],
            $options['action'], 
            $options['controller']
        );
        
        return button_to_url($text, $url, $options);
    }
    
    /**
     * Creates the one button form (An <input> tag enclosed in a
     * <form>). The text is used as the value of the button.
     * The URL serves as the form action. There are special options:
     * <b>method</b>, <b>confirm</b>, and <b>hidden_fields</b> described here:
     * {@link button_to}. Other options are appended to the <input> tag 
     * as its attributes.
     *
     * @see button_to
     * @see link_to_url
     * @param string $text Value of the button
     * @param string $url Form action
     * @param array $options Options and attributes
     * @return string One button <form> tag
     * @author Szymon Wrozynski
     */
    function button_to_url($text, $url, $options=array())
    {
        $form = '<form class="button-to" action="' . $url . '" method="';
        
        if (isset($options['method']))
        {
            $form .= $options['method'];
            unset($options['method']);
        }
        else
            $form .= 'post';
        
        if (isset($options['confirm']))
        {
            $form .= '" onSubmit="return confirm(\'' 
                . str_replace(
                    array('\'', '"'), 
                    array('\\x27', '\\x22'), 
                    $options['confirm']
                ) . '\');';
            
            unset($options['confirm']);
        }
        
        $form .= '">';
        
        if (isset($options['hidden_fields']))
        {
            foreach ($options['hidden_fields'] as $n => $v)
                $form .= '<input type="hidden" name="' . $n . '" value="' 
                    . $v . '" />';
            unset($options['hidden_fields']);
        }
        
        $form .= '<input type="submit" value="' . $text . '" ';
        
        foreach ($options as $n => $v)
            $form .= $n . '="' . $v . '" ';
        
        return $form . '/></form>';
    }
    
    /**
     * Creates a form for a model. The model might be an object (usually 
     * {@link ActiveRecord\Model} or {@link ActiveRecord\TablelessModel} 
     * instance), an array, or a null value. If the array is passed it is
     * automatically cast to an object (stdClass). Although the model is not
     * necessary, the form can work with it internally if present. Also, model
     * values are present in form fields and as form properties.
     *
     * The options are used to construct a form action URL (see {@link url_for}
     * for syntax details). The closure should be a function with one 
     * or two arguments. The first parameter is the {@link Tags\Form} instance.
     * The second one is the instance of current controller. That way you can
     * make the controller context ($this) available inside the closure.
     * All other options are parsed as the <form> tag attributes. 
     * By default, the form method is equal to 'post' and the 'accept-charset'
     * is set to 'utf-8'.
     * 
     * The form body is constructed within the $closure function and it 
     * uses an instance of the helper class {@link Tags\Form}.
     *
     * <code>
     * <?php echo form_for($this->person, 'update', function($f) { ?>
     *
     * <p>
     *     <?php echo $f->label('name', 'Name') ?>
     *     <?php echo $f->text_field('name', array('size' => 60)) ?>
     *     <?php echo $f->error_messages('name', array('wrap_in' => 'p', 
     *         'class' => 'error')) ?>
     * </p>
     *
     * <p>
     *     <?php echo $f->submit('Save', array('class' => 'button')) ?>
     * </p>
     *
     * <?php }) ?>
     * </code>
     *
     *
     * Example with two parameters used in the closure:
     *
     * <code>
     * <?php echo form_for(null, 'search', function($f, $that) { ?>
     *     <p>Last search: <?php echo $that->session->last_search ?></p>
     *     <p><?php echo $f->text_field('q') ?></p>
     * <?php }) ?>
     * </code>
     *
     * @see ActiveRecord\Model
     * @see ActiveRecord\TablelessModel
     * @see Tags\Form
     * @see form_for_url
     * @param mided $model Model corresponding with the form or null
     * @param mixed $options Array or string used to construct the form action
     * @param \Closure $closure Form body constructing closure
     * @return string <form> HTML tag
     * @author Szymon Wrozynski
     */
    function form_for($model, $options, $closure)
    {
        if ((array) $options !== $options)
            return form_for_url($model, url_for($options), null, $closure);
        
        $url = url_for($options);
        
        unset(
            $options['params'], 
            $options[0],
            $options['name'],
            $options['ssl'], 
            $options['anchor'],
            $options['locale'],
            $options['action'], 
            $options['controller']
        );
        
        return form_for_url($model, $url, $options, $closure);
    }
    
    /**
     * Creates a form for a model. The model might be an object (usually 
     * {@link ActiveRecord\Model} or {@link ActiveRecord\TablelessModel} 
     * instance), an array, or a null value. If the array is passed it is
     * automatically cast to an object (stdClass). Although the model is not
     * necessary, the form can work with it internally if present. Also, model
     * values are present in form fields and as form properties. 
     * The URL is used as the form action.
     *
     * @see form_for
     * @param mixed $model Model corresponding with the form or null
     * @param string $url Form action
     * @param mixed $options Form attributes or null to use default ones
     * @param \Closure $closure Form body constructing closure
     * @return string <form> HTML tag
     * @author Szymon Wrozynski
     */
    function form_for_url($model, $url, $options, $closure)
    {   
        $html = '<form action="' . $url . '"';
        
        if (isset($options['confirm']))
        {
            $html .= ' onSubmit="return confirm(\'' 
                . str_replace(
                    array('\'', '"'), 
                    array('\\x27', '\\x22'), 
                    $options['confirm']
                ) . '\');"';
            unset($options['confirm']);
        }
            
        if (!isset($options['method']))
            $html .= ' method="post"';
            
        if (!isset($options['accept-charset']))
            $html .= ' accept-charset="utf-8"';
        
        if ($options)
        {
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
        }
        
        ob_start();
        $closure(new Tags\Form($model), Application\Controller::instance());
        return $html . '>' . ob_get_clean() . '</form>';
    }
    
    /**
     * Creates a 'mailto' link for the specified email and options. 
     * The following options are available:
     *
     * <ul>
     * <li><b>text</b>: The text to be displayed within the created 
     *     hyperlink. If not specified, the $email will be used.</li>
     * <li><b>replace_at</b>: sets a replacement for the '@' sign, 
     *     to obfuscate the email address displayed if there is no custom text
     *     for the link</li>
     * <li><b>replace_dot</b>: same as above but obfuscates all dots in the 
     *     email address</li>
     * <li><b>subject</b>: sets the subject line of the email</li>
     * <li><b>body</b>: sets the body of the email</li>
     * <li><b>cc</b>: sets Carbon Copy recipients on the email</li>
     * <li><b>bcc</b>: sets Blind Carbon Copy recipients on the email</li>
     * </ul>
     *
     * Other options are appended to the <a> tag as its attributes.
     *
     * @see link_to_url
     * @param string $email Email address to use
     * @param array $options Options and attributes
     * @return string <a> tag with a 'mailto' reference
     * @author Szymon Wrozynski
     */
    function mail_to($email, $options=array())
    {
        if (isset($options['text']))
        {
            $text = $options['text'];
            unset($options['text']);
        }
        else
        {
            $text = $email;
            
            if (isset($options['replace_at']))
            {
                $text = str_replace('@', $options['replace_at'], $text);
                unset($options['replace_at']);
            }
            
            if (isset($options['replace_dot']))
            {
                $text = str_replace('.', $options['replace_dot'], $text);
                unset($options['replace_dot']);
            }
        }
        
        $params = array();
        
        if (isset($options['subject']))
        {
            $params['subject'] = $options['subject'];
            unset($options['subject']);
        }
        
        if (isset($options['body']))
        {
            $params['body'] = $options['body'];
            unset($options['body']);
        }
        
        if (isset($options['cc']))
        {
            $params['cc'] = $options['cc'];
            unset($options['cc']);
        }
        
        if (isset($options['bcc']))
        {
            $params['bcc'] = $options['bcc'];
            unset($options['bcc']);
        }
        
        $url = 'mailto:' . $email;
        
        if ($params)
            $url .= '?' .  str_replace('+', '%20', http_build_query($params));
        
        return link_to_url($text, $url, $options);    
    }
    
    /**
     * Returns the <img> tag with the URL to the static image according 
     * to file specified as the parameter. If the $file starts with ('/') it
     * is treated as it would reflect the public directory structure. 
     * Otherwise, the file is get along to the IMAGES_PATH constant defined in
     * the 'index.php' file. The path defined there can be a local public
     * directory like '/images' or even a standalone server  
     * (e.g. 'http://static.mydomain.com/images'). Also the $file can be an 
     * independent full URL address:
     *
     * <code>
     * <?php echo image_tag('http://static.mydomain.com/images/my_logo.png') ?>
     * </code>
     *
     * @see url_for
     * @param string $file Image file name or path
     * @param array $options HTML attributes appended to the <img> tag
     * @return string <img> HTML tag
     * @author Szymon Wrozynski
     */
    function image_tag($file, $options=array())
    {
        $html = '<img src="' . Tags\_asset_url(IMAGES_PATH, $file) . '"';
        
        foreach ($options as $n => $v)
            $html .= ' '. $n . '="' . $v . '"';
        
        return $html . ' />';
    }
    
    /**
     * Returns the <link> tag with the URL to the CSS file according 
     * to specified parameter. If the $file starts with ('/') it is
     * treated as it would reflect the public directory structure.
     * Otherwise the file is get along to the STYLESHEETS_PATH constant defined
     * in the 'index.php' file. The path defined there can be a local public
     * directory like '/stylesheets' or even a standalone server 
     * (e.g. 'http://static.mydomain.com/stylesheets').
     *
     * @see url_for     
     * @param string $file CSS file name or path
     * @param array $options HTML attributes appended to the <link> tag
     * @return string <link> HTML tag
     * @author Szymon Wrozynski
     */
    function stylesheet_link_tag($file, $options=array())
    {       
        $html = '<link rel="stylesheet" href="'
            . Tags\_asset_url(STYLESHEETS_PATH, $file) . '"';
            
        if (!isset($options['type']))
            $html .= ' type="text/css"';
        
        if (!isset($options['media']))
            $html .= ' media="screen"';
                    
        foreach ($options as $n => $v)
            $html .= ' ' . $n . '="' . $v . '"';
        
        return $html . ' />';
    }
    
    /**
     * Returns the <script> tag with the URL to the javascript file 
     * according to specified parameter. If the $file starts with ('/') it
     * is treated as it would reflect the public directory structure.
     * Otherwise the file is get along to the JAVASCRIPTS_PATH constant defined
     * in the 'index.php' file. The path defined there can be a local public
     * directory like '/javascripts' or even a standalone server 
     * (e.g. 'http://static.mydomain.com/javascripts').
     *
     * @see url_for     
     * @param string $file Javascript file name or path
     * @param array $options HTML attributes appended to the <script> tag
     * @return string <script> HTML tag
     * @author Szymon Wrozynski
     */
    function javascript_include_tag($file, $options=array())
    {
        $html = '<script src="' . Tags\_asset_url(JAVASCRIPTS_PATH, $file) .'"';
            
        if (!isset($options['type']))
            $html .= ' type="text/javascript"';
        
        if (!isset($options['charset']))
            $html .= ' charset="utf-8"';
                    
        foreach ($options as $n => $v)
            $html .= ' ' . $n . '="' . $v . '"';
        
        return $html . '></script>';
    }
}

namespace Tags
{
    /**
     * Internal function for assets URL resolving.
     *
     * @internal This function should not be used explicitly! Internal use only.    
     * @param string $static Static asset path
     * @param mixed $asset Requested asset
     * @return string URL to the asset
     * @author Szymon Wrozynski
     */
    function _asset_url($static, $asset)
    {
        if ($asset[0] === '/')
            return url_for($asset);
        
        if (strpos($asset, '://') !== false) 
            return $asset;
        
        return ($static[0] === '/') 
            ? url_for($static . '/' . $asset)
            : $static . '/' . $asset;
    }
    
    /**
     * The helper class used inside the form body building closure of the 
     * {@link form_for} function. It serves as a container of functions creating
     * fields of the form as well as a wrapper of the attached model. All public 
     * properties of the model are available as properties of the form class.
     * Also, all form methods are aware of corresponding model values. 
     *
     * @see form_for
     * @author Szymon Wrozynski
     */
    final class Form
    {
        private $_model;
        
        /**
         * The default constructor. The model might be an object, an array, or a 
         * null. If the array is passed it is automatically cast to an object.
         *
         * @param mixed $model Model passed to the {@link form_for} function
         */
        public function __construct($model=null)
        {
            if ($model)
                $this->_model = ((array) $model === $model)
                    ? (object) $model
                    : $model;
        }
        
        /**
    	 * Sets a model property (if a model has been attached).
    	 *
    	 * @param string $name Name of the property
    	 * @param mixed $value Property value
    	 */
    	public function __set($name, $value)
    	{
    	    if ($this->_model)
    	        $this->_model->$name = $value;
    	}

    	/**
    	 * Gets a model property (if a model has been attached).
    	 *
    	 * @param string $name Name of the property
    	 * @return mixed Model property or null
    	 */
    	public function __get($name)
    	{
            return ($this->_model) ? $this->_model->$name : null;
    	}
    	
    	/**
    	 * Returns a model reference.
    	 *
    	 * @return mixed Reference to the attached model (or null)
    	 */
    	public function &model()
    	{
    	    return $this->_model;
    	}
        
        /**
         * Returns <b>true</b> if there are any error messages in the model
         * for the specified field or for all fields (if none given).
         *
         * @param mixed $name Field name or e.g. null for all fields
         * @return bool True if there are error messages or false otherwise
         */
        public function is_error($name=null)
        {
            return $name 
                ? $this->_model && $this->_model->errors 
                    && $this->_model->errors->$name
                : $this->_model && $this->_model->errors 
                    && !$this->_model->errors->is_empty();
        }

        /**
         * Returns error messages after the form validation for the given 
         * field name or for all fields if no name was passed. If there are no
         * errors the null is returned. It works with ActiveRecord validation
         * engine and expects ActiveRecords\Errors object to be present in the
         * model.
         *
         * The following options are available:
         *
         * <ul>
         * <li><b>separator</b>: separator between a displayed name
         *     and a message. If empty, the field names in the constructed
         *     messages are omitted. Otherwise field names optionally translated
         *     are used.  Default: ' '</li>
         * <li><b>wrap_in</b>: name of the enclosing tag</li>
         * <li><b>localize</b>: <b>true</b>/<b>false</b> to explicitly turn 
         *     on/off localization</li>
         * </ul>
         *
         * If the 'wrap_in' is not present then error messages are separated
         * with a dot. If localization is turned on, the message and name are
         * translated separately.
         *
         * All other options are appended to the enclosing tag as attributes.
         *
         * @param mixed $name Field name or e.g. null for all fields
         * @param array $options Formatting options
         * @return string Error messages or HTML tag(s)
         */
        public function error_messages($name, $options=array())
        {
            if ($this->_model && $this->_model->errors)
            {
                $localize = isset($options['localize'])
                    ? $options['localize'] : (LOCALIZATION !== false);
                
                $separator = isset($options['separator'])
                    ? $options['separator'] : ' ';
                
                if ($name)
                {
                    $error_messages = $this->_model->errors->$name;
                
                    if (!$error_messages)
                        return;
                                
                    if ($separator)
                        $name = $localize 
                            ? t($name) : ucfirst(str_replace('_', ' ', $name));
                    else
                        $name = '';
                    
                    foreach ($error_messages as &$em)
                        $em = $name . $separator . ($localize ? t($em) : $em);
                }
                else
                    $error_messages = $this->_model->errors->full_messages(
                        $separator, $localize);
                
                if (isset($options['wrap_in']))
                {
                    $tag_opening = '<' . $options['wrap_in'];
                    $tag_close = '</' . $options['wrap_in'] . '>'; 
                    
                    unset(
                        $options['wrap_in'], 
                        $options['localize'], 
                        $options['separator']
                    );
                    
                    foreach ($options as $n => $v) 
                        $tag_opening .= ' ' . $n . '="' . $v . '"';
                    
                    $tag_opening .= '>';
                    
                    $html = '';
                    
                    foreach ($error_messages as $msg)
                        $html .= $tag_opening . $msg . $tag_close;
                    
                    return $html;
                }
                else
                    return implode('. ', $error_messages);
            }
        }
        
        /**
         * Creates the <label> tag for the given field name. It uses
         * localization or simple name humanization if no value supplied.
         * 
         * @param string $name Field name
         * @param string $value Label value
         * @param array $options Formatting options
         * @return string <label> HTML tag
         */
        public function label($name, $value=null, $options=array())
        {
            $html = '<label';
            
            if ($value === null) 
                $value = (LOCALIZATION !== false)
                    ? t($name) : ucfirst(str_replace('_', ' ', $name));
            
            if (!isset($options['for']))
                $html .= ' for="' . $name . '-field"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . '>' . $value . '</label>';
        }

        /**
         * Creates the <select> tag for the given field name. 
         * The passed $collection is an array of possible select values. 
         * The array may contain objects and/or key-value pairs, or just 
         * strings (strings will be used both as keys and values). 
         * For objects it is possible to set property names for the option text
         * and value or even more specified closures.
         *
         * Formatting options:
         *
         * <ul>
         * <li><b>option_text</b>: property name or a closure</li>
         * <li><b>option_value</b>: property name or a closure</li>
         * <li><b>selected</b>: closure comparing the current value and the
         *     model</li>
         * <li><b>blank</b>: special blank option value</li>
         * </ul> 
         *
         * The <b>option_text</b> and <b>option_value</b> might be property
         * names or anonymous functions which transform an object from 
         * the $collection into the option text or value:
         *
         * <code>
         * $f->select('person', $this->persons, array('option_text' =>
         *     function($p) { return $p->first_name . ' ' . $p->last_name; }));
         * </code>
         *
         * The default value for <b>option_text</b> is 'name' and for 
         * <b>option_value</b> - 'id'.
         *
         * The <b>selected</b> could be a closure of form: 
         * <code> 
         * bool function($model, $value)
         * </code>
         *
         * The default closure used looks similarily to this one: 
         *
         * <code>
         * function($model, $value) use ($name) 
         * {
         *     return $model && $model->$name == $value;
         * }
         * </code>
         *  
         * The <b>blank</b> option could be: 
         * 
         * <code>
         * $f->select('opt', $this->options, array('blank' => array(
         *     'Please choose a value' => 0
         * )));
         * </code>
         *
         * Other options are appended as the <select> tag attributes.
         *
         * @param string $name Field name
         * @param string $collection Possible selectable options
         * @param array $options Formatting options
         * @return string <select> HTML tag
         */
        public function select($name, $collection, $options=array())
        {
            $html = '<select name="' . $name . '"';
            
            if (!isset($options['id'])) 
                $html . ' id="' . $name . '-field"';
            
            if (isset($options['option_text'])) 
            {
                $option_text = $options['option_text'];
                unset($options['option_text']);
            } 
            else 
                $option_text = 'name';
            
            if (isset($options['option_value'])) 
            {
                $option_value = $options['option_value'];
                unset($options['option_value']);
            }
            else 
                $option_value = 'id';
                
            if (isset($options['selected']))
            {
                $selected_closure = $options['selected'];
                unset($options['selected']);
            }
            else
            {
                $selected_closure = function($model, $value) use ($name) 
                {
                    return $model && $model->$name == $value;
                };
            }
            
            if (isset($options['blank']))
            {
                if ((array) $options['blank'] === $options['blank'])
                    $collection = array_merge($options['blank'], $collection);
                else
                    array_unshift($collection, $options['blank']);
                
                unset($options['blank']);
            }
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            $html .= '>';
            
            foreach ($collection as $n => $v) 
            {
                if ((object) $v === $v)
                {
                    $n = ((string) $option_text === $option_text)
                        ? $v->$option_text : $option_text($v);
                    $v = ((string) $option_value === $option_value)
                        ? $v->$option_value : $option_value($v);
                }
                elseif ((int) $n === $n)
                    $n = $v;
                
                $html .= '<option value="' . $v . '"';
                
                if ($selected_closure($this->_model, $v))
                    $html .= ' selected="selected"';
                
                $html .= '>' . $n . '</option>';
            }
            
            return $html . '</select>';
        }

        private function checked_input($name, $options) 
        {
            $html = '<input name="' . $name . '"';
            
            if (!isset($options['id']))
                $html .= ' id="' . $name . '-field"';
            
            if (!isset($options['value'])) 
                $options['value'] = 1;
            
            if (isset($options['checked'])) 
            {
                if ($options['checked'])
                    $html .= ' checked="checked"';
                
                unset($options['checked']);
            } 
            elseif ($this->_model && ($this->_model->$name ==$options['value']))
                $html .= ' checked="checked"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
                
            return $html . ' />';
        }

        /**
         * Creates the <input> radio tag for the given field name. 
         * The options serve as tag attributes. The default 'name' attribute 
         * is set to the field name, the default value is set to 1. 
         * The 'checked' attribute can be set explicitly or estimated from 
         * the comparision of the model field ($name) and the value.
         *
         * @see check_box
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <input> radio button
         */
        public function radio_button($name, $options=array()) 
        {
            $options['type'] = 'radio';
            return $this->checked_input($name, $options);
        }
        
        /**
         * Creates the <input> check box tag for the given field name. 
         *
         * Formatting options:
         *
         * <ul>
         * <li><b>unchecked</b>: value of the unchecked box</li>
         * </ul>
         *
         * There is a hidden field put before the the check box containing
         * the value of the <b>unchecked</b> option. If the check box is not
         * checked, the hidden field value is sent instead of nothing.
         * If the <b>unchecked</b> option is not present then it is implicitly
         * set to 0. If the <b>unchecked</b> is set to <b>false</b> then no
         * hidden field prepends the check box tag.
         *
         * The other options serve as attributes. The default 'name' attribute 
         * is set to the field name, the default value is set to 1. 
         * The 'checked' attribute can be set explicitly or estimated from 
         * the comparision of the model field ($name) and the value.
         *
         * @see radio_button
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <input> check box
         */
        public function check_box($name, $options=array())
        {
            $options['type'] = 'checkbox';

            if (isset($options['unchecked']))
            {   
                $hidden = ($options['unchecked'] === false)
                    ? '' 
                    : $this->hidden_field(
                        $name, 
                        array('value' => $options['unchecked'])
                    );
                
                unset($options['unchecked']);
                return $hidden . $this->checked_input($name, $options);
            }
            else
                return $this->hidden_field($name, array('value' => 0))
                    . $this->checked_input($name, $options);
        }
        
        /**
         * Creates the <textarea> tag for the given field name. 
         * The options serve as tag attributes. The default 'name' attribute 
         * is set to the field name as well as the 'id' one. 
         *
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <textarea> HTML tag
         */
        public function text_area($name, $options=array()) 
        {
            $html = '<textarea name="' . $name . '"';
                
            if (!isset($options['id']))
                $html .= ' id="' . $name . '-field"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . '>' . htmlspecialchars($this->_model->$name) 
                . '</textarea>';
        }
        
        /**
         * Creates the <input> file tag for the given field name. 
         * The options serve as tag attributes. The default 'name' attribute 
         * is set to the field name as well as the 'id' one. 
         *
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <input> file HTML tag
         */
        public function file_field($name, $options=array())
        {
            $html = '<input type="file" name="' . $name . '"';
                
            if (!isset($options['id']))
                $html .= ' id="' . $name . '-field"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
                
            return $html . ' />';
        }
        
        private function valued_input($name, $options)
        {
            $html = '<input name="' . $name . '"';
            
            if (!isset($options['id']))
                $html .= ' id="' . $name . '-field"';
            
            if (!isset($options['value']) && $this->_model)
                $html .= ' value="' .htmlspecialchars($this->_model->$name).'"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . ' />';
        }
        
        /**
         * Creates the <input> hidden tag for the given field name. 
         * The options serve as tag attributes. The default 'name' attribute 
         * is set to the field name as well as the 'id' one. The 'value' is set
         * to the field name by default.
         *
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <input> hidden tag
         */
        public function hidden_field($name, $options=array())
        {
            $options['type'] = 'hidden';
            return $this->valued_input($name, $options);
        }
        
        /**
         * Creates the <input> text tag for the given field name. 
         * The options serve as tag attributes. The default 'name' attribute 
         * is set to the field name as well as the 'id' one. The 'value' is set
         * to the field name by default.
         *
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <input> text tag
         */
        public function text_field($name, $options=array())
        {
            $options['type'] = 'text';
            return $this->valued_input($name, $options);
        }
        
        /**
         * Creates the <input> password tag for the given field name. 
         * The options serve as tag attributes. The default 'name' attribute 
         * is set to the field name as well as the 'id' one. The 'value' is set
         * to the field name by default.
         *
         * @param string $name Field name
         * @param array $options Formatting options
         * @return string <input> password tag
         */
        public function password_field($name, $options=array()) 
        {
            $options['type'] = 'password';
            return $this->valued_input($name, $options);
        }
        
        /**
         * Creates the <input> submit button. The options serve as tag
         * attributes. The 'value' is set to the given parameter value.
         *
         * @param string $value Submit button value
         * @param array $options Formatting options
         * @return string <input> submit button
         */
        public function submit($value, $options=array()) 
        {
            $html = '<input type="submit" value="' . $value . '"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . ' />';            
        }
        
        /**
         * Creates the <input> button tag. The options serve as tag
         * attributes. The 'value' is set to the given parameter value.
         *
         * @param string $value Button value
         * @param array $options Formatting options
         * @return string <input> button tag
         */
        public function button($value, $options=array())
        {
            $html = '<input type="button" value="' . $value . '"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . ' />';
        }
        
        /**
         * Creates the <input> image button tag. Options serve as tag
         * attributes. The image file is resolved in the same way as in the
         * {@link image_tag} function.
         *
         * @see image_tag
         * @param string $file Button image file
         * @param array $options Formatting options
         * @return string <input> image button tag
         */
        public function image($file, $options=array()) 
        {
            $html='<input type="image" src="'._asset_url(IMAGES_PATH,$file).'"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . ' />';
        }
        
        /**
         * Creates the <input> reset button tag. Options serve as tag
         * attributes. The 'value' is set to the given parameter value.
         *
         * @param string $value Button value
         * @param array $options Formatting options
         * @return string <input> reset button tag
         */
        public function reset($value, $options=array())
        {
            $html = '<input type="reset" value="' . $value . '"';
            
            foreach ($options as $n => $v)
                $html .= ' ' . $n . '="' . $v . '"';
            
            return $html . ' />';            
        }
    }
}
?>'''), STRIP_PHPDOC)

def make_paginate_module(work):
    write(os.path.join(work, 'modules', 'paginate.php'), R'''<?php
/**
 * Paginate Module 1.0 for Pragwork %s
 *
 * @copyright %s
 * @license %s
 * @version %s
 * @package Paginate
 */
''' % (__pragwork_version__, __author__, __license__, __pragwork_version__) 
    + __strip_phpdoc(R'''
/**
 * Splits the collection into smaller chunks and returns the chunk, 
 * its ordinal number (page) and the overall number of extracts (total pages).
 * 
 * <code>
 * list($people, $current_page, $total_pages) = paginate($all_people, 3, 10);
 * </code>
 * 
 * Creates the $people array containing 10 people max (if possible it would be
 * records 20 to 29 of the $all_people array) along with the $current_page and 
 * $total_pages variables. The $current_page it is not always the same as the 
 * passed $page parameter. If the passed $page parameter was lower than 1 
 * the $current_page is set to 1, and if the passed $page was greater than 
 * the greatest possible value, the $current_page is corrected accordingly.
 * The $total_pages is computed according to the $per_page parameter 
 * and the passed collection size.  
 *
 * @param array $collection Collection to split
 * @param int $page Ordinal number of the extract to return
 * @param int $per_page Extract size
 * @return array Array of the extract, current page, and total pages count
 * @author Szymon Wrozynski
 */
function paginate($collection, $page, $per_page)
{
    if ($page < 1)
        $page = 1;
    
    $size = count($collection);
    $total_pages = ($size > $per_page) ? intval(ceil($size / $per_page)) : 1;
    
    if ($page > $total_pages)
        $page = $total_pages;
    
    $start = $per_page * ($page - 1);
    
    return array(
        array_slice($collection, $start, $per_page), 
        $page, 
        $total_pages
    );
}
?>'''), STRIP_PHPDOC)


# Command-line parsing and dispatching #######################################

def get_fields(args):
    declarations = []
    nextAdToPrev = False
    for a in args:
        if a.endswith(':nullable'):
            nextAdToPrev = True
            declarations.append(a)
        elif nextAdToPrev:
            declarations[-1] += ' ' + a
            nextAdToPrev = False
        else:
            declarations.append(a)
    return [Field(decl) for decl in declarations]
    
def fix_colon(args):
    new_args = []
    for a in args:
        if len(new_args) > 0:
            if a.startswith(':'):
                new_args[-1] += a
                continue
            elif new_args[-1].endswith(':'):
                new_args[-1] += a
                continue
        new_args.append(a)
    return new_args

def fix_case(args):
    new_args = []
    for a in args:
        if a in ('GET', 'POST', 'PUT', 'DELETE'):
            new_args.append(a)
        else:
            new_args.append(__uncamelize(a))
    return new_args

def parse_overwriting(command):
    overwrite = command.endswith('!')
    if overwrite:
        return (overwrite, "Overwriting a ")
    else:
        return (overwrite, "Generating new ")

def print_routes_footnote():
    if not ((SSL or (len(EXT) > 0)) and ASTERISK_USED):
        return
    msg = "* "
    if SSL:
        msg += "SSL"
        if len(EXT) > 0:
            msg += " and the '" + EXT + "' extension have"
        else:
            msg += " has"
    else:
        msg += "The '" + EXT + "' extension has"
    msg += " been set"
    print msg
    
def print_no_phpdoc_footnote():
    if ASTERISK_USED and STRIP_PHPDOC:
        print "* PHPDoc has been excluded"

def main():
    print '''Prag %s
The Console Generator for Pragwork %s
%s
%s
''' % (__prag_version__, __pragwork_version__, __author__, __license__)
    
    argv = fix_case(fix_colon(sys.argv))
    
    if len(argv) > 2 and argv[1] == 'ssl':
        global SSL
        SSL = True
        del argv[1]
        
    if len(argv) > 2 and argv[1][0] == '.':
        global EXT
        EXT = argv[1]
        del argv[1]
        
    print_only = False
    
    if len(argv) == 1:
        print 'Type "prag help" for more info.'
        print_only = True
    elif (len(argv) == 2) and (argv[1] in ('help', 'h')):
        help()
        print_only = True
    elif (len(argv) in range(2, 4)) and (argv[1] == 'update'):
        print "Updating modules to Pragwork " + __pragwork_version__ + "...\n"
        if len(argv) == 3:
            if (argv[2] == 'nodoc'):
                global STRIP_PHPDOC
                STRIP_PHPDOC = True
            else:
                error("Unknown modifier: " + argv[2])
        work = os.getcwd()
        os.chdir('..')
        make_modules(work)
    elif (len(argv) >= 2) and (argv[1] in ('localize', 'l', 'localize!', 'l!')):
        overwrite, msg = parse_overwriting(argv[1])
        if len(argv) == 2:
            check_dir_exists('locales')
            locales = [l.split('.')[0] for l in os.listdir('locales') 
                if not l.startswith('.')]
        else:
            locales = argv[2:]
        if overwrite:
            msg = "Overwriting "
        else:
            msg = "Generating "
        msg += "localization files"
        if len(locales) > 0: msg += " (" + ", ".join(locales) + ")"
        print msg + "...\n"
        for l in locales:
            find_locale_keys_and_create_locale(l, overwrite)
    elif len(argv) == 2:
        error("Unknown command: " + argv[1])
    elif argv[1] == 'work':
        print "Generating new project structure (" + argv[2] + ")...\n"
        new_work(argv[2])
    elif argv[1] in ('controller', 'c'):
        path = os.path.join('app', 'Controllers', 
            __camelize(ensure_ident(argv[2])).replace('\\', os.path.sep)) \
            + 'Controller.php'
        actions_count = 0
        for m in argv[3:]:
            if not m in ('GET', 'POST', 'PUT', 'DELETE'):
                ensure_ident(m, True)
                actions_count += 1
        if os.path.exists(path):
            if actions_count > 1:
                print "Adding new actions to " + __camelize(argv[2]) \
                    + " controller...\n"
                comment = ['New actions of controller ' + __camelize(argv[2])]
            else:
                print "Adding a new action to " + __camelize(argv[2]) \
                    + " controller...\n"
                comment = ['New action of controller ' + __camelize(argv[2])]
            new_actions_with_methods(argv[2], argv[3:], comment)
        else:
            print "Generating new controller (" + __camelize(argv[2]) + ")...\n"
            new_controller(argv[2],argv[3:],['Controller '+__camelize(argv[2])])
    elif argv[1] in ('scaffold', 's', 'scaffold!', 's!'):
        overwrite, msg = parse_overwriting(argv[1])
        ns, name = __get_ns_and_name(ensure_ident(argv[2]))
        print msg + "scaffolding (for " + __camelize(name) + ")...\n"
        new_scaffolding(argv[2], get_fields(argv[3:]), overwrite)
    elif argv[1] in ('model', 'm', 'model!', 'm!'):
        overwrite, msg = parse_overwriting(argv[1])
        ns, name = __get_ns_and_name(ensure_ident(argv[2]))
        print msg + "model (" + __camelize(name) + ")...\n"
        new_model(argv[2], get_fields(argv[3:]), overwrite)
    elif argv[1] in ('form', 'f', 'form!', 'f!'):
        overwrite, msg = parse_overwriting(argv[1])
        ns, name = __get_ns_and_name(ensure_ident(argv[2]))
        print msg + "form (" + __camelize(name) + ")...\n"
        new_form(argv[2], get_fields(argv[3:]), overwrite)
    else:
        error("Unknown commands")
    
    if WRITE_MSG is not None: print
    if not (print_only or WRITE_MSG is not None):
        error("Nothing to write!")
    
    print_routes_footnote()
    print_no_phpdoc_footnote()

if __name__ == '__main__':
    sys.exit(main())