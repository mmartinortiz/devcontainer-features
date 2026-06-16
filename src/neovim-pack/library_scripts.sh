#!/usr/bin/env bash

clean_download() {
  # The purpose of this function is to download a file with minimal impact on container layer size
  # this means if no valid downloader is found (curl or wget) then we install a downloader (currently wget) in a
  # temporary manner, and making sure to
  # 1. uninstall the downloader at the return of the function
  # 2. revert back any changes to the package installer database/cache (for example apt-get lists)
  # The above steps will minimize the leftovers being created while installing the downloader
  # Supported distros:
  #  debian/ubuntu/alpine

  url=$1
  output_location=$2
  tempdir=$(mktemp -d)
  downloader_installed=""

  function _apt_get_install() {
    tempdir=$1

    # copy current state of apt list - in order to revert back later (minimize contianer layer size)
    cp -p -R /var/lib/apt/lists $tempdir
    apt-get update -y
    apt-get -y install --no-install-recommends wget ca-certificates
  }

  function _apt_get_cleanup() {
    tempdir=$1

    echo "removing wget"
    apt-get -y purge wget --auto-remove

    echo "revert back apt lists"
    rm -rf /var/lib/apt/lists/*
    rm -r /var/lib/apt/lists && mv $tempdir/lists /var/lib/apt/lists
  }

  function _apk_install() {
    tempdir=$1
    # copy current state of apk cache - in order to revert back later (minimize contianer layer size)
    cp -p -R /var/cache/apk $tempdir

    apk add --no-cache wget
  }

  function _apk_cleanup() {
    tempdir=$1

    echo "removing wget"
    apk del wget
  }
  # try to use either wget or curl if one of them already installer
  if type curl >/dev/null 2>&1; then
    downloader=curl
  elif type wget >/dev/null 2>&1; then
    downloader=wget
  else
    downloader=""
  fi

  # in case none of them is installed, install wget temporarly
  if [ -z $downloader ]; then
    if [ -x "/usr/bin/apt-get" ]; then
      _apt_get_install $tempdir
    elif [ -x "/sbin/apk" ]; then
      _apk_install $tempdir
    else
      echo "distro not supported"
      exit 1
    fi
    downloader="wget"
    downloader_installed="true"
  fi

  if [ $downloader = "wget" ]; then
    wget -q $url -O $output_location
  else
    curl -sfL $url -o $output_location
  fi

  # NOTE: the cleanup procedure was not implemented using `trap X RETURN` only because
  # alpine lack bash, and RETURN is not a valid signal under sh shell
  if ! [ -z $downloader_installed ]; then
    if [ -x "/usr/bin/apt-get" ]; then
      _apt_get_cleanup $tempdir
    elif [ -x "/sbin/apk" ]; then
      _apk_cleanup $tempdir
    else
      echo "distro not supported"
      exit 1
    fi
  fi

}

detect_libc() {
  # Returns "musl" on Alpine/musl systems, "gnu" otherwise
  if [ -x "/sbin/apk" ]; then
    echo "musl"
  elif ldd --version 2>&1 | grep -qi musl; then
    echo "musl"
  else
    echo "gnu"
  fi
}

resolve_latest_tag() {
  # Resolve "latest" to actual tag via HTTP redirect (zero API calls).
  # GitHub redirects /releases/latest → /releases/tag/{actual_tag}
  local repo="$1"
  local url="https://github.com/${repo}/releases/latest"
  local resolved

  if type curl >/dev/null 2>&1; then
    resolved=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$url")
  elif type wget >/dev/null 2>&1; then
    resolved=$(wget --spider --max-redirect=5 -S "$url" 2>&1 | grep -i 'Location:' | tail -1 | awk '{print $2}' | tr -d '\r')
  else
    echo "Error: curl or wget required for resolve_latest_tag" >&2
    exit 1
  fi

  # Extract tag from URL: https://github.com/owner/repo/releases/tag/v1.2.3 → v1.2.3
  echo "${resolved##*/}"
}

install_gh_release() {
  # Download a GitHub release asset, extract it, and install the binary.
  # Zero API calls — constructs direct download URL.
  #
  # Usage: install_gh_release <repo> <tag> <asset_filename> <binary_name> [install_tree]
  #
  # Handles .tar.gz and .zip assets.
  # If install_tree is "true", copies the entire extracted directory tree into
  # /usr/local/ (for tools like neovim that need runtime files alongside the binary).
  # Otherwise, searches for <binary_name> and copies just that to /usr/local/bin/.
  local repo="$1"
  local tag="$2"
  local asset="$3"
  local binary="$4"
  local install_tree="${5:-false}"

  local url="https://github.com/${repo}/releases/download/${tag}/${asset}"
  local tmp_dir
  tmp_dir=$(mktemp -d -t gh-release-XXXXXXXXXX)

  echo "Installing ${binary} from ${repo}@${tag}..."
  echo "  URL: ${url}"

  # Download
  clean_download "$url" "${tmp_dir}/${asset}"

  # Extract
  case "$asset" in
    *.tar.gz|*.tgz)
      tar xzf "${tmp_dir}/${asset}" -C "$tmp_dir"
      ;;
    *.zip)
      unzip -qo "${tmp_dir}/${asset}" -d "$tmp_dir"
      ;;
    *)
      echo "Error: unsupported asset format: ${asset}" >&2
      rm -rf "$tmp_dir"
      exit 1
      ;;
  esac

  if [ "$install_tree" = "true" ]; then
    # Find the top-level extracted directory (e.g. nvim-linux-x86_64/)
    # and merge its contents into /usr/local/
    local extracted_dir
    extracted_dir=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [ -z "$extracted_dir" ]; then
      echo "Error: no directory found in extracted archive" >&2
      rm -rf "$tmp_dir"
      exit 1
    fi
    cp -r "${extracted_dir}"/* /usr/local/
    echo "  Installed tree: ${extracted_dir##*/}/* → /usr/local/"
  else
    # Find and install binary
    local found
    found=$(find "$tmp_dir" -name "$binary" -type f -executable | head -1)

    # Some archives have the binary without +x
    if [ -z "$found" ]; then
      found=$(find "$tmp_dir" -name "$binary" -type f | head -1)
    fi

    if [ -z "$found" ]; then
      echo "Error: binary '${binary}' not found in extracted archive" >&2
      ls -laR "$tmp_dir" >&2
      rm -rf "$tmp_dir"
      exit 1
    fi

    chmod +x "$found"
    cp "$found" /usr/local/bin/"$binary"
    echo "  Installed: /usr/local/bin/${binary}"
  fi

  rm -rf "$tmp_dir"
}

ensure_nanolayer() {
  # Ensure existance of the nanolayer cli program
  local variable_name=$1

  local required_version=$2
  # normalize version
  if ! [[ $required_version == v* ]]; then
    required_version=v$required_version
  fi

  local nanolayer_location=""

  # If possible - try to use an already installed nanolayer
  if [[ -z "${NANOLAYER_FORCE_CLI_INSTALLATION}" ]]; then
    if [[ -z "${NANOLAYER_CLI_LOCATION}" ]]; then
      if type nanolayer >/dev/null 2>&1; then
        echo "Found a pre-existing nanolayer in PATH"
        nanolayer_location=nanolayer
      fi
    elif [ -f "${NANOLAYER_CLI_LOCATION}" ] && [ -x "${NANOLAYER_CLI_LOCATION}" ]; then
      nanolayer_location=${NANOLAYER_CLI_LOCATION}
      echo "Found a pre-existing nanolayer which were given in env variable: $nanolayer_location"
    fi

    # make sure its of the required version
    if ! [[ -z "${nanolayer_location}" ]]; then
      local current_version
      current_version=$($nanolayer_location --version | tr -d '[:space:]')
      if ! [[ $current_version == v* ]]; then
        current_version=v$current_version
      fi

      if ! [ $current_version == $required_version ]; then
        echo "skipping usage of pre-existing nanolayer. (required version $required_version does not match existing version $current_version)"
        nanolayer_location=""
      fi
    fi

  fi

  # If not previuse installation found, download it temporarly and delete at the end of the script
  if [[ -z "${nanolayer_location}" ]]; then

    if [ "$(uname -sm)" == "Linux x86_64" ] || [ "$(uname -sm)" == "Linux aarch64" ]; then
      tmp_dir=$(mktemp -d -t nanolayer-XXXXXXXXXX)

      clean_up() {
        ARG=$?
        rm -rf $tmp_dir
        exit $ARG
      }
      trap clean_up EXIT

      if [ -x "/sbin/apk" ]; then
        clib_type=musl
      else
        clib_type=gnu
      fi

      tar_filename=nanolayer-"$(uname -m)"-unknown-linux-$clib_type.tgz

      # clean download will minimize leftover in case a downloaderlike wget or curl need to be installed
      clean_download https://github.com/devcontainers-extra/nanolayer/releases/download/$required_version/$tar_filename $tmp_dir/$tar_filename

      tar xfzv $tmp_dir/$tar_filename -C "$tmp_dir"
      chmod a+x $tmp_dir/nanolayer
      nanolayer_location=$tmp_dir/nanolayer

    else
      echo "No binaries compiled for non-x86-linux architectures yet: $(uname -m)"
      exit 1
    fi
  fi

  # Expose outside the resolved location
  declare -g ${variable_name}=$nanolayer_location

}
