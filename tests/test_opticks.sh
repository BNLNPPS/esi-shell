#!/usr/bin/env bash

set -e

HOME=${HOME/\/root/$ESI_DIR}

opticks-full-prepare
ctest --test-dir $OPTICKS_PREFIX/build/okconf
ctest --test-dir $OPTICKS_PREFIX/build/sysrap -E STTFTest
ctest --test-dir $OPTICKS_PREFIX/build/ana
ctest --test-dir $OPTICKS_PREFIX/build/analytic
ctest --test-dir $OPTICKS_PREFIX/build/bin
ctest --test-dir $OPTICKS_PREFIX/build/CSG -E "CSGNodeTest|CSGPrimSpecTest|CSGPrimTest|CSGFoundryTest|CSGFoundry_getCenterExtent_Test|CSGFoundry_findSolidIdx_Test|CSGNameTest|CSGTargetTest|CSGTargetGlobalTest|CSGFoundry_MakeCenterExtentGensteps_Test|CSGFoundry_getFrame_Test|CSGFoundry_getFrameE_Test|CSGFoundry_getMeshName_Test|CSGFoundryLoadTest|CSGQueryTest|CSGSimtraceTest|CSGSimtraceRerunTest|CSGSimtraceSampleTest|CSGCopyTest"
ctest --test-dir $OPTICKS_PREFIX/build/qudarap -E "QSimTest|QOpticalTest|QSim_Lifecycle_Test|QSimWithEventTest"
ctest --test-dir $OPTICKS_PREFIX/build/CSGOptiX -E CSGOptiXRenderTest
ctest --test-dir $OPTICKS_PREFIX/build/gdxml
ctest --test-dir $OPTICKS_PREFIX/build/u4 -E "U4GDMLReadTest|U4RandomTest|U4TraverseTest"
ctest --test-dir $OPTICKS_PREFIX/build/g4cx -E G4CXRenderTest
