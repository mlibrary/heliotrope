# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Press.create!(name: 'University of Michigan Press',
              logo_path: 'http://www.press.umich.edu/images/umpre/logo.png',
              description: 'The University of Michigan Press (www.press.umich.edu/) Publishes academic and general books about contemporary political, social, and cultural issues.',
              subdomain: 'umich')

Press.create!(name: 'The Penn State University Press',
              logo_path: 'http://www.psupress.org/site_images/logo_psupress.gif',
              description: 'The Penn State University Press (www.psupress.org/) Publishes academic books and journals, especially art history, philosophy, literature, religion, and political science.',
              subdomain: 'psu')
