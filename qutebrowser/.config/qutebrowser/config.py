# Qutebrowser configuration file

# Set default search engine
c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'g': 'https://www.google.com/search?q={}',
    'gh': 'https://github.com/search?q={}',
    'so': 'https://stackoverflow.com/search?q={}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'mdn': 'https://developer.mozilla.org/en-US/search?q={}',
    'rust': 'https://doc.rust-lang.org/std/?search={}',
    'py': 'https://docs.python.org/3/search.html?q={}',
    'cs': 'https://docs.microsoft.com/en-us/search/?terms={}',
}

# Set start pages
c.url.start_pages = ['https://duckduckgo.com']
c.url.default_page = 'https://duckduckgo.com'

# Download directory
c.downloads.location.directory = '~/Downloads'
c.downloads.location.prompt = False

# Tab behavior
c.tabs.position = 'top'
c.tabs.show = 'multiple'
c.tabs.background = True
c.tabs.new_position.related = 'next'
c.tabs.new_position.unrelated = 'last'

# Font settings for developers
c.fonts.default_family = ['JetBrains Mono', 'Source Code Pro', 'Fira Code', 'monospace']
c.fonts.default_size = '10pt'
c.fonts.web.family.monospace = 'JetBrains Mono, Source Code Pro, Fira Code, monospace'

# Dark mode preference
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = 'never'
c.colors.webpage.darkmode.policy.page = 'auto'

# Privacy settings
c.content.headers.do_not_track = True
c.content.cookies.accept = 'no-3rdparty'
c.content.geolocation = 'ask'
c.content.notifications.enabled = 'ask'

# Development-friendly settings
c.content.developer_extras = True
c.content.javascript.enabled = True
c.content.autoplay = False

# Vim-style completion
c.completion.height = '50%'
c.completion.open_categories = ['searchengines', 'quickmarks', 'bookmarks', 'history']
c.completion.show = 'auto'

# Scrolling behavior
c.scrolling.smooth = True
c.scrolling.bar = 'when-searching'

# Status bar settings
c.statusbar.show = 'always'
c.statusbar.position = 'bottom'

# Performance settings
c.content.cache.size = 52428800  # 50 MB
c.session.lazy_restore = True

# Security settings
c.content.ssl_strict = 'ask'
c.content.host_blocking.enabled = True
c.content.host_blocking.lists = [
    'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
]

# Key bindings for developers
config.bind('pw', 'spawn --userscript password_fill')
config.bind('<Ctrl-Shift-I>', 'devtools')
config.bind('<F12>', 'devtools')
config.bind('xb', 'config-cycle statusbar.show always never')
config.bind('xt', 'config-cycle tabs.show always switching never')
config.bind('xx', 'config-cycle statusbar.show always never;; config-cycle tabs.show always switching never')

# Quick bookmark shortcuts
config.bind(',g', 'open https://github.com')
config.bind(',gh', 'open https://github.com/{}'.format('YOUR_USERNAME'))  # Replace with your GitHub username
config.bind(',so', 'open https://stackoverflow.com')
config.bind(',mdn', 'open https://developer.mozilla.org')
config.bind(',rust', 'open https://doc.rust-lang.org')
config.bind(',py', 'open https://docs.python.org/3/')

# Gruvbox-inspired color scheme for developers
# Define color palette
base03 = '#282828'
base02 = '#32302f'
base01 = '#3c3836'
base00 = '#504945'
base0 = '#665c54'
base1 = '#7c6f64'
base2 = '#928374'
base3 = '#a89984'
base4 = '#bdae93'
orange = '#fe8019'
red = '#fb4934'
magenta = '#d3869b'
violet = '#b16286'
blue = '#83a598'
cyan = '#8ec07c'
green = '#b8bb26'
yellow = '#fabd2f'

# Apply color scheme
# Background color of the completion widget
c.colors.completion.bg = base03
# Text color of completion widget
c.colors.completion.fg = base3
# Background color of the completion widget for odd rows
c.colors.completion.odd.bg = base02
# Text color of the completion widget for odd rows
c.colors.completion.odd.fg = base3
# Color of the scrollbar in the completion view
c.colors.completion.scrollbar.bg = base03
c.colors.completion.scrollbar.fg = base0

# Completion categories
c.colors.completion.category.bg = blue
c.colors.completion.category.fg = base03
c.colors.completion.category.border.bottom = blue
c.colors.completion.category.border.top = blue

# Selected completion item
c.colors.completion.item.selected.bg = base01
c.colors.completion.item.selected.fg = base3
c.colors.completion.item.selected.border.bottom = base01
c.colors.completion.item.selected.border.top = base01

# Status bar
c.colors.statusbar.normal.bg = base03
c.colors.statusbar.normal.fg = base3
c.colors.statusbar.insert.bg = green
c.colors.statusbar.insert.fg = base03
c.colors.statusbar.command.bg = base03
c.colors.statusbar.command.fg = base3
c.colors.statusbar.caret.bg = violet
c.colors.statusbar.caret.fg = base03

# Tabs
c.colors.tabs.bar.bg = base03
c.colors.tabs.even.bg = base02
c.colors.tabs.even.fg = base3
c.colors.tabs.odd.bg = base03
c.colors.tabs.odd.fg = base3
c.colors.tabs.selected.even.bg = base01
c.colors.tabs.selected.even.fg = base4
c.colors.tabs.selected.odd.bg = base01
c.colors.tabs.selected.odd.fg = base4

# Hints
c.colors.hints.bg = yellow
c.colors.hints.fg = base03
c.colors.hints.match.fg = green

# Downloads
c.colors.downloads.bar.bg = base03
c.colors.downloads.start.bg = blue
c.colors.downloads.start.fg = base03
c.colors.downloads.stop.bg = cyan
c.colors.downloads.stop.fg = base03
c.colors.downloads.error.bg = red
c.colors.downloads.error.fg = base03

# Messages
c.colors.messages.error.bg = red
c.colors.messages.error.fg = base03
c.colors.messages.warning.bg = orange
c.colors.messages.warning.fg = base03
c.colors.messages.info.bg = blue
c.colors.messages.info.fg = base03

# Prompts
c.colors.prompts.bg = base02
c.colors.prompts.fg = base3
c.colors.prompts.border = base01
c.colors.prompts.selected.bg = base01
c.colors.prompts.selected.fg = base3
