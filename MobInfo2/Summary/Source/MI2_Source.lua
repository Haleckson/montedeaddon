MI2_SourceMixin = {}

function MI2_SourceMixin:Init()
end

function MI2_SourceMixin:AverageAmount()
  if self.Amount and self.NumSources then
    return self.Amount / self.NumSources
  end
end
