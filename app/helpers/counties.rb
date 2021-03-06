module Counties
  SAN_FRANCISCO = {
    name: 'San Francisco',
    courthouses: ['CASC San Francisco', 'CASC San Francisco Co', 'CAMC San Francisco'],
    misdemeanors: false,
    ada: { name: 'Sharon Woo', state_bar_number: '148139' }
  }.freeze
  LOS_ANGELES = {
    name: 'Los Angeles',
    courthouses: [
      'CAMC Beverly Hills',
      'CAMC Compton',
      'CAMC Culver City',
      'CAMC El Monte',
      'CAMC Glendale',
      'CAMC Hollywood',
      'CAMC Long Beach',
      'CAMC Los Angeles Metro',
      'CAMC San Fernando',
      'CAMC Santa Monica',
      'CAMC Van Nuys',
      'CASC Alhambra',
      'CASC Beverly Hills',
      'CASC Glendale',
      'CASC Long Beach',
      'CASC Los Angeles',
      'CASC MC Van Nuys',
      'CASC San Fernando',
      'CASC West Covina',
      'CASC West LA Airport',
      'CASC Los Angeles Central'
    ]
  }.freeze
  SAN_JOAQUIN = {
    name: 'San Joaquin',
    courthouses: [
      'CAMC Lodi',
      'CAMC Stockton',
      'CASC Lodi',
      'CASC Manteca',
      'CASC Stockton',
      'CASC Tracy'
    ]
  }.freeze
  CONTRA_COSTA = {
    name: 'Contra Costa',
    courthouses: [
      'CAMC Richmond',
      'CAMC Walnut Creek',
      'CASC Richmond',
      'CASC Walnut Creek'
    ]
  }.freeze
  SACRAMENTO = {
    name: 'Sacramento',
    courthouses: [
      'CAJV Sacramento',
      'CASC MC Sacramento',
      'CASC Sacramento'
    ]
  }.freeze
end
