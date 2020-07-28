# Change Log

All notable changes to the "action-sqlcheck" will be documented in this file.

## 1.3.0

- Add input paramter `directories` that allow you to add path(s) of directory under which the action check any files whether they are part of the repository or not. By default, the action checks only files in PR queries - [issue #16](https://github.com/yokawasa/action-sqlcheck/issues/16)
- Add output variable `issue-found` that is a boolean value to indicate an issue was found in the files that sqlcheck action checked

## 1.2.1

- No longer use the latest sqlcheck BUT `sqlcheck v1.2` for immutability
- fix entrypoint.sh as sqlcheck v1.2 exits with code 0 even if anti-patterns or hints are found
- Change base image from alpine to ubuntu to speed up the action spin up

## 1.1.0
- Fixup a bug ([PR #12](https://github.com/yokawasa/action-sqlcheck/pull/12)) thanks to @NathanBurkett - The cURL request fails if the repository is not public

## 1.0.0
- Add input parameter `verbose` to include verbose warning to the analysis result

## 0.0.5
- Add new input parameter `risk-level`

## 0.0.4
- Use API to get pull request files and no longer use git command

## 0.0.3
- Fixup bug: add git to install in Dockerfile

## 0.0.2
- Fixup bug: wrong entrypoint path in Dockerfile
- Added varidation check - entrypoint.sh

## 0.0.1
- Initial release (alpha release)
