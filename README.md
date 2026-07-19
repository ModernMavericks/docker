# mavericks-docker

Docker CLI for Mac OS X 10.9 Mavericks.

Run dependencies:
- VMware Fusion 8

## Building

Build dependencies:
- Go 1.26 for the CLI tools
- Docker for the Linux image

For the 
```sh
cmake --workflow --preset cross    # or "native" if on Mavericks
cmake --workflow --preset iso
```

## When Renovate bumps boot2docker

```sh
# 1. Bless the new upstream release asset (this hash approves the new target,
#    so eyeball the release first: right repo, right tag, plausible size).
REF=$(sed -n 's/^REF=//p' components/boot2docker/version)
curl -fsSLo /tmp/boot2docker.iso \
  "https://github.com/dragonflylee/boot2docker/releases/download/$REF/boot2docker.iso"
shasum -a 256 /tmp/boot2docker.iso | awk '{print $1}' > components/boot2docker/golden.sha256

# 2. Rebuild the ISO from source (needs a Docker daemon) and re-baseline the
#    fingerprint from it.
cmake --workflow --preset iso    # gates still fail here; the build is what matters
sh cmake/iso_fingerprint.sh emit build-iso/boot2docker/boot2docker.iso \
  cmake/characterization/boot2docker

# 3. Review before committing: kernel/label/engine should move to exactly the
#    announced new versions, and nothing else.
git diff components/boot2docker cmake/characterization/boot2docker

# 4. Confirm the gates pass, then commit both dirs to the Renovate branch.
ctest --preset iso
```

Major bumps: also check `components/boot2docker/patches/` — upstream may have
made a patch redundant (the build fails loudly if one stops applying).
