# Lint & Security Workflow

Reusable GitHub Actions workflow for YAML linting and security scanning.

## Features

- YAML linting with pre-commit hooks and yamllint
- Automatic lint fixes via GitHub App
- Security scanning with Checkov and Trivy
- Helm chart linting
- Profile-based configuration system

## Usage

### Option 1: Reusable Workflow

Create `.github/workflows/lint.yml` in your repository:

```yaml
name: Lint & Security

on:
  pull_request:
    paths:
      - '**.yaml'
      - '**.yml'

jobs:
  lint-and-security:
    uses: darkobas2/lint-test/.github/workflows/lint.yml@main
    permissions:
      contents: write
      pull-requests: write
      security-events: write
    with:
      checkov_skip_checks: 'CKV_K8S_43,CKV_K8S_40'
      trivy_skip_dirs: '.git,.github,vendor'
    secrets:
      LINT_BOT_APP_ID: ${{ secrets.LINT_BOT_APP_ID }}
      LINT_BOT_PRIVATE_KEY: ${{ secrets.LINT_BOT_PRIVATE_KEY }}
```

### Option 2: Local Pre-commit

Install pre-commit hooks locally:

```bash
# Install pre-commit
pip install pre-commit

# Bootstrap configuration (auto-detects profiles from repo name)
curl -sSf https://raw.githubusercontent.com/darkobas2/lint-test/main/install.sh | bash

# Install git hooks
pre-commit install

# Run checks
pre-commit run --all-files
```

Alternative: Use the bootstrap config to auto-sync on every pre-commit run:

```bash
curl -o .pre-commit-config.yaml https://raw.githubusercontent.com/darkobas2/lint-test/main/.pre-commit-config.bootstrap.yaml
pre-commit install
```

## Profile System

The pre-commit configuration uses a profile-based system. Profiles are automatically detected based on repository name or can be specified manually.

### Automatic Detection

The install script detects profiles from your repository name:
- `cloudformation` or `cfn` in name: CloudFormation profile
- `terraform` or `tf-` in name: Terraform profile
- `ansible` in name: Ansible profile
- `kubernetes`, `k8s`, or `helm` in name: Kubernetes profile

### Manual Profiles

Create a `.pre-commit-profiles` file in your repository root:

```
kubernetes
terraform
```

Available profiles: `base`, `cloudformation`, `terraform`, `ansible`, `kubernetes`

## Configuration

### Workflow Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `auto_fix` | Auto-commit lint fixes | `true` |
| `checkov_enabled` | Run Checkov security scanning | `true` |
| `checkov_skip_checks` | Comma-separated checks to skip | `''` |
| `checkov_framework` | Frameworks to scan | `kubernetes,helm,secrets` |
| `trivy_enabled` | Run Trivy security scanning | `true` |
| `trivy_skip_dirs` | Directories to skip | `.git,.github` |
| `helm_lint_enabled` | Run Helm chart linting | `true` |

### Security Enforcement

Security scans block merges by default. The workflow enforces:
- Checkov: Blocks on all findings
- Trivy: Blocks on CRITICAL, HIGH, and MEDIUM severity

Configure skip lists to exclude specific checks:
- `checkov_skip_checks`: Skip specific Checkov checks
- `trivy_skip_dirs`: Exclude directories from Trivy scans

## GitHub App Setup

For automatic lint fixes, create a GitHub App:

1. Settings → Developer settings → GitHub Apps → New App
2. Configure permissions:
   - Contents: Read & Write
   - Pull Requests: Read & Write
3. Install on your organization or repositories
4. Generate and download private key
5. Add secrets to your repository or organization:
   - `LINT_BOT_APP_ID`: Application ID
   - `LINT_BOT_PRIVATE_KEY`: Private key content

Without a GitHub App, the workflow uses GITHUB_TOKEN with limited permissions on protected branches.

## How It Works

The workflow runs three parallel jobs:

1. **Lint & Format**: Runs pre-commit hooks, auto-commits fixes if configured
2. **Helm Lint**: Validates Helm charts if present
3. **Security Scan**: Runs Checkov and Trivy, uploads SARIF results

Loop prevention: The workflow skips linting when the last commit is from lint-bot, preventing infinite auto-fix loops.

## Configuration Files

### Pre-commit Profiles

Located in `pre-commit/` directory:
- `base.yaml`: Core hooks for file hygiene, YAML linting, shell checking
- `cloudformation.yaml`: CloudFormation-specific linting
- `terraform.yaml`: Terraform validation and security checks
- `kubernetes.yaml`: Kubernetes manifest validation
- `ansible.yaml`: Ansible linting and validation

### yamllint Config

The `.yamllint` file configures YAML validation rules:
- 2-space indentation
- Excludes Helm templates
- Disables line length limits
- Allows flexible quoted strings

## Examples

Skip specific security checks:

```yaml
with:
  checkov_skip_checks: 'CKV_K8S_8,CKV_K8S_9,CKV_K8S_10'
  trivy_skip_dirs: '.git,.github,vendor,node_modules'
```

Disable auto-fix:

```yaml
with:
  auto_fix: false
```

## License

MIT
