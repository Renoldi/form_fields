# Contributing to FormFields

Thank you for your interest in contributing to FormFields! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/form_fields.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Commit: `git commit -m 'Add feature description'`
6. Push: `git push origin feature/your-feature-name`
7. Open a Pull Request

## Development Setup

```bash
# Get dependencies
flutter pub get

# Run example app
cd example
flutter run

# Run tests (if available)
flutter test
```

## Code Style

- Follow Dart style guide: https://dart.dev/guides/language/effective-dart/style
- Use `dart format` to format code
- Use `dart analyze` to check for issues
- Write meaningful commit messages

## Commit Messages

- Use clear, descriptive messages
- Start with a verb: "Add", "Fix", "Update", "Remove"
- Reference issues when relevant: "Fix #12"

Examples:
- `Add date range picker support`
- `Fix validation message for email fields`
- `Update documentation examples`

## Pull Request Process

1. Update documentation if needed
2. Add/update tests if applicable
3. Ensure code passes analysis: `dart analyze`
4. Format code: `dart format .`
5. Provide clear PR description explaining changes
6. Link related issues

## Reporting Issues

When reporting issues, include:

- Clear description of the problem
- Steps to reproduce
- Expected behavior
- Actual behavior
- Dart/Flutter versions
- Code example

Example:
```
**Description:** Email validation is not working for emails with plus sign

**Steps to reproduce:**
1. Create FormFields with FormType.email
2. Enter email: test+tag@example.com
3. Observe validation error

**Expected:** Email should be validated as valid
**Actual:** Shows validation error

**Environment:**
- Dart: 3.0.0
- Flutter: 3.10.0
```

## Feature Requests

When suggesting features, include:

- Clear description of the feature
- Use case/motivation
- Example usage
- Any related issues

## Questions?

Open an issue with the `question` label or provide feedback through GitHub Discussions.

Thank you for contributing!
