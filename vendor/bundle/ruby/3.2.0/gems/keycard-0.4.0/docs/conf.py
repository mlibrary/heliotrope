# -*- coding: utf-8 -*-

import guzzle_sphinx_theme
from recommonmark.parser import CommonMarkParser

# -- General configuration ------------------------------------------------
project = u'Keycard'
copyright = u'2018, Regents of the University of Michigan'
author = u'Noah Botimer'
version = u'0.2.4'
release = u'0.2.4'


extensions = ['guzzle_sphinx_theme']
templates_path = ['_templates']
master_doc = 'index'

source_parsers = {
    '.md': CommonMarkParser,
}
source_suffix = ['.rst', '.md']

language = None
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
pygments_style = 'sphinx'
todo_include_todos = False


# -- Options for HTML output ----------------------------------------------
html_theme_path = guzzle_sphinx_theme.html_theme_path()
html_theme = 'guzzle_sphinx_theme'
html_static_path = ['_static']

# Guzzle theme options (see theme.conf for more information)
html_theme_options = {
    "project_nav_name": "Keycard",
}

html_sidebars = {
    '**': [
        'logo-text.html',
        'globaltoc.html',
        'searchbox.html',
    ]
}

