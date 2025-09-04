# Ignored Directory

This directory contains files that are useful for local development but should NOT be committed to the remote repository.

## Contents

- **`setup-github-aws-oidc.sh`** - One-time setup for AWS OIDC authentication
- **`demo-setup.sh`** - Prepares environment for interview demos  
- **`dev-setup.sh`** - Manages containerized development environment
- **`Dockerfile`** - Containerized development environment
- **`docker-compose.yml`** - Orchestrates development services
- **`.dockerignore`** - Excludes files from Docker build context

## Purpose

These files are for local development, setup, and demos. They are not part of the core platform and are ignored by git.

## Usage

Use these files locally for development tasks, but they won't be deployed or shared via the repository.
