local addonName, FJ = ...

FJ.Name = addonName
FJ.Version = "0.1.0-beta.3"

function FJ.Initialize()
    FJ.Storage.Initialize()
    FJ.Launcher.Initialize()
end