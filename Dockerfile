# ============================================================================
# Frozen base image — IDENTICAL for every arm, every replicate.
# Build once, record the digest, never rebuild mid-experiment.
#
#   docker build -t cran-exp:base .
#   docker inspect --format='{{index .RepoDigests 0}}' cran-exp:base   # record this
#
# Two-layer design:
#   THIS LAYER  = OS + R + system deps + check tooling.  Frozen, arm-agnostic.
#   RUN LAYER   = the arm's declared package deps, installed at run time from
#                 the SAME date-pinned snapshot (see run_arm.sh).
#
# Rationale: arms legitimately diverge in DESCRIPTION. Baking deps into the
# image would either freeze them at C0 (arms that add a Suggests fail
# environmentally) or differ per arm (confounds the comparison). Installing at
# run time from a pinned snapshot keeps versions identical while allowing the
# dependency SET to vary.
# ============================================================================

# Pin by DIGEST, not tag. Tags move.
# rocker/r-ver:4.6.1 as of 2026-09-18 (Docker Hub API; "latest"/"4"/"4.6" all resolved
# to this same digest at pin time).
FROM rocker/r-ver@sha256:268e4c559c905a78519793f1a8c9ec5c8051a6ac98a16cbf489135ccdad330bb

# 2026-09-15: 3 days before the pin date, confirmed live (HTTP 200 on
# .../cran/2026-09-15/src/contrib/PACKAGES) so the snapshot is fully generated.
ARG PPM_SNAPSHOT_DATE=2026-09-15
ENV PPM_SNAPSHOT_DATE=${PPM_SNAPSHOT_DATE}

# --- System dependencies -----------------------------------------------------
# Under-provisioning here is the single biggest threat to the experiment:
# every arm burns turns on the same toolchain failure and the skill signal
# drowns. See pre-registration section 4.2 (hard gate).
RUN apt-get update && apt-get install -y --no-install-recommends \
      # R CMD check --as-cran essentials
      texlive-latex-base \
      texlive-latex-recommended \
      texlive-latex-extra \
      texlive-fonts-recommended \
      texlive-fonts-extra \
      lmodern \
      pandoc \
      qpdf \
      ghostscript \
      devscripts \
      # common package build deps
      libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
      libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
      libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
      # harness
      git curl jq nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# --- Date-pinned CRAN snapshot ----------------------------------------------
RUN echo "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/${PPM_SNAPSHOT_DATE}'))" \
      >> /usr/local/lib/R/etc/Rprofile.site \
 && echo "options(HTTPUserAgent = sprintf('R/%s R (%s)', getRversion(), \
      paste(getRversion(), R.version\$platform, R.version\$arch, R.version\$os)))" \
      >> /usr/local/lib/R/etc/Rprofile.site

# --- Frozen check tooling (section 4.1) -------------------------------------
RUN R -q -e "install.packages(c('rcmdcheck','urlchecker','spelling','rhub','desc','jsonlite'))"

# --- Claude Code -------------------------------------------------------------
# Pin the CLI version. It changes often; an unpinned install means arms run on
# different agents across a 3-week window.
# npm dist-tag "latest" as of 2026-09-18 (registry.npmjs.org).
ARG CLAUDE_CODE_VERSION=2.1.276
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# --- Offline documentation snapshot -----------------------------------------
# CRAN policy pages + the CRAN handbook, captured once and served identically
# to EVERY arm including the no-skill control (pre-registration section 6.4).
# Capture with: wget --mirror --convert-links --page-requisites
COPY snapshot/ /opt/cran-docs/
ENV CRAN_DOCS_PATH=/opt/cran-docs

# --- Environment verification gate ------------------------------------------
# Runs at image build. If the accepted version cannot check cleanly here,
# no experiment run may start.
COPY verify_env.sh /opt/verify_env.sh
RUN chmod +x /opt/verify_env.sh

WORKDIR /work
