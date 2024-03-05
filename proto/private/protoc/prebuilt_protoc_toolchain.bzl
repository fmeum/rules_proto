"""Repository rule that relies on fetching a protoc binary from GitHub Releases.

It exposes bin/protoc as a proto_toolchain.
"""

load(":versions.bzl", "PROTOC_PLATFORMS", "PROTOC_VERSIONS")

def _prebuilt_protoc_repo_impl(rctx):
    release_version = rctx.attr.version

    filename = "{}-{}-{}.zip".format(
        "protoc",
        release_version.removeprefix("v"),
        rctx.attr.platform,
    )
    url = "https://github.com/protocolbuffers/protobuf/releases/download/{}/{}".format(
        release_version,
        filename,
    )
    rctx.download_and_extract(
        url = url,
        integrity = PROTOC_VERSIONS[release_version][filename],
    )
    rctx.file("BUILD.bazel", """\
# Generated by @rules_proto//proto/toolchains:prebuilt_protoc_toolchain.bzl
load("@rules_proto//proto/private/rules:proto_toolchain_rule.bzl", "proto_toolchain")

proto_toolchain(
    name = "prebuilt_protoc_toolchain",
    proto_compiler = "{protoc_label}",
    visibility = ["//visibility:public"],
)
""".format(
        protoc_label = ":bin/protoc.exe" if rctx.attr.platform.find("windows") != -1 else ":bin/protoc",
    ))

prebuilt_protoc_repo = repository_rule(
    doc = "Download a pre-built protoc and create a concrete toolchains for it",
    implementation = _prebuilt_protoc_repo_impl,
    attrs = {
        "platform": attr.string(
            doc = "A platform that protobuf ships a release for",
            mandatory = True,
            values = PROTOC_PLATFORMS.keys(),
        ),
        "version": attr.string(
            doc = "Release tag from protocolbuffers/protobuf repo, e.g. 'v25.3'",
            mandatory = True,
        ),
    },
)
