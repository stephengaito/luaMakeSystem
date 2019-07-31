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
  executeCmd(lpDef.target, 'context --silent=all --once '..lpDef.mainDoc, function(code, signal)
    --
    -- remove the PDF file since we only want the litProg output
    --
    os.remove(lpDef.mainDoc:gsub('%.tex$', '.pdf')) 
    --
    chDir(curDir)
    onExit(code, signal)
  end)
end

local function installAndDiff(aDef, installDir, aFile)
  local buildTarget = makePath{ aDef.buildDir, aFile }
  local parentPath  = getParentPath(buildTarget)
  if parentPath then
    ensurePathExists(parentPath)
    tInsert(aDef.dependencies, parentPath)
  end
  aInsertOnce(buildTargets, buildTarget)
  target(hMerge(aDef, {
    target      = buildTarget,
    command     = compileLitProg,
    commandName = "LitProgs::compileLitProg"
  }))
      
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

function litProgs.targets(defaultDef, lpDef)

  lpDef = hMerge(defaultDef, lpDef or { })
  lpDef.creator = 'litProgs-targets'
  
  findSubDirs(lpDef)
  findDocuments(lpDef)

  lpDef.compileLitProg = compileLitProg
  lpDef.installAndDiff = installAndDiff

  lpDef.dependencies = lpDef.dependencies or { }

  for i, aDir in ipairs(lpDef.directories) do
    local aLitProgDir = makePath{lpDef.buildDir, aDir}
    ensurePathExists(aLitProgDir)
    aInsertOnce(lpDef.dependencies, aLitProgDir)
  end
  

  installAndDiff(lpDef, nil, 'lmsfile')
    
  return lpDef
end
