load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//:toml_parser.bzl", "format_toml", "parse_toml")

LARGE_TOML_STR_LEN = 10000
LARGE_TOML_STR = '\n'.join(['com_somedomain_somegroup_somedep_%s = "com.somedomain.somegroupsomedep%d:somedep-api:1.2.3"' % (i, i) for i in range(LARGE_TOML_STR_LEN)])

def _large_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed = parse_toml(LARGE_TOML_STR)
    asserts.equals(env, LARGE_TOML_STR_LEN, len(parsed))

    return unittest.end(env)

large_test = unittest.make(_large_test_impl)


def toml_test_large_suite(name):
    unittest.suite(
        name,
        large_test,
    )
