#!/bin/bash

origin_bucket_prefix() {
    echo "pulumi-docs-origin"
}

post_github_pr_comment() {
    local pr_comment=$1
    local pr_comment_api_url=$2
    local pr_comment_body=$(printf '{ "body": "%s" }' "$pr_comment")

    curl -s \
         -X POST \
         -H "Authorization: token ${GITHUB_TOKEN}" \
         -d "$pr_comment_body" \
         $pr_comment_api_url > /dev/null
}

echo "${GITHUB_EVENT_NAME}"
echo "${GITHUB_EVENT_PATH}"

if [[ "$GITHUB_EVENT_NAME" == "pull_request" && ! -z "$GITHUB_EVENT_PATH" ]]; then
    event="$(cat "$GITHUB_EVENT_PATH")"

    pr_number="$(echo $event | jq -r ".number")"
    pr_action="$(echo $event | jq -r ".action")"
    pr_merged="$(echo $event | jq -r ".merged")"

    echo "${pr_number}"
    echo "${pr_action}"
    echo "${pr_merged}"

    if [[ "$pr_action" == "closed" && "$pr_merged" == "false" ]]; then
        pr_bucket_name="$(origin_bucket_prefix)-pr-${pr_number}"
        pr_comment_api_url="$(echo $event | jq -r ".pull_request._links.comments.href")"

        echo "$pr_bucket_name"
        echo "$pr_comment_api_url"

        # if [ ! "$(aws s3api head-bucket --bucket $pr_bucket_name || echo '')" ]; then
        #     echo "Bucket ${pr_bucket_name} doesn't seem to exist. Exiting."
        #     exit 0
        # fi

        # echo "Found bucket ${pr_bucket_name}."

        prod_metadata="$(curl -s https://pulumi.com/metadata.json || echo '')"
        prod_bucket_name="$(echo $prod_metadata | jq -r ".bucket" || echo '')"

        if [[ ! -z "$prod_metadata" && "$pr_bucket_name" == "$prod_bucket_name" ]]; then
            echo "Bucket ${pr_bucket_name} appears to be serving the production website. Exiting."
            exit 0
        else

            # Delete the bucket.
            echo "Removing the bucket."
            # aws s3 rb "s3://${pr_bucket}" --force

            # Post a PR comment that the bucket was removed.
            post_github_pr_comment \
                "The site preview for this pull request was removed. ✨" \
                $pr_comment_api_url
        fi
    fi
fi
