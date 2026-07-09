# Nintendo Entertainment System development environment

This repo is retained as the historical Code198x NES platform-dev environment. The old Docker/devcontainer workflow has been retired.

## Current direction

Use the current 198x surfaces instead of this repo for new work:

- **Curriculum and learner samples:** `Code198x/website/` and `Code198x/code-samples/`.
- **Assembly/toolchain work:** `Asm198x/asm198x/`.
- **Run, capture, and verification:** native Emu198x tooling in `Emu198x/emu198x/`.
- **Local ROM/media inputs:** keep ROMs and generated cartridge images out of Git unless a sample explicitly owns them and rights are clear.

## Status

This repo no longer owns the active NES build/capture workflow. Keep changes here limited to historical cleanup, license/context updates, or removal of obsolete scaffolding.

## Historical note

The retired container previously installed cc65, FCEUX, and helper capture scripts. Those scripts and Docker files were removed once the project moved toward native Asm198x and Emu198x workflows.
