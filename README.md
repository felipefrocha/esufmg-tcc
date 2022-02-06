# esufmg-tcc
This is a repo for create and describe TCC files

## [DevContianer](https://code.visualstudio.com/docs/remote/containers)
### GITHUB Access
- [ ] Personal Access Token
    - Scope:
        - [ ] repository
        - [ ] write:package
- [ ] Package GHCR
    - `echo "<PAT>" | docker login ghcr.io --username "GITHUB_USER" --passowrd-stdin`
    - Command: docker pull ghcr.io/felipefrocha/action-docker-build-latex:main