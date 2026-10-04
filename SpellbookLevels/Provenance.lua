SBL_Provenance = {}
function SBL_Provenance.Describe(e, db)
    local text = 'Data: ' .. (e.dataOrigin or e.dbSource or 'Bundled reference / saved trainer data')
    if e.observedBuild then
        text = text .. ' (client ' .. tostring(e.observedBuild) .. ')'
        if GetBuildInfo and tostring(e.observedBuild) ~= tostring(select(4, GetBuildInfo())) then
            text = text .. ' — visit a trainer to refresh'
        end
    elseif db and db.trainingDataNeedsReview then
        text = text .. ' — visit a trainer to refresh'
    end
    if e.costEstimated then text = text .. '; price is an estimate' end
    return text
end
function SBL_Provenance.Tooltip(e, db)
    GameTooltip:AddLine(SBL_Provenance.Describe(e, db), .8, .8, .65, true)
end
