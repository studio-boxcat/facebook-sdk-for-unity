#!/bin/sh
#
# Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Facebook.
#
# As with any software that integrates with the Facebook platform, your use of
# this software is subject to the Facebook Developer Principles and Policies
# [http://developers.facebook.com/policy/]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN

# shellcheck disable=SC2039

. $(dirname $0)/common.sh

source "$PROJECT_ROOT/scripts/build.properties"

info "Starting build"
# Check for required settings
if [ -z "$ANDROID_HOME" ]; then
    echo "${RED}ERROR: ANDROID_HOME environment variable not set${NC}"
    echo "${RED}Please set the ANDROID_HOME environment variable to point to your android sdk${NC}"
    exit 1
fi

localBuild=false
if [[ $* == *--local* ]]; then
  localBuild=true
fi

#skycatle build
skycastleBuild=false
if [[ $* == *--skycastle* ]]; then
  skycastleBuild=true
fi

# Copy the required libs
UNITY_PLUGIN_FACEBOOK="$UNITY_PACKAGE_ROOT/Assets/FacebookSDK/Plugins/Android/libs"

FB_WRAPPER_PATH="$PROJECT_ROOT/facebook-android-wrapper"
FB_ANDROID_SDK_WRAPPER_NAME="facebook-android-wrapper-release.aar"
FB_ANDROID_SDK_WRAPPER="$FB_WRAPPER_PATH/build/outputs/aar/$FB_ANDROID_SDK_WRAPPER_NAME"

# Local build only properties
FB_WRAPPER_LIB_PATH="$FB_WRAPPER_PATH/libs"
FB_GS_SDK_AAR_NAME="facebook-gamingservices-release.aar"
# FB_GS_SDK_AAR_PATH="$FB_WRAPPER_LIB_PATH/$FB_GS_SDK_AAR_NAME"
FB_GS_SDK_AAR="$FB_ANDROID_SDK_PATH/facebook-gamingservices/build/outputs/aar/$FB_GS_SDK_AAR_NAME"

# Get Unity Jar Resolver
info "Step 1 - Download $UNITY_JAR_RESOLVER_NAME"
if [ "$skycastleBuild" = true ]; then
  info "Using custom version from Skycastle builder resource repo."
else
  downloadUnityJarResolverFromGithub
fi

info "Step 2 - Build android wrapper"
pushd "$FB_WRAPPER_PATH"
if [ "$localBuild" = true ]; then
  if [ ! -d "$FB_WRAPPER_LIB_PATH" ]; then
    mkdir -p "$FB_WRAPPER_LIB_PATH" || die "Failed to create wrapper libs folder"
  fi
  info "Step 2.1 - Build local Facebook Gaming Services Android SDK at '$FB_ANDROID_SDK_PATH'"
  pushd $FB_ANDROID_SDK_PATH
  ./gradlew :facebook-gamingservices:assemble || die "Failed to build Facebook Gaming Services Android SDK"
  popd
  info "Step 2.2 - Copy $FB_ANDROID_SDK_AAR to $FB_WRAPPER_LIB_PATH/$FB_GS_SDK_AAR_NAME folder"
  cp "$FB_GS_SDK_AAR" "$FB_WRAPPER_LIB_PATH/$FB_GS_SDK_AAR_NAME" || die "Failed to copy sdk to wrapper libs folder"
  ./gradlew clean -PlocalRepo=libs -PsdkVersion="$FB_ANDROID_SDK_VERSION" -Pskycastle=$skycastleBuild || die "Failed to perform gradle clean"
  ./gradlew assemble -PlocalRepo=libs -PsdkVersion="$FB_ANDROID_SDK_VERSION" -Pskycastle=$skycastleBuild || die "Failed to build facebook android wrapper"
else
  ./gradlew clean -Pskycastle=$skycastleBuild || die "Failed to perform gradle clean"
  ./gradlew assemble -Pskycastle=$skycastleBuild || die "Failed to build facebook android wrapper"
fi
popd

info "Step 3 - Copy libs to unity plugin folder"
if [ ! -d "$UNITY_PLUGIN_FACEBOOK" ]; then
  mkdir -p "$UNITY_PLUGIN_FACEBOOK" || die "Failed to make unity plugin lib folder"
fi
# clean the unity lib folder
rm -rf $UNITY_PLUGIN_FACEBOOK/*.jar
rm -rf $UNITY_PLUGIN_FACEBOOK/*.aar
rm -rf $UNITY_PLUGIN_FACEBOOK/*.meta

# Copy aars
cp "$FB_ANDROID_SDK_WRAPPER" "$UNITY_PLUGIN_FACEBOOK" || die 'Failed to copy wrapper to unity plugin folder'
# Rename wrapper to include sdk version
mv "$UNITY_PLUGIN_FACEBOOK/$FB_ANDROID_SDK_WRAPPER_NAME" "$UNITY_PLUGIN_FACEBOOK/facebook-android-wrapper-$SDK_VERSION.aar"

info "Done!"
