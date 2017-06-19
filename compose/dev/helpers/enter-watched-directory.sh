#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__dev_dir="$(cd "$(dirname "${__dir}")" && pwd)"
__compose_dir="$(cd "$(dirname "${__dev_dir}")" && pwd)"

cd ${__compose_dir}

# We use the archivematica-mcp-server service but the volume is available for
# other services too.

docker-compose run --rm --no-deps \
	--entrypoint bash \
	--workdir /var/archivematica/sharedDirectory \
		archivematica-mcp-server "$@"
