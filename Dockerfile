# Golden Path Infrastructure Platform - Development Tools
# Lightweight container for consistent linting and local development tasks
# across all platforms (Windows, macOS, Linux)

FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TERRAFORM_VERSION=1.6.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    jq \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install ShellCheck
RUN apt-get update && apt-get install -y shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install additional tools via apt (avoiding pip issues)
RUN apt-get update && apt-get install -y \
    yamllint \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install pre-commit in a virtual environment
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install pre-commit \
    && ln -s /opt/venv/bin/pre-commit /usr/local/bin/pre-commit

# Create development user
RUN useradd -m -s /bin/bash developer

# Set up working directory
WORKDIR /workspace

# Copy repository files
COPY . /workspace/

# Make scripts executable
RUN chmod +x scripts/*.sh platform/*.sh

# Set ownership
RUN chown -R developer:developer /workspace

# Switch to development user
USER developer

# Set up Git configuration
RUN git config --global init.defaultBranch main \
    && git config --global user.name "Developer" \
    && git config --global user.email "developer@example.com"

# Set up shell environment
RUN echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc \
    && echo 'export PS1="🔧 Dev Tools: \w$ "' >> ~/.bashrc

# Default command
CMD ["/bin/bash"]
