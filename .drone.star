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

    return [job(os, arch) for os, arch in combinations] + [publish(combinations)]


def job(os, arch):
    return dict(
        {
            "name": "build %s-%s" % (os, arch),
            "steps": [step(os, arch)],
            "when": {"event": ["pull_request"]},
        },
        **front_matter
    )


def step(os, arch):
    ext = "bin"
    if os == "windows":
        ext = "exe"

    os_name = os
    if os == "darwin":
        os_name = "macos"

    return {
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
    }


def publish(combinations):
    return dict(
        {
            "name": "publish",
            "steps": [step(os, arch) for os, arch in combinations]
            + [
                {
                    "name": "publish",
                    "image": "plugins/github-release",
                    "settings": {
                        "api_key": {"from_secret": "GITHUB_API_KEY"},
                        "files": ["bin/*", "CHANGELOG.md"],
                        "checksum": ["md5", "sha256"],
                        "title": "${DRONE_TAG}",
                        "notes": "CHANGELOG.md",
                    },
                    "when": {"event": ["tag"]},
                },
            ],
            "trigger": {"event": ["tag"]},
        },
        **front_matter
    )
