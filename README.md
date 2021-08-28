# Ccoop

Ccoop is my forked version of [Scoop](https://github.com/lukesampson/scoop).

## Different from Scoop

- Won't [breaking working directory if we cancel the update](https://github.com/lukesampson/scoop/issues/4358);
- Also cleanup buckets when run `scoop cleanup`;
- `scoop list --json` write json to stdout;
- use `scoop config autoupdate false` to disable auto update;
- Auto uninstall if package install failed when you install it again;

### For Developers

- Install Ccoop in editable mode;
