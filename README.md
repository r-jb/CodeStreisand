# CodeStreisand

This project is for automatically archiving Git repositories using GitHub Actions. It creates a [bundle](https://git-scm.com/docs/git-bundle) for each repository in a list, and hosts them in a separate branch.

See this [demo](https://github.com/r-jb/CodeStreisand/tree/archive).

## Features

- Backup repositories to a GitHub repository
- Automatically update the archived repos
- Supports posting to the [Software Heritage](https://www.softwareheritage.org/)

## Usage

> [!TIP]  
> If you want to host your archives privately, you can also import this repo using [GitHub Importer](https://docs.github.com/en/migrations/importing-source-code/using-github-importer/importing-a-repository-with-github-importer#importing-a-repository-with-github-importer)

1. Fork this repository
2. Edit [`list.txt`](list.txt) with the URLs of the repositories you want to archive, one per line
3. Trigger the manual run by going to `Actions` -> `Update Archives` -> `Run Workflow`
4. (Optional) Change the update schedule in [`main.yml`](.github/workflows/main.yml)

> [!NOTE]  
> The results are stored in the `archive` branch by default
