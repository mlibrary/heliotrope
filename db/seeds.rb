# This file should contain all the record creation needed to seed the database with its default values, or update those values when necessary.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

def michigan
  Press.where(name: 'University of Michigan Press').first_or_initialize.tap do |press|
    press.logo_path = 'http://www.press.umich.edu/images/umpre/logo.png'
    press.description = '[The University of Michigan Press](http://www.press.umich.edu/) publishes academic and general books about contemporary political, social, and cultural issues.'
    press.subdomain = 'michigan'
    press.press_url = 'http://www.press.umich.edu'
    press.save
  end
  puts "updated/created michigan"
end

def pennstate
  Press.where(name: 'Penn State University Press').first_or_initialize.tap do |press|
    press.logo_path = 'http://www.psupress.org/site_images/logo_psupress.gif'
    press.description = 'The Penn State University Press publishes academic books and journals, especially art history, philosophy, literature, religion, and political science. This page is the home of supplemental content for select Penn State University Press books. You can find the full catalog of Penn State titles on the [publisher\'s website](http://www.psupress.org/).'
    press.subdomain = 'pennstate'
    press.press_url = 'http://www.psupress.org'
    press.typekit = 'cbh1mev'
    press.save
  end
  puts "updated/created pennstate"
end

def indiana
  Press.where(name: 'Indiana University Press').first_or_initialize.tap do |press|
    press.logo_path = 'https://assets.iu.edu/brand/2.x/trident-large.png'
    press.description = "Indiana University Press's mission is to inform and inspire scholars, students, and thoughtful general readers by disseminating ideas and knowledge of global significance, regional importance, and lasting value."
    press.subdomain = 'indiana'
    press.press_url = 'http://www.iupress.indiana.edu'
    press.save
  end
  puts "updated/created indiana"
end

def northwestern
  Press.where(name: 'Northwestern University Press').first_or_initialize.tap do |press|
    press.logo_path = 'northwestern.png'
    press.description = "Northwestern University Press is dedicated to publishing works of enduring scholarly and cultural value, extending the University’s mission to a community of readers throughout the world.<br/><br/>[northwestern.fulcrum.org](http://northwestern.fulcrum.org) is the home of supplemental content for select books. You can find the full catalog of Northwestern University Press titles at the [publisher's website](http://www.nupress.northwestern.edu/)."
    press.subdomain = 'northwestern'
    press.press_url = 'http://nupress.northwestern.edu/'
    press.typekit = 'wyq1mfc'
    press.save
  end
  puts "updated/created northwestern"
end

def minnesota
  Press.where(name: 'University of Minnesota Press').first_or_initialize.tap do |press|
    press.logo_path = 'minnesota.png'
    press.description = "Established in 1925, the University of Minnesota Press is recognized internationally for its innovative, boundary-breaking editorial program in the humanities and social sciences, and is committed to publishing books on the people, history, and natural environment of Minnesota and the Upper Midwest.<br/><br/>This page is the home of supplemental content for select University of Minnesota Press books. You can find the full catalog of Minnesota titles on the [publisher's website](https://www.upress.umn.edu/)."
    press.subdomain = 'minnesota'
    press.press_url = 'https://www.upress.umn.edu/'
    press.typekit = 'vqj2dgv'
    press.save
  end
  puts "updated/created minnesota"
end

if Rails.env.eql?('production')
  # add presses as they become ready for production
  northwestern
  minnesota
  pennstate
else
  northwestern
  pennstate
  indiana
  minnesota
  michigan
end
