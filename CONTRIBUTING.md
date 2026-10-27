# Contributing

This is a small hobby project. Feel free to change things for your own setup. A focused PR for something you believe was broken is welcome, and ideally you should DM **cherry** on the Runes of Magic Discord about it too. Support and review are best effort; there is no review deadline or release schedule.

## Sending a fix

1. Make a branch from `main` and keep the change focused on one problem.
2. Explain how to reproduce the problem and what changes after the fix.
3. Test it in the RoM client where possible, including Reload UI if the change touches loading, events, settings or hooks. Say exactly what you checked and anything you could not check.
4. Run `python tools/build_release.py` for packaging checks, then install `tests/requirements.txt` in your own environment and run `python -m unittest discover -s tests -p "test_*.py" -v` for Lua 5.1 regressions.
5. Open a PR and mention any relevant addon/kit versions and probe output.

The original addon test harnesses and generators mentioned in some archived READMEs were not supplied with the initial import. Do not claim those checks passed unless you have the tools and actually ran them.

## Working in the code

- Keep addon folder names, saved-variable names and existing user settings compatible unless the change needs a migration.
- Use the existing Lua/XML patterns and load order. RoM's API differs from WoW's; verify an API in this client before depending on it.
- Preserve the original credits, licence files and media notices.
- Update the affected addon README when commands, installation, limitations or behaviour change.
- Every changed addon needs a new runtime version for a new release. Update its package metadata and README, bump the kit version, and follow [the release guide](docs/RELEASING.md). Keep unchanged addon packages byte-identical.

## Reporting a bug

Use [GitHub Issues](https://github.com/Cherrybooze/Cherrys-Kit/issues) or DM cherry on the Runes of Magic Discord. Include the kit and addon versions, the client/server you tested, steps to reproduce, and expected versus actual behaviour. Run the addon's probe command when its README recommends it.

Do not attach a whole SaveVariables file or GlobalBankHelper export: these can contain character details, chat keys and inventory data. Share the relevant error or probe output instead.
