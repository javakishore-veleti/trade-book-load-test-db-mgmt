# Trade Book Load Test DB Management

This repository is dedicated to managing database schema changes for the Trade Book CRUD API services using Liquibase. It includes Liquibase changelogs, configuration files, and scripts for applying and rolling back changes to the PostgreSQL database schema across various environments, including local developer setups and remote AWS EC2 instances.

## Repository Structure

- **changelogs/**: Directory containing Liquibase changelog files.
  - **master-changelog.xml**: The main changelog file that includes all versioned changelogs.
  - **v1.0/**: Directory containing version 1.0 changelogs.
- **properties/**: Directory containing environment-specific Liquibase properties files.
  - **liquibase-dev.properties**: Configuration for the `dev` environment.
  - **liquibase-qa.properties**: Configuration for the `qa` environment.
  - *(Add more properties files as needed for each environment)*
- **scripts/**: Shell scripts for various operations.
  - **apply-changes.sh**: Script to apply database changes based on the specified environment.
  - **rollback-changes.sh**: Script to rollback database changes based on the specified environment.
  - **install-liquibase-mac.sh**: Script to install Liquibase on a macOS local environment.
  - **install-liquibase-windows.sh**: Script to install Liquibase on a Windows local environment.
  - **install-liquibase-remote.sh**: Script to install or upgrade Liquibase on remote AWS EC2 Ubuntu machines or local environments.
- **ec2-instances.json**: Configuration file listing the IP addresses, Liquibase versions, and installation flags for different environments and machines.
- **README.md**: Documentation and usage instructions.

## Getting Started

### Prerequisites

- **Liquibase**: Install Liquibase on your local machine or remote environment. [Installation Guide](https://www.liquibase.org/download)
- **PostgreSQL**: Ensure PostgreSQL is set up and accessible.

### Configuring Liquibase

Update the appropriate `liquibase.properties` file for your environment with the correct database connection details:

```properties
url=jdbc:postgresql://localhost:5432/trade_book_db
username=your_db_username
password=your_db_password
changeLogFile=changelogs/master-changelog.xml
driver=org.postgresql.Driver
classpath=path/to/postgresql-connector.jar

## Managing Environments

The repository supports different environments (e.g., dev, qa, prod-us, local-dev, etc.) as specified in the ec2-instances.json file. This file contains configuration details such as IP addresses, Liquibase versions, and flags for making a specific version the latest.

```json
{
  "local-dev": [
    {
      "ip": "127.0.0.1",
      "version": "4.23.1",
      "make-it-latest": true,
      "os": "mac"
    }
  ],
  "local-dev-windows": [
    {
      "ip": "127.0.0.1",
      "version": "4.23.1",
      "make-it-latest": true,
      "os": "windows"
    }
  ],
  "dev": [
    {
      "ip": "192.168.1.10",
      "version": "4.23.1",
      "make-it-latest": true
    }
  ],
  "qa": [
    {
      "ip": "192.168.2.11",
      "version": "4.21.0",
      "make-it-latest": false
    },
    {
      "ip": "192.168.2.12",
      "version": "4.21.0",
      "make-it-latest": false
    }
  ],
  "prod-us": [
    {
      "ip": "54.85.123.45",
      "version": "4.22.0",
      "make-it-latest": true
    },
    {
      "ip": "54.85.123.46",
      "version": "4.22.0",
      "make-it-latest": false
    }
  ]
}


```

## Applying and Rolling Back Changes
Use the provided scripts to apply or rollback database changes:

### Apply Changes
To apply changes to a specific environment (e.g., dev), run the apply-changes.sh script with the environment name:

```shell
npm run run-liquibase-dev
```

### Rollback Changes
To rollback changes for a specific environment, use the rollback-changes.sh script with the environment name:

```shell
npm run rollback-liquibase-dev
```

## Installing or Upgrading Liquibase 
You can install or upgrade Liquibase on different environments using the provided scripts:

### Install on macOS Local Environment:
```shell
npm run install-liquibase-mac
```

### Install on Windows Local Environment:
```shell
npm run install-liquibase-windows
```

### Install or Upgrade on Remote EC2 Instances or Local Machines:
```shell
npm run install-liquibase-remote dev
```

Or specify multiple IP addresses:

```shell
npm run install-liquibase-remote dev 192.168.1.10,127.0.0.1
```

