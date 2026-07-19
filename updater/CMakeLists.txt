cmake_minimum_required(VERSION 3.16)
# Cocoa/Sparkle auto-updater .app for the mavericks-docker product. This is a SEPARATE project from
# the docker build (the repo root is project(... LANGUAGES NONE) and guards against non-preset
# configures); build it on its own with `cmake -S updater -B build-updater`. Native only: the product
# .pkg installs on the real 10.9 box, so the updater is x86_64 / min-10.9. It links Sparkle + Cocoa and
# NOTHING from docker (a Sparkle host has no product code) -- the release workflow asserts that.
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.9 CACHE STRING "updater runs on the 10.9 box")
set(CMAKE_OSX_ARCHITECTURES x86_64 CACHE STRING "Intel-only (10.9)")

project(MavericksDockerUpdater LANGUAGES C OBJC)   # C for mavericks_add_signer's native tools, OBJC for the app

find_package(MavericksSharedCMake REQUIRED)
include(MavericksSparkle)

# Single-source the version from the repo-root VERSION (this project's source dir is updater/).
file(STRINGS "${CMAKE_SOURCE_DIR}/../VERSION" MVD_VERSION LIMIT_COUNT 1)

# Sparkle framework: fetched (arch-thinned to x86_64) unless the CI passes it in with -D.
if(NOT DEFINED MVD_SPARKLE_FRAMEWORK)
  mavericks_fetch_sparkle(MVD_SPARKLE_FRAMEWORK)
endif()

# Build the native EdDSA signer the sanctioned way -- mavericks_add_signer, NOT the inline-cc shortcut
# golang/swift use. The release workflow signs the .pkg with the built mavericks_sign_update.
mavericks_fetch_ed25519(MVD_ED25519_SRC)
mavericks_add_signer(ED25519_SRC "${MVD_ED25519_SRC}")

mavericks_add_updater_app(
  NAME MavericksDockerUpdater
  PRODUCT_NAME "Docker for Mavericks"
  BUNDLE_ID com.schmonz.MavericksDockerUpdater
  FEED_URL "https://github.com/schmonz/mavericks-docker/releases/latest/download/appcast.xml"
  ED_PUBKEY "75mVrNGJhuo5r0yaff5Sd5wCsjKQnPirhpXX5qEkUJw="   # docker product's EdDSA public key
  ICON "${CMAKE_SOURCE_DIR}/mavericks-docker-updater.icns"
  VERSION "${MVD_VERSION}"
  AUTO_CHECK true
  SPARKLE_FRAMEWORK "${MVD_SPARKLE_FRAMEWORK}"
  LOG_PREFIX "MavDockerUpdater"
  CONFIRM_TITLE "Docker for Mavericks updated"
  CONFIRM_BODY "Docker CLI, Compose, Machine, and the boot2docker image were updated."
  RELAUNCH_MARKER "/tmp/.mavericks-docker-updater-relaunched"
  # no PANE_HINT_KEY -> background-found updates post an NSUserNotification (CLI product, no pane)
)
