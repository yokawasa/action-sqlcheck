# Change Log

All notable changes to the "action-sqlcheck" will be documented in this file.

## 1.2.1
- No longer use the latest sqlcheck BUT `sqlcheck v1.2` for immutability
- fix entrypoint.sh as sqlcheck v1.2 exits with code 0 even if anti-patterns or hints are found
- Change base image from alpine to ubuntu to speed up the action spin up

## 1.1.0
- Fixup a bug (PR #12) thanks to @NathanBurkett - The cURL request fails if the repository is not public

## 1.0.0
- Add Input parameter `verbose` to include verbose warning to the analysis result

## 0.0.5
- Add new input parameter: risk-level

## 0.0.4
- Use API to get pull request files and no longer use git command

## 0.0.3
- Fixup bug: add git to install in Dockerfile

## 0.0.2
- Fixup bug: wrong entrypoint path in Dockerfile
- Added varidation check - entrypoint.sh

## 0.0.1
- Initial release (alpha release)
