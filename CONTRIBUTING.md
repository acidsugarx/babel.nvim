# Contributing to babel.nvim

Thank you for your interest in contributing to babel.nvim!

## Development Setup

1. Fork and clone the repository
2. Install dependencies for linting/formatting:
   - [StyLua](https://github.com/JohnnyMorganz/StyLua) for formatting
   - [selene](https://github.com/Kampfkarren/selene) for linting
   - [typos](https://github.com/crate-ci/typos) for spell checking

## Code Style

- Format your code with StyLua before committing
- Run selene to check for lint errors
- Use descriptive variable names
- Add comments for complex logic (in English)

### Running Checks Locally

```bash
# Run all checks (format + lint)
make chores

# Format only
make style

# Lint only
make lint

# Run tests (when available)
make test
```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Ensure all checks pass (`make chores`)
4. Update CHANGELOG.md with your changes under `[Unreleased]`
5. Submit a pull request

## Commit Messages

Use clear, descriptive commit messages:
- `feat: add DeepL provider support`
- `fix: handle empty translation response`
- `docs: update README with new config options`
- `refactor: simplify picker detection logic`

## Adding a New Translation Provider

1. Create a new file in `lua/babel/providers/`
2. Follow the structure of `google.lua`
3. Export the provider in `lua/babel/providers/init.lua`
4. Add tests for the new provider
5. Update README.md with configuration options

## Reporting Issues

When reporting issues, please include:
- Neovim version (`:version`)
- babel.nvim version/commit
- Minimal reproduction config
- Expected vs actual behavior
- Error messages (if any)

## Questions?

Feel free to open an issue for questions or discussions.
