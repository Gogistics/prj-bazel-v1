# Bazel (WIP)
Thanks to the Bazel community; I learned a lot from the contributors, especially John Millikin, Brentley Jones, Jay Conrod, Łukasz Tekieli, Davide Asnaghi, etc.

Ref:
- [Bazel Intro.](https://dev.to/davidb31/series/11649)

## Required Files
- WORKSPACE
A `workspace` is a root directory contains source files that you want to build; basically, workspace directory has a WORKSPACE file which may be empty or contains a bunch of references to external dependencies required to build the outputs.

- BUILD/BUILD.bazel and .bzl
**BUILD** files register/build targets by making calls to the rules defined in themselves. **.bzl** files provide definitions for constants, rules, macros, and functions. Native functions and native rules are global symbols in BUILD files. .bzl files need to load them using the native module. There are two syntactic restrictions in BUILD files: 1) declaring functions is illegal, and 2) *args and **kwargs arguments are not allowed.

### General mechanism
* Packages: a collection of relevant files and their dependencies
* Targets: elements of a package
* Labels: name of target
* [rules](https://docs.bazel.build/versions/main/be/general.html): specifies relationships between input and output
* [actions](https://docs.bazel.build/versions/main/skylark/lib/actions.html)


### Skylark Globals
* rule
* select
Ref:
- [Globals](https://docs.bazel.build/versions/main/skylark/lib/globals.html)


### query v.s. cquery v.s. aquery
* query: Traditional Bazel query runs on the post-loading phase target graph and therefore has no concept of configurations and their related concepts.
* cquery (configurable query): cquery is a variant of query that correctly handles select() and build options' effects on the build graph. It achieves this by running over the results of Bazel's analysis phase, which integrates these effects. query, by constrast, runs over the results of Bazel's loading phase, before options are evaluated.
* aquery (action graph query): The aquery command allows you to query for actions in your build graph. It operates on the post-analysis Configured Target Graph and exposes information about **Actions, Artifacts and their relationships**.
* Sky Query: this is a mode of query that operates over a specified universe scope.

General comparison between **query** and **cquery**: **cquery** and **query** complement each other and excel in different niches. Consider the following to decide which is right for you:

- cquery follows specific select() branches to model the exact graph you build. query doesn't know which branch the build chooses, so overapproximates by including all branches.
- cquery's precision requires building more of the graph than query does. Specifically, cquery evaluates configured targets while query only evaluates targets. This takes more time and uses more memory.
- cquery's intepretation of the query language introduces ambiguity that query avoids. For example, if "//foo" exists in two configurations, which one should cquery "deps(//foo)" use? The config function can help with this.
- As a newer tool, cquery lacks support for certain use cases. See Known issues for details.

Ref:
- [query](https://docs.bazel.build/versions/main/query-how-to.html)
- [cquery](https://docs.bazel.build/versions/main/cquery.html)
- [aquery](https://docs.bazel.build/versions/main/aquery.html)
- [Visualize your build](https://blog.bazel.build/2015/06/17/visualize-your-build.html)

### Remote Caching

Ref:
- [Remote caching](https://docs.bazel.build/versions/main/remote-caching.html)
- [Bazel remote caching diagram](https://coggle.it/diagram/YZQ1Z2aAVbipHOb6/t/bazel-remote-caching)


### Remote Execution
By default, Bazel executes builds and tests on your local machine. Remote execution of a Bazel build allows you to distribute build and test actions across multiple machines, such as a datacenter.

Remote execution provides the following benefits:

* Faster build and test execution through scaling of nodes available for parallel actions
* A consistent execution environment for a development team
* Reuse of build outputs across a development team
* Bazel uses an open-source gRPC protocol to allow for remote execution and remote caching.

Ref:
- [Remote execution overview](https://docs.bazel.build/versions/main/remote-execution.html)
- [Remote execution rules](https://docs.bazel.build/versions/main/remote-execution-rules.html)
- [Bazel’s Remote Caching and Remote Execution Explained](https://brentley.dev/bazels-remote-caching-and-remote-execution-explained/)


## Platforms & Toolchains

### Constraints
A constraint setting is a category of constraint values, at most one of which may be true for any platform. A constraint setting may be defined with the constraint_setting rule. @platforms//os:os and @platforms//cpu:cpu are the two main settings to worry about, but again, you can define your own.

### Platforms
A platform is a environment in which software can run, defined by a list of constraint values. Constraint values are defined with the constraint_value rule. A constraint value is a fact about a platform, for example, that the CPU is x86_64, arm64, etc., or the operating system is Linux, osx, windows, and so on. The default constraint values are defined in the **github.com/bazelbuild/platforms**, which is automatically declared with the workspace name platforms. You can also define your own constraints.

Three types of platforms:
* The **host platform** is where Bazel itself runs.
* The **execution platform** is where Bazel actions run. Normally, this is the same as the host platform, but if you're using remote execution, the execution platform may be different.
* The **target platform** is where the software you're building should run. By default, this is also the same as the host platform, but if you're cross-compiling, it will be different.

General build scenarios regarding platofrms supported by Bazel:
* Single-platform builds (default) - host, execution, and target platforms are the same. For example, building a Linux executable on Ubuntu running on an Intel x64 CPU.
* Cross-compilation builds - host and execution platforms are the same, but the target platform is different. For example, building an iOS app on macOS running on a MacBook Pro.
* Multi-platform builds - host, execution, and target platforms are all different.



Flags:
* --host_platform
* --platforms

Ref:
- [Platforms](https://docs.bazel.build/versions/main/platforms.html)


### Toolchains
A toolchain is a target defined with the toolchain rule that associates a toolchain implementation with a toolchain type. A toolchain type is target defined with the tooclhain_type rule, which is a name that identifies a kind of toolchain. A toolchain implementation is a target that represents the actual toolchain by listing the files that are part of the toolchain (for example, the compiler and standard library) and code needed to use the toolchain. A toolchain implementation must return a ToolchainInfo provider.

References:
- [Writing Bazel rules: platforms and toolchains](https://jayconrod.com/posts/111/writing-bazel-rules-platforms-and-toolchains)
- [Bazel School: Toolchains](https://john-millikin.com/bazel-school/toolchains#defining-toolchains)
- [Cross compiling with Bazel](https://ltekieli.com/cross-compiling-with-bazel/)
- [Platforms](https://github.com/bazelbuild/bazel/blob/0.13.0/tools/platforms/BUILD)

---

## Tips of building by Bazel

### Configurable Build Attributes

[config_setting](https://docs.bazel.build/versions/main/configurable-attributes.html)
[select](https://docs.bazel.build/versions/main/be/functions.html#select)

### Pass variables to Bazel target build

```sh
# which packages depend on qtdb lib?
bazel query 'rdeps(..., //vistar/geo/qtdb:go_default_library)' --output package

# which packages does qtdb depend on?
bazel query 'deps(//vistar/geo/qtdb:go_default_library)' --output package

# which rules are defined in package root?
bazel query 'kind(rule, //:*)' --output label_kind

# get BUILD file output from a build artifact
bazel query --noimplicit_deps 'deps(trafficking/ui/selectors.jsar)' --output=build
bazel query --noimplicit_deps 'deps(@docker//:client)' --output=build
```

* --define
```sh
$ bazel build //my_app:my_rocks --define color=white --define texture=smooth --define type=metamorphic
```

* --workspace_status_command
```sh
# For example, add the following command to .bazelrc
$ build --workspace_status_command=./utils/scripts/bazel_stamp.sh
```

## Learn by example (WIP)
Let's learn basics of Bazel by developing a simple Envoy front proxy and its corresponding API services

References:
- [Install/Upgrade Bazel](https://docs.bazel.build/versions/main/install-os-x.html)
- [Starlark](https://docs.bazel.build/versions/main/skylark/language.html)
- [Configurable attributes](https://docs.bazel.build/versions/1.2.0/configurable-attributes.html)
- [Differences between BUILD and .bzl files](https://docs.bazel.build/versions/main/skylark/language.html#differences-between-build-and-bzl-files)
- [Pass variables to Bazel target build](https://stackoverflow.com/questions/61045101/how-to-pass-variables-to-bazel-target-build)
- [How to Bazel pass environment variables](https://www.kevinsimper.dk/posts/how-to-bazel-pass-environment-variables)
-[What is Bazel – Tutorial, Examples, and Advantages](https://semaphoreci.com/blog/bazel-build-tutorial-examples)
- [](https://gerrit.wikimedia.org/r/Documentation/dev-bazel.html)


## MIS

### Security

Ref:
- [Best Practices for securing CI/CD Pipelines or how to get Security right](https://youtu.be/i3Bx1iSzrUY)
- [Security in CI CD Pipelines: Tips for DevOps Engineers](https://youtu.be/S7TfXEyhLck)
