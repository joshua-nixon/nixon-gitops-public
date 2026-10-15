#!/bin/bash

set -euo pipefail

ALERTMANAGER_URL="${ALERTMANAGER_HOST}/api/v2/alerts"

log_message() {
    echo "[$1] $2"
}

log_new_line(){
    echo ""
}

split_version() {
    local version="${1#v}"
    version="${version%%-*}"

    local major minor
    IFS='.' read -r major minor _ <<< "$version"

    major="${major:-0}"
    minor="${minor:-0}"

    echo "${major}.${minor}"
}

is_newer_series() {
    local current_mm="$1"
    local latest_mm="$2"

    local current_major current_minor latest_major latest_minor
    IFS='.' read -r current_major current_minor <<< "$current_mm"
    IFS='.' read -r latest_major latest_minor <<< "$latest_mm"

    if (( latest_major > current_major )); then
        return 0
    fi

    if (( latest_major == current_major && latest_minor > current_minor )); then
        return 0
    fi

    return 1
}

declare -A CHART_REPO_BY_NAME
declare -A CHART_VERSION_BY_NAME

build_chart_cache() {
  local repo_index_json="$1"

  for repo in "${HTTP_HELM_REPOS[@]}"; do
      local repo_name repo_url
      read -r repo_name repo_url <<< "$repo"

      while IFS=$'\t' read -r chart_name full_repo_name chart_version; do
          [[ -z "$chart_name" ]] && continue

          if [[ -z "${CHART_REPO_BY_NAME[$chart_name]:-}" ]]; then
              CHART_REPO_BY_NAME[$chart_name]="$full_repo_name"
              CHART_VERSION_BY_NAME[$chart_name]="${chart_version#v}"
          fi
      done < <(
          jq -r --arg prefix "${repo_name}/" '
              .[]
              | select(.name | startswith($prefix))
              | [(.name | split("/") | .[-1]), .name, .version]
              | @tsv
          ' <<< "$repo_index_json"
      )
  done
}

get_oci_chart_version() {
    local oci_url="$1"
    
    local version
    version=$(helm show chart "$oci_url" 2>/dev/null | grep -E '^version:' | awk '{print $2}' | tr -d '"' || true)
    
    if [[ -n "$version" ]]; then
        echo "${version#v}"
        return 0
    fi
    return 1
}

find_chart_in_repos() {
    local target_chart="$1"

    if [[ -n "${CHART_REPO_BY_NAME[$target_chart]:-}" ]]; then
        echo "${CHART_REPO_BY_NAME[$target_chart]} ${CHART_VERSION_BY_NAME[$target_chart]}"
        return 0
    fi

    if [[ -n "${OCI_CHART_MAP[$target_chart]:-}" ]]; then
        local oci_url="${OCI_CHART_MAP[$target_chart]}"
        local oci_version=$(get_oci_chart_version "$oci_url")
        
        if [[ -n "$oci_version" ]]; then
            echo "$oci_url $oci_version"
            return 0
        fi
    fi

    return 1
}

UPDATES_LIST=()

record_update() {
    local release="$1"
    local chart="$2"
    local current_ver="$3"
    local new_ver="$4"

    UPDATES_LIST+=("• ${release} (${chart}): ${current_ver} -> ${new_ver}")
}

send_summary_alert() {
    local update_count="${#UPDATES_LIST[@]}"

    if [[ "$update_count" -eq 0 ]]; then
        log_message "INFO" "No updates found"
        return 0
    fi

    local updates_formatted=$(printf "%s\n" "${UPDATES_LIST[@]}")
    local future_epoch=$(( $(date +%s) + 86400 ))

    log_message "INFO" "Sending alert for $update_count pending update(s)"

    jq -n \
      --arg count "$update_count" \
      --arg list "$updates_formatted" \
      '[
        {
          "labels": {
            "alertname": "HelmChartUpdatesAvailable",
            "severity": "warning"
          },
          "annotations": {
            "summary": ($count + " Helm chart update(s) available"),
            "description": ("The following releases have newer chart versions available:\n\n" + $list)
          }
        }
      ]' | curl -s -XPOST "$ALERTMANAGER_URL" \
            -H 'Content-Type: application/json' \
            -d @- > /dev/null

    log_message "INFO" "Summary alert sent successfully"
}

HTTP_HELM_REPOS=(
    "jetstack https://charts.jetstack.io"
    "ingress-nginx https://kubernetes.github.io/ingress-nginx"
    "prometheus-community https://prometheus-community.github.io/helm-charts"
    "traefik https://traefik.github.io/charts"
    "argo https://argoproj.github.io/argo-helm"
    "cnpg https://cloudnative-pg.github.io/charts"
    "grafana https://grafana.github.io/helm-charts"
    "external-secrets https://charts.external-secrets.io"
    "hcloud https://charts.hetzner.cloud"
)

declare -A OCI_CHART_MAP=(
    ["netbird-operator"]="oci://ghcr.io/netbirdio/helm-charts/netbird-operator"
)

log_message "INFO" "Adding standard HTTP helm repositories"

for repo in "${HTTP_HELM_REPOS[@]}"; do
    read -r REPO_NAME REPO_URL <<< "$repo"    
    helm repo add "$REPO_NAME" "$REPO_URL" > /dev/null
done

helm repo update > /dev/null

log_message "INFO" "Building chart cache"
REPO_INDEX_JSON=$(helm search repo -o json)
build_chart_cache "$REPO_INDEX_JSON"

log_message "INFO" "Fetching helm list"
HELM_LIST=$(
    helm list --all-namespaces -o json | jq -c '.[]'
)

while read -r release; do
    [[ -z "$release" ]] && continue

    log_new_line
    
    IFS=$'\t' read -r RELEASE_NAME RELEASE_NAMESPACE CHART_WITH_VERSION <<< "$(jq -r '[.name, .namespace, .chart] | @tsv' <<< "$release")"

    if [[ "$CHART_WITH_VERSION" =~ ^(.+)-([vV]?[0-9].*)$ ]]; then
        CHART_NAME="${BASH_REMATCH[1]}"
        VERSION="${BASH_REMATCH[2]}"
    else
        log_message "WARN" "Unable to parse chart/version from '$CHART_WITH_VERSION'"
        continue
    fi

    VERSION="${VERSION#v}"

    log_message "INFO" "Checking release $RELEASE_NAME ($CHART_NAME)"

    CHART_INFO="$(find_chart_in_repos "$CHART_NAME" || true)"
    
    if [[ -z "$CHART_INFO" ]]; then
        log_message "WARN" "Chart '$CHART_NAME' not found in any registered repository or OCI map"
        continue
    fi

    read -r CHART_REPO CHART_VERSION <<< "$CHART_INFO"

    if [[ -z "$CHART_VERSION" ]]; then
        log_message "WARN" "Failed parsing version for '$CHART_NAME'"
        continue
    fi

    log_message "INFO" "Found chart $CHART_REPO ($CHART_VERSION)"

    VERSION_MM=$(split_version "$VERSION")
    CHART_VERSION_MM=$(split_version "$CHART_VERSION")

    if is_newer_series "$VERSION_MM" "$CHART_VERSION_MM"; then
        log_message "WARN" "New version available: $RELEASE_NAME ($CHART_NAME) $VERSION -> $CHART_VERSION"

        record_update "$RELEASE_NAME" "$CHART_NAME" "$VERSION" "$CHART_VERSION"
    fi

done <<< "$HELM_LIST"

log_new_line

send_summary_alert