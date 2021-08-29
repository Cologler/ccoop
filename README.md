# Ccoop

Ccoop is my forked version of [Scoop](https://github.com/lukesampson/scoop).

## Different from Scoop

### Features

- Also cleanup buckets when run `scoop cleanup`;
- `scoop list --json` write json to stdout;
- use `scoop config autoupdate false` to disable auto update;
- Auto uninstall if package install failed when you install it again;
- Able to pipe `scoop list` to `grep` or `ripgrep`;

#### Dispatch External First

When you installed `scoop-*` like packages ([scoop-search](https://github.com/tokiedokie/scoop-search)),
you can use `scoop *` to call them now.

They have higher priority.

### Fixes

- Won't remove all package when you run `scoop uninstall .`;
- Won't remove current version package when you run `scoop cleanup .`;
- Won't [breaking working directory if you cancel the update](https://github.com/lukesampson/scoop/issues/4358);

### Performance

- Ccoop is faster, because it only run scripts (like `core.ps1`) once;

### For Developers

- Install Ccoop in editable mode is possiable;
