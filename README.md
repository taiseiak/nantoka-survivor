# Love2D starter

This is a starter template mostly made for myself. It includes:

- Libraries I use often
- A simple script to build and push to itch.io

This has small enough code that it can be used for gamejams.

Base d on the great work at [simplifylabs/love-packager: CLI to package your LÖVE projects](https://github.com/simplifylabs/love-packager).

## Requirements

Before running any scripts, ensure that the following tools and dependencies are installed:

- **Node.js** (v16 or higher) - Required for running the `love-packager` command.
- **Butler** - A command-line tool used for uploading games to [itch.io](https://itch.io/). You can download stable and bleeding-edge builds of butler from its itch.io page https://itchio.itch.io/butler, but I recommend getting the [itch app](https://itch.io/app) and install it there as it's easy.

The `.env` file needs to be populated as well. For github actions, the secrets need to be setup on Github.

You can find your Butler API key locally:

Linux: `~/.config/itch/butler_creds`
Mac: `~/Library/Application Support/itch/butler_creds`
Windows: `%USERPROFILE%\\.config\\itch\\butler_creds`

Or on your API keys user settings page - the key you're looking for will have its source set to wharf.

## Scripts

### `package.sh`

This script packages the Love2D game into different formats (e.g., Windows, Mac, Web) using `love-packager`.

**Usage:**
```bash
./package.sh
```

**Optional Flags:**
- `--increment-version` - Increments the version number in the `packager.yml` file.

**Requirements:**
- Ensure `butler` is installed and the `BUTLER_CREDENTIALS` environment variable is set.

### `package-and-upload.sh`

This script first runs `package.sh` to package the game and then uploads the resulting packages to itch.io using `butler`.

**Usage:**
```bash
./package-and-upload.sh
```

**Optional Flags:**
- `--increment-version` - Increments the version number in the `packager.yml` file before packaging and uploading.

**Requirements:**
- Same as `package.sh`.
- Have a project created on itch with the same project name as teh one in `packager.yml`.
- Web builds will manually have to be selected to run in the page afterwards.

### `test-web-build.sh`

This script uncompresses the Web build (`Web.zip`) created by `package.sh` and starts a simple Python server to test the WebGL compatibility of the shader files.

**Usage:**
```bash
./test-web-build.sh
```

**Requirements:**
- Ensure Python 3 is installed to run the local HTTP server.

## Credits

- [simplifylabs/love-packager: CLI to package your LÖVE projects](https://github.com/simplifylabs/love-packager)
