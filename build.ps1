# Not tested

function Install-Deps {
  $pkgList = nimble list --installed
  if ( $pkgList -contains 'kirpi') {
    echo "kirpi is already installed"
  }
  else {
    echo "Installing kirpi"
    nimble install kirpi
  }
}

$Error.Clear()
Get-Command nimble | Out-Null
if ( -not $Error.length -gt 0 ) {
  Install-Deps
}

$checkPathBin = Test-Path .\bin
if ( -not $checkPathBin -eq "True" ) {
  mkdir .\bin | Out-Null
}

nim c `
  -d:release `
  .\src\game.nim

mv -Force .\src\game.exe .\bin
