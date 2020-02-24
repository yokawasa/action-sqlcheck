#!/usr/bin/env bash
set -x

TMPDIR="${GITHUB_WORKSPACE}/output"

POST_COMMENT=$1
GITHUB_TOKEN=$2

post_pr_comment() {
  local msg=$1
  payload=$(echo '{}' | jq --arg body "${msg}" '.body = $body')
  request_url=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
  curl -s -S \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "${payload}" \
    "${request_url}" > /dev/null
}

main() {
  # Create tmp dir if not exist
  if [ ! -d ${TMPDIR} ]
  then
    mkdir -p ${TMPDIR}
  fi

  # Get target sql files
  sql_files=$(git diff origin/${GITHUB_BASE_REF}..origin/${GITHUB_HEAD_REF} \
    --diff-filter=AM \
    --name-only -- '*.sql')

  # Run sqlcheck for each target file and get output
  risk_found_c=0
  unset risk_files
  unset risk_outputs
  for sql_file in ${sql_files};
  do
    if [ -f ${sql_file} ]
    then
      output_file="${TMPDIR}/${RANDOM}"
      /usr/local/bin/sqlcheck -r 1 -f ${sql_file} > ${output_file}
      RET=$?
      if [ $RET -ne 0 ]; then   # risk found
        risk_files[${risk_found_c}]=${sql_file}
        risk_outputs[${risk_found_c}]=${output_file}
        (( risk_found_c++ ))
      fi
    else
      echo "${sql_file} not found!" >&2  # skip
    fi
  done
  # Post an issue if risks are found with sqlcheck in sql files
  if [ "${POST_COMMENT}" = "true" ] && [ ${risk_found_c} -gt 0 ]; then
    comment_title="SQL Risks Found"
    comment_body=""

    c=0
    while [[ ${c} -lt ${risk_found_c} ]];
    do
      f=${risk_files[${c}]}
      o=$(cat ${risk_outputs[${c}]})
      comment_body="${comment_body}
<details><summary><code>${f}</code></summary>
\`\`\`
${o}
\`\`\`
"
      (( c++ ))
    done

    comment_msg="${comment_title}
${comment_body}   
"
    post_pr_comment ${comment_msg}
  fi
}

main "$@"
