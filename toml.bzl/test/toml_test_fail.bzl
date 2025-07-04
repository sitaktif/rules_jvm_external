load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//:toml_parser.bzl", "parse_toml")

# Testing the case where a function fails is a bit of a weird one. We need to:
# - Create an artificial "calling" rule that calls the function
# - Then, for each test case:
#   - Instantiate a target of that calling rule.
#   - Make an analysistest against that target.
#
# We define some functions at the top to help reduce boilerplate.

# Define an rule whose job is just to call the function.
def _parse_toml_rule_impl(ctx):
    parse_toml(ctx.attr.toml_str)
    return []

_parse_toml_caller_rule = rule(
    implementation = _parse_toml_rule_impl,
    attrs = {
        "toml_str": attr.string(mandatory = True),
    },
)

def _parse_toml_failure_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.expected_failure)
    return analysistest.end(env)

parse_toml_failure_test = analysistest.make(
    _parse_toml_failure_test_impl,
    expect_failure = True,
    attrs = {
        "expected_failure": attr.string(mandatory = True),
    },
)

def _make_parse_toml_failing_test(name, toml_str, expected_failure):
    caller_target = "_parse_toml_caller_rule_%s" % name
    _parse_toml_caller_rule(
        name = caller_target,
        toml_str = toml_str,
        tags = ["manual"],
    )
    parse_toml_failure_test(
        name = "_parse_toml_failure_test_%s" % name,
        target_under_test = caller_target,
        expected_failure = expected_failure,
    )

def toml_test_fail_suite(name):
    toml_content = 'invalid key = "value"'
    _make_parse_toml_failing_test(
        "invalid_key_space",
        toml_content,
        "Invalid key characters at line 1: invalid key (keys must be non-empty and contain only alphanumeric characters, underscores, or hyphens)",
    )

    # <added>
    toml_content = 'key@invalid = "value"'
    _make_parse_toml_failing_test(
        "invalid_key_special_chars",
        toml_content,
        "Invalid key characters at line 1: key@invalid (keys must be non-empty and contain only alphanumeric characters, underscores, or hyphens)",
    )

    toml_content = "[invalid section]"
    _make_parse_toml_failing_test(
        "invalid_section_name",
        toml_content,
        "Invalid section name characters at line 1: invalid section (section names must contain only alphanumeric characters, underscores, or hyphens)",
    )

    toml_content = 'incomplete = "\\u00E"'
    _make_parse_toml_failing_test(
        "unicode_error_incomplete",
        toml_content,
        "Error in decode: at offset 3, incomplete \\uXXXX escape",
    )

    toml_content = 'invalid_hex = "\\u00GZ"'
    _make_parse_toml_failing_test(
        "unicode_error_invalid_hex",
        toml_content,
        "Error in decode: at offset 3, invalid hex char \"G\" in \\uXXXX escape",
    )

    toml_content = '''
[[products]]
name = "Hammer"
sku = 738594937
'''
    _make_parse_toml_failing_test(
        "unsupported_array_of_tables",
        toml_content,
        "Array of tables ([[section]]) are not supported at line 2",
    )

    toml_content = """
# This should fail - arrays are not supported
numbers = [1, 2, 3, 4, 5]
"""
    _make_parse_toml_failing_test(
        "unsupported_arrays",
        toml_content,
        "Arrays are not supported at line 3",
    )

    toml_content = 'name.first = "Tom"'
    _make_parse_toml_failing_test(
        "unsupported_dotted_keys",
        toml_content,
        "Invalid key characters at line 1: name.first (keys must be non-empty and contain only alphanumeric characters, underscores, or hyphens)",
    )

    toml_content = "point = { x = 1, y = 2 }"
    _make_parse_toml_failing_test(
        "unsupported_inline_tables",
        toml_content,
        "Inline tables are not supported at line 1",
    )

    toml_content = "hex_number = 0xFF"
    _make_parse_toml_failing_test(
        "unsupported_number_formats",
        toml_content,
        "Hexadecimal numbers are not supported at line 1: 0xFF",
    )
    # </added>
