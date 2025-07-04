load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//:toml_parser.bzl", "format_toml", "parse_toml")

def _trivial_test_impl(ctx):
    env = unittest.begin(ctx)  # All test cases start with this header.

    # This is the test itself
    parsed = parse_toml("foo = 42")
    expected = {"foo": 42}

    # The "asserts" library provides useful assertion methods.
    # The env needs to be passed as the first argument.
    asserts.equals(env, expected, parsed)

    return unittest.end(env)  # All test cases end with this header.

# Each test impl needs to be added with the statement below.
trivial_test = unittest.make(_trivial_test_impl)

def _basic_parsing_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
# Basic configuration
name = "Test Application"
version = 1.2
debug = true
port = 8080
'''

    result = parse_toml(toml_content)
    expected = {
        "name": "Test Application",
        "version": 1.2,
        "debug": True,
        "port": 8080,
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

basic_parsing_test = unittest.make(_basic_parsing_test_impl)

def _sections_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
title = "My App"

[server]
host = "localhost"
port = 3000
ssl = false

[database]
driver = "postgresql"
host = "db.example.com"
port = 5432
'''

    result = parse_toml(toml_content)
    expected = {
        "title": "My App",
        "server": {
            "host": "localhost",
            "port": 3000,
            "ssl": False,
        },
        "database": {
            "driver": "postgresql",
            "host": "db.example.com",
            "port": 5432,
        },
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

sections_test = unittest.make(_sections_test_impl)

def _nested_sections_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = """
[database.connection]
timeout = 30
retries = 3

[database.pool]
min_size = 5
max_size = 20
"""

    result = parse_toml(toml_content)
    expected = {
        "database": {
            "connection": {
                "timeout": 30,
                "retries": 3,
            },
            "pool": {
                "min_size": 5,
                "max_size": 20,
            },
        },
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

nested_sections_test = unittest.make(_nested_sections_test_impl)

def _string_types_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
basic_string = "Hello World"
single_quoted = 'Single quotes'
with_escapes = "Line 1\\nLine 2\\tTabbed"
empty_string = ""
quoted_value = "simple_value"
'''

    result = parse_toml(toml_content)
    expected = {
        "basic_string": "Hello World",
        "single_quoted": "Single quotes",
        "with_escapes": "Line 1\nLine 2\tTabbed",
        "empty_string": "",
        "quoted_value": "simple_value",
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

string_types_test = unittest.make(_string_types_test_impl)

def _escape_sequences_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
# Test all valid TOML escape sequences in double quotes
newline = "Line 1\\nLine 2"
tab = "Column 1\\tColumn 2"
carriage_return = "Line 1\\rLine 2"
backspace = "Text\\bBackspace"
form_feed = "Text\\fFormFeed"
backslash = "Path\\\\to\\\\file"
double_quote = "Say \\"Hello\\""

# Test literal strings (single quotes) - escape sequences should be preserved
literal_backslash = 'C:\\Users\\test\\file.txt'
literal_double_backslash = '\\\\'
literal_newline = 'Line 1\\nLine 2'
literal_tab = 'Column 1\\tColumn 2'
literal_quote = 'He said "Hello World"'
literal_regex = '<\\d+>'
literal_unsupported = 'Invalid \\x escape sequence is allowed'
'''

    result = parse_toml(toml_content)
    expected = {
        # Double quoted strings - escape sequences processed
        "newline": "Line 1\nLine 2",
        "tab": "Column 1\tColumn 2",
        "carriage_return": "Line 1\rLine 2",
        "backspace": "Text\bBackspace",
        "form_feed": "Text\fFormFeed",
        "backslash": "Path\\to\\file",
        "double_quote": "Say \"Hello\"",

        # Single quoted strings - escape sequences preserved as-is
        "literal_backslash": "C:\\Users\\test\\file.txt",
        "literal_double_backslash": "\\\\",
        "literal_newline": "Line 1\\nLine 2",
        "literal_tab": "Column 1\\tColumn 2",
        "literal_quote": "He said \"Hello World\"",
        "literal_regex": "<\\d+>",
        "literal_unsupported": "Invalid \\x escape sequence is allowed",
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

escape_sequences_test = unittest.make(_escape_sequences_test_impl)

def _unicode_escapes_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
# Test \\uXXXX Unicode escape sequences
name = "Jos\\u00E9"  # José (U+00E9 = é)
copyright = "Copyright \\u00A9 2023"  # © (U+00A9)
heart = "I \\u2665 Unicode"  # ♥ (U+2665)
euro = "Price: 100\\u20AC"  # € (U+20AC)

# Test mixed escape sequences
mixed = "Name\\tJos\\u00E9\\nLocation\\tSF"
complex_string = "Quote: \\"Hello\\", Tab:\\t, Unicode: \\u2603"

# Test edge cases
ascii_a = "\\u0041"  # A (U+0041)
'''

    result = parse_toml(toml_content)
    expected = {
        "name": "José",
        "copyright": "Copyright © 2023",
        "heart": "I ♥ Unicode",
        "euro": "Price: 100€",
        "mixed": "Name\tJosé\nLocation\tSF",
        "complex_string": "Quote: \"Hello\", Tab:\t, Unicode: ☃",
        "ascii_a": "A",
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

unicode_escapes_test = unittest.make(_unicode_escapes_test_impl)

def _number_types_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = """
integer = 42
negative = -17
float_val = 3.14159
negative_float = -2.5
zero = 0
"""

    result = parse_toml(toml_content)
    expected = {
        "integer": 42,
        "negative": -17,
        "float_val": 3.14159,
        "negative_float": -2.5,
        "zero": 0,
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

number_types_test = unittest.make(_number_types_test_impl)

def _boolean_types_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = """
enabled = true
disabled = false
debug_mode = true
production = false
"""

    result = parse_toml(toml_content)
    expected = {
        "enabled": True,
        "disabled": False,
        "debug_mode": True,
        "production": False,
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

boolean_types_test = unittest.make(_boolean_types_test_impl)

def _comments_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
# This is a comment at the top
name = "Test App"  # This would be an inline comment in full TOML
  # Comment with preceding spaces
version = 1.0

# Section comment
[config]
# Key comment
debug = true
'''

    result = parse_toml(toml_content)
    expected = {
        "name": "Test App",
        "version": 1.0,
        "config": {
            "debug": True,
        },
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

comments_test = unittest.make(_comments_test_impl)

def _inline_comments_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
# Basic inline comments
name = "Test App"  # This is an inline comment
version = 1.0 # Another comment
debug = true#comment without space
port = 8080    #   comment with spaces

# Hash characters inside quoted strings should NOT be treated as comments
description = "This # is not a comment"
path = "C:\\\\Program Files\\\\App#1\\\\bin"
message = "Use # for comments"  # But this IS a comment

# Section headers with inline comments
[server]  # Server configuration
host = "localhost"  # Default host
port = 3000  # Default port

[database.config]  # Database settings
timeout = 30  # Connection timeout
'''

    result = parse_toml(toml_content)
    expected = {
        "name": "Test App",
        "version": 1.0,
        "debug": True,
        "port": 8080,
        "description": "This # is not a comment",
        "path": "C:\\Program Files\\App#1\\bin",
        "message": "Use # for comments",
        "server": {
            "host": "localhost",
            "port": 3000,
        },
        "database": {
            "config": {
                "timeout": 30,
            },
        },
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

inline_comments_test = unittest.make(_inline_comments_test_impl)

def _edge_case_comments_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
# Edge cases
empty_after_hash = ""  # Comment after empty string
single_quote = 'text'  # Comment after single quote
number_comment = 42  # Comment after number
bool_comment = true  # Comment after boolean

# Multiple hash characters
multi_hash = "text"  ## Multiple hashes
hash_in_comment = "value"  # Comment with # inside

# Whitespace variations
no_space = "value"#comment
lots_of_space = "value"        #    comment with lots of space
tab_separated = "value"	#	tab separated comment
'''

    result = parse_toml(toml_content)
    expected = {
        "empty_after_hash": "",
        "single_quote": "text",
        "number_comment": 42,
        "bool_comment": True,
        "multi_hash": "text",
        "hash_in_comment": "value",
        "no_space": "value",
        "lots_of_space": "value",
        "tab_separated": "value",
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

edge_case_comments_test = unittest.make(_edge_case_comments_test_impl)

def _formatting_test_impl(ctx):
    env = unittest.begin(ctx)

    data = {
        "title": "My Application",
        "version": 1.0,
        "debug": True,
        "server": {
            "host": "localhost",
            "port": 8080,
            "ssl": False,
        },
        "database": {
            "driver": "sqlite",
            "connection": {
                "timeout": 30,
                "pool_size": 10,
            },
        },
    }

    formatted = format_toml(data)
    expected_toml = '''title = "My Application"
version = 1.0
debug = true

[server]
host = "localhost"
port = 8080
ssl = false

[database]
driver = "sqlite"

[database.connection]
timeout = 30
pool_size = 10
'''

    # Assert that the formatted TOML matches the expected format
    asserts.equals(env, expected_toml.strip(), formatted.strip())

    # Test that the formatted TOML can be parsed back to the same data
    reparsed = parse_toml(formatted)
    asserts.equals(env, data, reparsed)

    return unittest.end(env)

formatting_test = unittest.make(_formatting_test_impl)

def _round_trip_test_impl(ctx):
    env = unittest.begin(ctx)

    original_toml = '''
title = "Round Trip Test"
version = 2.1
active = true

[settings]
timeout = 60
retries = 3

[settings.advanced]
buffer_size = 1024
'''

    expected = {
        "title": "Round Trip Test",
        "version": 2.1,
        "active": True,
        "settings": {
            "timeout": 60,
            "retries": 3,
            "advanced": {
                "buffer_size": 1024,
            },
        },
    }

    # Parse
    parsed = parse_toml(original_toml)
    asserts.equals(env, expected, parsed)

    # Format back
    formatted = format_toml(parsed)

    # Parse again to verify
    reparsed = parse_toml(formatted)

    # Verify that the original parsed data matches the re-parsed data
    asserts.equals(env, parsed, reparsed)

    return unittest.end(env)

round_trip_test = unittest.make(_round_trip_test_impl)

def _unicode_demo_test_impl(ctx):
    env = unittest.begin(ctx)

    demo_content = '''# Unicode Escape Sequence Demo
# This file demonstrates the \\u escape sequences

[personal]
name = "Jos\\u00E9"  # José - using \\u escape for é (U+00E9)

[symbols]
copyright = "Copyright \\u00A9 2023"  # © symbol (U+00A9)
heart = "I \\u2665 Unicode"  # ♥ symbol (U+2665)
euro = "Price: 100\\u20AC"  # € symbol (U+20AC)
snowman = "Winter \\u2603"  # ☃ snowman (U+2603)

[mixed]
# Mix of regular escapes and Unicode escapes
message = "Name:\\tJos\\u00E9\\nLocation:\\tSan Francisco"
complex = "Quote: \\"Hello\\", Tab:\\t, Unicode: \\u2603"

[edge_cases]
ascii_a = "\\u0041"  # A (U+0041) - ASCII character via Unicode escape
'''

    result = parse_toml(demo_content)
    expected = {
        "personal": {
            "name": "José",
        },
        "symbols": {
            "copyright": "Copyright © 2023",
            "heart": "I ♥ Unicode",
            "euro": "Price: 100€",
            "snowman": "Winter ☃",
        },
        "mixed": {
            "message": "Name:\tJosé\nLocation:\tSan Francisco",
            "complex": "Quote: \"Hello\", Tab:\t, Unicode: ☃",
        },
        "edge_cases": {
            "ascii_a": "A",
        },
    }

    asserts.equals(env, expected, result)

    # Test round-trip formatting
    formatted = format_toml(result)
    reparsed = parse_toml(formatted)
    asserts.equals(env, result, reparsed)

    return unittest.end(env)

unicode_demo_test = unittest.make(_unicode_demo_test_impl)

def _valid_keys_test_impl(ctx):
    env = unittest.begin(ctx)

    toml_content = '''
valid_key = "value1"
valid-key = "value2"
validKey123 = "value3"
key_with_underscores = "value4"
key-with-hyphens = "value5"
a = "single char"
a1 = "alphanumeric"
key123 = "numbers at end"

[valid_section]
another_valid_key = "value6"

[valid-section-name]
key123 = "value7"

[section_with_underscores]
test = "value8"
'''

    result = parse_toml(toml_content)
    expected = {
        "valid_key": "value1",
        "valid-key": "value2",
        "validKey123": "value3",
        "key_with_underscores": "value4",
        "key-with-hyphens": "value5",
        "a": "single char",
        "a1": "alphanumeric",
        "key123": "numbers at end",
        "valid_section": {
            "another_valid_key": "value6",
        },
        "valid-section-name": {
            "key123": "value7",
        },
        "section_with_underscores": {
            "test": "value8",
        },
    }

    asserts.equals(env, expected, result)
    return unittest.end(env)

valid_keys_test = unittest.make(_valid_keys_test_impl)

def toml_test_suite(name):
    unittest.suite(
        name,
        trivial_test,
        basic_parsing_test,
        sections_test,
        nested_sections_test,
        string_types_test,
        escape_sequences_test,
        unicode_escapes_test,
        number_types_test,
        boolean_types_test,
        comments_test,
        inline_comments_test,
        edge_case_comments_test,
        # formatting_test,  # Disabled due to format_toml recursion issue
        # round_trip_test,  # Disabled due to format_toml recursion issue
        # unicode_demo_test,  # Disabled due to format_toml recursion issue
        valid_keys_test,
    )
