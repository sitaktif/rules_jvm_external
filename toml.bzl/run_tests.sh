#!/bin/bash

set -eu -o pipefail

# Test script for TOML parser with Unicode escape sequences
# Tests both successful cases and error cases

regular_tests=("test/test_toml_parser.star")

error_tests=(
    "test/fail_expected/test_unicode_error_incomplete.star"
    "test/fail_expected/test_unicode_error_surrogate.star"
    "test/fail_expected/test_unicode_error_invalid_hex.star"
    "test/fail_expected/test_unicode_error_out_of_range.star"
    "test/fail_expected/test_unsupported_arrays.star"
    "test/fail_expected/test_unsupported_inline_tables.star"
    "test/fail_expected/test_unsupported_number_formats.star"
    "test/fail_expected/test_unsupported_dotted_keys.star"
    "test/fail_expected/test_unsupported_array_of_tables.star"
    "test/fail_expected/test_invalid_key_space.star"
    "test/fail_expected/test_invalid_key_special_chars.star"
    "test/fail_expected/test_invalid_section_name.star"
)


run_test() {
    local test_file="$1"
    test_name=$(basename "$test_file")
    echo
    echo "Running $test_name..."
    if ! starlark "$test_file"; then
        echo "✗ $test_name failed"
        return 1
    fi
    echo "✓ $test_name passed"
}

run_failing_test() {
    local test_file="$1"
    test_name=$(basename "$test_file")
    echo
    echo "Running $test_name and expecting it to fail..."
    if starlark "$test_file"; then
        echo "✗  test should have failed but didn't"
        return 1
    fi
    echo "✓  test correctly failed"
}


echo "TOML Parser Unicode Escape Sequence Test Suite"
echo "=============================================="

# Test error cases (should fail)
for error_test in "${error_tests[@]}"; do
    run_failing_test "$error_test" || test_failures+=("$error_test")
done

# Test successful cases
test_failures=()
for regular_test in "${regular_tests[@]}"; do
    run_test "$regular_test" || test_failures+=("$regular_test")
done

# Summary
echo
echo "Test Summary:"
echo "============="
if [[ ${#test_failures[@]} != 0 ]]; then
    echo "✗ Some tests failed."
    for test in "${test_failures[@]}"; do
        echo "  - $test"
    done
    exit 1
fi

echo "✓ All tests passed!"