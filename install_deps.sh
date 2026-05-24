#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$(eval echo ~${SUDO_USER:-$USER})"
echo "=== Install Script ==="
echo "Script directory: $SCRIPT_DIR"
echo "User home: $USER_HOME"

# Install Linux dependencies
install_linux_deps() {
    echo "[1/3] Installing Linux dependencies..."
    apt-get update
    apt-get upgrade
    apt autoremove
    apt-get install -y i2c-tools vim
    echo "Linux dependencies installed."
}

# Install Zig
install_zig() {
    echo "[1/2] Installing Zig..."

    ZIG_TARBALL="$SCRIPT_DIR/zig-aarch64-linux-0.16.0.tar.xz"
    ZIG_DIR="zig-aarch64-linux-0.16.0"
    ZIG_TARGET="$USER_HOME/zig-aarch64-linux-0.16.0"

    # Check if already installed (directory exists AND contains zig binary)
    if [ -d "$ZIG_TARGET" ] && [ -f "$ZIG_TARGET/zig" ]; then
        echo "Zig already installed at $ZIG_TARGET. Skipping."
    else
        if [ ! -f "$ZIG_TARBALL" ]; then
            echo "ERROR: Zig tarball not found at $ZIG_TARBALL"
            exit 1
        fi

        # Extract
        echo "Extracting $ZIG_TARBALL..."
        tar -xf "$ZIG_TARBALL"

        # Move to target location
        echo "Moving $ZIG_DIR to $ZIG_TARGET..."
        rm -rf "$ZIG_TARGET"
        mv "$ZIG_DIR" "$ZIG_TARGET"

        echo "Zig extracted and moved."
    fi

    # Add to PATH in .bashrc (check if already present)
    if ! grep -q "export PATH=\$PATH:$ZIG_TARGET" ~/.bashrc 2>/dev/null; then
        echo "Adding Zig to PATH in ~/.bashrc..."
        echo "" >> ~/.bashrc
        echo "# Zig PATH" >> ~/.bashrc
        echo "export PATH=\$PATH:$ZIG_TARGET" >> ~/.bashrc
    else
        echo "Zig PATH already in ~/.bashrc"
    fi

    echo "Zig setup complete. Run 'source ~/.bashrc' or restart shell."
}

# Install wiring pi .deb
install_wiringpi() {
    echo "[3/3] Installing wiring pi..."

    DEB_FILE="$SCRIPT_DIR/wiringpi_3.16_arm64.deb"

    # Check if already installed
    if dpkg -l | grep -q "wiringpi"; then
        echo "wiring pi already installed. Skipping."
    else
        if [ ! -f "$DEB_FILE" ]; then
            echo "ERROR: wiring pi .deb not found at $DEB_FILE"
            exit 1
        fi

        echo "Installing $DEB_FILE..."
        dpkg -i "$DEB_FILE"
        echo "wiring pi installed."
    fi
}

# Run installations
install_linux_deps
install_zig
install_wiringpi

echo "=== Installation Complete ==="
