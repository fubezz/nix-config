# 🍎 macOS Development Environment with Nix

A modular and comprehensive Nix-based development environment for macOS using [nix-darwin](https://github.com/LnL7/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager).

## ✨ Features

- **Modular Configuration**: Organized into focused modules for easy maintenance
- **VS Code Integration**: Fully configured with extensions and settings
- **Shell Experience**: Enhanced Zsh with oh-my-zsh, aliases, and modern CLI tools
- **Development Tools**: Container tools, cloud CLIs, and programming languages
- **Code Quality**: Pre-commit hooks with Nix formatting and linting
- **macOS Optimization**: System defaults and Homebrew integration

## 📁 Repository Structure

```
├── README.md                    # This file
├── flake.nix                   # Main flake configuration
├── flake.lock                  # Dependency lockfile
├── configuration.nix           # nix-darwin system configuration
├── home.nix                    # Home Manager entry point
├── .pre-commit-config.yaml     # Pre-commit hooks configuration
├── .gitlint                    # Git commit message linting
└── modules/
    ├── packages.nix            # Development packages and tools
    ├── shell.nix               # Shell configuration (Zsh, Git, etc.)
    ├── vscode.nix              # VS Code extensions and settings
    └── macos.nix               # macOS system defaults
```

## 🚀 Quick Start

### Prerequisites

1. **Install Nix** with flakes enabled:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Install nix-darwin**:
   ```bash
   nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .
   ```

### Installation

1. **Clone this repository**:
   ```bash
   git clone <your-repo-url> ~/.config/nix-darwin
   cd ~/.config/nix-darwin
   ```

2. **Update the configuration** in `flake.nix`:
   - Change `machineConfig.hostname` to your machine name
   - Update `machineConfig.username` and `machineConfig.home` to your user details

3. **Apply the configuration**:
   ```bash
   sudo darwin-rebuild switch --flake . --impure
   ```

4. **Install pre-commit hooks** (optional but recommended):
   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

## 🔧 Configuration Modules

### 📦 Packages (`modules/packages.nix`)

Includes comprehensive development tools:

- **Container & Orchestration**: Docker, Kubernetes, Helm, K9s
- **Cloud Platforms**: AWS CLI, Google Cloud SDK, Terraform, Terragrunt
- **Programming Languages**: Python, Node.js, Go, Rust toolchains
- **Developer Tools**: Git utilities, editors, file managers
- **System Utilities**: Modern replacements for standard Unix tools

### 🐚 Shell Configuration (`modules/shell.nix`)

Enhanced shell experience with:

- **Zsh + Oh My Zsh**: Configured with useful plugins
- **Git Integration**: Aliases, advanced configuration, and difftastic
- **Modern CLI Tools**: eza, bat, rg, fd, fzf integration
- **Development Aliases**: Shortcuts for common tasks
- **Ghostty Terminal**: Pre-configured terminal settings

### 🔧 VS Code (`modules/vscode.nix`)

Fully configured development environment:

- **Nix Language Support**: LSP, formatting, and syntax highlighting
- **Development Extensions**: Python, DevOps, Git, Docker, Kubernetes
- **Editor Settings**: Optimized for productivity
- **Theme & UI**: Consistent and modern interface

### 🍎 macOS Settings (`modules/macos.nix`)

System optimizations:

- **Dock Configuration**: Autohide, positioning, and behavior
- **Finder Settings**: Show extensions, hidden files, and path bar
- **Trackpad & Mouse**: Natural scrolling and tracking settings
- **System Behavior**: Key repeat, screenshots, and more

## 🛠️ Usage

### Updating the System

```bash
# Apply configuration changes
sudo darwin-rebuild switch --flake . --impure

# Update dependencies
nix flake update
sudo darwin-rebuild switch --flake . --impure
```

### Managing Packages

Add packages to `modules/packages.nix`:

```nix
home.packages = with pkgs; [
  # Add your packages here
  neovim
  htop
  # ...existing packages...
];
```

### Customizing VS Code

Modify `modules/vscode.nix`:

```nix
# Add extensions
extensions = with inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace; [
  # Add your extensions here
  ms-python.python
  # ...existing extensions...
];

# Modify settings
userSettings = {
  # Add your settings here
  "editor.fontSize" = 14;
  # ...existing settings...
};
```

### Shell Customization

Update `modules/shell.nix`:

```nix
shellAliases = {
  # Add your aliases here
  myalias = "some command";
  # ...existing aliases...
};
```

## 🔍 Code Quality

This repository includes comprehensive code quality tools:

### Pre-commit Hooks

- **File Quality**: Trailing whitespace, end-of-file fixes
- **Nix Formatting**: nixpkgs-fmt for consistent code style
- **Nix Linting**: statix for best practices and warnings
- **Dead Code**: deadnix to remove unused code
- **Commit Messages**: gitlint for conventional commit format

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`, `revert`

## 🐛 Troubleshooting

### Common Issues

1. **"No formatter configured" in VS Code**:
   - Ensure nil LSP is configured correctly in `modules/vscode.nix`
   - Restart VS Code after applying configuration

2. **Pre-commit hooks not working**:
   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

3. **Homebrew conflicts**:
   - Check brew services: `brew services list`
   - Restart affected services after rebuild

4. **Permission issues**:
   - Ensure user is in admin group
   - Use `sudo` for darwin-rebuild commands

### Logs and Debugging

```bash
# Check nix-darwin logs
sudo launchctl list | grep nix

# Verify configuration syntax
nix flake check

# Test configuration without applying
sudo darwin-rebuild check --flake . --impure
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** and ensure they follow the code quality standards
4. **Test your changes**: `sudo darwin-rebuild check --flake . --impure`
5. **Commit with conventional format**: `git commit -m "feat: add amazing feature"`
6. **Push and create a Pull Request**

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [nix-darwin](https://github.com/LnL7/nix-darwin) - Nix modules for macOS
- [Home Manager](https://github.com/nix-community/home-manager) - User environment management
- [Nix Community](https://github.com/nix-community) - Various Nix tools and extensions
- [Determinate Systems](https://determinate.systems/) - Nix installer and tooling

## 📚 Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Manual](https://github.com/LnL7/nix-darwin/blob/master/README.md)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Happy Nixing! 🎉**
