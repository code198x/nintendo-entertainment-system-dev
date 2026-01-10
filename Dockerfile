FROM ubuntu:24.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    git \
    curl \
    wget \
    unzip \
    # cc65 toolchain (includes ca65 and ld65)
    cc65 \
    # FCEUX emulator
    fceux \
    # Text editors
    vim \
    nano \
    # Utilities
    make \
    python3 \
    python3-pip \
    # Screenshot capture (headless)
    xvfb \
    imagemagick \
    xdotool \
    && rm -rf /var/lib/apt/lists/*

# Add screenshot capture script
COPY scripts/nes-screenshot.sh /usr/local/bin/nes-screenshot
RUN chmod +x /usr/local/bin/nes-screenshot

# Create workspace directory
WORKDIR /workspace

# Add helpful message when container starts
RUN echo '#!/bin/bash\n\
echo "╔════════════════════════════════════════════════════════════╗"\n\
echo "║   NES Development Environment - Code Like It'"'"'s 198x      ║"\n\
echo "╚════════════════════════════════════════════════════════════╝"\n\
echo ""\n\
echo "📦 Tools installed:"\n\
echo "  • ca65/ld65       - 6502 assembler and linker (cc65)"\n\
echo "  • FCEUX           - NES emulator with debugging"\n\
echo "  • cc65            - Full C compiler toolchain"\n\
echo ""\n\
echo "🚀 Quick start:"\n\
echo "  ca65 program.asm -o program.o          # Assemble"\n\
echo "  ld65 -C nes.cfg program.o -o game.nes  # Link"\n\
echo "  fceux game.nes                         # Run in emulator"\n\
echo "  nes-screenshot game.nes out.png        # Headless screenshot"\n\
echo ""\n\
echo "📚 Examples available in /workspace/examples/"\n\
echo ""\n\
' > /usr/local/bin/welcome && chmod +x /usr/local/bin/welcome

# Set default command to show welcome message
CMD ["/bin/bash", "-c", "welcome && /bin/bash"]
