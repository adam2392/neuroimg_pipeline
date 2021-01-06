import os
import sys
from datetime import date

import sphinx_bootstrap_theme
import sphinx_gallery  # noqa: F401
from sphinx_gallery.sorting import ExampleTitleSortKey

sys.path.append('../')
import seek

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.

curdir = os.path.dirname(__file__)
sys.path.append(os.path.abspath(os.path.join(curdir, '..', 'seek')))
sys.path.append(os.path.abspath(os.path.join(curdir, 'sphinxext')))

# -- Project information -----------------------------------------------------

project = seek.__name__
td = date.today()
copyright = u'2019-%s, SEEK Developers. Last updated on %s' % (td.year,
                                                               td.isoformat())

author = u'SEEK Developers'

# The short X.Y version
version = seek.__version__
# The full version, including alpha/beta/rc tags
release = version

# -- General configuration ---------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#
# needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx.ext.githubpages',
    'sphinx.ext.autodoc',
    'sphinx.ext.mathjax',
    'sphinx.ext.viewcode',
    'sphinx.ext.autosummary',
    'sphinx.ext.doctest',
    'sphinx.ext.intersphinx',
    'sphinx_gallery.gen_gallery',
    'sphinx.ext.autosectionlabel',
    'numpydoc',
    'sphinx_copybutton',
    # "seek.sphinxext.snakemakerule",
]

# generate autosummary even if no references
autosummary_generate = True
autodoc_default_options = {'inherited-members': None}
numpydoc_class_members_toctree = False
numpydoc_attributes_as_param_list = True
default_role = 'autolink'  # XXX silently allows bad syntax, someone should fix

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = None

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = None

# -- Options for HTML output -------------------------------------------------

# HTML options (e.g., theme)
# see: https://sphinx-bootstrap-theme.readthedocs.io/en/latest/README.html
# Clean up sidebar: Do not show "Source" link
html_show_sourcelink = False

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'bootstrap'
html_theme_path = sphinx_bootstrap_theme.get_html_theme_path()

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
# html_theme_options = {}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
html_theme_options = {
    'navbar_title': 'SEEK',
    'bootswatch_theme': "flatly",
    'navbar_sidebarrel': False,  # no "previous / next" navigation
    'navbar_pagenav': False,  # no "Page" navigation in sidebar
    'bootstrap_version': "3",
    'navbar_links': [
        # here list header string to show, and the rst filename
        ('News', 'whats_new'),
        ('Install', 'installation'),
        ('Tutorials', 'auto_examples/index'),
        ("Pipeline Description", "pipeline_description"),
        # ('Python API', 'api'),
        ("Contribute!", "contributing"),
        ("GitHub", "https://github.com/ncsl/seek", True),
    ]
}

# Example configuration for intersphinx: refer to the Python standard library.
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'mne': ('https://mne.tools/dev', None),
    'mne-bids': ('https://mne.tools/mne-bids/dev', None),
    'numpy': ('https://numpy.org/devdocs', None),
    'scipy': ('https://scipy.github.io/devdocs', None),
    'matplotlib': ('https://matplotlib.org', None),
    'nilearn': ('https://nilearn.github.io', None),
    'snakemake': ('https://snakemake.readthedocs.io/en/stable/', None),
}
intersphinx_timeout = 5

# Resolve binder filepath_prefix. From the docs:
# "A prefix to append to the filepath in the Binder links. You should use this
# if you will store your built documentation in a sub-folder of a repository,
# instead of in the root."
# we will store dev docs in a `dev` subdirectory and all other docs in a
# directory "v" + version_str. E.g., "v0.3"
if 'dev' in version:
    filepath_prefix = 'dev'
else:
    filepath_prefix = 'v{}'.format(version)

sphinx_gallery_conf = {
    'examples_dirs': ['../tutorials'],
    'within_subsection_order': ExampleTitleSortKey,
    'gallery_dirs': ['auto_examples', 'auto_tutorials'],
    'filename_pattern': '^((?!sgskip).)*$',
    'backreferences_dir': 'generated',
}

# def collect_pages(app: Sphinx):
#     """Add Snakefiles to documentation (in HTML mode)
#     """
#     if not hasattr(app.env, '_snakefiles'):
#         return
#
#     highlight_block = app.builder.highlighter.highlight_block
#
#     for snakefile in app.env._snakefiles:
#         try:
#             with open(os.path.join(BASEPATH, snakefile), 'r') as f:
#                 code = f.read()
#         except IOError:
#             logger.error("failed to open {}".format(snakefile))
#             continue
#         highlighted = highlight_block(code, 'snakemake', lineanchors="line")
#         context = {
#             'title': snakefile,
#             'body': '<h1>Snakefile "{}"</h1>'.format(snakefile) +
#             highlighted
#         }
#         yield (os.path.join('_snakefiles', snakefile), context, 'page.html')
#
#     html = ['\n']
#     context = {
#         'title': ('Overview: Snakemake rule files'),
#         'body': '<h1>All Snakemake rule files</h1>' +
#         ''.join(html)
#     }
#     yield ('_snakefiles/index', context, 'page.html')