#!/bin/bash

set -euo pipefail

CHART_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for tool in helm yq jq; do
    command -v "$tool" > /dev/null
done

helm lint "$CHART_DIR"

for clustering in false true; do
    baseline=""
    for autoscaling in false true; do
        rendered="$(helm template test "$CHART_DIR" \
            --set clustering.enabled="$clustering" \
            --set autoscaling.enabled="$autoscaling" \
            --set replicaCount=3 \
            --set clustering.jgroups.port=7790 \
            --set clustering.jgroups.fdPort=57790 \
            --set clustering.encryption.existingSecret=test-cluster-key \
            | yq -o=json '.' | jq -s '.')"

        printf '%s' "$rendered" | jq -e \
            --argjson clustering "$clustering" \
            --argjson autoscaling "$autoscaling" '
            map(select(.kind == "Deployment")) as $deployments |
            ($deployments | length == 1) and
            ($deployments[0].spec as $spec |
                (if $autoscaling then ($spec | has("replicas") | not)
                 else $spec.replicas == 3 end) and
                ($spec.template.spec as $pod |
                    $pod.containers[0] as $container |
                    ([$container.env[].name]) as $names |
                    if $clustering then
                        ([$container.ports[] | select(.name == "jgroups") | .containerPort] == [7790]) and
                        ([$container.ports[] | select(.name == "jgroups-fd") | .containerPort] == [57790]) and
                        ([$container.env[] | select(.name == "POD_IP") | .valueFrom.fieldRef.fieldPath] == ["status.podIP"]) and
                        ([$container.env[] | select(.name == "JAVA_OPTS_APPEND") | .value] |
                            length == 1 and all(.[];
                                contains("-Dreshapr.infinispan.stack=reshapr-k8s") and
                                contains("-Dreshapr.infinispan.dns-query=test-reshapr-proxy-headless.default.svc.cluster.local") and
                                contains("$(RESHAPR_CLUSTER_STORE_PASSWORD)") and
                                contains("$(RESHAPR_CLUSTER_KEY_PASSWORD)"))) and
                        (($names | index("RESHAPR_CLUSTER_STORE_PASSWORD")) < ($names | index("JAVA_OPTS_APPEND"))) and
                        (($names | index("RESHAPR_CLUSTER_KEY_PASSWORD")) < ($names | index("JAVA_OPTS_APPEND"))) and
                        ([$container.volumeMounts[] | select(.name == "cluster-keystore") | .readOnly] == [true]) and
                        ([$pod.volumes[] | select(.name == "cluster-keystore") | .secret.secretName] == ["test-cluster-key"]) and
                        ($pod.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution | length == 1)
                    else
                        ([$container.ports[].name] == ["http"]) and
                        ([$container.env[] | select(.name == "POD_IP" or .name == "JAVA_OPTS_APPEND" or
                            .name == "RESHAPR_CLUSTER_STORE_PASSWORD" or .name == "RESHAPR_CLUSTER_KEY_PASSWORD")] | length == 0) and
                        ([$container.volumeMounts[] | select(.name == "cluster-keystore")] | length == 0) and
                        ([$pod.volumes[] | select(.name == "cluster-keystore")] | length == 0)
                    end)) and
            ([.[] | select(.kind == "HorizontalPodAutoscaler")] | length == (if $autoscaling then 1 else 0 end))
        ' > /dev/null

        pod_template="$(printf '%s' "$rendered" | jq -cS '.[] | select(.kind == "Deployment") | .spec.template')"
        if [[ "$autoscaling" == false ]]; then
            baseline="$pod_template"
        else
            [[ "$pod_template" == "$baseline" ]]
        fi
        printf 'PASS clustering=%s autoscaling=%s\n' "$clustering" "$autoscaling"
    done
done