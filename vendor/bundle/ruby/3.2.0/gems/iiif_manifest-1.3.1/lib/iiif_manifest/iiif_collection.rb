module IIIFManifest
  class IIIFCollection < SimpleDelegator
    def viewing_hint
      return super if __getobj__.respond_to?(:viewing_hint)
      'multi-part'
    end
  end
end
