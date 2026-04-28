{
  username = "your-username";
  fullName = "Your Full Name";
  email    = "your@email.com";

  # Locale / timezone — find yours with `timedatectl list-timezones`
  timezone  = "Europe/Rome";
  locale    = "en_US.UTF-8";

  # Extra locale overrides — remove keys you don't need, or set to {}
  extraLocale = {};

  # Keyboard — run `localectl list-keymaps` for console maps,
  # `localectl list-x11-keymap-layouts` for X11/Wayland layouts
  keyboardLayout  = "us";
  keyboardVariant = "";

  # Machine identity — keep this out of the repo
  hostname = "my-hostname";   # used for networking.hostName
  gpu      = "amd";           # host file to load: amd or nvidia

  # SSH public key for authorized_keys
  sshPublicKey = "ssh-ed25519 AAAA... your-key-comment";
}
