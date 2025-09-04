# 🤝 Contributing Guidelines

> **How to contribute to the Golden Path Infrastructure Platform repository.**

## 🎯 **Getting Started**

Thank you for your interest in contributing to the Golden Path Infrastructure Platform! This guide will help you get started with contributing to the repository.

## 📋 **Prerequisites**

Before contributing, ensure you have:

- [ ] Read this contributing guide
- [ ] Set up your [development environment](local-development.md) or [containerized tools](containerized-development.md)
- [ ] Familiarized yourself with the [repository structure](../repository-structure.md)
- [ ] Reviewed the [code quality standards](code-quality.md)

## 🔄 **Development Workflow**

### **1. Fork and Clone**
```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/your-username/infrastructure-platform-devops.git
cd infrastructure-platform-devops

# Add upstream remote
git remote add upstream https://github.com/your-org/infrastructure-platform-devops.git
```

### **2. Create a Feature Branch**
```bash
# Create and switch to a new branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/your-bug-description
```

### **3. Make Changes**
- Write your code following the [code quality standards](code-quality.md)
- Update documentation as needed
- Add tests if applicable

### **4. Test Your Changes**
```bash
# Run linting (required)
./scripts/pre-commit-lint.sh

# Or using containerized tools
./scripts/dev-setup.sh lint

# Run additional tests
./scripts/dev-setup.sh validate
```

### **5. Commit Your Changes**
```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "feat: add your feature description"
```

### **6. Push and Create Pull Request**
```bash
# Push your branch
git push origin feature/your-feature-name

# Create a pull request on GitHub
```

## 📝 **Commit Message Convention**

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### **Format**
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### **Types**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### **Examples**
```bash
# Feature
git commit -m "feat: add containerized development tools"

# Bug fix
git commit -m "fix: resolve ShellCheck error in setup script"

# Documentation
git commit -m "docs: update contributing guidelines"

# Breaking change
git commit -m "feat!: change Terraform module interface

BREAKING CHANGE: The module now requires a different variable structure"
```

## 🎨 **Code Quality Standards**

### **Terraform**
- Use `terraform fmt -recursive` before committing
- Run `terraform validate` after changes
- Follow [Terraform best practices](https://developer.hashicorp.com/terraform/language)
- Use meaningful variable and resource names
- Add comments for complex logic

### **Shell Scripts**
- Use ShellCheck for linting
- Follow [Shell Script Best Practices](https://google.github.io/styleguide/shellguide.html)
- Use `set -e` for error handling
- Quote variables properly
- Use meaningful function and variable names

### **Documentation**
- Use clear, concise language
- Keep documentation up-to-date with code changes
- Use proper markdown formatting
- Include examples where helpful

## 🧪 **Testing Requirements**

### **Required Tests**
- [ ] All linting checks pass
- [ ] Terraform validation passes
- [ ] ShellCheck passes for all shell scripts
- [ ] Documentation is updated

### **Optional Tests**
- [ ] Manual testing of new features
- [ ] Integration testing with existing components
- [ ] Performance testing for significant changes

## 📚 **Documentation Requirements**

### **When to Update Documentation**
- Adding new features
- Changing existing functionality
- Modifying configuration options
- Updating development processes

### **Documentation Types**
- **README files**: High-level overview and quick start
- **Code comments**: Explain complex logic
- **Inline documentation**: Explain configuration options
- **API documentation**: For scripts and modules

## 🔍 **Pull Request Process**

### **Before Submitting**
- [ ] Run all required tests
- [ ] Update documentation
- [ ] Follow commit message conventions
- [ ] Ensure your branch is up-to-date with main

### **Pull Request Template**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Linting passes
- [ ] Terraform validation passes
- [ ] Manual testing completed
- [ ] Documentation updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### **Review Process**
1. **Automated Checks**: CI/CD pipeline runs linting and validation
2. **Code Review**: Team members review the code
3. **Testing**: Additional testing if needed
4. **Approval**: Maintainer approves the PR
5. **Merge**: PR is merged into main branch

## 🚫 **What Not to Commit**

- **Secrets**: Never commit API keys, passwords, or tokens
- **Large files**: Use Git LFS for large files
- **Temporary files**: Use `.gitignore` for temporary files
- **Personal configuration**: Don't commit personal settings

## 🆘 **Getting Help**

### **Questions and Support**
- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and discussions
- **Team Slack**: For quick questions and collaboration
- **Documentation**: Check existing docs first

### **Reporting Issues**
When reporting issues, include:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Relevant logs or error messages

## 🎯 **Contribution Areas**

### **Code Contributions**
- Bug fixes
- New features
- Performance improvements
- Code refactoring

### **Documentation Contributions**
- Improving existing documentation
- Adding missing documentation
- Fixing typos and errors
- Translating documentation

### **Testing Contributions**
- Adding new tests
- Improving test coverage
- Fixing flaky tests
- Performance testing

## 🏆 **Recognition**

Contributors are recognized through:
- GitHub contributor list
- Release notes acknowledgments
- Team recognition in meetings
- Contributor badges (if applicable)

## 📞 **Contact**

- **Maintainers**: @platform-team
- **Slack**: #golden-path-platform
- **Email**: platform-team@your-org.com

---

**Thank you for contributing! 🚀**
