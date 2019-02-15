# lfsbuild

My semi-automated LFS build scripts.
- Downloads the debian netinstaller, extracts it, alters it, adds pre-seed, packs it up again. Resulting in a auto-install iso.
- Creates a virtualbox with disks, mounts the altered iso, installs the host system and transforms it into a vagrant box.
- Prepares the host system, compiles the packages for it.

etc etc.

[Check out my blog post covering the whole procedure from a to z.](https://robin.radic.ninja/linux-from-scratch)
