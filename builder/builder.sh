#!/bin/sh
#
# Build `caddy` with `caddy-git` plugin, possibly using alternate source repos.
#
# Usage (in docker):
#
#   docker run --rm builder-image /build [version]
#
# Version to build, including the `v` prefix, is passed either as the first
# argument or via the `$version` env var (default: `v0.10.11`).  Any valid Git
# reference should work.
#
# Upstream sources for `caddy` and `caddy-git` are set via `$upstream_caddy`
# (default: `mholt`) and `$upstream_caddy_git` (default: `abiosoft`) env vars.
# Both can be set using the shorthand `$upstream` env var.

set -e

: ${version:=$1}
: ${version:=v0.10.11}
: ${upstream_caddy:=$upstream}
: ${upstream_caddy:=mholt}
: ${upstream_caddy_git:=$upstream}
: ${upstream_caddy_git:=abiosoft}

pkg() { printf 'github.com/%s/%s' "$@" ; }

gosrc() { printf '/go/src/%s' "$(pkg "$@")" ; }

clone() {
  local users=$1 repo=$2
  shift 2
  local github=${users%%:*} go=${users##*:}
  local src=https://"$(pkg $github $repo)" dst="$(gosrc $go $repo)"
  local ref=${1-} branch= checkout=false
  # construct `git clone` args in positional params
  set --
  if test -n "$ref"
  then
    # add branch arg if the ref is a branch on the remote end
    # otherwise, will need to checkout locally
    if git ls-remote --heads "$src" "$ref" 2>/dev/null | grep -q .
    then set -- -b $ref
    else checkout=true
    fi
  fi
  # can shallow-clone unless a checkout is required
  $checkout || set -- "$@" --depth 1
  git clone -o $github "$@" "$src" "$dst"
  $checkout || return 0
  cd "$(gosrc $go $repo)"
  git checkout --force $ref
}

{
  printf 'Building Caddy (version=%s)\n' "$version"
  printf '  %s src: https://%s\n' \
    caddy "$(pkg $upstream_caddy caddy)" \
    caddy-git "$(pkg $upstream_caddy_git caddy-git)"
} >&2

clone "${upstream_caddy}":mholt caddy $version
clone "${upstream_caddy_git}":abiosoft caddy-git
clone caddyserver builds

cat > "$(gosrc mholt caddy)"/caddyhttp/extraplugins.go <<ADD_PKG_GO
package caddyhttp
import _ "$(pkg abiosoft caddy-git)"
ADD_PKG_GO

cd "$(gosrc mholt caddy)"/caddy
export CGO_ENABLED=0 GOOS=${GOOS:-linux} GOARCH=${GOARCH:-amd64}
trim="-trimpath=$GOPATH"
go build -o /install/caddy -asmflags "$trim" -gcflags "$trim"
