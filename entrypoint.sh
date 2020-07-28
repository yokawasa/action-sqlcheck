#!/usr/bin/env bash
set -x

TMPDIR="${GITHUB_WORKSPACE}/output"
POST_COMMENT=$1
GITHUB_TOKEN=$2
RISK_LEVEL=$3
VERBOSE=$4
POSTFIXES=$5
DIRECTORIES=$6

if [ -z "${GITHUB_TOKEN}" ]; then
  >&2 echo "Set the GITHUB_TOKEN input variable."
  exit 1
fi
if [ -z "${POST_COMMENT}" ]; then
  POST_COMMENT="true"
fi
if [ -z "${RISK_LEVEL}" ]; then
  RISK_LEVEL="3"
fi
if [ -z "${VERBOSE}" ]; then
  VERBOSE="false"
fi
if [ -z "${POSTFIXES}" ]; then
  POSTFIXES="sql"
fi

get_pr_files(){
  local postfixes=$1
  pr_num=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.number)
  request_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pr_num}/files"
  auth_header="Authorization: token $GITHUB_TOKEN"
  files=$(curl -s -H "$auth_header" -X GET -G ${request_url} | jq -r '.[] | .filename')
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

get_directories_files(){
  local directories=$1
  local postfixes=$2
  matched_files=""
  for base in $(echo ${directories} | tr ',' ' ' )
  do
    for f in $(find ${base} -maxdepth 3 -type f)
    do
      f_postfix=$(echo "${f##*.}" |  tr '[A-Z]' '[a-z]')
      for p in $(echo ${postfixes} | tr ',' ' ' )
      do
        if [ "${p}" = "${f_postfix}" ]; then
          matched_files="${matched_files} ${f}"
        fi
      done
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

  postfixes_csv=$(echo "${POSTFIXES}" | tr ' ' ',' ) 
  sql_files=$(get_pr_files "${postfixes_csv}" )
  if [ ! -z "${DIRECTORIES}" ]; then
    directories_csv=$(echo "${DIRECTORIES}" | tr ' ' ',' )
    sql_files_under_dirs=$(get_directories_files "${directories_csv}" "${postfixes_csv}")
    sql_files=$(echo ${sql_files} ${sql_files_under_dirs})  
  fi

  # Run sqlcheck for each target file and get output
  risk_found_c=0
  unset risk_files
  unset risk_outputs
  for sql_file in ${sql_files};
  do
    if [ -f ${sql_file} ]
    then
      output_file="${TMPDIR}/${RANDOM}"
      if [ "${VERBOSE}" = "true" ]; then
        /usr/bin/sqlcheck -v -r ${RISK_LEVEL} -f ${sql_file} > ${output_file}
      else
        /usr/bin/sqlcheck -r ${RISK_LEVEL} -f ${sql_file} > ${output_file}
      fi
      if grep "^No issues found." ${output_file} > /dev/null 2>&1; then
        echo "NO issues found: ${sql_file}"
      else  # Issues found
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

\`\`\`\n
${o}
\`\`\`

</details>
"

      (( c++ ))
    done

    comment_msg="## ${comment_title}
${comment_body}   
"
    post_pr_comment "${comment_msg}"
  fi
  if [ ${risk_found_c} -gt 0 ]; then
    echo "::set-output name=issue-found::true"
  fi
}

main "$@"
