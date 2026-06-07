# setup-scripts

These are scripts I use to install and harden things, customize them however you want.

# Core Principles (From Trafotin):

- By default, all GUI packages go to Flatpak. Exceptions can be made with hardware-heavy or too problematic, of which I'd use dnf.
- Add agentic tooling on optional.
- For programming languages I use (Java, Go, Python, JavaScript and Rust), use package and version managers by default (sdkman, gvm, uv, nvm and pnpm and rustup)
- Wayland as much as possible.
- SELinux (or AppArmor) is on
- Additional privacy and security, with (or atleast added, even with a compromise) the convenience for network/programming-related tasks.

# TODO
- Add keyboard shortcuts I use(Windows PowerToys-like)
- Add Alt-Space tools(currently testing it)
- Backup and Restore scripts, especially for dconf.
- neovim config
- Disabling GNOME's automount
- BTRFS snapshots with snapper with GRUB selector + borg(Pika Backups) backups
- [catppuccin](https://github.com/catppuccin) everything
- Homelab setup scripts
- [LookingGlass](https://github.com/gnif/LookingGlass) for VMs

# Notes

- This is not perfect, will never be, but this documents the tools and configuration I use pretty much daily.
- I would add specific fixes for my devices(T480 w/i5, Ideapad w/11th gen i5) here, so keep that in mind I guess.
- This is partly made with Claude and DeepSeek. For more info on the division of work, see below.

<details>
<summary> Division of Work </summary>

|Task|Made with AI?| Work Split (No AI/AI) |
|---|---|---|
|Original Script|Trafotin with some modifications by me and AI| 80-20 |
|Adding Packages|Me with AI processing it|40-60|
|Adding Hardening|Trafotin Scripts + modifications by me and AI|70-30|

</details>

# References:
https://gitlab.com/trafotin/os-install-scripts
