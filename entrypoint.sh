#!/usr/bin/env bash
set -x

TMPDIR="${GITHUB_WORKSPACE}/output"
POST_COMMENT=$1
GITHUB_TOKEN=$2
POSTFIXES=$3

if [ -z "$GITHUB_TOKEN" ]; then
  >&2 echo "Set the GITHUB_TOKEN input variable."
  exit 1
fi
if [ -z "$POST_COMMENT" ]; then
  POST_COMMENT="true"
fi
if [ -z "$POSTFIXES" ]; then
  POSTFIXES="sql"
fi

get_pr_files(){
  local postfixes=$1
  pr_num=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.number)
  request_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pr_num}/files"
  files=$(curl -s -X GET -G ${request_url} | jq -r '.[] | .filename')
  matched_files=""
  for f in ${files}
  do
    f_postfix=$(echo "${f##*.}" |  tr '[A-Z]' '[a-z]')
    for p in $(echo ${postfixes} | tr ',' ' ' )
    do
      if [ "${p}" = "${f_postfix}" ]; then
        matched_files="${matched_files} ${f}"
      fi
    done
  done
  echo ${matched_files}
}

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

  sql_files=$(get_pr_files ${POSTFIXES} )

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

</details>
"
      (( c++ ))
    done

    comment_msg="##${comment_title}
${comment_body}   
"
    post_pr_comment "${comment_msg}"
  fi
}

main "$@"
