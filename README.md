# Nintendo Entertainment System Development Environment

Docker-based development environment for NES programming with 6502 Assembly language support.

## 🎯 What's Included

- **ca65/ld65** - 6502 assembler and linker (cc65 toolchain)
- **FCEUX** - NES emulator with debugging capabilities
- **cc65** - Full C compiler toolchain for NES development
- **Build tools** - make, git, and essential utilities

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Start the environment
docker-compose up -d

# Enter the container
docker-compose exec nes-dev bash

# Stop when done
docker-compose down
```

### Option 2: VS Code Dev Container

1. Install the "Dev Containers" extension in VS Code
2. Open this folder in VS Code
3. Click "Reopen in Container" when prompted
4. VS Code will build and start the container automatically

### Option 3: Docker CLI

```bash
# Build the image
docker build -t code198x/nintendo-entertainment-system:latest .

# Run interactively
docker run -it --rm -v $(pwd):/workspace code198x/nintendo-entertainment-system:latest

# Or run a specific command
docker run --rm -v $(pwd):/workspace code198x/nintendo-entertainment-system:latest \
  ca65 program.asm -o program.o
```

## 📚 Examples

Example projects are included:

### Assembly - Hello World
Basic NES program demonstrating PPU initialization and background rendering:
```bash
cd examples/assembly/hello
make          # Build
make run      # Run in FCEUX
```

### Assembly - Sprite Demo
Hardware sprite demonstration with controller input:
```bash
cd examples/assembly/sprite-demo
make          # Build
make run      # Run in FCEUX
```

## 🛠️ Common Commands

### Assembly Development

```bash
# Assemble source file
ca65 program.asm -o program.o

# Link with NES configuration
ld65 -C nes.cfg program.o -o game.nes

# Typical nes.cfg content (create in your project):
# MEMORY {
#     HEADER: start=$0000, size=$0010, fill=yes, file=%O;
#     ROM:    start=$8000, size=$8000, fill=yes, file=%O;
#     RAM:    start=$0000, size=$0800;
# }
# SEGMENTS {
#     HEADER:  load=HEADER, type=ro;
#     CODE:    load=ROM,    type=ro;
#     VECTORS: load=ROM,    type=ro, start=$FFFA;
#     CHARS:   load=ROM,    type=ro;
# }

# Run in emulator
fceux game.nes
```

### CHR Data (Graphics)

NES graphics use 8x8 pixel tiles stored in CHR-ROM or CHR-RAM:

```bash
# Convert PNG to CHR data (requires neslib tools or similar)
# See examples for manual CHR data creation

# Include CHR data in assembly:
# .segment "CHARS"
# .incbin "tiles.chr"
```

### Project Structure

Recommended project layout:
```
my-project/
├── src/
│   ├── main.asm      # Main source file
│   ├── reset.asm     # Reset/init code
│   ├── nmi.asm       # NMI handler
│   └── includes/     # Include files
├── chr/
│   └── tiles.chr     # CHR graphics data
├── build/            # Build output
├── nes.cfg           # Linker configuration
├── Makefile          # Build automation
└── README.md         # Project documentation
```

## 🎓 Learning Resources

This environment is designed for use with the [Code Like It's 198x](https://code198x.stevehill.xyz) educational platform.

**Courses available:**
- NES 6502 Assembly Phase 1 - Hardware fundamentals and arcade games

**Code samples:** https://github.com/code198x/code-samples

**Essential NES Documentation:**
- [NESDev Wiki](https://www.nesdev.org/wiki/) - Comprehensive hardware reference
- [6502 Reference](http://www.6502.org/) - CPU instruction set
- [NES Programming Tutorial](https://nerdy-nights.nes.science/) - Beginner-friendly guide

## 🔧 Troubleshooting

### Running FCEUX (Recommended Workflow)

**This container is designed primarily for building NES programs.** For the best experience:

1. **Build in the container** - Use the Docker environment for consistent compilation
2. **Run on your host** - Use FCEUX or Mesen installed natively on your machine for testing

```bash
# Build in container
docker run --rm -v $(pwd):/workspace ghcr.io/code198x/nintendo-entertainment-system:latest \
  make

# Run on host (install FCEUX/Mesen natively)
fceux game.nes
```

**Why this approach?**
- Native emulators provide better performance and audio quality
- Better controller/gamepad support
- Excellent debugging tools (especially Mesen)
- Avoids X11 forwarding complexity on macOS

### Installing NES Emulators on Your Host

**macOS:**
```bash
# FCEUX
brew install fceux

# Mesen (recommended for debugging)
brew install --cask mesen
```

**Linux (Ubuntu/Debian):**
```bash
# FCEUX
sudo apt-get install fceux

# Mesen
# Download from https://github.com/SourMesen/Mesen2
```

**Windows:**
- **FCEUX:** Download from [FCEUX website](https://fceux.com/)
- **Mesen:** Download from [Mesen GitHub](https://github.com/SourMesen/Mesen2)

### NES Cartridge Configuration

NES programs require proper iNES header configuration. Basic header for NROM (mapper 0):

```asm
.segment "HEADER"
    .byte "NES", $1A    ; iNES magic number
    .byte 2             ; 2 * 16KB PRG-ROM
    .byte 1             ; 1 * 8KB CHR-ROM
    .byte $00           ; Mapper 0 (NROM), horizontal mirroring
    .byte $00           ; No special features
```

### Advanced: Running FCEUX from Container

If you need to run FCEUX from within the container, X11 forwarding is required:

**macOS with XQuartz:**
```bash
# Install XQuartz
brew install --cask xquartz

# Enable TCP connections
defaults write org.xquartz.X11 nolisten_tcp 0

# Restart XQuartz and allow connections
xhost +localhost
```

**Linux:**
```bash
# Allow X11 connections
xhost +local:docker

# Run with display forwarding
docker run --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix ...
```

### Headless Mode

For automated builds and CI/CD:
```bash
# Just assemble and link, don't run emulator
ca65 program.asm -o program.o
ld65 -C nes.cfg program.o -o game.nes
```

### File Permissions

If you encounter permission issues:

```bash
# Change ownership to your user
sudo chown -R $(whoami):$(whoami) .
```

## 📝 Makefile Template

Create a `Makefile` in your project:

```makefile
# NES project
TARGET = game
SRC = $(TARGET).asm
CFG = nes.cfg

all: $(TARGET).nes

$(TARGET).o: $(SRC)
	ca65 $< -o $@

$(TARGET).nes: $(TARGET).o $(CFG)
	ld65 -C $(CFG) $(TARGET).o -o $@

run: $(TARGET).nes
	fceux $<

clean:
	rm -f $(TARGET).o $(TARGET).nes

.PHONY: all run clean
```

**Example nes.cfg:**
```
MEMORY {
    HEADER: start=$0000, size=$0010, fill=yes, file=%O;
    ROM:    start=$8000, size=$8000, fill=yes, file=%O;
    CHR:    start=$0000, size=$2000, fill=yes, file=%O;
    RAM:    start=$0000, size=$0800;
}

SEGMENTS {
    HEADER:  load=HEADER, type=ro;
    CODE:    load=ROM,    type=ro;
    VECTORS: load=ROM,    type=ro, start=$FFFA;
    CHARS:   load=CHR,    type=ro;
}
```

**Usage:**
```bash
# Build in container
docker run --rm -v $(pwd):/workspace ghcr.io/code198x/nintendo-entertainment-system:latest make

# Run on host (requires FCEUX installed locally)
make run
```

## 🐳 Building Custom Images

To customize the environment:

1. Edit `Dockerfile` to add tools or change configuration
2. Rebuild:
   ```bash
   docker-compose build
   # or
   docker build -t code198x/nintendo-entertainment-system:latest .
   ```

## 📦 Publishing

To share your image on Docker Hub:

```bash
# Tag with version
docker tag code198x/nintendo-entertainment-system:latest code198x/nintendo-entertainment-system:v1.0.0

# Push to Docker Hub
docker push code198x/nintendo-entertainment-system:latest
docker push code198x/nintendo-entertainment-system:v1.0.0
```

## 🤝 Contributing

This environment is part of the Code Like It's 198x educational project.

**Repository:** https://github.com/code198x/nintendo-entertainment-system-dev

## 📄 License

MIT License - See LICENSE file for details

## 🎮 About

Code Like It's 198x teaches retro game development for classic 8-bit and 16-bit systems. This NES environment provides everything needed to start coding for the legendary Nintendo Entertainment System.

**Website:** https://code198x.stevehill.xyz
**Course Materials:** https://github.com/code198x/
