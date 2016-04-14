# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
Press.create!(name: 'University of Michigan Press',
              logo_path: 'http://www.press.umich.edu/images/umpre/logo.png',
              description: 'The University of Michigan Press (www.press.umich.edu/) Publishes academic and general books about contemporary political, social, and cultural issues.',
              subdomain: 'michigan')

Press.create!(name: 'Penn State University Press',
              logo_path: 'http://www.psupress.org/site_images/logo_psupress.gif',
              description: 'The Penn State University Press (www.psupress.org/) Publishes academic books and journals, especially art history, philosophy, literature, religion, and political science.',
              subdomain: 'pennstate')

Press.create!(name: 'Indiana University Press',
              logo_path: 'https://assets.iu.edu/brand/2.x/trident-large.png',
              description: "Indiana University Press's mission is to inform and inspire scholars, students, and thoughtful general readers by disseminating ideas and knowledge of global significance, regional importance, and lasting value.",
              subdomain: 'indiana')

Press.create!(name: 'Northwestern University Press',
              logo_path: 'http://www.nupress.northwestern.edu/sites/all/themes/nupress/images/northwestern-press-logo-old.png',
              description: "Northwestern University Press is dedicated to publishing works of enduring scholarly and cultural value, extending the university’s mission to a community of readers throughout the world.",
              subdomain: 'northwestern')

Press.create!(name: 'University of Minnesota Press',
              logo_path: 'http://www.upress.umn.edu/++theme++ump.theme/_images/logo.gif',
              description: "The University of Minnesota Press holds a strong commitment to publishing books on the people, history, and natural environment of Minnesota and the Upper Midwest",
              subdomain: 'minnesota')
