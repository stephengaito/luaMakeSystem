-- A Lua script

-- This lms Lua script creates the targets required to build, diff or 
-- install a literate programming project. 

litProgs = { }
docTargets     = docTargets     or { }
buildTargets   = buildTargets   or { }
installTargets = installTargets or { }
diffTargets    = diffTargets    or { }

local function compileDocument(lpDef)
  local curDir = lfs.currentdir()
  chDir(lpDef.docDir)
  --
  -- build the complete context document
  --
  local result = executeCmd('context '..lpDef.mainDoc)
  --
  chDir(curDir)
  return result
end

local function compileLitProg(lpDef)
  local curDir = lfs.currentdir()
  chDir(lpDef.docDir)
  --
  -- build the litProg output usning simple one context pass...
  --
  local result = executeCmd('context --once '..lpDef.mainDoc)
  --
  -- remove the PDF file since we only want the litProg output
  --
  os.remove(lpDef.mainDoc:gsub('%.tex$', '.pdf')) 
  --
  chDir(curDir)
  return result
end

function litProgs.targets(lpDef)
  
  lpDef.dependencies = { }
  tInsert(lpDef.docFiles, 1, lpDef.mainDoc)
  for i, aDocFile in ipairs(lpDef.docFiles) do
    tInsert(lpDef.dependencies, lpDef.docDir..'/'..aDocFile)
  end
  
  for i, aSrcFile in ipairs(lpDef.srcFiles) do
    
    local srcTarget = lpDef.buildDir..'/'..aSrcFile
    tInsert(buildTargets, srcTarget)
    target(hMerge(lpDef, {
      target  = srcTarget,
      command = compileLitProg
    }))

    local diffTarget   = 'diff-'..aSrcFile
    local moduleTarget = lpDef.moduleDir..'/'..aSrcFile
    tInsert(diffTargets, diffTarget)
    target(hMerge(lpDef, {
      target       = diffTarget,
      dependencies = { srcTarget, moduleTarget },
      command      = 'diff '..srcTarget..' '..moduleTarget
    }))

    local installTarget = 'install-'..aSrcFile
    tInsert(installTargets, installTarget)
    target(hMerge(lpDef, {
      target       = installTarget,
      dependencies = { srcTarget },
      command      = 'cp '..srcTarget..' '..moduleTarget
    }))
  end
  
  local srcTarget = lpDef.buildDir..'/lmsfile'
  tInsert(buildTargets, srcTarget)
  target(hMerge(lpDef, {
    target  = srcTarget,
    command = compileLitProg
  }))
      
  local diffTarget   = 'diff-lmsfile'
  local moduleTarget = 'lmsfile'
  tInsert(diffTargets, diffTarget)
  target(hMerge(lpDef, {
    target       = diffTarget,
    dependencies = { srcTarget, moduleTarget },
    command      = 'diff '..srcTarget..' '..moduleTarget
  }))

  local installTarget = 'install-lmsfile'
  tInsert(installTargets, installTarget)
  target(hMerge(lpDef, {
    target       = installTarget,
    dependencies = { srcTarget },
    command      = 'cp '..srcTarget..' '..moduleTarget
  }))

  local docTarget = lpDef.docDir..'/'..lpDef.mainDoc:gsub('%.tex$', '.pdf')
  tInsert(docTargets, docTarget)
  target(hMerge(lpDef, {
    target  = docTarget,
    command = compileDocument
  }))
end