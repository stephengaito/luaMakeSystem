-- A Lua script

-- This lms Lua script creates the targets required to build, diff or 
-- install a literate programming project. 

litProgs     = litProgs     or { }
lms.litProgs = lms.litProgs or { }

-- no module defaults

litProgs = hMerge(lms.litProgs, litProgs)

local function compileLitProg(lpDef, onExit)
  local curDir = lfs.currentdir()
  chDir(lpDef.docDir)
  --
  -- build the litProg output using simple one context pass...
  --
  executeCmd(lpDef.target, 'context --nonstopmode --mode=codeOnly --once '..lpDef.mainDoc, function(code, signal)
    --
    -- remove the PDF file since we only want the litProg output
    --
    os.remove(lpDef.mainDoc:gsub('%.tex$', '.pdf')) 
    --
    onExit(code, signal)
  end)

  chDir(curDir)
end

local function installTarget(aDef, installDir, aFile)
  local buildTarget = makePath{ aDef.buildDir, aFile } 
  local diffTarget      = 'diff-'..aFile
  local installedTarget = aFile
  if installDir then
    installedTarget = makePath{ installDir, aFile }
  end

  local installDep = { buildTarget }
  parentPath = getParentPath(installedTarget)
  if parentPath then
    ensurePathExists(parentPath)
    aInsertOnce(installDep, parentPath)
  end
  
  aInsertOnce(installTargets, installedTarget)
  target(hMerge(aDef, {
    target       = installedTarget,
    dependencies = installDep,
    command      = 'cp '..buildTarget..' '..installedTarget,
    commandName  = 'LitProgs::installedTarget (shell command)'
  }))
  
  tInsert(cleanTargets, nameCleanTarget(buildTarget))
end

-- This assumes that installTarget has been run...
-- This target is used to see how much the new version (in the build 
-- directory) differs from the old version (in the installed location).
-- As such we do NOT want to install the new version just yet!
local function diffTarget(aDef, installDir, aFile)
  local buildTarget = makePath{ aDef.buildDir, aFile } 
  local diffTarget      = 'diff-'..aFile
  local installedTarget = aFile
  if installDir then
    installedTarget = makePath{ installDir, aFile }
  end
  aInsertOnce(diffTargets, diffTarget)
  target(hMerge(aDef, {
    target       = diffTarget,
    dependencies = { buildTarget },
    command      = 'diff '..buildTarget..' '..installedTarget,
    commandName  = 'LitProgs::diffTarget (shell command)'
  }))
end

function litProgs.targets(defaultDef, lpDef)

  lpDef = hMerge(defaultDef, lpDef or { })
  lpDef.creator = 'litProgs-targets'

--  print('lpDef: '..prettyPrint(lpDef))

  lpDef.docFiles = nil
  findDocumentsIn(lpDef, { lpDef.docDir })

  lpDef.compileLitProg = compileLitProg
  lpDef.installTarget  = installTarget
  lpDef.diffTarget     = diffTarget

  aInsertOnce(lpDef.directories, makePath { lpDef.buildDir, prefixDir })
  for i, aDir in ipairs(lpDef.directories) do
    local aLitProgDir = makePath{lpDef.buildDir, prefixDir, aDir}
    ensurePathExists(aLitProgDir)
    aInsertOnce(lpDef.dependencies, aLitProgDir)
  end

  local litProgsMainDoc = 'litProgs-'..lpDef.mainDoc
  
  lpDef.autoGenerated = lpDef.autoGenerated or { }
  local autoGenerated = lpDef.autoGenerated
  for aSrcType, someSrcFiles in pairs(autoGenerated) do
    lpDef[aSrcType] = lpDef[aSrcType] or { }
    local lpDefSrcType = lpDef[aSrcType]
    for i, aSrcFile in ipairs(someSrcFiles) do
      aInsertOnce(lpDefSrcType, aSrcFile)
      local buildTarget = makePath{ lpDef.buildDir, dirPrefix, aSrcFile }
      local parentPath  = getParentPath(buildTarget)
      if parentPath then
        ensurePathExists(parentPath)
        aInsertOnce(lpDef.dependencies, parentPath)
      end
      target(hMerge(lpDef, {
        target      = buildTarget,
        dependencies = { litProgsMainDoc }
      }))
    end
  end

  target(hMerge(lpDef, {
    target      = litProgsMainDoc,
    noOutput    = true,
    command     = compileLitProg,
    commandName = 'LitProgs::compileLitProg'
  }))

  installTarget(lpDef, nil, makePath{ dirPrefix, 'lmsfile'})
  diffTarget(lpDef, nil, makePath{ dirPrefix, 'lmsfile'})
    
  return lpDef
end
