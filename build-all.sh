#!/usr/bin/env zsh
set -e
set -o pipefail

SCRIPT="$(cd "$(dirname "${(%):-%x}")" && pwd)/$(basename "${(%):-%x}")"
REPO_URL="${REPO_URL:-r.j3ss.co}"
JOBS=${JOBS:-2}

ERRORS="$(pwd)/errors"

build_and_push() {
  base=$1
  suite=$2
  build_dir=$3

  echo "Building ${REPO_URL}/${base}:${suite} for context ${build_dir}"
  docker build --rm --force-rm -t "${REPO_URL}/${base}:${suite}" "${build_dir}" || return 1

  # on successful build, push the image
  echo "                       ---                                   "
  echo "Successfully built ${base}:${suite} with context ${build_dir}"
  echo "                       ---                                   "
}

dofile() {
  f=$1
  image=${f%Dockerfile}
  base=${image%%\/*}
  build_dir=$(dirname "$f")
  suite=${build_dir##*\/}

  if [[ -z $suite ]] || [[ $suite == "$base" ]]; then
    suite=latest
  fi

  {
    $SCRIPT build_and_push "${base}" "${suite}" "${build_dir}"
  } || {
    # add to errors
    echo "${base}:${suite}" >> "$ERRORS"
  }
  echo
  echo
}

main() {
  # get the dockerfiles
  files=("${(@f)$(find -L . -iname '*Dockerfile' | sed 's|./||' | sort)}")

  # build all dockerfiles
  echo "Running in parallel with ${JOBS} jobs."
  autoload -U zargs
  # Use -L 1 instead of -n 1 (zargs counts input list items, not arguments)
  zargs -L 1 -P "${JOBS}" -- "${files[@]}" -- "$SCRIPT" dofile

  if [[ ! -f $ERRORS ]]; then
    echo "No errors, hooray!"
  else
    echo "[ERROR] Some images did not build correctly, see below." >&2
    echo "These images failed: $(cat "$ERRORS")" >&2
    exit 1
  fi
}

run() {
  args=$*
  f=$1

  if [[ $f == "" ]]; then
    main "$args"
  else
    # Use zsh word splitting to execute function with arguments
    ${=args}
  fi
}

run "$@"
