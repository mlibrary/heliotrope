BagIt (for ruby)
================

[![Build Status](https://travis-ci.org/tipr/bagit.svg?branch=master)](http://travis-ci.org/tipr/bagit) [![Coverage Status](https://coveralls.io/repos/github/tipr/bagit/badge.svg?branch=master)](https://coveralls.io/github/tipr/bagit?branch=master)

This is a Ruby library and command line utility for creating BagIt archives based on the [BagItspec v0.97](https://confluence.ucop.edu/display/Curation/BagIt).

Supported Features:
-------------------
* Bag creation
* Manifest & tagmanifest generation
* Generation of tag files bag-info.txt and bagit.txt
* Fetching remote files (fetch.txt)
* Bag validation

Installation
------------
    # gem install bagit validatable

Example: making a bag
---------------------
    require 'bagit'

    # make a new bag at base_path
    bag = BagIt::Bag.new base_path

    # make a new file
    bag.add_file("samplefile") do |io|
      io.puts "Hello Bag!"
    end

    # generate the manifest and tagmanifest files
    bag.manifest!(algo: 'sha256')

Example: validating an existing bag
-----------------------------------

    bag = BagIt::Bag.new existing_base_path

    if bag.valid?
      puts "#{existing_base_path} is valid"
    else
      puts "#{existing_base_path} is not valid"
    end

Console Tool
------------
    # create a new bag/add files to existing bag
    bagit add -f file1 file2 -t tagfile1 tagfile2 ./path/to/bag	
    # validate
    bagit validate ./path/to/bag
    # for other commands
    bagit --help

Copyright © 2009, [Francesco Lazzarino](mailto:flazzarino@gmail.com).

Current maintainer: [Jamie Little](mailto:jamie@jamielittle.org).

Initial development sponsored by [Florida Center for Library Automation](http://www.fcla.edu).

See LICENSE.txt for terms.
