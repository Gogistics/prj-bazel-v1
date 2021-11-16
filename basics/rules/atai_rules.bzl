# Custom rules
# Ref:
# - https://jayconrod.com/posts/107/writing-bazel-rules--library-rule--depsets--providers
# - https://john-millikin.com/bazel-school/rules

## Basic rules

### 1. simply generate a file
def _hello(ctx):
    # define file name with the name attribute passed in from ctx
    out = ctx.actions.declare_file(ctx.attr.name)

    # write content into file
    ctx.actions.write(out, "Hello\n")

    return DefaultInfo(
        files = depset([out])
    )

# accessible function
hello = rule(
    _hello,
)


## 2. define attributes
def _attrs(ctx):
    out = ctx.actions.declare_file(ctx.attr.name)
    content = ctx.attr.template.format(**ctx.attr.vars)
    ctx.actions.write(out, content)
    return DefaultInfo(
        files = depset([out])
    )

attrs_demo = rule(
    _attrs,
    attrs = {
        "template": attr.string(mandatory = True),
        "vars": attr.string_dict(),
    }
)


## 3. sub-processes
def _subproc(ctx):
    out = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.run(
        executable = "dd",
        arguments = [
            "if=/dev/zero",
            "of={}".format(out.path),
            "bs={}".format(ctx.attr.block_size),
            "count={}".format(ctx.attr.count),
        ],
        outputs = [out],
        mnemonic = "CopyFile",
        progress_message = "Copying {} zeros".format(ctx.attr.count * ctx.attr.block_size),
    )

    return DefaultInfo(
        files = depset([out])
    )

subproc = rule(
    _subproc,
    attrs = {
        "block_size": attr.int(default = 1),
        "count": attr.int(mandatory = True),
    }
)


## 4. dependencies
def _deps_demo(ctx):
    outs = []
    for src_file in ctx.files.srcs:
        out = ctx.actions.declare_file(ctx.attr.name + "/" + src_file.basename)
        outs.append(out)
        ctx.actions.run(
            executable = "cp",
            arguments = [src_file.path, out.path],
            outputs = [out],
            inputs = [src_file],
            mnemonic = "CopyFile",
            progress_message = "Copying {}".format(src_file.path)
        )
    return DefaultInfo(
        files = depset(outs),
    )


deps_demo = rule(
    _deps_demo,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            allow_empty = False,
            mandatory = True,
        )
    }
)

# 5. struct
def _struct_demo(ctx):
    out = ctx.actions.declare_file(ctx.attr.name)
    # struct
    my_value = struct(
        foo = 12,
        bar = 34,
    )
    sum = my_value.foo + my_value.bar
    print(sum)
    # print() is going to generate the following message:
    #   DEBUG: /Users/alantai/Desktop/dev/prjEnvoy/prj-bazel-v1/basics/rules/atai_rules.bzl:81:10: 46

    # write content into file
    ctx.actions.write(out, "sum: {}\n".format(sum))

    return DefaultInfo(
        files = depset([out])
    )

struct_demo = rule(
    _struct_demo,
)

# 6. providers
# Ref:
#   https://docs.bazel.build/versions/main/skylark/lib/skylark-provider.html
#   https://docs.bazel.build/versions/main/skylark/lib/globals.html#provider

AtaiLibraryInfo = provider(
    doc = "Contains information about a Atai library",
    fields = {
        "info": """A struct containing information about this library.
        Has the following fields:
            importpath: Name by which the library may be imported.
            archive: The .a file compiled from the library's sources.
        """,
        "my_deps": "A depset of info structs for this library's dependencies",
    },
)

def _atai_provider(ctx):
    # define file name with the name attribute passed in from ctx
    out = ctx.actions.declare_file(ctx.attr.name)

    # write content into file
    ctx.actions.write(out, "Hello\n")

    return AtaiLibraryInfo(
        my_deps = depset([out])
    )

# accessible function
atai_provider = rule(
    _atai_provider,
)

### \Basic rules