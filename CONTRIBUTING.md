# Contributing to HTTPAssertion

Thank you for your interest in contributing to HTTPAssertion! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/HTTPAssertion.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Xcode 15.0 or later
- Swift 6.0 or later
- iOS Simulator for testing

### Building the Project

```bash
# Build the package
swift build

# Run tests
swift test
```

### Running the Example Project

The repository includes an example project in `Example/Demo/`:

1. Open `Example/Demo/Demo.xcodeproj` in Xcode
2. Build and run the project in the iOS Simulator
3. Run the UI tests to see HTTPAssertion in action

## Code Style Guidelines

### Swift Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Write documentation comments for public APIs
- Maintain Swift 6.0 compatibility

### Documentation

- All public APIs must include documentation comments
- Use English for all documentation and comments (even if development communication is in Japanese)
- Include usage examples for complex APIs

### Testing

- Write unit tests for new functionality
- Ensure all tests pass before submitting a PR
- Add integration tests for UI testing features
- Test on both iOS and macOS when applicable

## Submitting Changes

### Pull Request Process

1. Ensure your code follows the project's coding standards
2. Update documentation for any new or changed functionality
3. Add or update tests as appropriate
4. Ensure all tests pass
5. Update CHANGELOG.md with your changes
6. Submit a pull request with a clear description of the changes

### Pull Request Guidelines

- Use a clear and descriptive title
- Provide a detailed description of what the PR does
- Reference any related issues
- Include screenshots for UI-related changes
- Keep PRs focused on a single feature or bug fix

### Commit Message Format

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

Examples:
```
feat(logging): add support for custom HTTP headers
fix(testing): resolve race condition in request matching
docs: update README with advanced usage examples
```

## Project Structure

```
HTTPAssertion/
├── Sources/
│   ├── HTTPAssertionLogging/     # App-side HTTP logging
│   └── HTTPAssertionTesting/     # XCUITest assertion APIs
├── Tests/
│   └── HTTPAssertionTests/       # Unit and integration tests
├── Example/
│   └── Demo/                     # Example iOS app
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── Package.swift
```

## Architecture Notes

### HTTPAssertionLogging

- Uses method swizzling for URLSessionConfiguration interception
- Implements custom URLProtocol for request/response logging
- Stores data in simulator shared directory for cross-process access
- Built with Swift concurrency (actors, async/await)

### HTTPAssertionTesting

- Provides XCUITest-compatible assertion APIs
- Supports flexible request matching (URL, headers, query parameters)
- Includes waiting functionality for asynchronous operations
- Thread-safe file-based storage system

## Reporting Issues

When reporting issues, please include:

- HTTPAssertion version
- Xcode version
- iOS/macOS version
- Clear reproduction steps
- Expected vs actual behavior
- Code samples (when applicable)

## Feature Requests

For feature requests:

- Check existing issues to avoid duplicates
- Provide clear use case and motivation
- Suggest implementation approach if possible
- Consider backward compatibility implications

## Questions

For questions about usage or development:

- Check the README.md first
- Search existing issues
- Create a new issue with the "question" label

## Code of Conduct

Please be respectful and constructive in all interactions. We want to maintain a welcoming environment for all contributors.

## License

By contributing to HTTPAssertion, you agree that your contributions will be licensed under the MIT License.