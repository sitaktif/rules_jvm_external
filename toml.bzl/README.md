# Starlark TOML Parser

A simple TOML parser implementation written in native Starlark without external dependencies.

This is a WIP does not yet support all the TOML features.

## Features

This parser's TOML feature support status:

### Basic Types
- [x] **Strings**: Double quoted (`"string"`) with escape sequences
- [x] **Strings**: Single quoted literal strings (`'string'`)
- [ ] **Strings**: Unquoted bare values (not part of TOML spec)
- [x] **Numbers**: Basic integers (`42`, `-17`)
- [x] **Numbers**: Basic floats (`3.14`, `-2.5`)
- [ ] **Numbers**: Integer formats with underscores (`1_000`)
- [ ] **Numbers**: Hexadecimal (`0xFF`), octal (`0o755`), binary (`0b1010`)
- [ ] **Numbers**: Float scientific notation (`5e+22`)
- [ ] **Numbers**: Special float values (`inf`, `nan`)
- [x] **Booleans**: `true` and `false`
- [x] **Comments**: Full-line comments starting with `#`
- [x] **Comments**: Inline comments (comments after values)

### Structure
- [x] **Key-value pairs**: `key = value`
- [x] **Sections**: `[section]`
- [x] **Nested sections**: `[section.subsection]`
- [ ] **Quoted keys**: `"127.0.0.1" = "value"`
- [ ] **Dotted keys**: `physical.color = "orange"`

### String Features
- [x] **Basic escape sequences**: `\n`, `\t`, `\r`, `\\`, `\"`, `\'`
- [ ] **Unicode escape sequences**: `\uXXXX`, `\UXXXXXXXX`
- [ ] **Multi-line basic strings**: `"""..."""`
- [ ] **Multi-line literal strings**: `'''...'''`

### Collections
- [ ] **Arrays**: `[1, 2, 3]`
- [ ] **Inline tables**: `{key = "value"}`
- [ ] **Array of tables**: `[[table]]`

### Advanced Types
- [ ] **Date and time**: `1979-05-27T07:32:00Z`
- [ ] **Local date**: `1979-05-27`
- [ ] **Local time**: `07:32:00`
- [ ] **Local date-time**: `1979-05-27T07:32:00`

## Usage

### Parsing TOML

```python
load("toml_parser.bzl", "parse_toml")

toml_content = '''
title = "My App"
version = 1.0
debug = true

[database]
host = "localhost"
port = 5432
'''

result = parse_toml(toml_content)
# result equals {"title": "My App", "version": 1.0, "debug": True, "database": {"host": "localhost", "port": 5432}}
```

## API

### `parse_toml(toml_str)`

Parses a TOML string and returns a dictionary.

**Parameters:**
- `toml_str` (string): The TOML content to parse

**Returns:**
- Dictionary representing the parsed TOML structure

**Raises:**
- `fail()` on parsing errors with descriptive error messages

### `format_toml(data, indent_level=0)` (incomplete implementation)

Formats a dictionary back to TOML string format.

Note: Bazel's implementation of Starlark doesn't implement recursion so any
TOML containing sections or collections isn unsupported currently.

## Examples

`doit.bzl`:

```python
load("//toml_parser.bzl", "parse_toml")

def doit():
    toml_str = """
    # Application settings
    name = "My Application"
    version = 1.2
    debug = true
    port = 8080

    [server]
    host = "localhost"
    ssl = false

    [database]
    driver = "postgresql"
    timeout = 30.5
    """

    print(parse_toml(toml_str))
```

`BUILD.bazel`:

```python
load("//:doit.bzl", "doit")
doit()
```

Result:

```
[...]
DEBUG: /path/to/a.bzl:20:10: {"name": "My Application", "version": 1.2, "debug": True, "port": 8080, "server": {"host": "localhost", "ssl": False}, "database": {"driver": "postgresql", "timeout": 30.5}}
[...]
```

## Contributing

### Running Tests

```bash
bazel test //...
```
