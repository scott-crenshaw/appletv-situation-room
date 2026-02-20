#!/usr/bin/env python3
"""Generate a minimal Xcode project for tvOS SituationRoom app."""

import hashlib
import os

# Deterministic UUID-like IDs from a seed string
def make_id(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

PROJECT_DIR = "/Users/scott/Projects/mac-situation-room"
SOURCES_DIR = os.path.join(PROJECT_DIR, "SituationRoom", "Sources")
PROJ_DIR = os.path.join(PROJECT_DIR, "SituationRoom.xcodeproj")
PRODUCT_NAME = "SituationRoom"
BUNDLE_ID = "com.situationroom.tvos"
DEPLOY_TARGET = "18.0"

# Collect all .swift files
swift_files = []
for root, dirs, files in os.walk(SOURCES_DIR):
    for f in files:
        if f.endswith(".swift"):
            full = os.path.join(root, f)
            rel = os.path.relpath(full, PROJECT_DIR)
            swift_files.append((f, rel))

swift_files.sort(key=lambda x: x[1])

# Generate IDs
ROOT_GROUP_ID = make_id("root_group")
SOURCES_GROUP_ID = make_id("sources_group")
APP_GROUP_ID = make_id("app_group")
VIEWS_GROUP_ID = make_id("views_group")
MODELS_GROUP_ID = make_id("models_group")
SERVICES_GROUP_ID = make_id("services_group")
CONFIG_GROUP_ID = make_id("config_group")
PRODUCTS_GROUP_ID = make_id("products_group")
PROJECT_ID = make_id("project")
TARGET_ID = make_id("target")
BUILD_CONFIG_LIST_PROJECT = make_id("bcl_project")
BUILD_CONFIG_LIST_TARGET = make_id("bcl_target")
DEBUG_CONFIG_PROJECT = make_id("debug_project")
RELEASE_CONFIG_PROJECT = make_id("release_project")
DEBUG_CONFIG_TARGET = make_id("debug_target")
RELEASE_CONFIG_TARGET = make_id("release_target")
SOURCES_BUILD_PHASE = make_id("sources_build_phase")
FRAMEWORKS_BUILD_PHASE = make_id("frameworks_build_phase")
RESOURCES_BUILD_PHASE = make_id("resources_build_phase")
PRODUCT_REF = make_id("product_ref")

# File references and build file entries
file_refs = {}
build_files = {}
for fname, relpath in swift_files:
    fid = make_id(f"fileref_{relpath}")
    bid = make_id(f"buildfile_{relpath}")
    file_refs[relpath] = fid
    build_files[relpath] = bid

# Determine group membership
groups = {
    "App": [],
    "Views": [],
    "Models": [],
    "Services": [],
    "Config": [],
}
group_ids = {
    "App": APP_GROUP_ID,
    "Views": VIEWS_GROUP_ID,
    "Models": MODELS_GROUP_ID,
    "Services": SERVICES_GROUP_ID,
    "Config": CONFIG_GROUP_ID,
}

for fname, relpath in swift_files:
    if "/App/" in relpath:
        groups["App"].append(relpath)
    elif "/Views/" in relpath:
        groups["Views"].append(relpath)
    elif "/Models/" in relpath:
        groups["Models"].append(relpath)
    elif "/Services/" in relpath:
        groups["Services"].append(relpath)
    elif "/Config/" in relpath:
        groups["Config"].append(relpath)

# Build the pbxproj
lines = []
def w(s=""):
    lines.append(s)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t};")
w("\tobjectVersion = 56;")
w("\tobjects = {")
w("")

# PBXBuildFile
w("/* Begin PBXBuildFile section */")
for relpath, bid in build_files.items():
    fname = os.path.basename(relpath)
    fid = file_refs[relpath]
    w(f"\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};")
w("/* End PBXBuildFile section */")
w("")

# PBXFileReference
w("/* Begin PBXFileReference section */")
for relpath, fid in file_refs.items():
    fname = os.path.basename(relpath)
    w(f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{relpath}"; sourceTree = SOURCE_ROOT; }};')
w(f'\t\t{PRODUCT_REF} /* {PRODUCT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "{PRODUCT_NAME}.app"; sourceTree = BUILT_PRODUCTS_DIR; }};')
w("/* End PBXFileReference section */")
w("")

# PBXFrameworksBuildPhase
w("/* Begin PBXFrameworksBuildPhase section */")
w(f"\t\t{FRAMEWORKS_BUILD_PHASE} /* Frameworks */ = {{")
w("\t\t\tisa = PBXFrameworksBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXFrameworksBuildPhase section */")
w("")

# PBXGroup
w("/* Begin PBXGroup section */")
# Root group
w(f"\t\t{ROOT_GROUP_ID} = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{SOURCES_GROUP_ID} /* Sources */,")
w(f"\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,")
w("\t\t\t);")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Products group
w(f"\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w(f"\t\t\t\t{PRODUCT_REF} /* {PRODUCT_NAME}.app */,")
w("\t\t\t);")
w("\t\t\tname = Products;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Sources group
w(f"\t\t{SOURCES_GROUP_ID} /* Sources */ = {{")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for gname in ["App", "Config", "Models", "Services", "Views"]:
    w(f"\t\t\t\t{group_ids[gname]} /* {gname} */,")
w("\t\t\t);")
w("\t\t\tname = Sources;")
w("\t\t\tsourceTree = \"<group>\";")
w("\t\t};")

# Subgroups
for gname, members in groups.items():
    gid = group_ids[gname]
    w(f"\t\t{gid} /* {gname} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for relpath in members:
        fid = file_refs[relpath]
        fname = os.path.basename(relpath)
        w(f"\t\t\t\t{fid} /* {fname} */,")
    w("\t\t\t);")
    w(f"\t\t\tname = {gname};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

w("/* End PBXGroup section */")
w("")

# PBXNativeTarget
w("/* Begin PBXNativeTarget section */")
w(f"\t\t{TARGET_ID} /* {PRODUCT_NAME} */ = {{")
w("\t\t\tisa = PBXNativeTarget;")
w(f"\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_TARGET};")
w("\t\t\tbuildPhases = (")
w(f"\t\t\t\t{SOURCES_BUILD_PHASE} /* Sources */,")
w(f"\t\t\t\t{FRAMEWORKS_BUILD_PHASE} /* Frameworks */,")
w(f"\t\t\t\t{RESOURCES_BUILD_PHASE} /* Resources */,")
w("\t\t\t);")
w("\t\t\tbuildRules = (")
w("\t\t\t);")
w("\t\t\tdependencies = (")
w("\t\t\t);")
w(f'\t\t\tname = "{PRODUCT_NAME}";')
w(f"\t\t\tproductName = {PRODUCT_NAME};")
w(f"\t\t\tproductReference = {PRODUCT_REF} /* {PRODUCT_NAME}.app */;")
w('\t\t\tproductType = "com.apple.product-type.application";')
w("\t\t};")
w("/* End PBXNativeTarget section */")
w("")

# PBXProject
w("/* Begin PBXProject section */")
w(f"\t\t{PROJECT_ID} /* Project object */ = {{")
w("\t\t\tisa = PBXProject;")
w(f"\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_PROJECT};")
w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
w("\t\t\tdevelopmentRegion = en;")
w("\t\t\thasScannedForEncodings = 0;")
w("\t\t\tknownRegions = (")
w("\t\t\t\ten,")
w("\t\t\t\tBase,")
w("\t\t\t);")
w(f"\t\t\tmainGroup = {ROOT_GROUP_ID};")
w(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;")
w("\t\t\tprojectDirPath = \"\";")
w("\t\t\tprojectRoot = \"\";")
w("\t\t\ttargets = (")
w(f"\t\t\t\t{TARGET_ID} /* {PRODUCT_NAME} */,")
w("\t\t\t);")
w("\t\t};")
w("/* End PBXProject section */")
w("")

# PBXResourcesBuildPhase
w("/* Begin PBXResourcesBuildPhase section */")
w(f"\t\t{RESOURCES_BUILD_PHASE} /* Resources */ = {{")
w("\t\t\tisa = PBXResourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXResourcesBuildPhase section */")
w("")

# PBXSourcesBuildPhase
w("/* Begin PBXSourcesBuildPhase section */")
w(f"\t\t{SOURCES_BUILD_PHASE} /* Sources */ = {{")
w("\t\t\tisa = PBXSourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for relpath, bid in build_files.items():
    fname = os.path.basename(relpath)
    w(f"\t\t\t\t{bid} /* {fname} in Sources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXSourcesBuildPhase section */")
w("")

# XCBuildConfiguration
w("/* Begin XCBuildConfiguration section */")

# Project-level Debug
w(f"\t\t{DEBUG_CONFIG_PROJECT} /* Debug */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
w('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
w("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
w("\t\t\t\tCOPY_PHASE_STRIP = NO;")
w("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
w("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
w("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
w("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
w('\t\t\t\t\t"DEBUG=1",')
w('\t\t\t\t\t"$(inherited)",')
w("\t\t\t\t);")
w('\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;')
w("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
w(f'\t\t\t\tSDKROOT = appletvos;')
w("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
w("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
w(f'\t\t\t\tTVOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};')
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")

# Project-level Release
w(f"\t\t{RELEASE_CONFIG_PROJECT} /* Release */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
w('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
w("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
w("\t\t\t\tCOPY_PHASE_STRIP = NO;")
w('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
w("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
w("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
w('\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;')
w(f'\t\t\t\tSDKROOT = appletvos;')
w("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
w("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
w(f'\t\t\t\tTVOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};')
w("\t\t\t\tVALIDATE_PRODUCT = YES;")
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")

# Target-level Debug
w(f"\t\t{DEBUG_CONFIG_TARGET} /* Debug */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = \"App Icon & Top Shelf Image\";")
w(f'\t\t\t\tCODE_SIGN_STYLE = Automatic;')
w(f'\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Situation Room";')
w(f'\t\t\t\tINFOPLIST_KEY_NSAppTransportSecurity_NSAllowsArbitraryLoads = YES;')
w("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
w('\t\t\t\t\t"$(inherited)",')
w('\t\t\t\t\t"@executable_path/Frameworks",')
w("\t\t\t\t);")
w(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";')
w(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
w(f'\t\t\t\tGENERATE_INFOPLIST_FILE = YES;')
w(f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
w(f'\t\t\t\tSWIFT_VERSION = 5.0;')
w(f'\t\t\t\tTARGETED_DEVICE_FAMILY = 3;')
w(f'\t\t\t\tTVOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};')
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")

# Target-level Release
w(f"\t\t{RELEASE_CONFIG_TARGET} /* Release */ = {{")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
w("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = \"App Icon & Top Shelf Image\";")
w(f'\t\t\t\tCODE_SIGN_STYLE = Automatic;')
w(f'\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Situation Room";')
w(f'\t\t\t\tINFOPLIST_KEY_NSAppTransportSecurity_NSAllowsArbitraryLoads = YES;')
w("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
w('\t\t\t\t\t"$(inherited)",')
w('\t\t\t\t\t"@executable_path/Frameworks",')
w("\t\t\t\t);")
w(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";')
w(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
w(f'\t\t\t\tGENERATE_INFOPLIST_FILE = YES;')
w(f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
w(f'\t\t\t\tSWIFT_VERSION = 5.0;')
w(f'\t\t\t\tTARGETED_DEVICE_FAMILY = 3;')
w(f'\t\t\t\tTVOS_DEPLOYMENT_TARGET = {DEPLOY_TARGET};')
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")

w("/* End XCBuildConfiguration section */")
w("")

# XCConfigurationList
w("/* Begin XCConfigurationList section */")
w(f"\t\t{BUILD_CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{DEBUG_CONFIG_PROJECT} /* Debug */,")
w(f"\t\t\t\t{RELEASE_CONFIG_PROJECT} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w(f"\t\t{BUILD_CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget */ = {{")
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w(f"\t\t\t\t{DEBUG_CONFIG_TARGET} /* Debug */,")
w(f"\t\t\t\t{RELEASE_CONFIG_TARGET} /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w("/* End XCConfigurationList section */")
w("")

w("\t};")
w(f"\trootObject = {PROJECT_ID} /* Project object */;")
w("}")

# Write the file
os.makedirs(PROJ_DIR, exist_ok=True)
pbxproj_path = os.path.join(PROJ_DIR, "project.pbxproj")
with open(pbxproj_path, "w") as f:
    f.write("\n".join(lines))

print(f"Generated {pbxproj_path}")
print(f"  {len(swift_files)} Swift files included")
print(f"  Target: tvOS {DEPLOY_TARGET}")
print(f"  Bundle ID: {BUNDLE_ID}")
