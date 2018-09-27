module CodeSections
  PROP64_DISMISSIBLE =
    [
      'HS 11357', # simple possession
      'HS 11358', # cultivation
      'HS 11359', # possession for sale
      'HS 11360', # transportation for sale
    ].freeze

  PROP64_INELIGIBLE =
    [
      'HS 11359(c)(3)',
      'HS 11359(d)',
      'HS 11360(a)(3)(c)',
      'HS 11360(a)(3)(d)'
    ].freeze
end
