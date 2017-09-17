-- A Lua script

-- This lms Lua script creates the targets required to build, diff or 
-- install a suite of Contests based unit tests. 

require 'lms.c'

contests     = contests     or { }
lms.contests = lms.contests or { }

local contestsDefaults = {
  contestsIncDir =
    makePath{
      getEnv('HOME'), 'texmf', 't-contests', 'tex',
      'context', 'third', 'contests'
    },
  contestsStartup = 't-contests-cTests.lua'
}

contests = hMerge(contestsDefaults, lms.contests, contests)

docTargets     = docTargets     or { }
buildTargets   = buildTargets   or { }
installTargets = installTargets or { }
diffTargets    = diffTargets    or { }
testTargets    = testTargets    or { }

function contests.targets(cDef)

  cDef.dependencies = { }
  tInsert(cDef.docFiles, 1, cDef.mainDoc)
  for i, aDocFile in ipairs(cDef.docFiles) do
    tInsert(cDef.dependencies, makePath{ cDef.docDir, aDocFile })
  end

  for i, aTestExec in ipairs(cDef.testExecs) do
  
    local srcTarget = makePath{ cDef.buildDir, aTestExec..'.c' }
    tInsert(buildTargets, srcTarget)
    target(hMerge(cDef, {
      target  = srcTarget,
      command = litProgs.compileLitProg
    }))
    
    local testExecTarget = makePath{ cDef.buildDir, aTestExec }
    local cDependencies = { }
    tInsert(cDependencies, srcTarget)
    for j, aSrcFile in ipairs(cDef.srcFiles) do
      tInsert(cDependencies, makePath{ cDef.buildDir, aSrcFile })
    end
    local pDef = hMerge(c, cDef)
    tInsert(pDef.cOpts, tConcat({
      '-DCONTESTS_STARTUP=\\"',
      makePath{
        contests.contestsIncDir,
        contests.contestsStartup
      },
      '\\"'
    }, ''))
    tInsert(pDef.cIncs, '-I'..contests.contestsIncDir)
    c.program(hMerge(pDef, {
      target       = testExecTarget,
      dependencies = c.collectCDependencies(cDependencies),
      needs        = { 'lua5.2' }
    }))
    
    local testTarget = makePath{ cDef.buildDir, aTestExec..'-results.lua' }
    tInsert(testTargets, testTarget)
    target(hMerge(cDef, {
      target       = testTarget,
      dependencies = { testExecTarget },
      command      = testExecTarget
    }))
  end
  
end

