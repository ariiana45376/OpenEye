#!/usr/bin/env bash
set -e

if (( $# > 1 )); then
    echo "Usage: $0 [seed]" >&2
    exit 2
fi
seed=${1-42}
case $seed in ''|*[!0-9]*) echo 'Seed must be a nonnegative integer' >&2; exit 2;; esac

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
mkdir -p results
# Builds, headers and CSV files are shared; run sequentially with other PE tests.
exec 9>results/.run.lock
flock -n 9 || { echo 'Another recorded PE run is active' >&2; exit 1; }
run_dir=$(mktemp -d "$PWD/results/seed${seed}.XXXXXX")
command=(make run SIM=icarus "SEED=$seed"
    "COCOTB_RESULTS_FILE=$run_dir/results.xml"
    "COCOTB_PLUSARGS=+FST_PATH=$run_dir/PE.fst")
{
    printf 'seed=%s\ncommand=cd %q && ' "$seed" "$PWD"
    printf '%q ' "${command[@]}"
    printf '\n'
} > "$run_dir/metadata.txt"
printf 'Results: %s\n' "$run_dir"

set +e
"${command[@]}" 2>&1 | tee "$run_dir/output.log"
statuses=("${PIPESTATUS[@]}")
set -e
status=${statuses[0]}
if (( status == 0 )); then status=${statuses[1]}; fi
if [[ -f "$run_dir/results.xml" ]]; then
    cp -- parameters_PE.vh parameters_PE_cluster.vh "$run_dir/" || status=$?
fi
printf 'exit_status=%s\n' "$status" >> "$run_dir/metadata.txt"
exit "$status"
