front_matter = {
    "kind": "pipeline",
    "type": "docker",
    "platform": {"os": "linux", "arch": "arm64"},
}


def main(ctx):
    combinations = (
        ("linux", "amd64"),
        ("linux", "arm64"),
        ("linux", "arm"),
        ("linux", "386"),
        ("windows", "amd64"),
        ("windows", "arm64"),
        ("windows", "arm"),
        ("windows", "386"),
        ("darwin", "amd64"),
        ("darwin", "arm64"),
    )

    return [
        dict({"steps": [step(os, arch) for os, arch in combinations]}, **front_matter)
    ]


def step(os, arch):
    ext = "bin"
    if os == "windows":
        ext = "exe"

    os_name = os
    if os == "darwin":
        os_name = "macos"

    return dict(
        {
            "name": "%s-%s" % (os, arch),
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
    )


def publish(combinations):
    depends_on = ["{}-{}".format(os, arch) for os, arch in combinations]

    return dict(
        {
            "name": "publish",
            "depends_on": depends_on,
            "trigger": {"branch": ["master"]},
            "steps": [
                {
                    "name": "release",
                    "image": "plugins/github-release",
                    "settings": {
                        "api_key": {"from_secret": "GITHUB_API_KEY"},
                        "files": ["bin/*"],
                        "checksum": ["md5", "sha256"],
                    },
                }
            ],
        },
        **front_matter
    )
