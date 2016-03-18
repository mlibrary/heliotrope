# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Press.create!(name: 'University of Michigan Press',
              logo_path: 'http://www.press.umich.edu/images/umpre/logo.png',
              description: 'A description of the press',
              subdomain: 'umich')

Press.create!(name: 'The Penn State University Press',
              logo_path: 'http://www.psupress.org/site_images/logo_psupress.gif',
              description: 'A description of the press',
              subdomain: 'psu')
