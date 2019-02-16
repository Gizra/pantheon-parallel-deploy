# pantheon-parallel-deploy

Modular deployment process to similar sites on Pantheon hosting platform. Practical for large number of almost identical sites, where the paralell execution is useful.

## Requirements
 * Bash
 * [terminus](https://pantheon.io/docs/terminus/)
 * [GNU Parallel](https://www.gnu.org/software/parallel/)

## Usage

## Initial configuration

The initial configuration is optional, if skipped, the script will ask for these parameters interactively.

Under a specific project or under `$HOME`, create a file `.pantheon-parallel-deploy` with the following content:
```bash
ORG=orgname
TAG=tagname
```

One of the above parameters are required.
If you specify only the organization, all the sites under the specific Pantheon organization will be added to the list of sites to deploy.
If you specify the organization and the tag, the sites under the specific Pantheon organization are filtered by the specific tag, so a narrowed down list will added to the list of sites to deploy.
If you only specify the tag, all the sites will be filtered by sitename (non-organization accounts do not have tagging).

## Command line arguments
Usage: `./deploy.sh [options] [modules]" 61)`

The options:
 - `-h` - Show the usage
 - `-y` - Always yes, non-interactive (if config file present)
 - `-m` - Show the list of available deployment modules. These can be activated independently to perform optional steps.
 - `-l` - If specified, deploy from test to live environment, otherwise deploy from dev to test.
 - `-e` - Text file path. Exclude the list of sites from the deploy.
 - `-c` - Amount of concurrent deploys. Default value: 2. This helps to execute large number of deploys across many sites quicker.
 - `-t` - Activates test mode. No change is done on the sites, just print the commands that would be executed.

## Custom deployment modules

Under your project, you can write specific deployment modules and the script will recognize them when it's launched from the project directory.

A sample deployment script would look like this:
```bash
#!/bin/bash

# Deploy module: make sure admin user cannot login.

t drush "$1" -- user:block admin
```

That must live under `$PROJECT_ROOT/deploy_modules/modulename.sh`.
As you see, `terminus` is invoked via a wrapper to make test mode possible and the site identifier is passed to the script via the first argument.
