# action-sqlcheck

GitHub Actions that automatically identifies anti-patterns in SQL queries using [sqlcheck](https://github.com/jarulraj/sqlcheck) when PR is requested  and comment on the PR if risks are found in the queries  

![](assets/action-sqlcheck-pr-comment.png)

## Usage

Supports `pull_request` event type.

### Inputs
|Parameter|Required|Default Value|Description|
|:--:|:--:|:--:|:--|
|`post-comment`|false|true|Post comment to PR if it's true|
|`token`|true|""|GitHub Token in order to add comment to PR|
|`risk-level`|false|3|Set of SQL anti-patterns to check: 1,2, or 3<br>- 1 (all anti-patterns, default)<br>- 2 (only medium and high risk anti-patterns)<br> - 3 (only high risk anti-patterns) |
|`verbose`|false|false|Add verbose warnings to SQLCheck analysis result|
|`postfixes`|false|"sql"|List of file postfix to match |
|`directories`|false|""| Path(s) of directory under which the action check any files whether they are part of the repository or not. By default, the action checks only files in PR queries. By specifying directories the action no longer check files in PR queries but files under the directories (maxdepth 3)|

### Outputs
|Parameter|Description|
|:--:|:--:|
|`issue-found`| A boolean value to indicate an issue was found in the files that sqlcheck action checked|


## Sample Workflow
### Sample1
> .github/workflows/test1.yml

```yaml
name: sqlcheck workflow1
on: pull_request

jobs:
  sqlcheck:
    name: sqlcheck job
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: yokawasa/action-sqlcheck@v1.3.0
      with:
        post-comment: true
        risk-level: 3
        verbose: false
        token: ${{ secrets.GITHUB_TOKEN }}
```

### Sample2 ( postfixes and directories inputs )
> .github/workflows/test2.yml

```yaml
name: sqlcheck workflow2
on: pull_request

jobs:
  sqlcheck:
    name: sqlcheck job
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: yokawasa/action-sqlcheck@v1.3.0
      id: sqlcheck
      with:
        post-comment: true
        risk-level: 3
        verbose: true
        token: ${{ secrets.GITHUB_TOKEN }}
        postfixes: |
          sql
          sqlx
          schema
        directories: |
          sql
          build/sql_dir
          tests/sql_dir
    - name: Get output
      run: echo "Issues found in previous step"
      if: steps.sqlcheck.outputs.issue-found
```
