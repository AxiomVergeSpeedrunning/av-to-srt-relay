def main(ctx):
    combinations = (
        ("linux", "amd64"),
        ("linux", "arm64"),
        ("linux", "arm"),
        ("windows", "amd64"),
        ("darwin", "amd64"),
        ("darwin", "arm64"),
    )

    return [step(os, arch) for os, arch in combinations]


def step(os, arch):
    ext = "bin"
    if os == "windows":
        ext = "exe"

    os_name = os
    if os == "darwin":
        os_name = "macos"

    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "%s-%s" % (os, arch),
        "platform": {"os": "linux", "arch": "arm64"},
        "trigger": {"branch": ["main"]},
        "steps": [
            {
                "name": "build",
                "image": "golang",
                "commands": [
                    "mkdir -p bin",
                    "GOOS={os} GOARCH={arch} go build -o bin/avsrt-{os_name}-{arch}.{ext}".format(
                        os=os,
                        os_name=os_name,
                        arch=arch,
                        ext=ext,
                    ),
                ],
            },
        ],
    }
